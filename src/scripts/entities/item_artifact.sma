#pragma semicolon 1

#include <amxmodx>

#include <api_assets>
#include <api_custom_entities>

#include <snowwars_player_artifacts>
#include <snowwars_internal>

#define ENTITY_NAME ENTITY(ArtifactItem)
#define MEMBER(%1) ENTITY_MEMBER<ArtifactItem>(%1)

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(SW_AssetLibrary, SW_Asset_Entity_Artifact_Model, g_szModel, charsmax(g_szModel));

  CE_RegisterClass(ENTITY_NAME, CE_Class_BaseItem);

  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_CanPickup, "@Entity_CanPickup");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Pickup, "@Entity_Pickup");

  CE_RegisterClassKeyMemberBinding(ENTITY_NAME, "target", MEMBER(szArtifactId), CEMemberType_String);
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(ArtifactItem), SW_VERSION, "Hedgehog Fog");
}

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-4.0, -4.0, -4.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{4.0, 4.0, 4.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
}

bool:@Entity_CanPickup(const this, const pPlayer) {
  static szId[16]; CE_GetMemberString(this, MEMBER(szArtifactId), szId, charsmax(szId));
  if (equal(szId, NULL_STRING)) return true;

  return !SW_PlayerArtifact_Has(pPlayer, szId);
}

@Entity_Pickup(const this, const pPlayer) {
  static szId[16]; CE_GetMemberString(this, MEMBER(szArtifactId), szId, charsmax(szId));
  if (equal(szId, NULL_STRING)) return;

  SW_PlayerArtifact_Give(pPlayer, szId);
}
