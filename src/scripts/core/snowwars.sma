#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <snowwars>

#define PLUGIN "Snow Wars"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new g_pCvarVersion;

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_forward(FM_GetGameDescription, "OnGetGameDescription");

    g_pCvarVersion = register_cvar("snowwars_version", VERSION, FCVAR_SERVER);
    hook_cvar_change(g_pCvarVersion, "OnVersionCvarChange");
}

public plugin_natives() {
    register_library("snowwars");
}

public OnVersionCvarChange() {
    set_pcvar_string(g_pCvarVersion, SW_VERSION);
}

public OnGetGameDescription() {
    static szGameName[32];
    format(szGameName, charsmax(szGameName), "%s %s", SW_TITLE, SW_VERSION);
    forward_return(FMV_STRING, szGameName);

    return FMRES_SUPERCEDE;
}
