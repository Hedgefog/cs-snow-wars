#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>

#include <snowwars>
#include <api_custom_entities>

#define PLUGIN "[Entity] Snowball"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "sw_item_artifact"

public plugin_precache() {
    CE_Register(
        .szName = ENTITY_NAME,
        .vMins = Float:{-4.0, -4.0, -4.0},
        .vMaxs = Float:{4.0, 4.0, 4.0},
        .modelIndex = precache_model("models/w_isotopebox.mdl"),
        .preset = CEPreset_Item
    );

    CE_RegisterHook(CEFunction_Pickup, ENTITY_NAME, "@Entity_Pickup");
    CE_RegisterHook(CEFunction_Picked, ENTITY_NAME, "@Entity_Picked");
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public @Entity_Pickup(this, pPlayer) {
    static szId[16];
    pev(this, pev_target, szId, charsmax(szId));
    return SW_Player_HasArtifact(pPlayer, szId) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public @Entity_Picked(this, pPlayer) {
    static szId[16];
    pev(this, pev_target, szId, charsmax(szId));
    SW_Player_GiveArtifact(pPlayer, szId);
}
