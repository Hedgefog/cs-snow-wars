#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>
#include <xs>

#include <snowwars>
#include <api_custom_entities>
#include <screenfade_util>

#define PLUGIN "[Entity] Snowball"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define IS_PLAYER(%1) (%1 > 0 && %1 <= MaxClients)

#define ENTITY_NAME "sw_snowball"

new g_iCeHandler;
new g_iBloodModelIndex;

new g_pCvarAimAssistRange;

public plugin_precache() {
    g_iCeHandler = CE_Register(
        .szName = ENTITY_NAME,
        .vMins = Float:{-4.0, -4.0, -4.0},
        .vMaxs = Float:{4.0, 4.0, 4.0},
        .modelIndex = precache_model(SW_WEAPON_SNOWBALL_W_MODEL),
        .fLifeTime = 10.0
    );

    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
    CE_RegisterHook(CEFunction_Kill, ENTITY_NAME, "@Entity_Kill");

    g_iBloodModelIndex = precache_model("sprites/blood.spr");
    precache_sound(SW_SOUND_SNOWBALL_HIT);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Touch, CE_BASE_CLASSNAME, "Ham_Base_Touch_Post", .Post = 1);
    RegisterHam(Ham_Think, CE_BASE_CLASSNAME, "Ham_Base_Think", .Post = 0);
    RegisterHam(Ham_TakeDamage, "player", "Ham_Player_TakeDamage_Post", .Post = 1);

    g_pCvarAimAssistRange = register_cvar("sw_snowball_aimassist_range", "16.0");
}

public @Entity_Spawn(this) {
    set_pev(this, pev_solid, SOLID_BBOX);
    set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
    set_pev(this, pev_gravity, 0.4);
    set_pev(this, pev_sequence, 1);
    set_pev(this, pev_framerate, 1.0);
    set_pev(this, pev_dmg, 50.0);
    set_pev(this, pev_takedamage, DAMAGE_YES);
    set_pev(this, pev_health, 1.0);
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

public @Entity_Kill(this) {
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

    emit_sound(this, CHAN_BODY, SW_SOUND_SNOWBALL_HIT, 0.5, ATTN_NORM, 0, PITCH_NORM);
}

public @Player_SnowballHitEffect(this, Float:flRatio) {
    UTIL_ScreenFade(this, { 255, 255, 255 }, 3.0 * flRatio, 1.0, floatround(100 * flRatio));

    static Float:vecPunchangle[3];
    vecPunchangle[0] = random_float(-16.0 * flRatio, 16.0 * flRatio);
    vecPunchangle[1] = random_float(-16.0 * flRatio, 24.0 * flRatio);
    vecPunchangle[2] = random_float(-16.0 * flRatio, 16.0 * flRatio);
    set_pev(this, pev_punchangle, vecPunchangle);
}

public Ham_Base_Touch_Post(pEntity, pTarget) {
    if (CE_GetHandlerByEntity(pEntity) != g_iCeHandler) {
        return HAM_IGNORED;
    }

    if (pev(pTarget, pev_solid) < SOLID_BBOX) {
        return HAM_IGNORED;
    }

    new pOwner = pev(pEntity, pev_owner);

    static Float:vecOrigin[3];
    pev(pEntity, pev_origin, vecOrigin);

    set_pev(pEntity, pev_enemy, pTarget);

    // static Float:vecTarget[3];
    // global_get(glb_v_forward, vecTarget);
    // xs_vec_mul_scalar(vecTarget, 32.0, vecTarget);
    // xs_vec_add(vecOrigin, vecTarget, vecTarget);

    // static Float:vecTarget[3];
    // pev(pEntity, pev_velocity, vecTarget);
    // xs_vec_sub(vecTarget, vecOrigin, vecTarget);
    // xs_vec_normalize(vecTarget, vecTarget);
    // xs_vec_add(vecOrigin, vecTarget, vecTarget);

    static Float:flDamage = 0.0;
    pev(pEntity, pev_dmg, flDamage);

    if (IS_PLAYER(pTarget)) {
        static Float:vecTarget[3];
        pev(pTarget, pev_origin, vecTarget);

        // static Float:vecStart[3];
        // pev(pEntity, pev_origin, vecStart);
        // pev(pTarget, pev_origin, vecStart);

        // static Float:vecEnd[3];
        // pev(pTarget, pev_origin, vecEnd);
        // pev(pTarget, pev_origin, vecEnd);
        // xs_vec_copy(vecStart, vecEnd);
        // vecEnd[2] = vecOrigin[2];

        // new pTr = create_tr2();
        // engfunc(EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pEntity, pTr);
        // new iHitgroup = get_tr2(pTr, TR_iHitgroup);
        // free_tr2(pTr);

        new iHitgroup = vecOrigin[2] - vecTarget[2] >= 18.0 ? HIT_HEAD : 0;

        if (rg_is_player_can_takedamage(pTarget, pOwner)) {
            ExecuteHamB(Ham_TakeDamage, pTarget, pEntity, pOwner, flDamage, iHitgroup == HIT_HEAD ? DMG_DROWN : DMG_GENERIC);
        }

    } else if (pev(pTarget, pev_takedamage) != DAMAGE_NO) {
        ExecuteHamB(Ham_TakeDamage, pTarget, pEntity, pOwner, flDamage, DMG_GENERIC);
    } else {
        // if (pev(pEntity, pev_iuser3) < 1) {
        //     static Float:vecVelocity[3];
        //     pev(pEntity, pev_velocity, vecVelocity);
        //     xs_vec_mul_scalar(vecVelocity, 0.25, vecVelocity);
        //     set_pev(pEntity, pev_velocity, vecVelocity);
        //     set_pev(pEntity, pev_iuser3, pev(pEntity, pev_iuser3) + 1);
        //     return HAM_IGNORED;
        // }
    }

    ExecuteHamB(Ham_TakeDamage, pEntity, pTarget, pTarget, 1.0, DMG_GENERIC);

    return HAM_HANDLED;
}

public Ham_Base_Think(pEntity) {
    if (CE_GetHandlerByEntity(pEntity) != g_iCeHandler) {
        return HAM_IGNORED;
    }

    new Float:flAimAssistRange = get_pcvar_float(g_pCvarAimAssistRange);

    if (flAimAssistRange > 0.0) {
        new pOwner = pev(pEntity, pev_owner);

        static Float:vecOrigin[3];
        pev(pEntity, pev_origin, vecOrigin);

        new pNearestPlayer = -1;
        new Float:flNearestPlayerDistance = 0.0;

        for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
            if (!is_user_alive(pPlayer)) {
                continue;
            }

            if (pOwner == pPlayer) {
                continue;
            }

            static Float:vecTargetOrigin[3];
            pev(pPlayer, pev_origin, vecTargetOrigin);
            if (floatabs(vecOrigin[2] - vecTargetOrigin[2]) > 32.0) {
                continue;
            }

            if (!rg_is_player_can_takedamage(pPlayer, pOwner)) {
                continue;
            }

            new Float:flDistance = xs_vec_distance(vecOrigin, vecTargetOrigin);
            if (pNearestPlayer == -1 || flDistance < flNearestPlayerDistance) {
                pNearestPlayer = pPlayer;
                flNearestPlayerDistance = flDistance;
            }
        }

        if (pNearestPlayer != -1) {
            DoAimAssist(pEntity, pNearestPlayer, flAimAssistRange);
        }
    }

    set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);

    return HAM_HANDLED;
}

