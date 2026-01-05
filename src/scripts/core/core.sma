#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <api_assets>
#include <api_player_model>

#include <snowwars_const>

#define PLUGIN "Snow Wars"
#define AUTHOR "Hedgehog Fog"

new g_fwConfigLoaded;

new g_pCvarVersion;

public plugin_precache() {
  Asset_Library_Load(SW_AssetLibrary);
  PlayerModel_PrecacheAnimation("snowwars/v110/player.mdl");

  g_pCvarVersion = register_cvar("snowwars_version", SW_VERSION, FCVAR_SERVER);

  hook_cvar_change(g_pCvarVersion, "CvarHook_Version");
}

public plugin_init() {
  register_plugin(PLUGIN, SW_VERSION, AUTHOR);

  g_fwConfigLoaded = CreateMultiForward("SW_Fw_ConfigLoaded", ET_IGNORE);

  register_forward(FM_GetGameDescription, "FMForward_GetGameDescription");
}

public plugin_cfg() {
  LoadConfig();
}

public plugin_natives() {
  register_library("snowwars");
}

/*--------------------------------[ Hooks ]--------------------------------*/

public CvarHook_Version() {
  set_pcvar_string(g_pCvarVersion, SW_VERSION);
}

public FMForward_GetGameDescription() {
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
