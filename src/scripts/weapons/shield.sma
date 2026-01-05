#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <reapi>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <snowwars_const>

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

#define PLUGIN "[Snow Wars] Weapon Snowman"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define DEPLOY_HEIGHT_STEP 32.0
#define DEPLOY_DISTANCE 64.0

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];

new g_pTrace;

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Model_View, g_szVModel, charsmax(g_szVModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Model_Player, g_szPModel, charsmax(g_szPModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Model_World, g_szWModel, charsmax(g_szWModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Sound_Impact);

  CW_RegisterClass(SW_Weapon_Shield);

  CW_ImplementClassMethod(SW_Weapon_Shield, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(SW_Weapon_Shield, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(SW_Weapon_Shield, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(SW_Weapon_Shield, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(SW_Weapon_Shield, CW_Method_GetMaxSpeed, "@Weapon_GetMaxSpeed");
  CW_ImplementClassMethod(SW_Weapon_Shield, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");

  CW_RegisterClassMethod(SW_Weapon_Shield, "HitFeedback", "@Weapon_HitFeedback", CW_Type_Cell, CW_Type_Cell, CW_Type_Cell, CW_Type_Cell);
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  CE_RegisterClassNativeMethodHook(SW_Entity_Snowball, CE_Method_Touch, "CEHook_Snowball_Touch");
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public CEHook_Snowball_Touch(const pSnowball, const pToucher) {
  if (!IS_PLAYER(pToucher)) return CE_IGNORED;

  new pActiveItem = get_ent_data_entity(pToucher, "CBasePlayer", "m_pActiveItem");

  if (pActiveItem != FM_NULLENT && CW_IsInstanceOf(pActiveItem, SW_Weapon_Shield)) {
    static Float:vecOrigin[3]; pev(pToucher, pev_origin, vecOrigin);
    static Float:vecProjectileOrigin[3]; pev(pSnowball, pev_origin, vecProjectileOrigin);
    if (IsBlockedByShield(pToucher, pSnowball)) {
      CW_CallMethod(pActiveItem, "HitFeedback", pSnowball, pev(pSnowball, pev_owner), 0.0, 0);
      ExecuteHamB(Ham_Killed, pSnowball, pToucher, 0);

      return CE_SUPERCEDE;
    }


    return CE_HANDLED;
  }

  return CE_HANDLED;
}

@Weapon_HitFeedback(const this, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  new pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 21.0 / 35.0);
  rg_set_animation(pPlayer, PLAYER_ATTACK1);

  Asset_EmitSound(pPlayer, CHAN_ITEM, SW_AssetLibrary, SW_Asset_Weapon_Shield_Sound_Impact, .iPitch = 80 + random(20));
}

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iId, SW_WeaponsIds_Shield);
  CW_SetMember(this, CW_Member_iSlot, 1);
  CW_SetMember(this, CW_Member_iPosition, 1);
}

@Weapon_Idle(const this) {
  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 0.1);
}

@Weapon_Deploy(const this) {
  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 0, "shield");
  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 0.1);
}

@Weapon_PrimaryAttack(const this) {
  return true;
}

Float:@Weapon_GetMaxSpeed(const this) {
  return 250.0;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

#define SHIELD_WIDTH 36.0
#define SHIELD_HEIGHT 48.0
#define SHIELD_DISTANCE 16.0
#define SHIELD_OFFSET_Z 16.0

bool:IsBlockedByShield(const &pPlayer, const &pProjectile) {
  static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
  static Float:vecProjectileOrigin[3]; pev(pProjectile, pev_origin, vecProjectileOrigin);
  static Float:vecAbsMin[3]; pev(pPlayer, pev_absmin, vecAbsMin);
  static Float:vecAbsMax[3]; pev(pPlayer, pev_absmax, vecAbsMax);

  static Float:vecHitOrigin[3]; xs_vec_set(
    vecHitOrigin,
    floatclamp(vecProjectileOrigin[0], vecAbsMin[0], vecAbsMax[0]),
    floatclamp(vecProjectileOrigin[1], vecAbsMin[1], vecAbsMax[1]),
    floatclamp(vecProjectileOrigin[2], vecAbsMin[2], vecAbsMax[2])
  );

  // Half of pitch (max 45 degrees)
  vecAngles[0] *= 0.5;

  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

  static Float:vecVelocity[3]; pev(pPlayer, pev_velocity, vecVelocity);
  static Float:vecProjectileVelocity[3]; pev(pProjectile, pev_velocity, vecProjectileVelocity);

  static Float:vecDirection[3];
  xs_vec_sub(vecProjectileVelocity, vecVelocity, vecDirection);
  xs_vec_normalize(vecDirection, vecDirection);

  static Float:flDirDot; flDirDot = xs_vec_dot(vecDirection, vecForward);
  if (flDirDot >= 0.0) return false;

  static Float:vecUp[3]; angle_vector(vecAngles, ANGLEVECTOR_UP, vecUp);
  static Float:vecRight[3]; angle_vector(vecAngles, ANGLEVECTOR_RIGHT, vecRight);

  static Float:vecShieldOrigin[3];
  xs_vec_add_scaled(vecOrigin, vecForward, SHIELD_DISTANCE, vecShieldOrigin);
  xs_vec_add_scaled(vecShieldOrigin, vecUp, SHIELD_OFFSET_Z, vecShieldOrigin);

  static Float:vecDelta[3]; xs_vec_sub(vecProjectileOrigin, vecShieldOrigin, vecDelta);

  if (floatabs(xs_vec_dot(vecDelta, vecUp)) > SHIELD_HEIGHT * 0.5) return false;
  if (floatabs(xs_vec_dot(vecDelta, vecRight)) > SHIELD_WIDTH * 0.5) return false;

  return true;
}
