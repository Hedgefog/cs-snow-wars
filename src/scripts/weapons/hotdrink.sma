#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_entities>
#include <api_custom_weapons>

#include <snowwars_internal>

#define WEAPON_NAME WEAPON(HotDrink)
#define MEMBER(%1) WEAPON_MEMBER<HotDrink>(%1)
#define METHOD(%1) WEAPON_METHOD<HotDrink>(%1)

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_HotDrink_Model_View), g_szVModel, charsmax(g_szVModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_HotDrink_Model_Player), g_szPModel, charsmax(g_szPModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_HotDrink_Model_World), g_szWModel, charsmax(g_szWModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_HotDrink_Sound_Drink));

  CW_RegisterClass(WEAPON_NAME);

  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Holster, "@Weapon_Holster");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_GetMaxSpeed, "@Weapon_GetMaxSpeed");

  CW_RegisterClassMethod(WEAPON_NAME, METHOD(ReleaseDrink), "@Weapon_ReleaseDrink");
  CW_RegisterClassMethod(WEAPON_NAME, METHOD(Interrupt), "@Weapon_Interrupt");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(HotDrink), SW_VERSION, "Hedgehog Fog");
}

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iFlags, ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
  CW_SetMember(this, CW_Member_iId, SW_WeaponsIds_HotDrink);
  CW_SetMember(this, CW_Member_iSlot, 2);
  CW_SetMember(this, CW_Member_iPosition, 0);
  CW_SetMember(this, CW_Member_iPrimaryAmmoType, 8);
  CW_SetMember(this, CW_Member_iMaxClip, -1);
  CW_SetMember(this, CW_Member_iClip, -1);
  CW_SetMember(this, CW_Member_iDefaultAmmo, 100);
  CW_SetMember(this, CW_Member_bExhaustible, true);

  CW_SetMember(this, MEMBER(flReleaseDrink), 0.0);
}

@Weapon_Deploy(const this) {
  if (!CW_CallBaseMethod()) return false;

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 1, "hotdrink");
  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 0.1);

  return true;
}

@Weapon_Holster(const this) {
  if (!CW_CallBaseMethod()) return false;

  CW_CallMethod(this, METHOD(Interrupt));

  return true;
}

@Weapon_Idle(const this) {
  if (!CW_CallBaseMethod()) return false;

  CW_CallMethod(this, METHOD(Interrupt));

  return true;
}

@Weapon_PrimaryAttack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static iAmmoType; iAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmoType);
  if (iAmmo <= 0) return;

  static Float:flReleaseDrink; flReleaseDrink = CW_GetMember(this, MEMBER(flReleaseDrink));

  if (flReleaseDrink && flReleaseDrink < get_gametime()) {
    CW_CallMethod(this, METHOD(ReleaseDrink));
    return;
  }

  CW_SetMember(this, MEMBER(flReleaseDrink), get_gametime());

  Asset_EmitSound(pPlayer, CHAN_VOICE, ASSET_LIBRARY, ASSET(Weapon_HotDrink_Sound_Drink), .iPitch = 80 + random(30));
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 0.1);
  CW_SetPlayerAnimation(pPlayer, PLAYER_ATTACK1);

  CW_SetMember(this, CW_Member_flNextPrimaryAttack, get_gametime() + 1.5);
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

@Weapon_ReleaseDrink(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static iAmmoType; iAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmoType);
  if (iAmmo <= 0) return;

  static Float:flMaxHealth; pev(pPlayer, pev_max_health, flMaxHealth);
  static Float:flHealth; pev(pPlayer, pev_health, flHealth);

  if (iAmmo > 0 && flHealth < flMaxHealth) {
    static Float:flHealthToAdd; flHealthToAdd = floatmin(flHealth + floatmin(float(iAmmo), 10.0), flMaxHealth) - flHealth;
    flHealthToAdd = floatmin(flHealthToAdd, float(iAmmo));

    if (flHealthToAdd > 0.0) {
      set_pev(pPlayer, pev_health, flHealth += flHealthToAdd);
      set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmo - floatround(flHealthToAdd), iAmmoType);
    }
  }

  CW_SetMember(this, MEMBER(flReleaseDrink), 0.0);
  CW_SetMember(this, CW_Member_flNextPrimaryAttack, get_gametime() + 1.5);
  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 1.5);
}

@Weapon_Interrupt(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  
  if (Float:CW_GetMember(this, MEMBER(flReleaseDrink))) {
    emit_sound(pPlayer, CHAN_VOICE, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    CW_SetMember(this, MEMBER(flReleaseDrink), 0.0);
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 0.1);
    CW_SetPlayerAnimation(pPlayer, PLAYER_IDLE);
  }
}

Float:@Weapon_GetMaxSpeed(const this) {
  return 250.0;
}
