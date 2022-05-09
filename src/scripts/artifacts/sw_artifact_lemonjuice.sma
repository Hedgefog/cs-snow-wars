#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>

#include <snowwars>
#include <api_custom_entities>
#include <screenfade_util>

#define ARTIFACT_ID "lemonjuice"
#define SPLASH_DAMAGE 15.0

new const g_szSndSnowballHit[] = "debris/bustflesh1.wav";
new const g_szMdlWSnowball[] = "models/snowwars/v090/weapons/w_snowball_lemon.mdl";
new const g_szMdlWArtifact[] = "models/snowwars/v090/artifacts/w_lemonsnow.mdl";

new g_iSnowballCeHandler;

public plugin_precache() {
    precache_model(g_szMdlWArtifact);
    precache_sound(g_szSndSnowballHit);
    precache_model(g_szMdlWSnowball);

    SW_PlayerArtifact_Register(ARTIFACT_ID, "@Artifact_Activated", "@Artifact_Deactivated");
}

public plugin_init() {
    register_plugin("[Snow Wars] Lemon Juice Artifact", SW_VERSION, "Hedgehog Fog");

    RegisterHam(Ham_TakeDamage, "player", "Ham_Player_TakeDamage_Post", .Post = 1);

    CE_RegisterHook(CEFunction_Spawn, "sw_item_artifact", "@ArtifactItem_Spawn");
    CE_RegisterHook(CEFunction_Spawn, "sw_snowball", "@Snowball_Spawn");
    CE_RegisterHook(CEFunction_Kill, "sw_snowball", "@Snowball_Kill");

    register_event("ResetHUD", "Event_ResetHUD", "b");

    g_iSnowballCeHandler = CE_GetHandler("sw_snowball");
}

public Event_ResetHUD(pPlayer) {
    @Player_UpdateStatusIcon(pPlayer);
}

public @Artifact_Activated(this) {
    // new Float:flPower = SW_Player_GetAttribute(this, SW_PlayerAttribute_Power);
    // SW_Player_SetAttribute(this, SW_PlayerAttribute_Power, flPower + 1.0);
    @Player_UpdateStatusIcon(this);
}

public @Artifact_Deactivated(this) {
    // new Float:flPower = SW_Player_GetAttribute(this, SW_PlayerAttribute_Power);
    // SW_Player_SetAttribute(this, SW_PlayerAttribute_Power, flPower - 1.0);
    @Player_UpdateStatusIcon(this);
}

public @ArtifactItem_Spawn(this) {
    static szId[16];
    pev(this, pev_target, szId, charsmax(szId));
    if (!equal(szId, ARTIFACT_ID)) {
        return;
    }

    engfunc(EngFunc_SetModel, this, g_szMdlWArtifact);
}

public @Snowball_Spawn(this) {
    new pOwner = pev(this, pev_owner);
    if (!SW_Player_HasArtifact(pOwner, ARTIFACT_ID)) {
        return;
    }

    engfunc(EngFunc_SetModel, this, g_szMdlWSnowball);
    set_pev(this, pev_iuser4, 1);

    new Float:flDamage = 0.0;
    pev(this, pev_dmg, flDamage);
    set_pev(this, pev_dmg, flDamage + SPLASH_DAMAGE);
}

public @Snowball_Kill(this) {
    if (pev(this, pev_iuser4) != 1) {
        return;
    }

    @Snowball_ExplosionEffect(this);
    @Snowball_SplashDamage(this);
}

public @Snowball_ExplosionEffect(this) {
    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    static s_iBloodModelIndex = 0;
    if (!s_iBloodModelIndex) {
        s_iBloodModelIndex = engfunc(EngFunc_ModelIndex, "sprites/blood.spr");
    }

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_BLOODSPRITE);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_short(s_iBloodModelIndex);
    write_short(s_iBloodModelIndex);
    write_byte(241);
    write_byte(8);
    message_end();

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_BLOODSTREAM);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_byte(197);
    write_byte(8);
    message_end();
    
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_ELIGHT);
    write_short(0);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_coord(64);
    write_byte(100);
    write_byte(100);
    write_byte(0);
    write_byte(2);
    write_coord(12);
    message_end();

    emit_sound(this, CHAN_BODY, g_szSndSnowballHit, 0.5, ATTN_NORM, 0, PITCH_NORM);
}

public @Snowball_SplashDamage(this) {
    new pTr = create_tr2();

    new pOwner = pev(this, pev_owner);

    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) {
            continue;
        }

        if (!is_user_alive(pPlayer)) {
            continue;
        }

        if (!rg_is_player_can_takedamage(pPlayer, pOwner)) {
            continue;
        }

        if (pev(this, pev_enemy) == pPlayer) {
            continue;
        }

        static Float:vecTargetOrigin[3];
        pev(pPlayer, pev_origin, vecTargetOrigin);

        if (xs_vec_distance(vecOrigin, vecTargetOrigin) > 80.0) {
            continue;
        }

        engfunc(EngFunc_TraceLine, vecOrigin, vecTargetOrigin, DONT_IGNORE_MONSTERS, this, pTr);

        static Float:flFraction;
        get_tr2(pTr, TR_flFraction, flFraction);

        if (flFraction < 1.0 && get_tr2(pTr, TR_pHit) != pPlayer) {
            continue;
        }

        ExecuteHamB(Ham_TakeDamage, pPlayer, this, pOwner, SPLASH_DAMAGE, DMG_GENERIC);
    }

    free_tr2(pTr);
}

public Ham_Player_TakeDamage_Post(this, pWeapon, pAttacker, Float:flDamage, iDamageBits) {
    if (CE_GetHandlerByEntity(pWeapon) != g_iSnowballCeHandler) {
        return HAM_IGNORED;
    }

    if (pev(pWeapon, pev_iuser4) != 1) {
        return HAM_IGNORED;
    }

    new Float:flRatio = flDamage / 100.0;

    new iHitgroup = get_member(this, m_LastHitGroup);
    if (iHitgroup == HIT_HEAD) {
        flRatio *= 2.0;
    }

    UTIL_ScreenFade(this, { 150, 150, 0 }, 3.0 * flRatio, 1.0, floatround(100 * flRatio));

    return HAM_HANDLED;
}

public @Player_UpdateStatusIcon(this) {
    static gmsgStatusIcon = 0;
    if (!gmsgStatusIcon) {
        gmsgStatusIcon = get_user_msgid("StatusIcon");
    }

    if (SW_Player_HasArtifact(this, ARTIFACT_ID)) {
        message_begin(MSG_ONE, gmsgStatusIcon, _, this);
        write_byte(1);
        write_string("d_skull");
        write_byte(255);
        write_byte(255);
        write_byte(255);
        message_end();
    } else {
        message_begin(MSG_ONE, gmsgStatusIcon, _, this);
        write_byte(0);
        write_string("d_skull");
        message_end();
    }
}
