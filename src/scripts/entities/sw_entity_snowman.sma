#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>

#include <api_assets>
#include <api_custom_entities>

#include <snowwars_const>

#define PLUGIN "[Entity] Snowman"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME SW_ENTITY_SNOWMAN

#define IS_PLAYER(%1) (%1 > 0 && %1 <= MaxClients)
#define RESPAWN_DELAY 5.0

new const RespawnPlayer[] = "RespawnPlayer";
new const Effect[] = "Effect";
new const CanTakeDamage[] = "CanTakeDamage";
new const GetRelationship[] = "GetRelationship";
new const ShouldRespawnPlayer[] = "ShouldRespawnPlayer";
new const UnassignOwner[] = "UnassignOwner";

new Float:g_rgflPlayerDeathTime[MAX_PLAYERS + 1];
new g_iPlayerDeadFlag[MAX_PLAYERS + 1];

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szSnowballHitSound[MAX_RESOURCE_PATH_LENGTH];
new g_szReturnSound[MAX_RESOURCE_PATH_LENGTH];

new g_iBloodModelIndex;

public plugin_precache() {
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWMAN_MODEL, g_szModel, charsmax(g_szModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_SNOWBALL_HIT_SOUND, g_szSnowballHitSound, charsmax(g_szSnowballHitSound));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_RETURN_SOUND, g_szReturnSound, charsmax(g_szReturnSound));

  CE_RegisterClass(ENTITY_NAME, CE_Class_BaseProp);

  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Allocate, "@Entity_Allocate");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_TakeDamage, "@Entity_TakeDamage");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Killed, "@Entity_Killed");

  CE_RegisterClassMethod(ENTITY_NAME, RespawnPlayer, "@Entity_RespawnPlayer", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, Effect, "@Entity_Effect");
  CE_RegisterClassMethod(ENTITY_NAME, CanTakeDamage, "@Entity_CanTakeDamage", CE_Type_Cell, CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, GetRelationship, "@Entity_GetRelationship", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, ShouldRespawnPlayer, "@Entity_ShouldRespawnPlayer", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY_NAME, UnassignOwner, "@Entity_UnassignOwner");

  g_iBloodModelIndex = precache_model("sprites/blood.spr");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

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
  // log_amx("CHECK WIN CONDITIONS");
  client_print(0, print_chat, "CHECK WIN CONDITIONS");

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
}

@Entity_Allocate(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-16.0, -16.0, 0.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{16.0, 16.0, 72.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_health, 200.0);
  set_pev(this, pev_takedamage, DAMAGE_AIM);

  CE_CallMethod(this, Effect);

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Killed(const this, const pKiller, iShouldGib) {
  CE_CallBaseMethod(pKiller, iShouldGib);
  CE_CallMethod(this, Effect);
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
        if (CE_CallMethod(this, ShouldRespawnPlayer, pOwner)) {
          CE_CallMethod(this, RespawnPlayer, pOwner);
        }
      } else {
        // Owner changed the team, unassign
        CE_CallMethod(this, UnassignOwner);
      }
    } else {
      set_pev(this, pev_team, iTeam = iOwnerTeam);
    }
  } else {
    new pPlayer = FindOldestDiedPlayer(iTeam);
    if (pPlayer != FM_NULLENT && CE_CallMethod(this, ShouldRespawnPlayer, pPlayer)) {
      CE_CallMethod(this, RespawnPlayer, pPlayer);
    }
  }

  // Update skin based on team
  set_pev(this, pev_skin, (iTeam == 1 || iTeam == 2) ? iTeam : 0);

  set_pev(this, pev_nextthink, flGameTime + 1.0);
}

@Entity_TakeDamage(const this, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!CE_CallMethod(this, CanTakeDamage, pInflictor, pAttacker)) return;

  CE_CallBaseMethod(pInflictor, pAttacker, flDamage, iDamageBits);
}

@Entity_Effect(const this) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_BLOODSPRITE);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  write_short(g_iBloodModelIndex);
  write_short(g_iBloodModelIndex);
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

SW_Snowman_Relationship:@Entity_GetRelationship(const this, const pEntity) {
  if (!IS_PLAYER(pEntity)) return SW_Snowman_Relationship_None;
  if (pev(this, pev_deadflag) != DEAD_NO) return SW_Snowman_Relationship_None;

  static pOwner; pOwner = pev(this, pev_owner);
  if (IS_PLAYER(pOwner)) {
    if (pOwner != pEntity) return SW_Snowman_Relationship_None;

    return SW_Snowman_Relationship_Owner;
  }

  static iTeam; iTeam = pev(this, pev_team);
  if (iTeam) {
    static iPlayerTeam; iPlayerTeam = get_ent_data(pEntity, "CBasePlayer", "m_iTeam");
    if (iPlayerTeam != iTeam) return SW_Snowman_Relationship_None;

    return SW_Snowman_Relationship_Team;
  }

  return SW_Snowman_Relationship_Shared;
}

bool:@Entity_ShouldRespawnPlayer(const this, const pPlayer) {
  if (pev(this, pev_deadflag) != DEAD_NO) return false;
  if (is_user_alive(pPlayer)) return false;
  if (!g_rgflPlayerDeathTime[pPlayer]) return false;

  static Float:flGameTime; flGameTime = get_gametime();
  if (flGameTime - g_rgflPlayerDeathTime[pPlayer] < RESPAWN_DELAY) return false;

  static SW_Snowman_Relationship:iRelationship; iRelationship = CE_CallMethod(this, GetRelationship, pPlayer);
  if (iRelationship == SW_Snowman_Relationship_None) return false;

  return true;
}

@Entity_UnassignOwner(const this) {
  set_pev(this, pev_owner, 0);
  rg_check_win_conditions();
  client_print(0, print_chat, "UNASSIGN");
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
    if (CE_CallMethod(pSnowman, GetRelationship, pPlayer) != SW_Snowman_Relationship_None) return true;
  }

  return false;
}

// FindPlayerSnowman(const &pPlayer) {
//   new pBestSnowman = FM_NULLENT;

//   new pSnowman = FM_NULLENT;
//   while ((pSnowman = CE_Find(ENTITY_NAME, pSnowman)) != FM_NULLENT) {
//     if (pev(pSnowman, pev_deadflag) != DEAD_NO) continue;

//     static SW_Snowman_Relationship:iRelationship; iRelationship = CE_CallMethod(pBestSnowman, GetRelationship, pPlayer);
//     if (iRelationship == SW_Snowman_Relationship_None) continue;

//     if (pBestSnowman == FM_NULLENT || iRelationship > CE_CallMethod(pBestSnowman, GetRelationship, pPlayer)) {
//       pBestSnowman = pSnowman;
//     }
//   }

//   return pBestSnowman;
// }
