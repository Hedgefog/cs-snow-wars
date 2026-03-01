#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <snowwars_internal>

#define WEAPON_NAME WEAPON(Snowman)

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_Snowman_Model_View), g_szVModel, charsmax(g_szVModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_Snowman_Model_Player), g_szPModel, charsmax(g_szPModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_Snowman_Model_World), g_szWModel, charsmax(g_szWModel));

  CW_RegisterClass(WEAPON_NAME, SW_Weapon_BaseBlueprint);

  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");

  CW_RegisterClassMethod(WEAPON_NAME, SW_Weapon_BaseBlueprint_Method_CreateInstallation, "@Weapon_CreateInstallation");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Snowman), SW_VERSION, "Hedgehog Fog");
}

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iId, SW_WeaponsIds_Snowman);
  CW_SetMember(this, CW_Member_iPosition, 3);
  CW_SetMember(this, CW_Member_iPrimaryAmmoType, 6);
}

@Weapon_Deploy(const this) {
  if (!CW_CallBaseMethod()) return false;

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 1, "blueprint");
  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 0.5);

  return true;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

@Weapon_CreateInstallation(const this) {
  return CE_Create(ENTITY(Snowman));
}
