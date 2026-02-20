#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>
#include <weapon_base_throwable_const>

#include <snowwars_internal>

#define WEAPON_NAME WEAPON(Snowball)

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];
new g_szThrowSound[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Snowball_Model_View, g_szVModel, charsmax(g_szVModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Snowball_Model_Player, g_szPModel, charsmax(g_szPModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Snowball_Model_World, g_szWModel, charsmax(g_szWModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Snowball_Sound_Throw, g_szThrowSound, charsmax(g_szThrowSound));

  CW_RegisterClass(WEAPON_NAME, WEAPON_BASE_THROWABLE);

  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");

  CW_RegisterClassMethod(WEAPON_NAME, Weapon_BaseThrowable_Method_Throw, "@Weapon_Throw");
  CW_RegisterClassMethod(WEAPON_NAME, Weapon_BaseThrowable_Method_SpawnProjectile, "@Weapon_SpawnProjectile");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Snowball), SW_VERSION, "Hedgehog Fog");
}

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iId, SW_WeaponsIds_Snowball);
  CW_SetMember(this, CW_Member_iSlot, 0);
  CW_SetMember(this, CW_Member_iPosition, 5);

  CW_SetMember(this, Weapon_BaseThrowable_Member_flThrowForce, 750.0);
}

@Weapon_Idle(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static bool:bRedeploy; bRedeploy = CW_GetMember(this, Weapon_BaseThrowable_Member_bRedeploy);
  static Float:flStartThrow; flStartThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flStartThrow);
  static Float:flReleaseThrow; flReleaseThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flReleaseThrow);

  CW_CallBaseMethod();

  if (!flStartThrow && flReleaseThrow == -1.0 && !bRedeploy) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 31.0 / 30.0);

    // Instant run animation check
    set_ent_data_float(pPlayer, "CBasePlayer", "m_flLastFired", 0.0);
  }
}

@Weapon_Deploy(const this) {
  static Float:flGameTime; flGameTime = get_gametime();

  if (!CW_CallBaseMethod()) return;

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 3, "snowball");

  CW_SetMember(this, CW_Member_flTimeIdle, flGameTime + 0.5);
  CW_SetMember(this, CW_Member_iClip, 1);
}

@Weapon_PrimaryAttack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static Float:flStartThrow; flStartThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flStartThrow);

  if (flStartThrow > 0.0 && is_user_bot(pPlayer)) {
    CW_CallNativeMethod(this, CW_Method_Idle);
    return;
  }

  if (!CW_CallBaseMethod()) return;

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 0.5);

  // Force throw for bots
  if (is_user_bot(pPlayer)) {
    CW_CallNativeMethod(this, CW_Method_Idle);
  }
}

@Weapon_Throw(const this) {
  CW_CallBaseMethod();

  new pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  emit_sound(pPlayer, CHAN_BODY, g_szThrowSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2);
}

@Weapon_SpawnProjectile(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static Float:vecForward[3]; get_global_vector(GL_v_forward, vecForward);
  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

  xs_vec_add_scaled(vecSrc, vecForward, 16.0, vecSrc);

  new pProjectile = CE_Create(ENTITY(Snowball), vecSrc);
  if (pProjectile == FM_NULLENT) return FM_NULLENT;

  set_pev(pProjectile, pev_owner, pPlayer);
  dllfunc(DLLFunc_Spawn, pProjectile);

  return pProjectile;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}
