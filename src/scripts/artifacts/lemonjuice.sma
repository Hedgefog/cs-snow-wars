#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_assets>
#include <api_custom_entities>
#include <screenfade_util>
#include <combat_util>

#include <snowwars_player_artifacts>
#include <snowwars_const>

#define PLUGIN "[Snow Wars] Lemon Juice Artifact"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ARTIFACT_ID SW_Artifact_LemonJuice
#define SPLASH_DAMAGE 22.0
#define SPLASH_RANGE 80.0
#define ARTIFACT_STATUS_ICON "d_skull"

new const m_bLemonJuice[] = "bLemonJuice";

new g_szSnowballModel[MAX_RESOURCE_PATH_LENGTH];
new g_szItemModel[MAX_RESOURCE_PATH_LENGTH];
new g_szHitSound[MAX_RESOURCE_PATH_LENGTH];
new g_szShowSplashSprite[MAX_RESOURCE_PATH_LENGTH];

new g_pTrace;

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(SW_AssetLibrary, SW_Asset_Artifact_LemonJuice_Model_World, g_szItemModel, charsmax(g_szItemModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Artifact_LemonJuice_Model_Snowball, g_szSnowballModel, charsmax(g_szSnowballModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Artifact_LemonJuice_Sprite_Splash, g_szShowSplashSprite, charsmax(g_szShowSplashSprite));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Artifact_LemonJuice_Sound_Hit);

  SW_PlayerArtifact_Register(ARTIFACT_ID, "Callback_Artifact_Activated", "Callback_Artifact_Deactivated");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);

  CE_RegisterClassNativeMethodHook(SW_Entity_ArtifactItem, CE_Method_Spawn, "CEHook_ArtifactItem_Spawn");
  CE_RegisterClassNativeMethodHook(SW_Entity_Snowball, CE_Method_Spawn, "CEHook_Snowball_Spawn_Post");
  CE_RegisterClassNativeMethodHook(SW_Entity_Snowball, CE_Method_Killed, "CEHook_Snowball_Killed");

  register_event("ResetHUD", "Event_ResetHUD", "b");
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public Event_ResetHUD(const pPlayer) {
  @Player_UpdateStatusIcon(pPlayer);
}

public HamHook_Player_TakeDamage_Post(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!CE_IsInstanceOf(pInflictor, SW_Entity_Snowball)) return HAM_IGNORED;
  if (!CE_GetMember(pInflictor, m_bLemonJuice)) return HAM_IGNORED;

  new Float:flRatio = flDamage / 100.0;

  new iHitgroup = get_member(pPlayer, m_LastHitGroup);
  if (iHitgroup == HIT_HEAD) {
    flRatio *= 2.0;
  }

  UTIL_ScreenFade(pPlayer, { 150, 150, 0 }, 3.0 * flRatio, 1.0, floatround(100 * flRatio));

  return HAM_HANDLED;
}

public CEHook_ArtifactItem_Spawn(const pEntity) {
  static szId[16]; CE_GetMemberString(pEntity, "szArtifactId", szId, charsmax(szId));
  if (!equal(szId, ARTIFACT_ID)) return;

  engfunc(EngFunc_SetModel, pEntity, g_szItemModel);
}

public Callback_Artifact_Activated(const pPlayer) {
  // new Float:flPower = SW_Player_GetAttribute(pPlayer, SW_PlayerAttribute_Power);
  // SW_Player_SetAttribute(pPlayer, SW_PlayerAttribute_Power, flPower + 1.0);
  @Player_UpdateStatusIcon(pPlayer);
}

public Callback_Artifact_Deactivated(const pPlayer) {
  // new Float:flPower = SW_Player_GetAttribute(pPlayer, SW_PlayerAttribute_Power);
  // SW_Player_SetAttribute(pPlayer, SW_PlayerAttribute_Power, flPower - 1.0);
  @Player_UpdateStatusIcon(pPlayer);
}

public CEHook_Snowball_Spawn_Post(const this) {
  new pOwner = pev(this, pev_owner);
  if (!SW_PlayerArtifact_Has(pOwner, ARTIFACT_ID)) return;

  engfunc(EngFunc_SetModel, this, g_szSnowballModel);
  CE_SetMember(this, m_bLemonJuice, true);

  CE_SetMember(this, "flDamage", Float:CE_GetMember(this, "flDamage") + SPLASH_DAMAGE);
}

public CEHook_Snowball_Killed(const this) {
  if (!CE_GetMember(this, m_bLemonJuice)) return;

  @Snowball_ExplosionEffect(this);
  @Snowball_SplashDamage(this);
}

@Snowball_ExplosionEffect(const &this) {
  static iSplashSpriteModelIndex = 0;
  if (!iSplashSpriteModelIndex) {
    iSplashSpriteModelIndex = engfunc(EngFunc_ModelIndex, g_szShowSplashSprite);
  }

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_BLOODSPRITE);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  write_short(iSplashSpriteModelIndex);
  write_short(iSplashSpriteModelIndex);
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

  Asset_EmitSound(this, CHAN_ITEM, SW_AssetLibrary, SW_Asset_Artifact_LemonJuice_Sound_Hit, _, 0.5);
}

@Snowball_SplashDamage(const &this) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static pOwner; pOwner = pev(this, pev_owner);

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_alive(pPlayer)) continue;
    if (!rg_is_player_can_takedamage(pPlayer, pOwner)) continue;
    if (pev(this, pev_enemy) == pPlayer) continue;
    if (entity_range(this, pPlayer) > SPLASH_RANGE) continue;

    static Float:vecTarget[3]; pev(pPlayer, pev_origin, vecTarget);
    engfunc(EngFunc_TraceLine, vecOrigin, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);

    static Float:flFraction; get_tr2(g_pTrace, TR_flFraction, flFraction);
    if (flFraction < 1.0 && get_tr2(g_pTrace, TR_pHit) != pPlayer) continue;

    ExecuteHamB(Ham_TakeDamage, pPlayer, this, pOwner, SPLASH_DAMAGE, DMG_GENERIC);
  }
}

@Player_UpdateStatusIcon(const this) {
  static gmsgStatusIcon = 0;
  if (!gmsgStatusIcon) {
    gmsgStatusIcon = get_user_msgid("StatusIcon");
  }

  if (SW_PlayerArtifact_Has(this, ARTIFACT_ID)) {
    message_begin(MSG_ONE, gmsgStatusIcon, _, this);
    write_byte(1);
    write_string(ARTIFACT_STATUS_ICON);
    write_byte(255);
    write_byte(255);
    write_byte(255);
    message_end();
  } else {
    message_begin(MSG_ONE, gmsgStatusIcon, _, this);
    write_byte(0);
    write_string(ARTIFACT_STATUS_ICON);
    message_end();
  }
}
