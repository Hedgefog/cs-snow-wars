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

#define PLUGIN "[Snow Wars] Weapon Slingshot"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define CHARGE_TIME 1.0
#define MISFIRE_DELAY 10.0
#define MISFIRE_MAX_SHAKING 0.25
#define MISFIRE_MAX_ERROR 0.125

new const g_szMdlVSnowball[] = "models/snowwars/v090/weapons/v_slingshot.mdl";
new const g_szMdlPSnowball[] = "models/snowwars/v090/weapons/p_slingshot.mdl";
new const g_szMdlWSnowball[] = "models/snowwars/v090/weapons/w_slingshot.mdl";
new const g_szSndThrow[] = "snowwars/v090/snowthrow1.wav";

new g_bPlayerRedeploy[MAX_PLAYERS + 1];

new CW:g_iCwHandler;

public plugin_precache() {
  precache_generic("sprites/snowwars/v090/weapon_slingshot.txt");
  precache_model(g_szMdlVSnowball);
  precache_model(g_szMdlPSnowball);
  precache_model(g_szMdlWSnowball);
  precache_sound(g_szSndThrow);
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  g_iCwHandler = CW_Register("snowwars/v090/weapon_slingshot", CSW_AK47, 1, _, _, _, _, 0, 1, _, "skull", CWF_NoBulletSmoke);
  CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
  CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_Bind(g_iCwHandler, CWB_SecondaryAttack, "@Weapon_SecondaryAttack");
  CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
  CW_Bind(g_iCwHandler, CWB_Holster, "@Weapon_Holster");
  // CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");
  CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
  CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
}

public @Weapon_Idle(this) {
  new pPlayer = CW_GetPlayer(this);

  set_member(pPlayer, m_szAnimExtention, "shieldgun");

  if (!get_member(this, m_flReleaseThrow) && get_member(this, m_flStartThrow)) {
    set_member(this, m_flReleaseThrow, get_gametime());
  }

  if (get_member(this, m_flStartThrow)) {
    new Float:flChargeDuration = GetChargeDuration(this);
    new bool:bMissfire = flChargeDuration > MISFIRE_DELAY;
    new Float:flPower = floatmax(floatmin(flChargeDuration / CHARGE_TIME, 1.0), 0.0);

    if (flPower > 0.2) {
      ThrowGrenade(this, flPower, bMissfire);
      emit_sound(pPlayer, CHAN_BODY, g_szSndThrow, 1.0, ATTN_NORM, 0, PITCH_NORM);
    } else {
      set_member(this, m_flReleaseThrow, 0.0);
      set_member(this, m_flStartThrow, 0.0);
    }
  } else if (get_member(this, m_flReleaseThrow) > 0.0) {
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
    CW_DefaultDeploy(this, g_szMdlVSnowball, g_szMdlPSnowball, 3, "shieldgun");
    g_bPlayerRedeploy[pPlayer] = false;
}

public @Weapon_Holster(this) {
    new pPlayer = CW_GetPlayer(this);

    if (!is_user_connected(pPlayer)) {
        return;
    }

    set_member(this, m_flReleaseThrow, 0.0);
    set_member(this, m_flStartThrow, 0.0);
}

// public @Weapon_CanDrop(this) {
//   return PLUGIN_HANDLED;
// }

public @Weapon_PrimaryAttack(this) {
  new pPlayer = CW_GetPlayer(this);

  if (!get_member(this, m_flStartThrow)) {
    set_member(this, m_flStartThrow, get_gametime());
    set_member(this, m_flReleaseThrow, 0.0);
    CW_PlayAnimation(this, 1, 0.0);
  } else {
    new Float:flChargeDuration = GetChargeDuration(this);

    if (flChargeDuration > MISFIRE_DELAY) {
      @Player_AnglesShake(pPlayer);
    } else if (flChargeDuration >= CHARGE_TIME) {
      new pPlayer = CW_GetPlayer(this);
      if (is_user_bot(pPlayer)) { // force throw for bots
        CW_Idle(this);
      }
    }
  }
}

public @Weapon_SecondaryAttack(this) {
  CW_Idle(this);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szMdlWSnowball);
}

public Float:@Weapon_GetMaxSpeed(this) {
  return 250.0;
}

public @Player_AnglesShake(this) {
  static Float:vecViewAngle[3];
  pev(this, pev_v_angle, vecViewAngle);

  for (new i = 0; i < 3; ++i) {
    vecViewAngle[i] += random_float(-MISFIRE_MAX_SHAKING, MISFIRE_MAX_SHAKING);
  }

  set_pev(this, pev_angles, vecViewAngle);
  set_pev(this, pev_v_angle, vecViewAngle);
  set_pev(this, pev_fixangle, 1);
}

ThrowGrenade(this, Float:flPower, bool:bMissfire = false) {
  new pPlayer = CW_GetPlayer(this);

  static Float:vecSrc[3];
  ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);
  
  static Float:vecThrow[3];
  pev(pPlayer, pev_velocity, vecThrow);

  static Float:vecThrowAngle[3];
  pev(pPlayer, pev_v_angle, vecThrowAngle);
  engfunc(EngFunc_MakeVectors, vecThrowAngle); 

  static Float:vecForward[3];
  get_global_vector(GL_v_forward, vecForward);
  xs_vec_normalize(vecForward, vecForward);

  for (new i = 0; i < 3; ++i) {
    new Float:flError = bMissfire ? random_float(-MISFIRE_MAX_ERROR, MISFIRE_MAX_ERROR) : 0.0;
    vecSrc[i] += vecForward[i] * 16.0;
    vecThrow[i] += (vecForward[i] + flError) * (2048.0 * flPower);
  }

  ShootTimed(pPlayer, vecSrc, vecThrow);

  set_member(pPlayer, m_szAnimExtention, "onehanded");
  CW_PlayAnimation(this, 2, 11.0 / 30.0);
  rg_set_animation(pPlayer, PLAYER_RELOAD);

  set_member(this, m_flReleaseThrow, 0.0);
  set_member(this, m_flStartThrow, 0.0);
  set_member(this, m_Weapon_flNextPrimaryAttack, 1.0);
  set_member(this, m_Weapon_flNextSecondaryAttack, 1.0);
  set_member(this, m_Weapon_flTimeWeaponIdle, 1.0);

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

Float:GetChargeDuration(this) {
  return get_gametime() - Float:get_member(this, m_flStartThrow);
}

