#include <amxmodx>
#include <hamsandwich>

#include <snowwars>

#define PLUGIN "[Snow Wars] Player Attributes"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new g_rgiPlayerAttributes[MAX_PLAYERS + 1][SW_PlayerAttribute];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_TakeDamage, "player", "Ham_Player_TakeDamage", .Post = 0);
}

public plugin_natives() {
    register_native("SW_Player_GetAttribute", "Native_GetAttribute")
    register_native("SW_Player_SetAttribute", "Native_SetAttribute")
}

public client_connect(pPlayer) {
    @Player_ResetAttributes(pPlayer);
}

public Native_GetAttribute(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    new SW_PlayerAttribute:iAttrib = SW_PlayerAttribute:get_param(2);

    return @Player_GetAttribute(pPlayer, iAttrib);
}

public Native_SetAttribute(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    new SW_PlayerAttribute:iAttrib = SW_PlayerAttribute:get_param(2);
    new any:value = any:get_param(3);

    @Player_SetAttribute(pPlayer, iAttrib, value);
}

public Ham_Player_TakeDamage(pPlayer, pInflictor, pAttacker, Float:flDamage, iDamageBits) {
    new Float:flRatio = CalculateDamageRatio(pAttacker, pPlayer);
    SetHamParamFloat(4, flDamage * flRatio);
    return HAM_HANDLED;
}

public @Player_GetAttribute(this, SW_PlayerAttribute:iAttrib) {
    return g_rgiPlayerAttributes[this][iAttrib];
}

public @Player_SetAttribute(this, SW_PlayerAttribute:iAttrib, any:value) {
    g_rgiPlayerAttributes[this][iAttrib] = value;
}

public @Player_ResetAttributes(this) {
    for (new iAttrib = 0; iAttrib < _:SW_PlayerAttribute; ++iAttrib) {
        g_rgiPlayerAttributes[this][SW_PlayerAttribute:iAttrib] = 0;
    }
}

Float:CalculateDamageRatio(pAttacker, pVictim) {
    new Float:flPower = ExecuteHamB(Ham_IsPlayer, pAttacker) ? SW_Player_GetAttribute(pAttacker, SW_PlayerAttribute_Power) : 0.0;
    new Float:flResistence = SW_Player_GetAttribute(pVictim, SW_PlayerAttribute_Resistance);

    return  (1.0 + flPower) * (1.0 - floatmin(flResistence, 1.0));
}

