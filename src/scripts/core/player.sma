#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <api_assets>

#include <snowwars>
#include <snowwars_internal>

new g_rgiPlayerAttributes[MAX_PLAYERS + 1][SW_PlayerAttribute];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Player_Sound_Hit));
  Asset_Precache(ASSET_LIBRARY, ASSET(Player_Sound_Spawn));
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Player"), SW_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);

  RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip_Post", .post = 1);
}

public plugin_natives() {
  register_native("SW_Player_GetAttribute", "Native_GetAttribute");
  register_native("SW_Player_SetAttribute", "Native_SetAttribute");
}

public client_connect(pPlayer) {
  @Player_ResetAttributes(pPlayer);
}

public Native_GetAttribute(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  new SW_PlayerAttribute:iAttrib = SW_PlayerAttribute:get_param(2);

  return @Player_GetAttribute(pPlayer, iAttrib);
}

public Native_SetAttribute(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  new SW_PlayerAttribute:iAttrib = SW_PlayerAttribute:get_param(2);
  new any:value = any:get_param(3);

  @Player_SetAttribute(pPlayer, iAttrib, value);
}

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  Asset_EmitSound(pPlayer, CHAN_BODY, ASSET_LIBRARY, ASSET(Player_Sound_Spawn));

  return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(const pPlayer) {
  static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);

  static iSnowBallModelIndex = 0;
  if (!iSnowBallModelIndex) {
    iSnowBallModelIndex = Asset_GetModelIndex(ASSET_LIBRARY, ASSET(Entity_Snowball_Model));
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

  Asset_EmitSound(pPlayer, CHAN_VOICE, ASSET_LIBRARY, ASSET(Player_Sound_Hit));

  return HAM_HANDLED;
}

public HamHook_Player_TakeDamage_Post(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  Asset_EmitSound(pPlayer, CHAN_VOICE, ASSET_LIBRARY, ASSET(Player_Sound_Hit));

  return HAM_HANDLED;
}

public HC_Player_SpawnEquip_Post(const pPlayer) {
  emit_sound(pPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public HamHook_Player_TakeDamage(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  new Float:flRatio = CalculateDamageRatio(pAttacker, pPlayer);
  SetHamParamFloat(4, flDamage * flRatio);
  return HAM_HANDLED;
}

@Player_GetAttribute(const this, SW_PlayerAttribute:iAttrib) {
  return g_rgiPlayerAttributes[this][iAttrib];
}

@Player_SetAttribute(const this, SW_PlayerAttribute:iAttrib, any:value) {
  g_rgiPlayerAttributes[this][iAttrib] = value;
}

@Player_ResetAttributes(const this) {
  for (new iAttrib = 0; iAttrib < _:SW_PlayerAttribute; ++iAttrib) {
    g_rgiPlayerAttributes[this][SW_PlayerAttribute:iAttrib] = 0;
  }
}

Float:CalculateDamageRatio(const &pAttacker, const &pVictim) {
  new Float:flPower = IS_PLAYER(pAttacker) ? SW_Player_GetAttribute(pAttacker, SW_PlayerAttribute_Power) : 0.0;
  new Float:flResistence = SW_Player_GetAttribute(pVictim, SW_PlayerAttribute_Resistance);

  return  (1.0 + flPower) * (1.0 - floatmin(flResistence, 1.0));
}
