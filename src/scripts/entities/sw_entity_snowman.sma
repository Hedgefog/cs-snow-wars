#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>
#include <xs>

#include <snowwars>
#include <api_custom_entities>

#define PLUGIN "[Entity] Snowman"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define IS_PLAYER(%1) (%1 > 0 && %1 <= MaxClients)

#define ENTITY_NAME "sw_snowman"

#define RESPAWN_DELAY 5.0
#define CHANGE_DIRECTION_RATE 0.5

new g_iPlayerDeadFlag[MAX_PLAYERS + 1];
new g_iCeHandler;
new g_iBloodModelIndex;

public plugin_precache() {
    g_iCeHandler = CE_Register(
        .szName = ENTITY_NAME,
        .vMins = Float:{-16.0, -16.0, 0.0},
        .vMaxs = Float:{16.0, 16.0, 72.0},
        .modelIndex = precache_model(SW_MODEL_SNOWMAN),
        .preset = CEPreset_Prop
    );

    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
    CE_RegisterHook(CEFunction_Kill, ENTITY_NAME, "@Entity_Kill");

    g_iBloodModelIndex = precache_model("sprites/blood.spr");
    precache_sound(SW_SOUND_SNOWBALL_HIT);
    precache_sound(SW_SOUND_RETURN);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", .Post = 1);
    RegisterHam(Ham_TakeDamage, CE_BASE_CLASSNAME, "Ham_Base_TakeDamage", .Post = 0);
    RegisterHam(Ham_Think, CE_BASE_CLASSNAME, "Ham_Base_Think_Post", .Post = 1);

    RegisterHookChain(RG_CSGameRules_CheckWinConditions, "HC_CheckWinConditions", .post = 0);
    RegisterHookChain(RG_CSGameRules_CheckWinConditions, "HC_CheckWinConditions_Post", .post = 1);
}

public client_disconnected(pPlayer) {
    @Player_UnassignSnowmans(pPlayer);
}

public HC_CheckWinConditions() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        new iPlayerDeadFlag = pev(pPlayer, pev_deadflag);

        if (iPlayerDeadFlag != DEAD_NO) {
            new pSnowman = @Player_FindSnowman(pPlayer);
            if (pSnowman) {
                set_pev(pPlayer, pev_deadflag, DEAD_NO);
                g_iPlayerDeadFlag[pPlayer] = iPlayerDeadFlag;
            }
        }
    }
}

public HC_CheckWinConditions_Post() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (g_iPlayerDeadFlag[pPlayer] != DEAD_NO) {
            set_pev(pPlayer, pev_deadflag, g_iPlayerDeadFlag[pPlayer]);
            g_iPlayerDeadFlag[pPlayer] = DEAD_NO;
        }
    }
}

public Ham_Player_Killed_Post(pPlayer) {
    set_task(RESPAWN_DELAY, "Task_PlayerRespawn", pPlayer);
}

public Ham_Base_TakeDamage(pEntity, pInflictor, pAttacker, Float:flDamage, iDamageBits) {
    if (CE_GetHandlerByEntity(pEntity) == g_iCeHandler) {
        if (!@Entity_CanTakeDamage(pEntity, pInflictor, pAttacker)) {
            return HAM_SUPERCEDE;
        }

        return HAM_HANDLED;
    }

    return HAM_IGNORED;
}

public Ham_Base_Think_Post(pEntity) {
    if (CE_GetHandlerByEntity(pEntity) == g_iCeHandler) {
        @Entity_Think(pEntity);
        return HAM_HANDLED;
    }

    return HAM_IGNORED;
}

