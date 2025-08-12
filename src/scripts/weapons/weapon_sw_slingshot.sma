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
#include <weapon_base_throwable_const>

#include <snowwars_const>

#define PLUGIN "[Snow Wars] Weapon Slingshot"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define MISFIRE_DELAY 10.0
#define MISFIRE_MAX_SHAKING 0.25
#define MISFIRE_MAX_ERROR 0.125

new const m_flChargeTime[] = "flChargeTime";

new const GetPower[] = "GetPower";
new const GetChargeDuration[] = "GetChargeDuration";

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];
new g_szThrowSound[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SLINGSHOT_V_MODEL, g_szVModel, charsmax(g_szVModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SLINGSHOT_P_MODEL, g_szPModel, charsmax(g_szPModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SLINGSHOT_W_MODEL, g_szWModel, charsmax(g_szWModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWBALL_THROW_SOUND, g_szThrowSound, charsmax(g_szThrowSound));

  CW_RegisterClass(SW_WEAPON_SLINGSHOT, WEAPON_BASE_THROWABLE);

  CW_ImplementClassMethod(SW_WEAPON_SLINGSHOT, CW_Method_Allocate, "@Weapon_Allocate");
  CW_ImplementClassMethod(SW_WEAPON_SLINGSHOT, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(SW_WEAPON_SLINGSHOT, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(SW_WEAPON_SLINGSHOT, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(SW_WEAPON_SLINGSHOT, CW_Method_CanDrop, "@Weapon_CanDrop");
  CW_ImplementClassMethod(SW_WEAPON_SLINGSHOT, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");

  CW_RegisterClassMethod(SW_WEAPON_SLINGSHOT, Weapon_BaseThrowable_Method_Throw, "@Weapon_Throw");
  CW_RegisterClassMethod(SW_WEAPON_SLINGSHOT, Weapon_BaseThrowable_Method_SpawnProjectile, "@Weapon_SpawnProjectile");

  CW_RegisterClassMethod(SW_WEAPON_SLINGSHOT, GetPower, "@Weapon_GetPower");
  CW_RegisterClassMethod(SW_WEAPON_SLINGSHOT, GetChargeDuration, "@Weapon_GetChargeDuration");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);
}

@Weapon_Allocate(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iId, 4);
  CW_SetMember(this, CW_Member_iSlot, 0);
  CW_SetMember(this, CW_Member_iPosition, 1);

  CW_SetMember(this, Weapon_BaseThrowable_Member_flThrowForce, 2048.0);
  CW_SetMember(this, m_flChargeTime, 1.0);
}

@Weapon_Idle(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static bool:bRedeploy; bRedeploy = CW_GetMember(this, Weapon_BaseThrowable_Member_bRedeploy);
  static Float:flStartThrow; flStartThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flStartThrow);
  static Float:flReleaseThrow; flReleaseThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flReleaseThrow);

  client_print(pPlayer, print_console, "Idle %.3f %.3f", flStartThrow, flReleaseThrow);
  if (flStartThrow && !flReleaseThrow) {
    static Float:flPower; flPower = CW_CallMethod(this, GetPower);
    client_print(pPlayer, print_console, "POWER: %f", flPower);

    if (flPower < 0.2) {
      CW_SetMember(this, Weapon_BaseThrowable_Member_flStartThrow, 0.0);
      CW_SetMember(this, Weapon_BaseThrowable_Member_flReleaseThrow, -1.0);
      return;
    }
  }

  CW_CallBaseMethod();

  if (!flStartThrow && flReleaseThrow == -1.0 && !bRedeploy) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 31.0 / 30.0);
  }
}

@Weapon_Deploy(const this) {
  static Float:flGameTime; flGameTime = get_gametime();

  if (!CW_CallBaseMethod()) return;

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 3, "shieldgun");

  CW_SetMember(this, CW_Member_flTimeIdle, flGameTime + 1.0);
  CW_SetMember(this, Weapon_BaseThrowable_Member_bRedeploy, false);
}

@Weapon_PrimaryAttack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static Float:flChargeTime; flChargeTime = CW_GetMember(this, m_flChargeTime);
  static Float:flChargeDuration; flChargeDuration = CW_CallMethod(this, GetChargeDuration);

  if (flChargeDuration > MISFIRE_DELAY) {
    @Player_AnglesShake(pPlayer);
  }

  if (flChargeDuration >= flChargeTime) {
    if (is_user_bot(pPlayer)) {
      CW_CallNativeMethod(this, CW_Method_Idle);
      return;
    }
  }

  if (!CW_CallBaseMethod()) return;

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1);
}

