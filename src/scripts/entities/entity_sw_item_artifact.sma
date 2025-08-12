#pragma semicolon 1

#include <amxmodx>

#include <api_assets>
#include <api_custom_entities>

#include <snowwars>

#define PLUGIN "[Entity] Item Artifact"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME SW_ENTITY_ARTIFACT_ITEM

new const m_szArtifactId[] = "szArtifactId";

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(SW_ASSET_LIBRARY, SW_ASSET_ARTIFACT_MODEL, g_szModel, charsmax(g_szModel));

  CE_RegisterClass(ENTITY_NAME, CE_Class_BaseItem);

  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Allocate, "@Entity_Allocate");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_CanPickup, "@Entity_CanPickup");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Pickup, "@Entity_Pickup");

  CE_RegisterClassKeyMemberBinding(ENTITY_NAME, "target", m_szArtifactId, CEMemberType_String);
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);
}

@Entity_Allocate(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-4.0, -4.0, -4.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{4.0, 4.0, 4.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
}

bool:@Entity_CanPickup(const this, const pPlayer) {
  static szId[16]; CE_GetMemberString(this, m_szArtifactId, szId, charsmax(szId));
  if (equal(szId, NULL_STRING)) return true;

  return !SW_Player_HasArtifact(pPlayer, szId);
}

@Entity_Pickup(const this, const pPlayer) {
  static szId[16]; CE_GetMemberString(this, m_szArtifactId, szId, charsmax(szId));
  if (equal(szId, NULL_STRING)) return;

  SW_Player_GiveArtifact(pPlayer, szId);
}
