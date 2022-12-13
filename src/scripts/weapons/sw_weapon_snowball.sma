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

#define PLUGIN "[Snow Wars] Weapon Snowball"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new const g_szMdlVSnowball[] = "models/snowwars/v090/weapons/v_snowball.mdl";
new const g_szMdlPSnowball[] = "models/snowwars/v090/weapons/p_snowball.mdl";
new const g_szMdlWSnowball[] = "models/snowwars/v090/weapons/w_snowball.mdl";
new const g_szSndThrow[] = "snowwars/v090/snowthrow1.wav";

new g_bPlayerRedeploy[MAX_PLAYERS + 1];

new CW:g_iCwHandler;

public plugin_precache() {
  precache_generic("sprites/snowwars/v090/weapon_snowball.txt");
  precache_model(g_szMdlVSnowball);
  precache_model(g_szMdlPSnowball);
  precache_model(g_szMdlWSnowball);
  precache_sound(g_szSndThrow);
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  g_iCwHandler = CW_Register("snowwars/v090/weapon_snowball", CSW_DEAGLE, 1, _, _, _, _, 1, 1, _, "skull", CWF_NoBulletSmoke|CWF_NoSecondaryAttack);
  CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
  CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
  CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");
  CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
  CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
}

public @Weapon_Idle(this) {
  new pPlayer = CW_GetPlayer(this);

  if (!get_member(this, m_flReleaseThrow) && get_member(this, m_flStartThrow)) {
    set_member(this, m_flReleaseThrow, get_gametime());
  }

  if (get_member(this, m_flStartThrow)) {
    ThrowGrenade(this);
    emit_sound(pPlayer, CHAN_BODY, g_szSndThrow, 1.0, ATTN_NORM, 0, PITCH_NORM);
    return;
  }
  
  if (get_member(this, m_flReleaseThrow) > 0.0) {
    // we've finished the throw, restart.
    set_member(this, m_flStartThrow, 0.0);
    set_member(this, m_flReleaseThrow, -1.0);
    return;
  }

  if (g_bPlayerRedeploy[pPlayer]) {
    ExecuteHamB(Ham_Item_Deploy, this);
  } else {
    CW_PlayAnimation(this, 0, 31.0 / 30.0);
  }
}

public @Weapon_Deploy(this) {
    new pPlayer = CW_GetPlayer(this);
    CW_DefaultDeploy(this, g_szMdlVSnowball, g_szMdlPSnowball, 3, "grenade");
    g_bPlayerRedeploy[pPlayer] = false;
}

public @Weapon_CanDrop(this) {
  return PLUGIN_HANDLED;
}

public @Weapon_PrimaryAttack(this) {
  if (!get_member(this, m_flStartThrow)) {
    set_member(this, m_flStartThrow, get_gametime());
    set_member(this, m_flReleaseThrow, 0.0);
    CW_PlayAnimation(this, 1, 31.0 / 35.0);
  } else {
    new pPlayer = CW_GetPlayer(this);
    if (is_user_bot(pPlayer)) { // force throw for bots
      CW_Idle(this);
    }
  }
}
public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szMdlWSnowball);
}

public Float:@Weapon_GetMaxSpeed(this) {
  return 250.0;
}

ThrowGrenade(this) {
  new pPlayer = CW_GetPlayer(this);

  static Float:vecThrowAngle[3];
  pev(pPlayer, pev_v_angle, vecThrowAngle);

  static Float:vecPunchangle[3];
  pev(pPlayer, pev_punchangle, vecPunchangle);

  xs_vec_add(vecThrowAngle, vecPunchangle, vecThrowAngle);

  if (vecThrowAngle[0] < 0.0) {
      vecThrowAngle[0] = -10.0 + vecThrowAngle[0] * ((90.0 - 10.0) / 90.0);
  } else {
      vecThrowAngle[0] = -10.0 + vecThrowAngle[0] * ((90.0 + 10.0) / 90.0);
  }

  new Float:flVel = (90.0 - vecThrowAngle[0]) * 6.0;
  if (flVel > 750.0) {
      flVel = 750.0;
  }

  engfunc(EngFunc_MakeVectors, vecThrowAngle); 

  static Float:vecSrc[3];
  ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

  static Float:vecThrow[3];
  pev(pPlayer, pev_velocity, vecThrow);

  static Float:vecForward[3];
  get_global_vector(GL_v_forward, vecForward);

  for (new i = 0; i < 3; ++i) {
      vecSrc[i] += vecForward[i] * 16.0;
      vecThrow[i] += vecForward[i] * flVel;
  }

  new pSnowball = ShootTimed(pPlayer, vecSrc, vecThrow);
  set_pev(pSnowball, pev_angles, vecThrowAngle);

  CW_PlayAnimation(this, 2, 11.0 / 30.0);
  rg_set_animation(pPlayer, PLAYER_ATTACK1);

  set_member(this, m_flReleaseThrow, 0.0);
  set_member(this, m_flStartThrow, 0.0);
  set_member(this, m_Weapon_flTimeWeaponIdle, 0.5);
  set_member(this, m_Weapon_flNextPrimaryAttack, 0.5);
  set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);

  g_bPlayerRedeploy[pPlayer] = true;
}

ShootTimed(pOwner, const Float:vecStart[3], const Float:vecVelocity[3]) {
    new pSnowball = CE_Create("sw_snowball", vecStart);
    set_pev(pSnowball, pev_owner, pOwner);
    dllfunc(DLLFunc_Spawn, pSnowball);
    engfunc(EngFunc_SetOrigin, pSnowball, vecStart);
    set_pev(pSnowball, pev_velocity, vecVelocity);

    static Float:vecAngles[3];
    vector_to_angle(vecVelocity, vecAngles);
    set_pev(pSnowball, pev_angles, vecAngles);

    return pSnowball;
}
