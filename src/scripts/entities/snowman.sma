#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>

#include <api_assets>
#include <api_custom_entities>

#include <snowwars_internal>

#define ENTITY_NAME ENTITY(Snowman)
#define METHOD(%1) ENTITY_METHOD<Snowman>(%1)

#define RESPAWN_DELAY 5.0

new Float:g_rgflPlayerDeathTime[MAX_PLAYERS + 1];
new g_iPlayerDeadFlag[MAX_PLAYERS + 1];

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szSnowballHitSound[MAX_RESOURCE_PATH_LENGTH];
new g_szReturnSound[MAX_RESOURCE_PATH_LENGTH];
new g_szBloodSprite[] = "sprites/blood.spr";

public plugin_precache() {
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_Snowman_Model, g_szModel, charsmax(g_szModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_Snowman_Sound_Spawn, g_szSnowballHitSound, charsmax(g_szSnowballHitSound));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Player_Sound_Return, g_szReturnSound, charsmax(g_szReturnSound));

  precache_model(g_szBloodSprite);

  CE_RegisterClass(ENTITY_NAME, CE_Class_BaseProp);

  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_TakeDamage, "@Entity_TakeDamage");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Killed, "@Entity_Killed");

  CE_RegisterClassMethod(ENTITY_NAME, METHOD(RespawnPlayer), "@Entity_RespawnPlayer", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, METHOD(Effect), "@Entity_Effect");
  CE_RegisterClassMethod(ENTITY_NAME, METHOD(CanTakeDamage), "@Entity_CanTakeDamage", CE_Type_Cell, CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, METHOD(GetRelationship), "@Entity_GetRelationship", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, METHOD(ShouldRespawnPlayer), "@Entity_ShouldRespawnPlayer", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, METHOD(UnassignOwner), "@Entity_UnassignOwner");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(Snowman), SW_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);

  RegisterHookChain(RG_CSGameRules_CheckWinConditions, "HC_CheckWinConditions", .post = 0);
  RegisterHookChain(RG_CSGameRules_CheckWinConditions, "HC_CheckWinConditions_Post", .post = 1);
}

public client_connect(pPlayer) {
  g_rgflPlayerDeathTime[pPlayer] = 0.0;
}

public client_disconnected(pPlayer) {
  UnassignPlayerSnowmans(pPlayer);
}

public HC_CheckWinConditions() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    new iPlayerDeadFlag = pev(pPlayer, pev_deadflag);

    if (iPlayerDeadFlag != DEAD_NO) {

      if (PlayerHasSnowman(pPlayer)) {
        set_pev(pPlayer, pev_deadflag, DEAD_NO);
        g_iPlayerDeadFlag[pPlayer] = iPlayerDeadFlag;
      }
    }
  }
}

public HC_CheckWinConditions_Post() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    if (g_iPlayerDeadFlag[pPlayer] != DEAD_NO) {
      set_pev(pPlayer, pev_deadflag, g_iPlayerDeadFlag[pPlayer]);
      g_iPlayerDeadFlag[pPlayer] = DEAD_NO;
    }
  }
}

public HamHook_Player_Killed_Post(const pPlayer) {
  g_rgflPlayerDeathTime[pPlayer] = get_gametime();

  return HAM_HANDLED;
}

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-16.0, -16.0, 0.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{16.0, 16.0, 72.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_health, 200.0);
  set_pev(this, pev_takedamage, DAMAGE_AIM);

  CE_CallMethod(this, METHOD(Effect));

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Killed(const this, const pKiller, iShouldGib) {
  CE_CallBaseMethod(pKiller, iShouldGib);
  CE_CallMethod(this, METHOD(Effect));
  rg_check_win_conditions();
}

@Entity_Think(const this) {
  CE_CallBaseMethod();

  if (pev(this, pev_deadflag) != DEAD_NO) return;

  static Float:flGameTime; flGameTime = get_gametime();

  static iTeam; iTeam = pev(this, pev_team);
  static pOwner; pOwner = pev(this, pev_owner);

  if (pOwner && IS_PLAYER(pOwner)) {
    static iOwnerTeam; iOwnerTeam = get_ent_data(pOwner, "CBasePlayer", "m_iTeam");

    if (!is_user_alive(pOwner)) {
      if (!iTeam || iTeam == iOwnerTeam) {
        if (CE_CallMethod(this, METHOD(ShouldRespawnPlayer), pOwner)) {
          CE_CallMethod(this, METHOD(RespawnPlayer), pOwner);
        }
      } else {
        // Owner changed the team, unassign
        CE_CallMethod(this, METHOD(UnassignOwner));
      }
    } else {
      set_pev(this, pev_team, iTeam = iOwnerTeam);
    }
  } else {
    new pPlayer = FindOldestDiedPlayer(iTeam);
    if (pPlayer != FM_NULLENT && CE_CallMethod(this, METHOD(ShouldRespawnPlayer), pPlayer)) {
      CE_CallMethod(this, METHOD(RespawnPlayer), pPlayer);
    }
  }

  // Update skin based on team
  set_pev(this, pev_skin, (iTeam == 1 || iTeam == 2) ? iTeam : 0);

  set_pev(this, pev_nextthink, flGameTime + 1.0);
}

