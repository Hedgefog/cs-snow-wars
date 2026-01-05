#include <amxmodx>
#include <hamsandwich>

#include <function_pointer>

#include <snowwars_const>
#include <snowwars_player_artifacts>

#define MAX_ARTIFACTS 32

new Trie:g_itArtifactIds = Invalid_Trie;
new g_rgszArtifactIds[MAX_ARTIFACTS][32];
new Function:g_rgfnArtifactActivate[MAX_ARTIFACTS];
new Function:g_rgfnArtifactDeactivate[MAX_ARTIFACTS];
new g_iArtifactsNum = 0;

new g_rgiPlayerArtifacts[MAX_PLAYERS + 1][MAX_ARTIFACTS];

public plugin_precache() {
  g_itArtifactIds = TrieCreate();
}

public plugin_init() {
  register_plugin("[Snow Wars] Player Artifacts", SW_VERSION, "Hedgehog Fog");
}

public plugin_destroy() {
  TrieDestroy(g_itArtifactIds);
}

public plugin_natives() {
  register_library("snowwars_artifacts");
  register_native("SW_PlayerArtifact_Register", "Native_RegisterArtifact");
  register_native("SW_PlayerArtifact_GetHandle", "Native_GetHandle");
  register_native("SW_PlayerArtifact_Give", "Native_GiveArtifact");
  register_native("SW_PlayerArtifact_Take", "Native_TakeArtifact");
  register_native("SW_PlayerArtifact_TakeAll", "Native_TakeAllArtifacts");
  register_native("SW_PlayerArtifact_TakeBySlot", "Native_TakeArtifactBySlot");
  register_native("SW_PlayerArtifact_Has", "Native_HasArtifact");
  register_native("SW_PlayerArtifact_Find", "Native_FindArtifact");
}

public client_connect(pPlayer) {
  for (new iSlot = 0; iSlot < MAX_ARTIFACTS; ++iSlot) {
    g_rgiPlayerArtifacts[pPlayer][iSlot] = -1;
  }
}

public client_disconnected(pPlayer) {
  for (new iSlot = 0; iSlot < MAX_ARTIFACTS; ++iSlot) {
    @Player_TakeArtifactBySlot(pPlayer, iSlot);
  }
}

public Native_RegisterArtifact(const iPluginId, const iArgc) {
  new szId[16]; get_string(1, szId, charsmax(szId));
  new szActivateFunc[64]; get_string(2, szActivateFunc, charsmax(szActivateFunc));
  new szDeactivateFunc[64]; get_string(3, szDeactivateFunc, charsmax(szDeactivateFunc));

  new Function:fnActivate = get_func_pointer(szActivateFunc, iPluginId);
  new Function:fnDeactivate = get_func_pointer(szDeactivateFunc, iPluginId);

  return Artifact_Register(szId, fnActivate, fnDeactivate);
}

public Native_GetHandle(const iPluginid, const iArgc) {
  static szId[16]; get_string(1, szId, charsmax(szId));

  return Artifact_GetId(szId);
}

public bool:Native_GiveArtifact(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  static szId[16]; get_string(2, szId, charsmax(szId));

  return @Player_GiveArtifact(pPlayer, szId);
}

public bool:Native_TakeArtifact(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  static szId[16]; get_string(2, szId, charsmax(szId));

  return @Player_TakeArtifact(pPlayer, szId);
}

public bool:Native_TakeArtifactBySlot(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);
  new iSlot = get_param(2);

  return @Player_TakeArtifactBySlot(pPlayer, iSlot);
}

public bool:Native_TakeAllArtifacts(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  for (new iSlot = 0; iSlot < MAX_ARTIFACTS; ++iSlot) {
    @Player_TakeArtifactBySlot(pPlayer, iSlot);
  }
}

public bool:Native_HasArtifact(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  static szId[16]; get_string(2, szId, charsmax(szId));

  return @Player_HasArtifact(pPlayer, szId);
}

public Native_FindArtifact(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);
  new iOffset = get_param(2);
  new iLen = get_param(4);

  static szId[16];
  new iSlot = @Player_FindArtifact(pPlayer, iOffset, szId, charsmax(szId));
  set_string(3, szId, iLen);
  
  return iSlot;
}

public bool:@Player_GiveArtifact(const &this, const szId[]) {
  if (@Player_HasArtifact(this, szId)) {
    // client_print(this, print_chat, "You already have this artifact!");
    return false;
  }

  new iSlot = @Player_GetFreeArtifactSlot(this);
  if (iSlot == -1) {
    // client_print(this, print_chat, "You have no free artifacts slots!");
    return false;
  }

  new iId = Artifact_GetId(szId);

  g_rgiPlayerArtifacts[this][iSlot] = iId;

  callfunc_begin_p(g_rgfnArtifactActivate[iId]);
  callfunc_push_int(this);
  callfunc_end();

  return true;
}

public bool:@Player_TakeArtifact(const &this, const szId[]) {
  new bool:bResult = false;

  new iId = Artifact_GetId(szId);
  for (new iSlot = 0; iSlot < MAX_ARTIFACTS; ++iSlot) {
    if (g_rgiPlayerArtifacts[this][iSlot] == iId) {
      @Player_TakeArtifactBySlot(this, iSlot);
      bResult = true;
    }
  }

  return bResult;
}

public bool:@Player_TakeArtifactBySlot(const &this, const iSlot) {
  new iId = g_rgiPlayerArtifacts[this][iSlot];

  if (iId == -1) return false;

  g_rgiPlayerArtifacts[this][iSlot] = -1;

  callfunc_begin_p(g_rgfnArtifactDeactivate[iId]);
  callfunc_push_int(this);
  callfunc_end();

  return true;
}

public bool:@Player_HasArtifact(const &this, const szId[]) {
  new iId = Artifact_GetId(szId);

  return @Player_FindArtifactById(this, iId, 0) != -1;
}

@Player_GetFreeArtifactSlot(const &this) {
  return @Player_FindArtifactById(this, -1, 0);
}

@Player_FindArtifact(const &this, const iOffset, szId[], iLen) {
  for (new iSlot = iOffset + 1; iSlot < MAX_ARTIFACTS; ++iSlot) {
    new iId = g_rgiPlayerArtifacts[this][iSlot];

    if (iId != -1) {
      copy(szId, iLen, g_rgszArtifactIds[iId]);
      return iSlot;
    }
  }

  return -1;
}

@Player_FindArtifactById(const &this, const iId, const iOffset) {
  for (new iSlot = iOffset; iSlot < MAX_ARTIFACTS; ++iSlot) {
    if (g_rgiPlayerArtifacts[this][iSlot] == iId) return iSlot;
  }

  return -1;
}

Artifact_Register(const szId[], const &Function:fnActivate, const &Function:fnDeactivate) {
  new iId = g_iArtifactsNum;

  copy(g_rgszArtifactIds[iId], charsmax(g_rgszArtifactIds[]), szId);
  g_rgfnArtifactActivate[iId] = fnActivate;
  g_rgfnArtifactDeactivate[iId] = fnDeactivate;

  TrieSetCell(g_itArtifactIds, szId, iId);

  g_iArtifactsNum++;

  return iId;
}

Artifact_GetId(const szId[]) {
  new iId;
  if (!TrieGetCell(g_itArtifactIds, szId, iId)) return -1;

  return iId;
}
