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

public plugin_precache() {
    for (new i = 0; i < sizeof(SW_SOUND_PLAYER_HIT); ++i) {
        precache_sound(SW_SOUND_PLAYER_HIT[i]);
    }

    precache_sound(SW_SOUND_PLAYER_SPAWN);
    precache_model(SW_MODEL_WEAPON_SNOWBALL_W);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn_Post", .Post = 1);
    RegisterHam(Ham_TakeDamage, "player", "Ham_Player_TakeDamage_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", .Post = 1);

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip_Post", .post = 1);
}

public Ham_Player_Spawn_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    emit_sound(pPlayer, CHAN_BODY, SW_SOUND_PLAYER_SPAWN, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HAM_HANDLED;
}

public Ham_Player_Killed_Post(pPlayer) {
    static Float:vecOrigin[3];
    pev(pPlayer, pev_origin, vecOrigin);

    static s_iMdlSnowball = 0;
    if (!s_iMdlSnowball) {
        s_iMdlSnowball = engfunc(EngFunc_ModelIndex, SW_MODEL_WEAPON_SNOWBALL_W);
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

    emit_sound(pPlayer, CHAN_VOICE, SW_SOUND_PLAYER_HIT[random(sizeof(SW_SOUND_PLAYER_HIT))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public Ham_Player_TakeDamage_Post(pPlayer, iInflictor, pAttacker, Float:flDamage, iDamageBits) {
    emit_sound(pPlayer, CHAN_VOICE, SW_SOUND_PLAYER_HIT[random(sizeof(SW_SOUND_PLAYER_HIT))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HAM_HANDLED;
}

public HC_Player_SpawnEquip_Post(pPlayer) {
    emit_sound(pPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
