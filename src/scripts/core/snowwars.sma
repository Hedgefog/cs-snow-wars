#pragma semicolon 1

#include <amxmodx>
#include <snowwars>

#define PLUGIN "Snow Wars"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_natives() {
    register_library("snowwars");
}
