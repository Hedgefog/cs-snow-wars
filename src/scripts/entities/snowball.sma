#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_entities>
#include <screenfade_util>

#include <snowwars_internal>

#define ENTITY_NAME ENTITY(Snowball)
#define MEMBER(%1) ENTITY_MEMBER<Snowball>(%1)
#define METHOD(%1) ENTITY_METHOD<Snowball>(%1)

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szHitSound[MAX_RESOURCE_PATH_LENGTH];
new g_szShowSplashSprite[MAX_RESOURCE_PATH_LENGTH];

new g_pTrace;

new Float:g_flAutoGuidanceRange;
new Float:g_flAutoGuidanceAngle;

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_Snowball_Model, g_szModel, charsmax(g_szModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_Snowball_Sound_Hit, g_szHitSound, charsmax(g_szHitSound));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_Snowball_Sprites_Splash, g_szShowSplashSprite, charsmax(g_szShowSplashSprite));

  CE_RegisterClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_InitPhysics, "@Entity_InitPhysics");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Killed, "@Entity_Killed");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Touch, "@Entity_Touch");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");

  CE_RegisterClassMethod(ENTITY_NAME, METHOD(AutoGuidance), "@Entity_AutoGuidance", CE_Type_Cell);
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(Snowball), SW_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);

  bind_pcvar_float(create_cvar(CVAR("snowball_autoguidance_range"), "16.0"), g_flAutoGuidanceRange);
  bind_pcvar_float(create_cvar(CVAR("snowball_autoguidance_angle"), "15.0"), g_flAutoGuidanceAngle);
}

public plugin_end() {
  free_tr2(g_pTrace);
}

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-4.0, -4.0, -4.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{4.0, 4.0, 4.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
  CE_SetMember(this, CE_Member_flLifeTime, 10.0);

  CE_SetMember(this, MEMBER(flDamage), 50.0);
  CE_SetMember(this, MEMBER(flAutoGuidanceRange), g_flAutoGuidanceRange);
  CE_SetMember(this, MEMBER(flAutoGuidanceAngle), g_flAutoGuidanceAngle);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_sequence, 1);
  set_pev(this, pev_framerate, 1.0);
  set_pev(this, pev_takedamage, DAMAGE_YES);
  set_pev(this, pev_health, 1.0);

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_InitPhysics(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_solid, SOLID_BBOX);
  set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
  set_pev(this, pev_gravity, 0.4);
}

@Entity_Killed(const this, const pKiller, iShouldGib) {
  static iSplashSpriteModelIndex = 0;
  if (!iSplashSpriteModelIndex) {
    iSplashSpriteModelIndex = engfunc(EngFunc_ModelIndex, g_szShowSplashSprite);
  }

  if (!pev(this, pev_waterlevel)) {
    static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
    static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);
    static Float:vecMoveDirection[3]; xs_vec_normalize(vecVelocity, vecMoveDirection);

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_BLOODSPRITE);
    engfunc(EngFunc_WriteCoord, vecOrigin[0] - vecMoveDirection[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1] - vecMoveDirection[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2] - vecMoveDirection[2]);
    write_short(iSplashSpriteModelIndex);
    write_short(iSplashSpriteModelIndex);
    write_byte(12);
    write_byte(8);
    message_end();

    emit_sound(this, CHAN_BODY, g_szHitSound, 0.5, ATTN_NORM, 0, PITCH_NORM);
  }

  CE_CallBaseMethod(pKiller, iShouldGib);
}

@Player_SnowballHitEffect(this, Float:flRatio) {
  UTIL_ScreenFade(this, { 255, 255, 255 }, 3.0 * flRatio, 1.0, floatround(100 * flRatio));

  static Float:vecPunchangle[3];
  vecPunchangle[0] = random_float(-16.0 * flRatio, 16.0 * flRatio);
  vecPunchangle[1] = random_float(-16.0 * flRatio, 24.0 * flRatio);
  vecPunchangle[2] = random_float(-16.0 * flRatio, 16.0 * flRatio);

  set_pev(this, pev_punchangle, vecPunchangle);
}

