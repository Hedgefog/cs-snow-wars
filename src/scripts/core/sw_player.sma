#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>

#include <snowwars>

#define PLUGIN "[Snow Wars] Player"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new const g_szPlayerHitSounds[][] = {
    "snowwars/v090/snowhit_human1.wav",
    "snowwars/v090/snowhit_human2.wav"
};

new const g_szPlayerSpawnSound[] = "snowwars/v090/push.wav";
new const g_szMdlWSnowball[] = "models/snowwars/v090/weapons/w_snowball.mdl";

public plugin_precache() {
    for (new i = 0; i < sizeof(g_szPlayerHitSounds); ++i) {
        precache_sound(g_szPlayerHitSounds[i]);
    }

    precache_sound(g_szPlayerSpawnSound);
    precache_model(g_szMdlWSnowball);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn_Post", .Post = 1);
    RegisterHam(Ham_TakeDamage, "player", "Ham_Player_TakeDamage_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", .Post = 1);

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip_Post", .post = 1);
}

public Ham_Player_Spawn_Post(this) {
    if (!is_user_alive(this)) {
        return HAM_IGNORED;
    }

    emit_sound(this, CHAN_BODY, g_szPlayerSpawnSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HAM_HANDLED;
}

public Ham_Player_Killed_Post(this) {
    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    static s_iMdlSnowball = 0;
    if (!s_iMdlSnowball) {
        s_iMdlSnowball = engfunc(EngFunc_ModelIndex, g_szMdlWSnowball);
    }

    message_begin(MSG_ALL, SVC_TEMPENTITY);
    write_byte(TE_SPRITETRAIL);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2] + -4.0);
    write_short(s_iMdlSnowball);
    write_byte(5);
    write_byte(3);
    write_byte(10);
    write_byte(10);
    write_byte(1);
    message_end();

    emit_sound(this, CHAN_VOICE, g_szPlayerHitSounds[random(sizeof(g_szPlayerHitSounds))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public Ham_Player_TakeDamage_Post(this, iInflictor, pAttacker, Float:flDamage, iDamageBits) {
    emit_sound(this, CHAN_VOICE, g_szPlayerHitSounds[random(sizeof(g_szPlayerHitSounds))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HAM_HANDLED;
}

public HC_Player_SpawnEquip_Post(this) {
    emit_sound(this, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