@Entity_TakeDamage(const this, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!CE_CallMethod(this, METHOD(CanTakeDamage), pInflictor, pAttacker)) return;

  CE_CallBaseMethod(pInflictor, pAttacker, flDamage, iDamageBits);
}

@Entity_Effect(const this) {
  static iBloodModelIndex = 0;
  if (!iBloodModelIndex) {
    iBloodModelIndex = engfunc(EngFunc_ModelIndex, g_szBloodSprite);
  }

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_BLOODSPRITE);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  write_short(iBloodModelIndex);
  write_short(iBloodModelIndex);
  write_byte(12);
  write_byte(8);
  message_end();

  emit_sound(this, CHAN_BODY, g_szSnowballHitSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

bool:@Entity_CanTakeDamage(const this, const pInflictor, const pAttacker) {
  new pOwner = pev(this, pev_owner);

  if (!pOwner || !IS_PLAYER(pOwner)) return false;
  if (pOwner == pAttacker) return false;
  if (!rg_is_player_can_takedamage(pOwner, pAttacker)) return false;

  return true;
}

@Entity_RespawnPlayer(const this, const pPlayer) {
  ExecuteHamB(Ham_CS_RoundRespawn, pPlayer);

  static Float:vecMins[3]; pev(pPlayer, pev_mins, vecMins);
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(this, pev_angles, vecAngles);

  vecOrigin[2] -= vecMins[2];

  set_pev(pPlayer, pev_angles, vecAngles);
  set_pev(pPlayer, pev_v_angle, vecAngles);
  engfunc(EngFunc_SetOrigin, pPlayer, vecOrigin);

  emit_sound(pPlayer, CHAN_STATIC, g_szReturnSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  ExecuteHamB(Ham_Killed, this, 0, 0);
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

bool:@Entity_ShouldRespawnPlayer(const this, const pPlayer) {
  if (pev(this, pev_deadflag) != DEAD_NO) return false;
  if (is_user_alive(pPlayer)) return false;
  if (!g_rgflPlayerDeathTime[pPlayer]) return false;

  static Float:flGameTime; flGameTime = get_gametime();
  if (flGameTime - g_rgflPlayerDeathTime[pPlayer] < RESPAWN_DELAY) return false;

  static SW_EntityRelationship:iRelationship; iRelationship = CE_CallMethod(this, METHOD(GetRelationship), pPlayer);
  if (iRelationship == SW_EntityRelationship_None) return false;

  return true;
}

@Entity_UnassignOwner(const this) {
  set_pev(this, pev_owner, 0);
  rg_check_win_conditions();
}

FindOldestDiedPlayer(const iTeam = 0) {
  new pBestPlayer = FM_NULLENT;

  for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
    if (!IS_PLAYER(pPlayer)) continue;
    if (!is_user_connected(pPlayer)) continue;
    if (is_user_alive(pPlayer)) continue;
    if (!g_rgflPlayerDeathTime[pPlayer]) continue;

    if (iTeam) {
      if (get_ent_data(pPlayer, "CBasePlayer", "m_iTeam") != iTeam) continue;
    }

    if (pBestPlayer == FM_NULLENT || g_rgflPlayerDeathTime[pBestPlayer] > g_rgflPlayerDeathTime[pPlayer]) {
      pBestPlayer = pPlayer;
    }
  }

  return pBestPlayer;
}

UnassignPlayerSnowmans(const &pPlayer) {
  new pSnowman = FM_NULLENT;
  while ((pSnowman = CE_Find(ENTITY_NAME, pSnowman)) != FM_NULLENT) {
    static pOwner; pOwner = pev(pSnowman, pev_owner);

    if (pOwner == pPlayer) {
      set_pev(pSnowman, pev_owner, 0);
    }
  }
}

bool:PlayerHasSnowman(const &pPlayer) {
  new pSnowman = FM_NULLENT;
  while ((pSnowman = CE_Find(ENTITY_NAME, pSnowman)) != FM_NULLENT) {
    if (CE_CallMethod(pSnowman, METHOD(GetRelationship), pPlayer) != SW_EntityRelationship_None) return true;
  }

  return false;
}
