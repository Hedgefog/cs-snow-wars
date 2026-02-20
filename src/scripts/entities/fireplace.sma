#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_assets>
#include <api_custom_entities>

#include <entity_fire_const>

#include <snowwars_internal>

#define ENTITY_NAME ENTITY(Fireplace)
#define MEMBER(%1) ENTITY_MEMBER<Fireplace>(%1)
#define METHOD(%1) ENTITY_METHOD<Fireplace>(%1)

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

new Float:g_rgflPlayerNextHeal[MAX_PLAYERS + 1];

public plugin_precache() {
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_Fireplace_Model, g_szModel, charsmax(g_szModel));

  CE_RegisterClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Killed, "@Entity_Killed");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_InitPhysics, "@Entity_InitPhysics");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_TakeDamage, "@Entity_TakeDamage");

  CE_RegisterClassMethod(ENTITY_NAME, METHOD(CanTakeDamage), "@Entity_CanTakeDamage", CE_Type_Cell, CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, METHOD(GetRelationship), "@Entity_GetRelationship", CE_Type_Cell);
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(Fireplace), SW_VERSION, "Hedgehog Fog");

  new Float:vecAbsMin[3]; pev(0, pev_absmin, vecAbsMin);
  new Float:vecAbsMax[3]; pev(0, pev_absmax, vecAbsMax);
  dllfunc(DLLFunc_GetHullBounds, 0, vecAbsMin, vecAbsMax);
}

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-16.0, -16.0, 0.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{16.0, 16.0, 16.0});

  CE_SetMember(this, MEMBER(flHealRate), 0.1);
  CE_SetMember(this, MEMBER(flHealAmount), 3.0);
  CE_SetMember(this, MEMBER(flHealRange), 128.0);
  CE_SetMember(this, MEMBER(pFire), FM_NULLENT);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  new pFire = CE_GetMember(this, MEMBER(pFire));

  if (pFire == FM_NULLENT) {
    pFire = CE_Create(ENTITY_FIRE);
  }

  if (pFire != FM_NULLENT) {
    CE_SetMember(pFire, Entity_Fire_Member_bAllowSpread, false);
    CE_SetMember(pFire, CE_Member_flLifeTime, 0.0);

    dllfunc(DLLFunc_Spawn, pFire);
    set_pev(pFire, pev_owner, this);
    set_pev(pFire, pev_aiment, this);
    set_pev(pFire, pev_movetype, MOVETYPE_FOLLOW);
  }

  set_pev(this, pev_health, 200.0);
  set_pev(this, pev_takedamage, DAMAGE_AIM);

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Killed(const this, const pKiller, iShouldGib) {
  CE_CallBaseMethod(pKiller, iShouldGib);

  new pFire = CE_GetMember(this, MEMBER(pFire));
  if (pFire != FM_NULLENT) {
    ExecuteHamB(Ham_Killed, pFire, pKiller, iShouldGib);
    CE_SetMember(this, MEMBER(pFire), FM_NULLENT);
  }
}

@Entity_InitPhysics(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_solid, SOLID_BBOX);
  set_pev(this, pev_movetype, MOVETYPE_NONE);
}

@Entity_Think(const this) {
  CE_CallBaseMethod();

  static Float:flGameTime; flGameTime = get_gametime();

  static Float:flLTime; pev(this, pev_ltime, flLTime);
  static Float:flHealAmount; flHealAmount = CE_GetMember(this, MEMBER(flHealAmount));
  static Float:flHealRate; flHealRate = CE_GetMember(this, MEMBER(flHealRate));
  static Float:flHealRange; flHealRange = CE_GetMember(this, MEMBER(flHealRange));
  static Float:flEffectiveHealRange; flEffectiveHealRange = flHealRange * 0.5;
  static Float:flTimeDelta; flTimeDelta = flLTime ? flGameTime - flLTime : flHealRate;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_alive(pPlayer)) continue;
    if (g_rgflPlayerNextHeal[pPlayer] > flGameTime) continue;
    
    static Float:flDistance; flDistance = entity_range(this, pPlayer);
    if (flDistance > flHealRange) continue;

    g_rgflPlayerNextHeal[pPlayer] = flGameTime + flHealRate;

    static Float:flMaxHealth; pev(pPlayer, pev_max_health, flMaxHealth);
    static Float:flHealth; pev(pPlayer, pev_health, flHealth);
    if (flHealth >= flMaxHealth) continue;
    if (flHealth < 1.0) continue;

    static Float:flDistanceRatio;
    
    flDistanceRatio = floatmin((flHealRange - flDistance) / (flHealRange - flEffectiveHealRange), 1.0);
    
    static Float:flHealthToAdd; flHealthToAdd = floatmin(flHealAmount * flDistanceRatio * flTimeDelta, flHealRange - flDistance);
    if (flHealthToAdd <= 0.0) continue;

    set_pev(pPlayer, pev_health, flHealth = floatmin(flHealth + flHealthToAdd, flMaxHealth));
  }

  set_pev(this, pev_nextthink, flGameTime + flHealRate);
  set_pev(this, pev_ltime, flGameTime);
}

@Entity_TakeDamage(const this, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!CE_CallMethod(this, METHOD(CanTakeDamage), pInflictor, pAttacker)) return;

  CE_CallBaseMethod(pInflictor, pAttacker, flDamage, iDamageBits);
}

bool:@Entity_CanTakeDamage(const this, const pInflictor, const pAttacker) {
  new pOwner = pev(this, pev_owner);

  if (CE_IsInstanceOf(pAttacker, ENTITY_FIRE)) return false;
  if (IS_PLAYER(pAttacker) && !rg_is_player_can_takedamage(pOwner, pAttacker)) return false;

  return true;
}

SW_EntityRelationship:@Entity_GetRelationship(const this, const pEntity) {
  if (!IS_PLAYER(pEntity)) return SW_EntityRelationship_None;
  if (pev(this, pev_deadflag) != DEAD_NO) return SW_EntityRelationship_None;

  static pOwner; pOwner = pev(this, pev_owner);
  if (IS_PLAYER(pOwner)) {
    if (pOwner != pEntity) return SW_EntityRelationship_None;

    return SW_EntityRelationship_Owner;
  }

  static iTeam; iTeam = pev(this, pev_team);
  if (iTeam) {
    static iPlayerTeam; iPlayerTeam = get_ent_data(pEntity, "CBasePlayer", "m_iTeam");
    if (iPlayerTeam != iTeam) return SW_EntityRelationship_None;

    return SW_EntityRelationship_Team;
  }

  return SW_EntityRelationship_Shared;
}
