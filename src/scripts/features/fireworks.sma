#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>
#include <reapi>

#include <api_custom_entities>

#include <snowwars_internal>

new Float:g_vecAbsMins[3] = {8192.0, 8192.0, 8192.0};
new Float:g_vecAbsMax[3] = {-8192.0, -8192.0, -8192.0};
new g_iCurrentYear = 0;

new g_pTrace;

new Float:g_flNextLaunch = 0.0;
new g_iRocketsNum = 0;
new g_iLaunchRate = 0;

public plugin_precache() {
  g_pTrace = create_tr2();
  date(g_iCurrentYear);

  register_forward(FM_Spawn, "FMHook_Spawn_Post", ._post = 1);  
}

public plugin_init() {
  register_plugin(FEATURE_PLUGIN(Fireworks), SW_VERSION, "Hedgehog Fog");

  bind_pcvar_num(create_cvar("sw_fireworks_launch_rate", "60"), g_iLaunchRate);
  bind_pcvar_num(create_cvar("sw_fireworks_rockets_num", "6"), g_iRocketsNum);

  RegisterHookChain(RG_RoundEnd, "HC_RoundEnd", .post = 0);

  register_concmd("sw_fireworks_launch", "Command_LaunchFireworks", ADMIN_CVAR);

  set_task(1.0, "Task_Update", .flags = "b");
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public Command_LaunchFireworks(const pPlayer, iLevel, iCId) {
  if (!cmd_access(pPlayer, iLevel, iCId, 1)) return PLUGIN_HANDLED;

  new iRocketsNum = read_argc() > 1 ? read_argv_int(1) : 0;
  LaunchFireworks(iRocketsNum);

  return PLUGIN_HANDLED;
}

public FMHook_Spawn_Post(const pEntity) {
  if (!pev_valid(pEntity)) return FMRES_IGNORED;

  static Float:vecAbsMin[3]; pev(pEntity, pev_absmin, vecAbsMin);
  static Float:vecAbsMax[3]; pev(pEntity, pev_absmax, vecAbsMax);

  for (new i = 0; i < 3; ++i) {
    g_vecAbsMins[i] = floatmin(g_vecAbsMins[i], vecAbsMin[i]);
    g_vecAbsMax[i] = floatmax(g_vecAbsMax[i], vecAbsMax[i]);
  }

  return FMRES_HANDLED;
}

LaunchFireworks(iRocketsNum = 0) {
  if (!iRocketsNum) iRocketsNum = g_iRocketsNum;

  static Float:vecOrigin[3]; xs_vec_set(vecOrigin, random_float(g_vecAbsMins[0], g_vecAbsMax[0]), random_float(g_vecAbsMins[1], g_vecAbsMax[1]), 8192.0);

  static Float:vecDown[3]; xs_vec_set(vecDown, vecOrigin[0], vecOrigin[1], g_vecAbsMax[2]);

  engfunc(EngFunc_TraceLine, vecOrigin, vecDown, DONT_IGNORE_MONSTERS, 0, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecOrigin);

  for (new i = 0; i < iRocketsNum; ++i) {
    new pRocket = CE_Create(ENTITY(FireworkRocket), vecOrigin);
    if (pRocket == FM_NULLENT) continue;

    static Float:vecAngles[3]; xs_vec_set(vecAngles, random_float(-75.0, -105.0), random_float(-180.0, 180.0), 0.0);
    set_pev(pRocket, pev_angles, vecAngles);

    dllfunc(DLLFunc_Spawn, pRocket);
    set_pev(pRocket, pev_solid, SOLID_NOT);
    set_pev(pRocket, pev_movetype, MOVETYPE_NOCLIP);
  }
}

public HC_RoundEnd() {
  LaunchFireworks();
}

public Task_Update() {
  new Float:flGameTime = get_gametime();

  if (!g_flNextLaunch) {
    g_flNextLaunch = flGameTime + g_iLaunchRate;
    return;
  }

  if (g_iLaunchRate && g_flNextLaunch < flGameTime) {
    LaunchFireworks();
    g_flNextLaunch = flGameTime + g_iLaunchRate;
  } else {
    new iYear; date(iYear);

    if (g_iCurrentYear < iYear) {
      LaunchFireworks();
    }

    g_iCurrentYear = iYear;
  }
}