public Ham_Player_TakeDamage_Post(pPlayer, pWeapon, pAttacker, Float:flDamage, iDamageBits) {
    if (CE_GetHandlerByEntity(pWeapon) != g_iCeHandler) {
        return HAM_IGNORED;
    }

    new Float:flRatio = flDamage / 100.0;

    new iHitgroup = get_member(pPlayer, m_LastHitGroup);
    if (iHitgroup == HIT_HEAD) {
        flRatio *= 2.0;
    }

    @Player_SnowballHitEffect(pPlayer, flRatio);

    return HAM_HANDLED;
}

DoAimAssist(pSnowball, pTarget, Float:flRange) {
    new pTr = create_tr2();

    static Float:vecOrigin[3];
    pev(pSnowball, pev_origin, vecOrigin);

    static Float:vecTarget[3];
    pev(pTarget, pev_origin, vecTarget);
    vecTarget[2] = vecOrigin[2];
    xs_vec_sub(vecTarget, vecOrigin, vecTarget);
    xs_vec_normalize(vecTarget, vecTarget);
    xs_vec_mul_scalar(vecTarget, flRange, vecTarget);
    xs_vec_add(vecOrigin, vecTarget, vecTarget);
    engfunc(EngFunc_TraceMonsterHull, pSnowball, vecOrigin, vecTarget, DONT_IGNORE_MONSTERS, pSnowball, pTr);

    if (get_tr2(pTr, TR_pHit) == pTarget) {
        static Float:vecVelocity[3];
        pev(pSnowball, pev_velocity, vecVelocity);

        new Float:flSpeed = xs_vec_len(vecVelocity);

        get_tr2(pTr, TR_vecEndPos, vecVelocity);
        xs_vec_sub(vecVelocity, vecOrigin, vecVelocity);
        xs_vec_normalize(vecVelocity, vecVelocity);
        xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);

        set_pev(pSnowball, pev_velocity, vecVelocity);
    }

    free_tr2(pTr);
}
