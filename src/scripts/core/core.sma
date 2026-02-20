#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <api_assets>
#include <api_player_model>

#include <snowwars_internal>

new g_fwConfigLoaded;

public plugin_precache() {
  Asset_Library_Load(SW_AssetLibrary);
  PlayerModel_PrecacheAnimation("snowwars/v110/player.mdl");

  hook_cvar_change(create_cvar(CVAR("version"), SW_VERSION, FCVAR_SERVER), "CvarHook_Version");
}

public plugin_init() {
  register_plugin(SW_TITLE, SW_VERSION, "Hedgehog Fog");

  g_fwConfigLoaded = CreateMultiForward("SW_OnConfigLoaded", ET_IGNORE);

  register_forward(FM_GetGameDescription, "FMHook_GetGameDescription");
}

public plugin_cfg() {
  LoadConfig();
}

public plugin_natives() {
  register_library("snowwars");
}

/*--------------------------------[ Hooks ]--------------------------------*/

public CvarHook_Version(const pCvar) {
  set_pcvar_string(pCvar, SW_VERSION);
}

public FMHook_GetGameDescription() {
  static szGameName[32];
  format(szGameName, charsmax(szGameName), "%s %s", SW_TITLE, SW_VERSION);
  forward_return(FMV_STRING, szGameName);

  return FMRES_SUPERCEDE;
}

/*--------------------------------[ Functions ]--------------------------------*/

LoadConfig() {
  new szConfigDir[32]; get_configsdir(szConfigDir, charsmax(szConfigDir));
  new szMapName[64]; get_mapname(szMapName, charsmax(szMapName));

  server_cmd("exec %s/snowwars.cfg", szConfigDir);
  server_cmd("exec %s/snowwars/%s.cfg", szConfigDir, szMapName);
  server_exec();

  ExecuteForward(g_fwConfigLoaded);
}
