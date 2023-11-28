#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>
#include <xs>

#include <snowwars>
#include <api_custom_entities>

#define PLUGIN "[Entity] Firework Rocket"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "sw_fireworkrocket"
#define ROCKET_SPEED 1024.0
#define ROCKET_HEALTH 3

new const g_szSmokeModel[] = "sprites/smoke.spr";

new const g_rgszSprBeam[][] = {
    "sprites/laserbeam.spr",
    "sprites/shockwave.spr",
    "sprites/shellchrome.spr",
    "sprites/zbeam1.spr",
    "sprites/zbeam2.spr",
    "sprites/zbeam3.spr",
    "sprites/zbeam4.spr",
    "sprites/zbeam5.spr",
    "sprites/zbeam6.spr",
    "sprites/xbeam1.spr",
    "sprites/xbeam2.spr",
    "sprites/xbeam3.spr",
    "sprites/xbeam4.spr",
    "sprites/xbeam5.spr"
};

new const g_rgszSprTrail[][] = {
    "sprites/flare1.spr",
    "sprites/flare3.spr",
    "sprites/muz2.spr",
    "sprites/muz3.spr",
    "sprites/muz4.spr",
    "sprites/muz5.spr",
    "sprites/muz6.spr",
    "sprites/muz7.spr",
    "sprites/muz8.spr"
};

new g_iCeHandler;

public plugin_precache() {
    precache_model(g_szSmokeModel);

    g_iCeHandler = CE_Register(
        .szName = ENTITY_NAME,
        .vMins = Float:{-4.0, -4.0, -4.0},
        .vMaxs = Float:{4.0, 4.0, 4.0},
        .modelIndex = precache_model("models/rpgrocket.mdl"),
        .preset = CEPreset_Prop,
        .fLifeTime = 1.5
    );

    for (new i = 0; i < sizeof(g_rgszSprBeam); ++i) {
        precache_model(g_rgszSprBeam[i]);
    }

    for (new i = 0; i < sizeof(g_rgszSprTrail); ++i) {
        precache_model(g_rgszSprTrail[i]);
    }

    precache_sound(SW_SOUND_FIREWORK_ROCKET);

    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
    CE_RegisterHook(CEFunction_Kill, ENTITY_NAME, "@Entity_Kill");

    RegisterHam(Ham_Touch, CE_BASE_CLASSNAME, "Ham_Base_Touch_Post", .Post = 1);
    RegisterHam(Ham_Think, CE_BASE_CLASSNAME, "Ham_Base_Think_Post", .Post = 1);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public @Entity_Spawn(this) {
    new iSprite = engfunc(EngFunc_ModelIndex, g_szSmokeModel);

    set_pev(this, pev_solid, SOLID_TRIGGER);
    set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
    set_pev(this, pev_gravity, 0.1);

    new Float:flColor[3];
    flColor[0] = float(random(256));
    flColor[1] = float(random(256));
    flColor[2] = float(random(256));

    engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Float:{0.0, 0.0, 0.0}, 0);
    write_byte(TE_BEAMFOLLOW);
    write_short(this);
    write_short(iSprite);
    write_byte(10);
    write_byte(4);
    write_byte(floatround(flColor[0]));
    write_byte(floatround(flColor[1]));
    write_byte(floatround(flColor[2]));
    write_byte(255);
    message_end();

    static Float:vecVelocity[3];
    pev(this, pev_angles, vecVelocity);
    angle_vector(vecVelocity, ANGLEVECTOR_FORWARD, vecVelocity);
    // xs_vec_mul_scalar(vecVelocity, 1024.0, vecVelocity);
    set_pev(this, pev_velocity, vecVelocity);
    set_pev(this, pev_iuser4, 0);

    set_pev(this, pev_rendercolor, flColor);
    dllfunc(DLLFunc_Think, this);
    emit_sound(this, CHAN_BODY, SW_SOUND_FIREWORK_ROCKET, 0.5, ATTN_NORM, 0, PITCH_NORM);
}

