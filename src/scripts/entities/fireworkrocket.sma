#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_entities>

#include <combat_util>

#include <snowwars_const>

#define PLUGIN "[Entity] Firework Rocket"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME SW_Entity_FireworkRocket

new const m_flSpeed[] = "flSpeed";

new const ExplosionEffect[] = "ExplosionEffect";

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szTrailSprite[MAX_RESOURCE_PATH_LENGTH];

new g_pTrace;

new Float:g_rgrgflColors[3 * 5][3];

public plugin_precache() {
  g_pTrace = create_tr2();

  for (new i = 0; i < sizeof(g_rgrgflColors); ++i) {
    new iPrimaryColor = i % (sizeof(g_rgrgflColors) / 3) % 3;

    g_rgrgflColors[i][iPrimaryColor] = 255.0;
    g_rgrgflColors[i][(iPrimaryColor + 1) % 3] = random_float(0.0, 255.0);
    g_rgrgflColors[i][(iPrimaryColor + 2) % 3] = random_float(0.0, 100.0);
  }

  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_FireworkRocket_Sprites_Trail, g_szTrailSprite, charsmax(g_szTrailSprite));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_FireworkRocket_Model, g_szModel, charsmax(g_szModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_FireworkRocket_Sound_Whistle);

  CE_RegisterClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_InitPhysics, "@Entity_InitPhysics");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Killed, "@Entity_Killed");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Touch, "@Entity_Touch");

  CE_RegisterClassMethod(ENTITY_NAME, ExplosionEffect, "@Entity_ExplosionEffect");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_end() {
  free_tr2(g_pTrace);
}

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-4.0, -4.0, -4.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{4.0, 4.0, 4.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
  CE_SetMember(this, CE_Member_flLifeTime, 1.5);  
  CE_SetMember(this, CE_Member_bForceVisible, true);
  CE_SetMember(this, m_flSpeed, 1024.0);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  new iTrailModelIndex = engfunc(EngFunc_ModelIndex, g_szTrailSprite);

  new iColor = random(sizeof(g_rgrgflColors));

  engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Float:{0.0, 0.0, 0.0}, 0);
  write_byte(TE_BEAMFOLLOW);
  write_short(this);
  write_short(iTrailModelIndex);
  write_byte(10);
  write_byte(4);
  write_byte(floatround(g_rgrgflColors[iColor][0]));
  write_byte(floatround(g_rgrgflColors[iColor][1]));
  write_byte(floatround(g_rgrgflColors[iColor][2]));
  write_byte(80);
  message_end();

  set_pev(this, pev_rendercolor, g_rgrgflColors[iColor]);

  Asset_EmitSound(this, CHAN_BODY, SW_AssetLibrary, SW_Asset_Entity_FireworkRocket_Sound_Whistle, .iPitch = 90 + random(30), .flAttenuation = 0.5);

  set_pev(this, pev_nextthink, get_gametime());
}

@Entity_InitPhysics(const this) {
  set_pev(this, pev_solid, SOLID_TRIGGER);
  set_pev(this, pev_movetype, MOVETYPE_TOSS);
  set_pev(this, pev_gravity, 0.1);
}

@Entity_Killed(const this, const pKiller, iShouldGib) {
  static pOwner; pOwner = pev(this, pev_owner);
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  UTIL_RadiusDamage(vecOrigin, this, pOwner, 500.0, 256.0, 0, DMG_GENERIC);

  CE_CallMethod(this, ExplosionEffect);

  CE_CallBaseMethod(pKiller, iShouldGib);
}

@Entity_Touch(const this, const pTarget) {
  if (pev(this, pev_deadflag) != DEAD_NO) return;

  CE_CallBaseMethod(pTarget);

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  static iContent; iContent = engfunc(EngFunc_PointContents, vecOrigin);

  if (iContent == CONTENTS_SKY) {
    set_pev(this, pev_solid, SOLID_NOT);
    set_pev(this, pev_movetype, MOVETYPE_NOCLIP);
    return;
  }

  static Float:vecAngles[3]; pev(this, pev_angles, vecAngles);
  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);
  static Float:vecTarget[3]; xs_vec_add(vecOrigin, vecVelocity, vecTarget);
  static Float:vecForward[3]; xs_vec_normalize(vecVelocity, vecForward);
  static Float:vecBackward[3]; xs_vec_neg(vecForward, vecBackward);

  engfunc(EngFunc_TraceLine, vecOrigin, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);

  static Float:vecPlaneNormal[3]; get_tr2(g_pTrace, TR_vecPlaneNormal, vecPlaneNormal);

  static Float:flHitAngle; flHitAngle = xs_vec_angle(vecPlaneNormal, vecBackward);
  static Float:flChance; flChance = (1.0 - floatmin(flHitAngle / 90.0, 1.0));

  if (random_float(0.0, 1.0) <= flChance) {
    ExecuteHamB(Ham_Killed, this, 0, 0);
    return;
  }

  static Float:vecReflection[3]; xs_vec_reflect(vecForward, vecPlaneNormal, vecReflection);

  vector_to_angle(vecReflection, vecAngles);
  vecAngles[0] -= vecAngles[0];
  set_pev(this, pev_angles, vecAngles);
}

@Entity_Think(const this) {
  if (pev(this, pev_deadflag) != DEAD_NO) return;

  static Float:vecAngles[3]; pev(this, pev_angles, vecAngles);
  static Float:flSpeed; flSpeed = CE_GetMember(this, m_flSpeed);

  static Float:vecVelocity[3];
  angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecVelocity);
  xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);
  set_pev(this, pev_velocity, vecVelocity);

  CE_CallBaseMethod();

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_ExplosionEffect(const this) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(this, pev_angles, vecAngles);

  engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_TAREXPLOSION);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  message_end();

  static Float:vecUp[3]; angle_vector(vecAngles, ANGLEVECTOR_UP, vecUp);
  static Float:vecRight[3]; angle_vector(vecAngles, ANGLEVECTOR_RIGHT, vecRight);
  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

  for (new i = 0; i < 5; ++i) {
    new iColor = random(sizeof(g_rgrgflColors));

    static Float:vecTarget[3];
    for (new i = 0; i < 3; ++i) {
      vecAngles[i] += random_float(-30.0, 30.0);
      vecTarget[i] = vecOrigin[i] + (vecForward[i] * -32.0) + (vecUp[i] * random_float(-64.0, 64.0)) + (vecRight[i] * random_float(-64.0, 64.0)) + (vecForward[i] * -random_float(0.0, 64.0));
    }

    new pFireworkEffect = CE_Create("sw_firework_effect", vecTarget);
    if (pFireworkEffect == FM_NULLENT) continue;

    set_pev(pFireworkEffect, pev_rendercolor, g_rgrgflColors[iColor]);
    set_pev(pFireworkEffect, pev_scale, random_float(0.5, 1.5));
    set_pev(pFireworkEffect, pev_angles, vecAngles);
    dllfunc(DLLFunc_Spawn, pFireworkEffect);
    set_pev(pFireworkEffect, pev_nextthink, get_gametime() + (i * 0.125)); 
  }

  engfunc(EngFunc_TraceLine, vecOrigin, vecForward, IGNORE_MONSTERS, this, g_pTrace);
  static Float:flFraction; get_tr2(g_pTrace, TR_flFraction, flFraction);

  if (flFraction < 1.0) {
    UTIL_ExplosionDecalTrace(g_pTrace);
  }
}
