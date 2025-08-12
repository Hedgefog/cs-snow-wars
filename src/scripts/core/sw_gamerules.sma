#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>
#include <api_custom_weapons>

#include <snowwars>

#define PLUGIN "[Snow Wars] Gamemode"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_precache() {
  CE_RegisterNullClass("armoury_entity");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed", .Post = 0);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
  RegisterHam(Ham_Touch, "weaponbox", "HamHook_WeaponBox_Touch", .Post = 0);

  RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip", .post = 0);
  RegisterHookChain(RG_CSGameRules_RestartRound, "HC_GameRules_RestartRound", .post = 0);
}

public client_disconnected(pPlayer) {
  if (!is_user_connected(pPlayer)) return;

  @Player_DropItems(pPlayer);
  @Player_DropArtifacts(pPlayer);
}

public HamHook_Player_Killed(pPlayer) {
  set_ent_data(pPlayer, "CBasePlayer", "m_bHasDefuser", false);
  @Player_DropItems(pPlayer);
}

public HamHook_Player_Killed_Post(pPlayer) {
  @Player_DropArtifacts(pPlayer);
}

public HamHook_WeaponBox_Touch(const pWeaponBox, const pTarget) {
  if (!is_user_connected(pTarget)) return HAM_IGNORED;

  // Dont allow to stack weapons
  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", iSlot);
    static pPlayerItem; pPlayerItem = get_ent_data_entity(pTarget, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    
    if (pItem != -1 && pPlayerItem != -1) return HAM_SUPERCEDE;
  }

  return HAM_HANDLED;
}

public HC_Player_SpawnEquip(const pPlayer) {
  CW_Give(pPlayer, SW_WEAPON_SNOWBALL);

  if (get_ent_data(pPlayer, "CBasePlayer", "m_iTeam") == 2) {
    set_ent_data(pPlayer, "CBasePlayer", "m_bHasDefuser", true);
  }

  return HC_SUPERCEDE;
}

public HC_GameRules_RestartRound() {
  new bool:bCompleteReset = get_member_game(m_bCompleteReset);

  if (bCompleteReset) {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
      if (!is_user_connected(pPlayer)) continue;

      static szId[16];
      static iSlot; iSlot = -1;
      while ((iSlot = SW_Player_FindArtifact(pPlayer, iSlot, szId, charsmax(szId))) != -1) {
        SW_Player_TakeArtifactBySlot(pPlayer, iSlot);
      }
    }
  }
}

@Player_DropArtifacts(const &this) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  static szId[16];
  static iSlot; iSlot = -1;
  while ((iSlot = SW_Player_FindArtifact(this, iSlot, szId, charsmax(szId))) != -1) {
    SW_Player_TakeArtifactBySlot(this, iSlot);

    static pArtifactItem; pArtifactItem = CE_Create(SW_ENTITY_ARTIFACT_ITEM, vecOrigin);
    CE_SetMemberString(pArtifactItem, "szArtifactId", szId);
    dllfunc(DLLFunc_Spawn, pArtifactItem);

    static Float:vecVelocity[3];
    vecVelocity[0] = random_float(48.0, 64.0) * (random(2) ? -1.0 : 1.0);
    vecVelocity[1] = random_float(48.0, 64.0) * (random(2) ? -1.0 : 1.0);
    vecVelocity[2] = random_float(192.0, 256.0);

    set_pev(pArtifactItem, pev_velocity, vecVelocity);

    static Float:vecAngles[3];
    vecAngles[0] = 0.0;
    vecAngles[1] = random_float(-180.0, 180.0);
    vecAngles[2] = 0.0;

    set_pev(pArtifactItem, pev_angles, vecAngles);
  }
}

@Player_DropItems(const &this) {
  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(this, "CBasePlayer", "m_rgpPlayerItems", iSlot);

    while (pItem != -1) {
      static pNextItem; pNextItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");

      if (ExecuteHamB(Ham_CS_Item_CanDrop, pItem)) {
        static szClassname[32]; pev(pItem, pev_classname, szClassname, charsmax(szClassname));
        rg_drop_item(this, szClassname);
      }

      pItem = pNextItem;
    }
  }
}
