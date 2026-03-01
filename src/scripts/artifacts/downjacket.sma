#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_assets>
#include <api_custom_entities>
#include <api_player_cosmetics>

#include <snowwars>
#include <snowwars_player_artifacts>
#include <snowwars_internal>

/*--------------------------------[ Helpers ]--------------------------------*/

#define ARTIFACT_ID ARTIFACT(Downjacket)

/*--------------------------------[ Player State State ]--------------------------------*/

new g_pPlayerJacket[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Artifact_DownJacket_Model_Player));
  Asset_Precache(ASSET_LIBRARY, ASSET(Artifact_DownJacket_Model_World));
  Asset_Precache(ASSET_LIBRARY, ASSET(Artifact_DownJacket_Sound_Equip));

  SW_PlayerArtifact_Register(ARTIFACT_ID, "Callback_Artifact_Activated", "Callback_Artifact_Deactivated");
}

public plugin_init() {
  register_plugin(ARTIFACT_PLUGIN(Downjacket), SW_VERSION, "Hedgehog Fog");

  register_event("ResetHUD", "Event_ResetHUD", "b");
  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn", .Post = 1);

  CE_RegisterClassNativeMethodHook(ENTITY(ArtifactItem), CE_Method_Spawn, "CEHook_ArtifactItem_Spawn");
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_pPlayerJacket[pPlayer] = FM_NULLENT;
}

/*--------------------------------[ Artifact Callbacks ]--------------------------------*/

public Callback_Artifact_Activated(const pPlayer) {
  @Player_EquipJacket(pPlayer);
}

public Callback_Artifact_Deactivated(const pPlayer) {
  @Player_UnequipJacket(pPlayer);
}

/*--------------------------------[ Hooks ]--------------------------------*/

public Event_ResetHUD(const pPlayer) {
  @Player_UpdateStatusIcon(pPlayer);
}

public HamHook_Player_Spawn(const pPlayer) {
  @Player_UpdateJacket(pPlayer);

  return HAM_HANDLED;
}

public CEHook_ArtifactItem_Spawn(const pEntity) {
  static szId[16]; CE_GetMemberString(pEntity, SW_Entity_ArtifactItem_Member_szArtifactId, szId, charsmax(szId));
  if (!equal(szId, ARTIFACT_ID)) return;

  Asset_SetModel(pEntity, ASSET_LIBRARY, ASSET(Artifact_DownJacket_Model_World));
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_EquipJacket(const &this) {
  new Float:flResistance = SW_Player_GetAttribute(this, SW_PlayerAttribute_Resistance);
  SW_Player_SetAttribute(this, SW_PlayerAttribute_Resistance, flResistance + 0.5);

  g_pPlayerJacket[this] = PlayerCosmetic_Equip(this, Asset_GetModelIndex(ASSET_LIBRARY, ASSET(Artifact_DownJacket_Model_Player)));
  @Player_UpdateJacket(this);

  Asset_EmitSound(this, CHAN_ITEM, ASSET_LIBRARY, ASSET(Artifact_DownJacket_Sound_Equip));

  @Player_UpdateStatusIcon(this);
}

@Player_UnequipJacket(const &this) {
  new Float:flResistance = SW_Player_GetAttribute(this, SW_PlayerAttribute_Resistance);
  SW_Player_SetAttribute(this, SW_PlayerAttribute_Resistance, flResistance - 0.5);

  if (g_pPlayerJacket[this] != FM_NULLENT) {
    PlayerCosmetic_Unequip(this, Asset_GetModelIndex(ASSET_LIBRARY, ASSET(Artifact_DownJacket_Model_Player)));
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

  if (SW_PlayerArtifact_Has(this, ARTIFACT_ID)) {
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
