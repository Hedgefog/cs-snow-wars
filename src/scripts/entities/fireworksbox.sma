#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_entities>

#include <snowwars_const>

#define PLUGIN "[Entity] Fireworks Box"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME SW_Entity_FireworksBox

new const m_iMaxRocketsNum[] = "iMaxRocketsNum";
new const m_iRocketsNum[] = "iRocketsNum";

new const SpawnRocket[] = "SpawnRocket";

new g_szMusicSound[MAX_RESOURCE_PATH_LENGTH];
new g_szModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_FireworksBox_Sound_Music, g_szMusicSound, charsmax(g_szMusicSound));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_FireworksBox_Model, g_szModel, charsmax(g_szModel));

  CE_RegisterClass(ENTITY_NAME);

  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Destroy, "@Entity_Destroy");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_InitPhysics, "@Entity_InitPhysics");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");

  CE_RegisterClassMethod(ENTITY_NAME, SpawnRocket, "@Entity_SpawnRocket");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);
}

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-8.0, -8.0, 0.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{8.0, 8.0, 8.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);

  CE_SetMember(this, m_iMaxRocketsNum, 8);
}

@Entity_InitPhysics(const this) {
  set_pev(this, pev_solid, SOLID_TRIGGER);
  set_pev(this, pev_movetype, MOVETYPE_TOSS);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, m_iRocketsNum, CE_GetMember(this, m_iMaxRocketsNum));

  emit_sound(this, CHAN_BODY, g_szMusicSound, VOL_NORM * 0.375, ATTN_IDLE, 0, PITCH_NORM);
  
  set_pev(this, pev_nextthink, get_gametime() + 7.0);
}

@Entity_Destroy(const this) {
  CE_CallBaseMethod();

  emit_sound(this, CHAN_BODY, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

@Entity_Think(const this) {
  CE_CallBaseMethod();

  static iRocketCount; iRocketCount = CE_GetMember(this, m_iRocketsNum);
  
  if (iRocketCount <= 0) {
    ExecuteHamB(Ham_Killed, this, 0, 0);
    return;
  }
  
  new pRocket = CE_CallMethod(this, SpawnRocket);

  // Detonate first rocket instantly
  if (iRocketCount == CE_GetMember(this, m_iMaxRocketsNum)) {
    ExecuteHamB(Ham_Killed, pRocket, 0, 0);
    set_pev(this, pev_effects, EF_NODRAW);
  }

  CE_SetMember(this, m_iRocketsNum, iRocketCount -= 1);

  set_pev(this, pev_nextthink, get_gametime() + 0.125);
}

@Entity_SpawnRocket(const this) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  new pRocket = CE_Create(SW_Entity_FireworkRocket, vecOrigin);
  if (pRocket == FM_NULLENT) return FM_NULLENT;

  set_pev(pRocket, pev_owner, pev(this, pev_owner));

  static Float:vecAngles[3]; xs_vec_set(vecAngles, -random_float(15.0, 80.0), random_float(-180.0, 180.0), 0.0);
  set_pev(pRocket, pev_angles, vecAngles);

  dllfunc(DLLFunc_Spawn, pRocket);

  return pRocket;
}
