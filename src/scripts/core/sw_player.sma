#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <api_assets>

#include <snowwars>

#define PLUGIN "[Snow Wars] Player"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new g_szPlayerSpawnSound[MAX_RESOURCE_PATH_LENGTH];
new g_szSnowballModel[MAX_RESOURCE_PATH_LENGTH];
new g_rgszPlayerHitSounds[4][MAX_RESOURCE_PATH_LENGTH];
new g_iPlayerHitSoundsNum;

public plugin_precache() {
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWBALL_W_MODEL, g_szSnowballModel, charsmax(g_szSnowballModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_PLAYER_SPAWN_SOUND, g_szPlayerSpawnSound, charsmax(g_szPlayerSpawnSound));

  g_iPlayerHitSoundsNum = Asset_PrecacheList(SW_ASSET_LIBRARY, SW_ASSET_PLAYER_HIT_SOUND, g_rgszPlayerHitSounds, sizeof(g_rgszPlayerHitSounds), charsmax(g_rgszPlayerHitSounds[]));
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);

  RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip_Post", .post = 1);
}

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  emit_sound(pPlayer, CHAN_BODY, g_szPlayerSpawnSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(const pPlayer) {
  static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);

  static iSnowBallModelIndex = 0;
  if (!iSnowBallModelIndex) {
    iSnowBallModelIndex = engfunc(EngFunc_ModelIndex, g_szSnowballModel);
  }

  message_begin(MSG_ALL, SVC_TEMPENTITY);
  write_byte(TE_SPRITETRAIL);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2] + -4.0);
  write_short(iSnowBallModelIndex);
  write_byte(5);
  write_byte(3);
  write_byte(10);
  write_byte(10);
  write_byte(1);
  message_end();

  emit_sound(pPlayer, CHAN_VOICE, g_rgszPlayerHitSounds[random(g_iPlayerHitSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public HamHook_Player_TakeDamage_Post(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  emit_sound(pPlayer, CHAN_VOICE, g_rgszPlayerHitSounds[random(g_iPlayerHitSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  return HAM_HANDLED;
}

public HC_Player_SpawnEquip_Post(const pPlayer) {
  emit_sound(pPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