public @Entity_Spawn(this) {
    engfunc(EngFunc_DropToFloor, this);

    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    set_pev(this, pev_health, 20.0);
    set_pev(this, pev_takedamage, DAMAGE_AIM);

    @Entity_Effect(this);
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

public @Entity_Kill(this) {
    @Entity_Effect(this);
}

public @Entity_Think(this) {
    new pOwner = pev(this, pev_owner);

    new iTeam = 0;
    new iSkin = 0;

    if (pOwner && IS_PLAYER(pOwner)) {
        iTeam = get_member(pOwner, m_iTeam);
        iSkin = iTeam == 1 || iTeam == 2 ? iTeam : 0;
    }

    set_pev(this, pev_skin, iSkin);
    set_pev(this, pev_team, iTeam);

    set_pev(this, pev_nextthink, get_gametime() + 1.0);
}

public @Entity_Effect(this) {
    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_BLOODSPRITE);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_short(g_iBloodModelIndex);
    write_short(g_iBloodModelIndex);
    write_byte(12);
    write_byte(8);
    message_end();

    emit_sound(this, CHAN_BODY, SW_SOUND_SNOWBALL_HIT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public bool:@Entity_CanTakeDamage(this, pInflictor, pAttacker) {
    new pOwner = pev(this, pev_owner);

    if (!pOwner || !IS_PLAYER(pOwner)) {
        return false;
    }

    if (pOwner == pAttacker) {
        return false;
    }

    if (!rg_is_player_can_takedamage(pOwner, pAttacker)) {
        return false;
    }

    return true;
}

public @Entity_RespawnPlayer(this, pPlayer) {
    ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);

    static Float:vecMins[3];
    pev(pPlayer, pev_mins, vecMins);

    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);
    vecOrigin[2] -= vecMins[2];

    static Float:vecAngles[3];
    pev(this, pev_angles, vecAngles);

    set_pev(pPlayer, pev_angles, vecAngles);
    set_pev(pPlayer, pev_v_angle, vecAngles);
    engfunc(EngFunc_SetOrigin, pPlayer, vecOrigin);

    emit_sound(pPlayer, CHAN_STATIC, SW_SOUND_RETURN, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    CE_Kill(this);
}

public @Player_UnassignSnowmans(this) {
    new pPlayerSnowman = 0;
    while ((pPlayerSnowman = engfunc(EngFunc_FindEntityByString, pPlayerSnowman, "classname", ENTITY_NAME)) != 0) {
        new pSnowmanOwner = pev(pPlayerSnowman, pev_owner);
        if (pSnowmanOwner == this) {
            set_pev(pPlayerSnowman, pev_owner, 0);
        }
    }
}

public @Player_FindSnowman(this) {
    new iTeam = get_member(this, m_iTeam);

    new pPlayerSnowman = 0;
    while ((pPlayerSnowman = engfunc(EngFunc_FindEntityByString, pPlayerSnowman, "classname", ENTITY_NAME)) != 0) {
        new pSnowmanOwner = pev(pPlayerSnowman, pev_owner);
        if (pSnowmanOwner == this) {
            return pPlayerSnowman;
        }
    }

    new pTeamSnowman = 0;
    while ((pTeamSnowman = engfunc(EngFunc_FindEntityByString, pTeamSnowman, "classname", ENTITY_NAME)) != 0) {
        new pSnowmanOwner = pev(pTeamSnowman, pev_owner);
        if (pSnowmanOwner) {
            continue;
        }

        if (pev(pTeamSnowman, pev_team) == iTeam) {
            return pTeamSnowman;
        }
    }

    new pSharedSnowman = 0;
    while ((pSharedSnowman = engfunc(EngFunc_FindEntityByString, pSharedSnowman, "classname", ENTITY_NAME)) != 0) {
        new pSnowmanOwner = pev(pSharedSnowman, pev_owner);
        if (pSnowmanOwner) {
            continue;
        }

        if (!pev(pTeamSnowman, pev_team)) {
            return pSharedSnowman;
        }
    }

    return 0;
}

public bool:@Player_TryRespawn(this) {
    new pSnowman = @Player_FindSnowman(this);
    if (!pSnowman) {
        return false;
    }

    @Entity_RespawnPlayer(pSnowman, this);

    return true;
}

public Task_PlayerRespawn(iTaskId) {
    new pPlayer = iTaskId;

    if (!is_user_alive(pPlayer)) {
        @Player_TryRespawn(pPlayer);
    }
}