@Entity_Touch(const this, const pTarget) {
  CE_CallBaseMethod(pTarget);

  if (pev(pTarget, pev_solid) < SOLID_BBOX) return;

  static pOwner; pOwner = pev(this, pev_owner);
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:flDamage; flDamage = CE_GetMember(this, MEMBER(flDamage));

  set_pev(this, pev_enemy, pTarget);

  if (IS_PLAYER(pTarget)) {
    if (rg_is_player_can_takedamage(pTarget, pOwner)) {
      static Float:vecTarget[3]; pev(pTarget, pev_origin, vecTarget);
      static iHitgroup; iHitgroup = vecOrigin[2] - vecTarget[2] >= 18.0 ? HIT_HEAD : 0;

      ExecuteHamB(Ham_TakeDamage, pTarget, this, pOwner, flDamage, iHitgroup == HIT_HEAD ? DMG_DROWN : DMG_GENERIC);
    }
  } else if (pev(pTarget, pev_takedamage) != DAMAGE_NO) {
    ExecuteHamB(Ham_TakeDamage, pTarget, this, pOwner, flDamage, DMG_GENERIC);
  }

  ExecuteHamB(Ham_TakeDamage, this, pTarget, pTarget, 1.0, DMG_GENERIC);
}

@Entity_Think(const this) {
  if (pev(this, pev_waterlevel) > 1) {
    ExecuteHamB(Ham_TakeDamage, this, 0, 0, 1.0, DMG_GENERIC);
    return;
  }

  static Float:flAutoGuidanceRange; flAutoGuidanceRange = CE_GetMember(this, MEMBER(flAutoGuidanceRange));

  if (flAutoGuidanceRange > 0.0) {
    static pOwner; pOwner = pev(this, pev_owner);

    static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

    static pNearestPlayer; pNearestPlayer = FM_NULLENT;
    static Float:flNearestPlayerDistance; flNearestPlayerDistance = 0.0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
      if (pOwner == pPlayer) continue;
      if (!is_user_alive(pPlayer)) continue;

      static Float:vecTargetOrigin[3]; pev(pPlayer, pev_origin, vecTargetOrigin);
      if (floatabs(vecOrigin[2] - vecTargetOrigin[2]) > 32.0) continue;

      static Float:flDistance; flDistance = get_distance_f(vecOrigin, vecTargetOrigin);
      if (flDistance > flAutoGuidanceRange) continue;

      if (!rg_is_player_can_takedamage(pPlayer, pOwner)) continue;

      if (pNearestPlayer == FM_NULLENT || flDistance < flNearestPlayerDistance) {
        pNearestPlayer = pPlayer;
        flNearestPlayerDistance = flDistance;
      }
    }

    if (pNearestPlayer != FM_NULLENT) {
      CE_CallMethod(this, METHOD(AutoGuidance), pNearestPlayer);
    }
  }

  CE_CallBaseMethod();

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

public HamHook_Player_TakeDamage_Post(pPlayer, pInflictor, pAttacker, Float:flDamage, iDamageBits) {
  if (!CE_IsInstanceOf(pInflictor, ENTITY_NAME)) return HAM_IGNORED;

  new Float:flRatio = flDamage / 100.0;

  new iHitgroup = get_ent_data(pPlayer, "CBaseMonster", "m_LastHitGroup");
  if (iHitgroup == HIT_HEAD) {
    flRatio *= 2.0;
  }

  @Player_SnowballHitEffect(pPlayer, flRatio);

  return HAM_HANDLED;
}

@Entity_AutoGuidance(const this, const pTarget) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecTarget[3]; pev(pTarget, pev_origin, vecTarget);

  vecTarget[2] = vecOrigin[2];

  engfunc(EngFunc_TraceMonsterHull, this, vecOrigin, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
  if (get_tr2(g_pTrace, TR_pHit) != pTarget) return;

  static Float:vecDirection[3];
  xs_vec_sub(vecTarget, vecOrigin, vecDirection);
  vecDirection[2] = 0.0;
  xs_vec_normalize(vecDirection, vecDirection);

  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);
  static Float:flSpeed; flSpeed = xs_vec_len_2d(vecVelocity);

  static Float:flAutoGuidanceAngle; flAutoGuidanceAngle = Float:CE_GetMember(this, MEMBER(flAutoGuidanceAngle));
  static Float:flAngle; flAngle = xs_rad2deg(xs_acos(xs_vec_dot(vecVelocity, vecDirection) / flSpeed, radian));

  if (flAngle > flAutoGuidanceAngle) return;

  vecVelocity[0] = vecDirection[0] * flSpeed;
  vecVelocity[1] = vecDirection[1] * flSpeed;

  set_pev(this, pev_velocity, vecVelocity);
}
