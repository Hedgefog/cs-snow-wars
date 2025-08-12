#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <snowwars_const>

#define PLUGIN "[Snow Wars] Weapon Fireworks Box"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_FIREWORKSBOX_V_MODEL, g_szVModel, charsmax(g_szVModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_FIREWORKSBOX_P_MODEL, g_szPModel, charsmax(g_szPModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_FIREWORKSBOX_W_MODEL, g_szWModel, charsmax(g_szWModel));

  CW_RegisterClass(SW_WEAPON_FIREWORKSBOX);
  CW_ImplementClassMethod(SW_WEAPON_FIREWORKSBOX, CW_Method_Allocate, "@Weapon_Allocate");
  CW_ImplementClassMethod(SW_WEAPON_FIREWORKSBOX, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(SW_WEAPON_FIREWORKSBOX, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(SW_WEAPON_FIREWORKSBOX, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(SW_WEAPON_FIREWORKSBOX, CW_Method_GetMaxSpeed, "@Weapon_GetMaxSpeed");
  CW_ImplementClassMethod(SW_WEAPON_FIREWORKSBOX, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);
}

@Weapon_Allocate(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iFlags, ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
  CW_SetMember(this, CW_Member_iId, 6);
  CW_SetMember(this, CW_Member_iSlot, 4);
  CW_SetMember(this, CW_Member_iPosition, 3);
  CW_SetMember(this, CW_Member_iDefaultAmmo, 1);
  CW_SetMember(this, CW_Member_iPrimaryAmmoType, 2);
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

  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 0.5);
}

@Weapon_Deploy(const this) {
  if (!CW_CallBaseMethod()) return;

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 0, "c4");
}

@Weapon_PrimaryAttack(const this) {
  new pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static iShotsFired; iShotsFired = CW_GetMember(this, CW_Member_iShotsFired);
  if (iShotsFired > 0) return false;

  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);

  if (iAmmo <= 0) return false;

  static Float:vecOrigin[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecOrigin);

  static Float:vecAngles[3];
  pev(pPlayer, pev_v_angle, vecAngles);
  vecAngles[0] = 0.0;
  vecAngles[2] = 0.0;

  new pInstallation = CE_Create(SW_ENTITY_FIREWORKS_BOX, vecOrigin);
  set_pev(pInstallation, pev_owner, pPlayer);
  set_pev(pInstallation, pev_angles, vecAngles);
  dllfunc(DLLFunc_Spawn, pInstallation);

  set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", --iAmmo, iPrimaryAmmoType);
  CW_SetMember(this, CW_Member_iShotsFired, ++iShotsFired);

  CW_SetMember(this, CW_Member_flNextPrimaryAttack, get_gametime() + 0.5);
  CW_SetMember(this, CW_Member_flNextSecondaryAttack, get_gametime() + 0.5);

  return true;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

Float:@Weapon_GetMaxSpeed(const this) {
  return 250.0;
}
