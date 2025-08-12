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

#define ENTITY_NAME SW_ENTITY_FIREWORK_ROCKET

new const m_flSpeed[] = "flSpeed";

new const ExplosionEffect[] = "ExplosionEffect";

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szTrailSprite[MAX_RESOURCE_PATH_LENGTH];
new g_szRocketSound[MAX_RESOURCE_PATH_LENGTH];
new g_rgszParticleSprites[16][MAX_RESOURCE_PATH_LENGTH];
new g_rgszWaveSprites[10][MAX_RESOURCE_PATH_LENGTH];

new g_iWaveSpritesNum = 0;
new g_iParticleSpritesNum = 0;

new g_pTrace;

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_ROCKET_TRAIL_SPRITE, g_szTrailSprite, charsmax(g_szTrailSprite));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_FIREWORK_ROCKET_MODEL, g_szModel, charsmax(g_szModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_FIREWORK_ROCKET_SOUND, g_szRocketSound, charsmax(g_szRocketSound));

  g_iWaveSpritesNum = Asset_PrecacheList(SW_ASSET_LIBRARY, SW_ASSET_FIREWORK_WAVE_SPRITE, g_rgszWaveSprites, sizeof(g_rgszWaveSprites), charsmax(g_rgszWaveSprites[]));
  g_iParticleSpritesNum = Asset_PrecacheList(SW_ASSET_LIBRARY, SW_ASSET_FIREWORK_PARTICLE_SPRITE, g_rgszParticleSprites, sizeof(g_rgszParticleSprites), charsmax(g_rgszParticleSprites[]));

  CE_RegisterClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Allocate, "@Entity_Allocate");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_UpdatePhysics, "@Entity_UpdatePhysics");
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

@Entity_Allocate(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-4.0, -4.0, -4.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{4.0, 4.0, 4.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
  CE_SetMember(this, CE_Member_flLifeTime, 1.5);  
  CE_SetMember(this, m_flSpeed, 1024.0);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  new iTrailModelIndex = engfunc(EngFunc_ModelIndex, g_szTrailSprite);

  new Float:rgflColor[3];
  rgflColor[0] = float(random(256));
  rgflColor[1] = float(random(256));
  rgflColor[2] = float(random(256));

  engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Float:{0.0, 0.0, 0.0}, 0);
  write_byte(TE_BEAMFOLLOW);
  write_short(this);
  write_short(iTrailModelIndex);
  write_byte(10);
  write_byte(4);
  write_byte(floatround(rgflColor[0]));
  write_byte(floatround(rgflColor[1]));
  write_byte(floatround(rgflColor[2]));
  write_byte(255);
  message_end();

  set_pev(this, pev_rendercolor, rgflColor);

  emit_sound(this, CHAN_BODY, g_szRocketSound, 0.5, ATTN_NORM, 0, PITCH_NORM);

  set_pev(this, pev_nextthink, get_gametime());
}

@Entity_UpdatePhysics(const this) {
  set_pev(this, pev_solid, SOLID_TRIGGER);
  set_pev(this, pev_movetype, MOVETYPE_TOSS);
  set_pev(this, pev_gravity, 0.1);
}

@Entity_Killed(const this, const pKiller, iShouldGib) {
  static pOwner; pOwner = pev(this, pev_owner);
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  UTIL_RadiusDamage(vecOrigin, this, pOwner, 500.0, 256.0, 0, DMG_GENERIC, g_pTrace);

  CE_CallMethod(this, ExplosionEffect);

  CE_CallBaseMethod(pKiller, iShouldGib);
}

@Entity_Touch(const this, const pTarget) {
  if (pev(this, pev_deadflag) != DEAD_NO) return;

  CE_CallBaseMethod(pTarget);

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  static iContent; iContent = engfunc(EngFunc_PointContents, vecOrigin);

  if (iContent == CONTENTS_SKY) {
    vecOrigin[2] -= 128.0;
    set_pev(this, pev_origin, vecOrigin);
    ExecuteHamB(Ham_Killed, this, 0, 0);
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
  static Float:flChance; flChance = 1.0 - floatmin(flHitAngle / 90.0, 1.0);

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
  static iWaveModelIndex; iWaveModelIndex = engfunc(EngFunc_ModelIndex, g_rgszWaveSprites[random(g_iWaveSpritesNum)]);

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:rgflColor[3]; pev(this, pev_rendercolor, rgflColor);

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_TAREXPLOSION);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  message_end();

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_DLIGHT);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  write_byte(100);
  write_byte(floatround(rgflColor[0]));
  write_byte(floatround(rgflColor[1]));
  write_byte(floatround(rgflColor[2]));
  write_byte(10);
  write_byte(64);
  message_end();

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_BEAMDISK);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2] + 128.0);
  write_short(iWaveModelIndex);
  write_byte(0);
  write_byte(0);
  write_byte(25);
  write_byte(255);
  write_byte(0);
  write_byte(floatround(rgflColor[0]));
  write_byte(floatround(rgflColor[1]));
  write_byte(floatround(rgflColor[2]));
  write_byte(150);
  write_byte(0);
  message_end();

  if (random(2)) {
    static iParticleModelIndex; iParticleModelIndex = engfunc(EngFunc_ModelIndex, g_rgszParticleSprites[random(g_iParticleSpritesNum)]);

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_SPRITETRAIL);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2] + 128.0);
    write_short(iParticleModelIndex);
    write_byte(50);
    write_byte(3);
    write_byte(3);
    write_byte(50);
    write_byte(40);
    message_end();
  } else {
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_PARTICLEBURST);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_short(150);
    write_byte(random(256));
    write_byte(10);
    message_end();
  }
}
