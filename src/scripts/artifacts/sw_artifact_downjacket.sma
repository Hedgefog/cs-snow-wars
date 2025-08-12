#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_assets>
#include <api_custom_entities>
#include <api_player_cosmetics>

#include <snowwars>

#define PLUGIN "[Snow Wars] Down Jacket Artifact"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ARTIFACT_ID SW_ARTIFACT_DOWNJACKET

new g_pPlayerJacket[MAX_PLAYERS + 1];

new g_szCosmeticModel[MAX_RESOURCE_PATH_LENGTH];
new g_szItemModel[MAX_RESOURCE_PATH_LENGTH];
new g_szEquipSound[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_DOWNJACKET_P_MODEL, g_szCosmeticModel, charsmax(g_szCosmeticModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_DOWNJACKET_W_MODEL, g_szItemModel, charsmax(g_szItemModel));
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_DOWNJACKET_SOUND, g_szEquipSound, charsmax(g_szEquipSound));

  SW_PlayerArtifact_Register(ARTIFACT_ID, "Callback_Artifact_Activated", "Callback_Artifact_Deactivated");
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  register_event("ResetHUD", "Event_ResetHUD", "b");
  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn", .Post = 1);

  CE_RegisterClassMethodHook(SW_ENTITY_ARTIFACT_ITEM, CE_Method_Spawn, "CEHook_ArtifactItem_Spawn");
}

public client_connect(pPlayer) {
  g_pPlayerJacket[pPlayer] = FM_NULLENT;
}

public HamHook_Player_Spawn(const pPlayer) {
  @Player_UpdateJacket(pPlayer);
}

public Event_ResetHUD(const pPlayer) {
  @Player_UpdateStatusIcon(pPlayer);
}

public CEHook_ArtifactItem_Spawn(const pEntity) {
  static szId[16]; CE_GetMemberString(pEntity, "szArtifactId", szId, charsmax(szId));
  if (!equal(szId, ARTIFACT_ID)) return;

  engfunc(EngFunc_SetModel, pEntity, g_szItemModel);
}

public Callback_Artifact_Activated(const pPlayer) {
  @Player_EquipJacket(pPlayer);
}

public Callback_Artifact_Deactivated(const pPlayer) {
  @Player_UnequipJacket(pPlayer);
}

@Player_EquipJacket(const &this) {
  new Float:flResistance = SW_Player_GetAttribute(this, SW_PlayerAttribute_Resistance);
  SW_Player_SetAttribute(this, SW_PlayerAttribute_Resistance, flResistance + 0.5);

  g_pPlayerJacket[this] = PlayerCosmetic_Equip(this, engfunc(EngFunc_ModelIndex, g_szCosmeticModel));
  @Player_UpdateJacket(this);

  emit_sound(this, CHAN_ITEM, g_szEquipSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  @Player_UpdateStatusIcon(this);
}

@Player_UnequipJacket(const &this) {
  new Float:flResistance = SW_Player_GetAttribute(this, SW_PlayerAttribute_Resistance);
  SW_Player_SetAttribute(this, SW_PlayerAttribute_Resistance, flResistance - 0.5);

  if (g_pPlayerJacket[this] != FM_NULLENT) {
    PlayerCosmetic_Unequip(this, engfunc(EngFunc_ModelIndex, g_szCosmeticModel));
    g_pPlayerJacket[this] = FM_NULLENT;
  }

  @Player_UpdateStatusIcon(this);
}

@Player_UpdateJacket(const &this) {
  if (g_pPlayerJacket[this] == FM_NULLENT) return;

  set_pev(g_pPlayerJacket[this], pev_skin, get_ent_data(this, "CBasePlayer", "m_iTeam"));
}

@Player_UpdateStatusIcon(const &this) {
  static gmsgStatusIcon = 0;
  if (!gmsgStatusIcon) {
    gmsgStatusIcon = get_user_msgid("StatusIcon");
  }

  if (SW_Player_HasArtifact(this, ARTIFACT_ID)) {
    message_begin(MSG_ONE, gmsgStatusIcon, {0,0,0}, this);
    write_byte(1);
    write_string("suit_full");
    write_byte(255);
    write_byte(255);
    write_byte(255);
    message_end();
  } else {
    message_begin(MSG_ONE, gmsgStatusIcon, {0,0,0}, this);
    write_byte(0);
    write_string("suit_full");
    message_end();
  }
}
