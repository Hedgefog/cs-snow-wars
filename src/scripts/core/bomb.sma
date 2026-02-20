#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>

#include <snowwars_internal>

new Float:g_vecBombOrigin[3];

public plugin_init() {
  register_plugin(PLUGIN_NAME("Bomb"), SW_VERSION, "Hedgehog Fog");

  RegisterHookChain(RG_CGrenade_ExplodeBomb, "HC_Grenade_ExplodeBomb", .post = 0);
}

public HC_Grenade_ExplodeBomb(const pGrenade) {
  set_member(pGrenade, m_Grenade_bJustBlew, true);
  set_member_game(m_bTargetBombed, true);
  rg_check_win_conditions();

  pev(pGrenade, pev_origin, g_vecBombOrigin);

  ExecuteHamB(Ham_Killed, SpawnRocket(g_vecBombOrigin), 0, 0);

  for (new i = 0; i < 8; ++i) {
    set_task(0.125 * i, "Task_SpawnRocket");
  }

  set_pev(pGrenade, pev_flags, pev(pGrenade, pev_flags) | FL_KILLME);
  // dllfunc(DLLFunc_Think, pGrenade);

  return HC_SUPERCEDE;
}

SpawnRocket(const Float:vecOrigin[3]) {
  new pRocket = CE_Create(ENTITY(FireworkRocket), vecOrigin);
  if (pRocket == FM_NULLENT) return FM_NULLENT;

  static Float:vecAngles[3];
  vecAngles[0] = random_float(0.0, 90.0);
  vecAngles[1] = random_float(-180.0, 180.0);
  vecAngles[2] = 0.0;
  set_pev(pRocket, pev_angles, vecAngles);

  dllfunc(DLLFunc_Spawn, pRocket);

  return pRocket;
}

public Task_SpawnRocket() {
  SpawnRocket(g_vecBombOrigin);
}
