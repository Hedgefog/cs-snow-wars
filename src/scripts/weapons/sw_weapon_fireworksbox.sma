#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>

#include <snowwars>
#include <api_custom_weapons>
#include <api_custom_entities>

#define PLUGIN "[Snow Wars] Weapon Fireworks Box"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new const g_szMdlVFireworkbox[] = "models/snowwars/v090/weapons/v_fireworksbox.mdl";
new const g_szMdlPFireworkbox[] = "models/snowwars/v090/weapons/p_fireworksbox.mdl";
new const g_szMdlWFireworkbox[] = "models/snowwars/v090/weapons/w_fireworksbox.mdl";

new CW:g_iCwHandler;

public plugin_precache() {
  precache_generic("sprites/snowwars/v090/weapon_fireworksbox.txt");
  precache_model(g_szMdlVFireworkbox);
  precache_model(g_szMdlPFireworkbox);
  precache_model(g_szMdlWFireworkbox);
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  g_iCwHandler = CW_Register("snowwars/v090/weapon_fireworksbox", CSW_FAMAS, _, _, _, _, _, 4, 1, _, "skull", CWF_NoBulletSmoke);
  CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
  CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
  CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
  CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
}

public @Weapon_Idle(this) {
  // new pPlayer = CW_GetPlayer(this);
}

public @Weapon_Deploy(this) {
    // new pPlayer = CW_GetPlayer(this);
    CW_DefaultDeploy(this, g_szMdlVFireworkbox, g_szMdlPFireworkbox, 0, "c4");
}

public @Weapon_PrimaryAttack(this) {
  new pPlayer = CW_GetPlayer(this);

  static Float:vecOrigin[3];
  ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecOrigin);

  static Float:vecAngles[3];
  pev(pPlayer, pev_v_angle, vecAngles);
  vecAngles[0] = 0.0;
  vecAngles[2] = 0.0;

  new pInstallation = CE_Create("sw_fireworksbox", vecOrigin);
  set_pev(pInstallation, pev_owner, pPlayer);
  set_pev(pInstallation, pev_angles, vecAngles);
  dllfunc(DLLFunc_Spawn, pInstallation);

  CW_RemovePlayerItem(this);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szMdlWFireworkbox);
}

public Float:@Weapon_GetMaxSpeed(this) {
  return 250.0;
}
