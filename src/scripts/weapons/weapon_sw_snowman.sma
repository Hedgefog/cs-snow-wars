#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <snowwars_const>

#define PLUGIN "[Snow Wars] Weapon Snowman"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define DEPLOY_HEIGHT_STEP 32.0
#define DEPLOY_DISTANCE 64.0

new g_szSnowmanModel[MAX_RESOURCE_PATH_LENGTH];
new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];

new g_pTrace;

new g_pInstallation = -1;

new Float:g_vecPlayerDeployOrigin[MAX_PLAYERS + 1][3];
new Float:g_vecPlayerDeployAngles[MAX_PLAYERS + 1][3];
new bool:g_bPlayerCanDeploy[MAX_PLAYERS + 1];
new bool:g_bPlayerShowDeployPreview[MAX_PLAYERS + 1];

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWMAN_MODEL, g_szSnowmanModel, charsmax(g_szSnowmanModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWMAN_V_MODEL, g_szVModel, charsmax(g_szVModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWMAN_P_MODEL, g_szPModel, charsmax(g_szPModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWMAN_W_MODEL, g_szWModel, charsmax(g_szWModel));

  CW_RegisterClass(SW_WEAPON_SNOWMAN);

  CW_ImplementClassMethod(SW_WEAPON_SNOWMAN, CW_Method_Allocate, "@Weapon_Allocate");
  CW_ImplementClassMethod(SW_WEAPON_SNOWMAN, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(SW_WEAPON_SNOWMAN, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(SW_WEAPON_SNOWMAN, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(SW_WEAPON_SNOWMAN, CW_Method_GetMaxSpeed, "@Weapon_GetMaxSpeed");
  CW_ImplementClassMethod(SW_WEAPON_SNOWMAN, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");

  register_forward(FM_CheckVisibility, "FMHook_CheckVisibility", 0);
  register_forward(FM_AddToFullPack, "FMForward_AddToFullPack", 0);
  register_forward(FM_AddToFullPack, "FMForward_AddToFullPack_Post", 1);

  InitInstallationPreview();
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public FMHook_CheckVisibility(const pEntity) {
  if (pEntity == g_pInstallation) {
    forward_return(FMV_CELL, 1);
    return FMRES_SUPERCEDE;
  }

  return FMRES_IGNORED;
}

public FMForward_AddToFullPack(const es, const e, const pEntity, const pHost, iHostFlags, iPlayer, pSet) {
  if (pEntity == g_pInstallation) {
    if (!is_user_alive(pHost)) return FMRES_SUPERCEDE;

    new pActiveItem = get_ent_data_entity(pHost, "CBasePlayer", "m_pActiveItem");
    if (pActiveItem == FM_NULLENT || !CW_IsInstanceOf(pActiveItem, SW_WEAPON_SNOWMAN)) return FMRES_SUPERCEDE;

    if (!g_bPlayerShowDeployPreview[pHost]) return FMRES_SUPERCEDE;

    return FMRES_HANDLED;
  }

  return FMRES_IGNORED;
}

public FMForward_AddToFullPack_Post(const es, const e, const pEntity, const pHost, iHostFlags, iPlayer, pSet) {
  if (pEntity == g_pInstallation) {
    if (!is_user_alive(pHost)) return FMRES_IGNORED;

    new pActiveItem = get_ent_data_entity(pHost, "CBasePlayer", "m_pActiveItem");
    if (pActiveItem == FM_NULLENT || !CW_IsInstanceOf(pActiveItem, SW_WEAPON_SNOWMAN)) return FMRES_IGNORED;

    static Float:vecVelocity[3]; pev(pHost, pev_velocity, vecVelocity);

    set_es(es, ES_Origin, g_vecPlayerDeployOrigin[pHost]);
    set_es(es, ES_Angles, g_vecPlayerDeployAngles[pHost]);
    set_es(es, ES_Velocity, vecVelocity);
    set_es(es, ES_Effects, 0);
    set_es(es, ES_RenderMode, kRenderTransTexture);
    set_es(es, ES_RenderFx, kRenderFxGlowShell);
    set_es(es, ES_RenderAmt, 1);
    set_es(es, ES_RenderColor, g_bPlayerCanDeploy[pHost] ? {0, 255, 0} : {255, 0, 0});

    return FMRES_HANDLED;
  }

  return FMRES_IGNORED;
}

@Weapon_Allocate(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iFlags, ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
  CW_SetMember(this, CW_Member_iId, 5);
  CW_SetMember(this, CW_Member_iSlot, 3);
  CW_SetMember(this, CW_Member_iPosition, 2);
  CW_SetMember(this, CW_Member_iDefaultAmmo, 1);
  CW_SetMember(this, CW_Member_iPrimaryAmmoType, 1);
  CW_SetMember(this, CW_Member_bExhaustible, true);
}

@Weapon_Idle(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);

  if (!iAmmo) {
    ExecuteHamB(Ham_Weapon_RetireWeapon, this);
    return;
  }

  @Player_UpdateDeployVars(pPlayer);

  CW_SetMember(this, CW_Member_flTimeIdle, 0.1);
}

@Weapon_Deploy(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 0, "c4");
  CW_SetMember(this, CW_Member_flTimeIdle, 0.1);
  g_bPlayerCanDeploy[pPlayer] = false;
  g_bPlayerShowDeployPreview[pPlayer] = false;
}

@Weapon_PrimaryAttack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  if (!g_bPlayerCanDeploy[pPlayer]) return false;

  static iShotsFired; iShotsFired = CW_GetMember(this, CW_Member_iShotsFired);
  if (iShotsFired > 0) return false;

  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);

  if (iAmmo <= 0) return false;

  @Player_DeploySnowman(pPlayer);

  set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", --iAmmo, iPrimaryAmmoType);
  CW_SetMember(this, CW_Member_iShotsFired, ++iShotsFired);

  CW_SetMember(this, CW_Member_flNextPrimaryAttack, get_gametime() + 0.5);
  CW_SetMember(this, CW_Member_flNextSecondaryAttack, get_gametime() + 0.5);

  g_bPlayerCanDeploy[pPlayer] = false;
  g_bPlayerShowDeployPreview[pPlayer] = false;

  return true;
}

Float:@Weapon_GetMaxSpeed(const this) {
  return 250.0;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

@Player_UpdateDeployVars(const &this) {
  static Float:vecAngles[3]; pev(this, pev_v_angle, vecAngles);
  vecAngles[0] = 0.0;
  vecAngles[1] -= 180.0;
  vecAngles[2] = 0.0;

  g_bPlayerShowDeployPreview[this] = true;
  g_bPlayerCanDeploy[this] = @Player_FindDeploymentPos(this, g_vecPlayerDeployOrigin[this]);
  xs_vec_copy(vecAngles, g_vecPlayerDeployAngles[this]);
}

@Player_DeploySnowman(const &this) {
  new pInstallation = CE_Create(SW_ENTITY_SNOWMAN, g_vecPlayerDeployOrigin[this]);
  set_pev(pInstallation, pev_angles, g_vecPlayerDeployAngles[this]);
  set_pev(pInstallation, pev_owner, this);
  set_pev(pInstallation, pev_team, get_ent_data(this, "CBasePlayer", "m_iTeam"));
  dllfunc(DLLFunc_Spawn, pInstallation);
}

bool:@Player_FindDeploymentPos(const &this, Float:vecTarget[3]) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(this, pev_v_angle, vecAngles);
  static Float:vecMins[3]; pev(this, pev_mins, vecMins);

  vecAngles[0] = 0.0;
  vecAngles[2] = 0.0;

  static Float:vecSrc[3]; xs_vec_set(vecSrc, vecOrigin[0], vecOrigin[1], vecOrigin[2] + DEPLOY_HEIGHT_STEP);

  set_pev(g_pInstallation, pev_solid, SOLID_BBOX);

  static bool:bCanDeploy; bCanDeploy = true;

  // Check forward direction
  angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecTarget);
  xs_vec_add_scaled(vecSrc, vecTarget, DEPLOY_DISTANCE, vecTarget);
  engfunc(EngFunc_TraceMonsterHull, g_pInstallation, vecSrc, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecSrc);

  // Moving installation to the ground
  xs_vec_set(vecTarget, vecSrc[0], vecSrc[1], vecSrc[2] + vecMins[2] - DEPLOY_HEIGHT_STEP);
  engfunc(EngFunc_TraceMonsterHull, g_pInstallation, vecSrc, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecTarget);

  if (bCanDeploy) {
    // Check if stuck in something
    engfunc(EngFunc_TraceMonsterHull, g_pInstallation, vecTarget, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
    bCanDeploy = !!get_tr2(g_pTrace, TR_InOpen);
  }

  if (bCanDeploy) {
    // Can only deploy if on ground
    xs_vec_copy(vecTarget, vecSrc);
    vecSrc[2] -= 1.0;
    engfunc(EngFunc_TraceMonsterHull, g_pInstallation, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, this, g_pTrace);
    bCanDeploy = !get_tr2(g_pTrace, TR_InOpen);
  }

  set_pev(g_pInstallation, pev_solid, SOLID_NOT);

  return bCanDeploy;
}

InitInstallationPreview() {
  g_pInstallation = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
  dllfunc(DLLFunc_Spawn, g_pInstallation);
  set_pev(g_pInstallation, pev_solid, SOLID_NOT);
  // set_pev(g_pInstallation, pev_flags, EF_NODRAW);
  engfunc(EngFunc_SetModel, g_pInstallation, g_szSnowmanModel);
  engfunc(EngFunc_SetSize, g_pInstallation, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 72.0});
}