public @Entity_Kill(this) {
    new iSprBeam = engfunc(EngFunc_ModelIndex, g_rgszSprBeam[random(sizeof(g_rgszSprBeam))]);

    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    new pTarget;
    new pPrevEntity;
    while ((pTarget = engfunc(EngFunc_FindEntityInSphere, pTarget, vecOrigin, 256.0)) != 0) {
            if (pPrevEntity >= pTarget) {
                    break;
            }

            pPrevEntity = pTarget;

            if (!pev_valid(pTarget)) {
                    continue;
            }

            if (pev(pTarget, pev_takedamage) == DAMAGE_NO) {
                    continue;
            }

            static Float:vecSpot[3];
            ExecuteHamB(Ham_BodyTarget, pTarget, vecOrigin, vecSpot);
            engfunc(EngFunc_TraceLine, vecOrigin, vecSpot, IGNORE_MONSTERS, this, 0);

            static Float:flFraction;
            get_tr2(0, TR_flFraction, flFraction);

            if (flFraction != 1.0 && get_tr2(0, TR_pHit) != pTarget) {
                    continue;
            }

            ExecuteHamB(Ham_TakeDamage, pTarget, this, pev(this, pev_owner), 500.0, DMG_GENERIC);
    }

    static Float:flColor[3];
    pev(this, pev_rendercolor, flColor);

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_TAREXPLOSION);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    message_end();

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_DLIGHT);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_byte(100);
    write_byte(floatround(flColor[0]));
    write_byte(floatround(flColor[1]));
    write_byte(floatround(flColor[2]));
    write_byte(10);
    write_byte(64);
    message_end();

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_BEAMDISK);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2] + 128.0);
    write_short(iSprBeam);
    write_byte(0);
    write_byte(0);
    write_byte(25);
    write_byte(255);
    write_byte(0);
    write_byte(floatround(flColor[0]));
    write_byte(floatround(flColor[1]));
    write_byte(floatround(flColor[2]));
    write_byte(150);
    write_byte(0);
    message_end();

    if (random(2)) {
        new iSprTrail = engfunc(EngFunc_ModelIndex, g_rgszSprTrail[random(sizeof(g_rgszSprTrail))]);

        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
        write_byte(TE_SPRITETRAIL);
        engfunc(EngFunc_WriteCoord, vecOrigin[0]);
        engfunc(EngFunc_WriteCoord, vecOrigin[1]);
        engfunc(EngFunc_WriteCoord, vecOrigin[2]);
        engfunc(EngFunc_WriteCoord, vecOrigin[0]);
        engfunc(EngFunc_WriteCoord, vecOrigin[1]);
        engfunc(EngFunc_WriteCoord, vecOrigin[2] + 128.0);
        write_short(iSprTrail);
        write_byte(50);
        write_byte(3); 
        write_byte(5);
        write_byte(50);
        write_byte(40);
        message_end();
    } else {
        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
        write_byte(TE_PARTICLEBURST);
        engfunc(EngFunc_WriteCoord, vecOrigin[0]);
        engfunc(EngFunc_WriteCoord, vecOrigin[1]);
        engfunc(EngFunc_WriteCoord, vecOrigin[2]);
        write_short(150);
        write_byte(random(256));
        write_byte(10);
        message_end();
    }
}

public Ham_Base_Touch_Post(pEntity, pTarget) {
    if (CE_GetHandlerByEntity(pEntity) != g_iCeHandler) {
        return HAM_IGNORED;
    }

    new iTouchCount = pev(pEntity, pev_iuser4);

    if (iTouchCount < ROCKET_HEALTH) {
        static Float:vecOrigin[3];
        pev(pEntity, pev_origin, vecOrigin);

        new iContent = engfunc(EngFunc_PointContents, vecOrigin);

        if (iContent == CONTENTS_SKY) {
            vecOrigin[2] -= 128.0;
            set_pev(pEntity, pev_origin, vecOrigin);
            CE_Kill(pEntity);
        } else {
            set_pev(pEntity, pev_iuser4, iTouchCount + 1);
        }
    } else {
        CE_Kill(pEntity);
    }

    return HAM_HANDLED;
}

public Ham_Base_Think_Post(pEntity) {
    if (CE_GetHandlerByEntity(pEntity) != g_iCeHandler) {
        return HAM_IGNORED;
    }

    static Float:vecVelocity[3];
    pev(pEntity, pev_velocity, vecVelocity);
    xs_vec_normalize(vecVelocity, vecVelocity);
    xs_vec_mul_scalar(vecVelocity, ROCKET_SPEED, vecVelocity);
    set_pev(pEntity, pev_velocity, vecVelocity);

    static Float:vecAngles[3];
    vector_to_angle(vecVelocity, vecAngles);
    // vecAngles[0] -= 90.0;
    set_pev(pEntity, pev_angles, vecAngles);

    set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);

    return HAM_HANDLED;
}