@Weapon_CanDrop(const this) {
  return true;
}

@Weapon_Throw(const this) {
  new Float:flChargeDuration = CW_CallMethod(this, GetChargeDuration);
  new bool:bMissfire = flChargeDuration > MISFIRE_DELAY;
  new Float:flPower = CW_CallMethod(this, GetPower);

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
  static Float:vecPunchAngle[3]; pev(pPlayer, pev_punchangle, vecPunchAngle);
  static Float:vecThrowAngle[3]; xs_vec_add(vecAngles, vecPunchAngle, vecThrowAngle);
  static Float:flThrowForce; flThrowForce = CW_GetMember(this, Weapon_BaseThrowable_Member_flThrowForce);

  engfunc(EngFunc_MakeVectors, vecThrowAngle);

  static pProjectile; pProjectile = CW_CallMethod(this, Weapon_BaseThrowable_Method_SpawnProjectile);

  if (pProjectile != FM_NULLENT) {
    static Float:vecForward[3]; get_global_vector(GL_v_forward, vecForward);

    if (bMissfire) {
      for (new i = 0; i < 3; ++i) {
        vecForward[i] += random_float(-MISFIRE_MAX_ERROR, MISFIRE_MAX_ERROR);
      }

      xs_vec_normalize(vecForward, vecForward);
    }

    static Float:vecThrow[3]; pev(pPlayer, pev_velocity, vecThrow);

    xs_vec_add_scaled(vecThrow, vecForward, flThrowForce * flPower, vecThrow);

    set_pev(pProjectile, pev_velocity, xs_vec_len(vecThrow) ? vecThrow : Float:{0.0, 0.0, 1.0});
    
    static Float:vecAngles[3]; vector_to_angle(vecThrow, vecAngles);

    set_pev(pProjectile, pev_angles, vecAngles);
  }

  set_ent_data_string(pPlayer, "CBasePlayer", "m_szAnimExtention", "onehanded");
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 11.0 / 30.0);
  rg_set_animation(pPlayer, PLAYER_RELOAD);

  emit_sound(pPlayer, CHAN_BODY, g_szThrowSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

  CW_SetMember(this, Weapon_BaseThrowable_Member_flStartThrow, 0.0);
  CW_SetMember(this, CW_Member_flNextPrimaryAttack, 1.0);
  CW_SetMember(this, CW_Member_flNextSecondaryAttack, 1.0);
  CW_SetMember(this, CW_Member_flTimeIdle, 1.0);
}

@Weapon_SpawnProjectile(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static Float:vecForward[3]; get_global_vector(GL_v_forward, vecForward);
  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

  xs_vec_add_scaled(vecSrc, vecForward, 16.0, vecSrc);

  new pProjectile = CE_Create(SW_ENTITY_SNOWBALL, vecSrc);
  dllfunc(DLLFunc_Spawn, pProjectile);

  set_pev(pProjectile, pev_owner, pPlayer);

  return pProjectile;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

Float:@Weapon_GetPower(const this) {
  static Float:flChargeTime; flChargeTime = CW_GetMember(this, m_flChargeTime);
  static Float:flChargeDuration; flChargeDuration = CW_CallMethod(this, GetChargeDuration);

  return floatclamp(flChargeDuration / flChargeTime, 0.0, 1.0);
}

Float:@Weapon_GetChargeDuration(const this) {
  return get_gametime() - Float:CW_GetMember(this, Weapon_BaseThrowable_Member_flStartThrow);
}

@Player_AnglesShake(const &this) {
  static Float:vecPunchAngle[3]; pev(this, pev_punchangle, vecPunchAngle);

  // static Float:vecViewAngle[3]; pev(this, pev_v_angle, vecViewAngle);

  for (new i = 0; i < 3; ++i) {
    vecPunchAngle[i] += random_float(-MISFIRE_MAX_SHAKING, MISFIRE_MAX_SHAKING);
  }

  // set_pev(this, pev_angles, vecViewAngle);
  // set_pev(this, pev_v_angle, vecViewAngle);
  // set_pev(this, pev_fixangle, 1);
  set_pev(this, pev_punchangle, vecPunchAngle);
}
