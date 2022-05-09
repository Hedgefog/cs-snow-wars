#include <amxmodx>
#include <hamsandwich>

#include <snowwars>

#define PLUGIN "[Snow Wars] Player Artifacts"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define MAX_ARTIFACTS 32

new Array:g_irgszArtifactIds;
new Array:g_irgiArtifactPluginId;
new Array:g_irgiArtifactActivateFuncId;
new Array:g_irgiArtifactDeactivateFuncId;
new Trie:g_iArtifactIdsMap;
new g_iArtifactCount = 0;

new g_rgiPlayerArtifacts[MAX_PLAYERS + 1][MAX_ARTIFACTS];

public plugin_precache() {
    g_irgszArtifactIds = ArrayCreate(16);
    g_irgiArtifactPluginId = ArrayCreate();
    g_irgiArtifactActivateFuncId = ArrayCreate();
    g_irgiArtifactDeactivateFuncId = ArrayCreate();
    g_iArtifactIdsMap = TrieCreate();
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_destroy() {
    ArrayDestroy(g_irgszArtifactIds);
    ArrayDestroy(g_irgiArtifactPluginId);
    ArrayDestroy(g_irgiArtifactActivateFuncId);
    ArrayDestroy(g_irgiArtifactDeactivateFuncId);
    TrieDestroy(g_iArtifactIdsMap);
}

public plugin_natives() {
    register_native("SW_PlayerArtifact_Register", "Native_RegisterArtifact");
    register_native("SW_PlayerArtifact_GetHandler", "Native_GetHandler");
    register_native("SW_Player_GiveArtifact", "Native_GiveArtifact");
    register_native("SW_Player_TakeArtifact", "Native_TakeArtifact");
    register_native("SW_Player_TakeArtifactBySlot", "Native_TakeArtifactBySlot");
    register_native("SW_Player_HasArtifact", "Native_HasArtifact");
    register_native("SW_Player_FindArtifact", "Native_FindArtifact");
}

public client_connect(pPlayer) {
    for (new iSlot = 0; iSlot < MAX_ARTIFACTS; ++iSlot) {
        g_rgiPlayerArtifacts[pPlayer][iSlot] = -1;
    }
}

public Native_RegisterArtifact(iPluginId, iArgc) {
    static szId[16];
    get_string(1, szId, charsmax(szId));

    static szActivateFunc[32];
    get_string(2, szActivateFunc, charsmax(szActivateFunc));

    static szDeactivateFunc[32];
    get_string(3, szDeactivateFunc, charsmax(szDeactivateFunc));

    new iActivateFuncId = get_func_id(szActivateFunc, iPluginId);
    new iDeactivateFuncId = get_func_id(szDeactivateFunc, iPluginId);

    return RegisterArtifact(szId, iPluginId, iActivateFuncId, iDeactivateFuncId);
}

public Native_GetHandler(iPluginid, iArgc) {
    static szId[16];
    get_string(1, szId, charsmax(szId));

    return GetHandler(szId);
}

public bool:Native_GiveArtifact(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    static szId[16];
    get_string(2, szId, charsmax(szId));

    return @Player_GiveArtifact(pPlayer, szId);
}

public bool:Native_TakeArtifact(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    static szId[16];
    get_string(2, szId, charsmax(szId));

    return @Player_TakeArtifact(pPlayer, szId);
}

public bool:Native_TakeArtifactBySlot(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    new iSlot = get_param(2);

    return @Player_TakeArtifactBySlot(pPlayer, iSlot);
}

public bool:Native_HasArtifact(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    static szId[16];
    get_string(2, szId, charsmax(szId));

    return @Player_HasArtifact(pPlayer, szId);
}

public Native_FindArtifact(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    new iOffset = get_param(2);
    new iLen = get_param(4);

    static szId[16];
    new iSlot = @Player_FindArtifact(pPlayer, iOffset, szId, charsmax(szId));
    set_string(3, szId, iLen);
    
    return iSlot;
}

public bool:@Player_GiveArtifact(this, const szId[]) {
    if (@Player_HasArtifact(this, szId)) {
        // client_print(this, print_chat, "You already have this artifact!");
        return false;
    }

    new iSlot = @Player_GetFreeArtifactSlot(this);
    if (iSlot == -1) {
        // client_print(this, print_chat, "You have no free artifacts slots!");
        return false;
    }

    new iId = GetHandler(szId);
    new iArtifactPluginId = ArrayGetCell(g_irgiArtifactPluginId, iId);
    new iActivateFuncId = ArrayGetCell(g_irgiArtifactActivateFuncId, iId);

    g_rgiPlayerArtifacts[this][iSlot] = GetHandler(szId);

    callfunc_begin_i(iActivateFuncId, iArtifactPluginId);
    callfunc_push_int(this);
    callfunc_end();

    return true;
}

public bool:@Player_TakeArtifact(this, const szId[]) {
    new bool:bResult = false;

    new iId = GetHandler(szId);
    for (new iSlot = 0; iSlot < MAX_ARTIFACTS; ++iSlot) {
        if (g_rgiPlayerArtifacts[this][iSlot] == iId) {
            @Player_TakeArtifactBySlot(this, iSlot);
            bResult = true;
        }
    }

    return bResult;
}

public bool:@Player_TakeArtifactBySlot(this, iSlot) {
    new iId = g_rgiPlayerArtifacts[this][iSlot];

    if (iId == -1) {
        return false;
    }

    new iArtifactPluginId = ArrayGetCell(g_irgiArtifactPluginId, iId);
    new iDeactivateFuncId = ArrayGetCell(g_irgiArtifactDeactivateFuncId, iId);

    g_rgiPlayerArtifacts[this][iSlot] = -1;

    callfunc_begin_i(iDeactivateFuncId, iArtifactPluginId);
    callfunc_push_int(this);
    callfunc_end();

    return true;
}

public bool:@Player_HasArtifact(this, const szId[]) {
    new iId = GetHandler(szId);

    return @Player_FindArtifactById(this, iId, 0) != -1;
}

public @Player_GetFreeArtifactSlot(this) {
    return @Player_FindArtifactById(this, -1, 0);
}

public @Player_FindArtifact(this, iOffset, szId[], iLen) {
    for (new iSlot = iOffset + 1; iSlot < MAX_ARTIFACTS; ++iSlot) {
        new iId = g_rgiPlayerArtifacts[this][iSlot];

        if (iId != -1) {
            ArrayGetString(g_irgszArtifactIds, iId, szId, iLen);
            return iSlot;
        }
    }

    return -1;
}

public @Player_FindArtifactById(this, iId, iOffset) {
    for (new iSlot = iOffset; iSlot < MAX_ARTIFACTS; ++iSlot) {
        if (g_rgiPlayerArtifacts[this][iSlot] == iId) {
            return iSlot;
        }
    }

    return -1;
}

RegisterArtifact(const szId[], const iPluginId, const iActivateFuncId, const iDeactivateFuncId) {
    new iId = g_iArtifactCount;

    ArrayPushString(g_irgszArtifactIds, szId);
    ArrayPushCell(g_irgiArtifactPluginId, iPluginId); 
    ArrayPushCell(g_irgiArtifactActivateFuncId, iActivateFuncId); 
    ArrayPushCell(g_irgiArtifactDeactivateFuncId, iDeactivateFuncId); 

    TrieSetCell(g_iArtifactIdsMap, szId, iId);

    g_iArtifactCount++;

    return iId;
}

GetHandler(const szId[]) {
    new iId;
    if (TrieGetCell(g_iArtifactIdsMap, szId, iId)) {
        return iId;
    }

    return -1;
}
