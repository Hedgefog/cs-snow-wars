#if defined _snowwars_const_included
  #endinput
#endif
#define _snowwars_const_included

/*--------------------------------[ Title ]--------------------------------*/

stock const SW_TITLE[] = "Snow Wars";
stock const SW_VERSION[] = "1.1.0";

/*--------------------------------[ Asset Library ]--------------------------------*/

stock const SW_AssetLibrary[] = "snowwars";

/*--------------------------------[ Shop ]--------------------------------*/

stock const SW_Shop[] = "snowwars";

/*--------------------------------[ Shop Items ]--------------------------------*/

stock const SW_Shop_Item_Slingshot[] = "sw-slingshot";
stock const SW_Shop_Item_LemonJuice[] = "sw-lemon-juice";
stock const SW_Shop_Item_DownJacket[] = "sw-down-jacket";
stock const SW_Shop_Item_Snowman[] = "sw-snowman";
stock const SW_Shop_Item_SurpriseBox[] = "sw-surprise-box";
stock const SW_Shop_Item_Fireplace[] = "sw-fireplace";
stock const SW_Shop_Item_Shield[] = "sw-shield";
stock const SW_Shop_Item_HotDrink[] = "sw-hotdrink";

/*--------------------------------[ Player Assets ]--------------------------------*/

stock const SW_Asset_Player_Sound_Spawn[] = "player.sounds.spawn";
stock const SW_Asset_Player_Sound_Return[] = "player.sounds.return";
stock const SW_Asset_Player_Sound_Hit[] = "player.sounds.hit";

/*--------------------------------[ Weapons Assets ]--------------------------------*/

stock const SW_Asset_Weapon_Snowball_Model_View[] = "weapons.snowball.models.view";
stock const SW_Asset_Weapon_Snowball_Model_Player[] = "weapons.snowball.models.player";
stock const SW_Asset_Weapon_Snowball_Model_World[] = "weapons.snowball.models.world";
stock const SW_Asset_Weapon_Snowball_Sound_Throw[] = "weapons.snowball.sounds.throw";
stock const SW_Asset_Weapon_Slingshot_Model_View[] = "weapons.slingshot.models.view";
stock const SW_Asset_Weapon_Slingshot_Model_Player[] = "weapons.slingshot.models.player";
stock const SW_Asset_Weapon_Slingshot_Model_World[] = "weapons.slingshot.models.world";
stock const SW_Asset_Weapon_Fireworksbox_Model_View[] = "weapons.fireworksbox.models.view";
stock const SW_Asset_Weapon_Fireworksbox_Model_Player[] = "weapons.fireworksbox.models.player";
stock const SW_Asset_Weapon_Fireworksbox_Model_World[] = "weapons.fireworksbox.models.world";
stock const SW_Asset_Weapon_Snowman_Model_View[] = "weapons.snowman.models.view";
stock const SW_Asset_Weapon_Snowman_Model_Player[] = "weapons.snowman.models.player";
stock const SW_Asset_Weapon_Snowman_Model_World[] = "weapons.snowman.models.world";
stock const SW_Asset_Weapon_Shield_Model_View[] = "weapons.shield.models.view";
stock const SW_Asset_Weapon_Shield_Model_Player[] = "weapons.shield.models.player";
stock const SW_Asset_Weapon_Shield_Model_World[] = "weapons.shield.models.world";
stock const SW_Asset_Weapon_Shield_Sound_Impact[] = "weapons.shield.sounds.impact";
stock const SW_Asset_Weapon_HotDrink_Model_View[] = "weapons.hotdrink.models.view";
stock const SW_Asset_Weapon_HotDrink_Model_Player[] = "weapons.hotdrink.models.player";
stock const SW_Asset_Weapon_HotDrink_Model_World[] = "weapons.hotdrink.models.world";
stock const SW_Asset_Weapon_HotDrink_Sound_Drink[] = "weapons.hotdrink.sounds.drink";
stock const SW_Asset_Weapon_Fireplace_Model_View[] = "weapons.fireplace.models.view";
stock const SW_Asset_Weapon_Fireplace_Model_Player[] = "weapons.fireplace.models.player";
stock const SW_Asset_Weapon_Fireplace_Model_World[] = "weapons.fireplace.models.world";
stock const SW_Asset_Weapon_Slingshot_Sound_Snap[] = "weapons.slingshot.sounds.snap";
stock const SW_Asset_Weapon_Slingshot_Sound_Throw[] = "weapons.slingshot.sounds.throw";
stock const SW_Asset_Weapon_Slingshot_Sound_Stretch[] = "weapons.slingshot.sounds.stretch";

/*--------------------------------[ Entities Assets ]--------------------------------*/

stock const SW_Asset_Entity_Snowman_Model[] = "entities.snowman.model";
stock const SW_Asset_Entity_Snowman_Sound_Spawn[] = "entities.snowman.sounds.spawn";
stock const SW_Asset_Entity_Fireplace_Model[] = "entities.fireplace.model";
stock const SW_Asset_Entity_Snowball_Model[] = "entities.snowball.model";
stock const SW_Asset_Entity_Snowball_Sound_Hit[] = "entities.snowball.sounds.hit";
stock const SW_Asset_Entity_Artifact_Model[] = "entities.artifact.model";
stock const SW_Asset_Entity_FireworkRocket_Sound_Whistle[] = "entities.firework-rocket.sounds.whistle";
stock const SW_Asset_Entity_FireworkEffect_Model[] = "entities.firework-effect.model";
stock const SW_Asset_Entity_FireworkEffect_Sound_Explosion[] = "entities.firework-effect.sounds.explosion";
stock const SW_Asset_Entity_Snowball_Sprites_Splash[] = "entities.snowball.sprites.splash";
stock const SW_Asset_Entity_FireworkRocket_Sprites_Trail[] = "entities.firework-rocket.sprites.trail";
stock const SW_Asset_Entity_FireworkRocket_Model[] = "entities.firework-rocket.model";
stock const SW_Asset_Entity_FireworksBox_Sound_Music[] = "entities.fireworksbox.sounds.music";
stock const SW_Asset_Entity_FireworksBox_Model[] = "entities.fireworksbox.model";

/*--------------------------------[ Artifacts Assets ]--------------------------------*/

stock const SW_Asset_Artifact_DownJacket_Sound_Equip[] = "artifacts.downjacket.sounds.equip";
stock const SW_Asset_Artifact_DownJacket_Model_Player[] = "artifacts.downjacket.models.player";
stock const SW_Asset_Artifact_DownJacket_Model_World[] = "artifacts.downjacket.models.world";
stock const SW_Asset_Artifact_DownJacket_Sprite_Splash[] = "artifacts.downjacket.sprites.splash";
stock const SW_Asset_Artifact_LemonJuice_Sound_Hit[] = "artifacts.lemonjuice.sounds.hit";
stock const SW_Asset_Artifact_LemonJuice_Model_World[] = "artifacts.lemonjuice.models.world";
stock const SW_Asset_Artifact_LemonJuice_Model_Snowball[] = "artifacts.lemonjuice.models.snowball";
stock const SW_Asset_Artifact_LemonJuice_Sprite_Splash[] = "artifacts.lemonjuice.sprites.splash";

/*--------------------------------[ Weapons ]--------------------------------*/

stock const SW_Weapon_Snowball[] = "snowwars/v110/weapon_snowball";
stock const SW_Weapon_Slingshot[] = "snowwars/v110/weapon_slingshot";
stock const SW_Weapon_FireworksBox[] = "snowwars/v110/weapon_fireworksbox";
stock const SW_Weapon_Snowman[] = "snowwars/v110/weapon_snowman";
stock const SW_Weapon_Shield[] = "snowwars/v110/weapon_shield";
stock const SW_Weapon_HotDrink[] = "snowwars/v110/weapon_hotdrink";
stock const SW_Weapon_Fireplace[] = "snowwars/v110/weapon_fireplace";
stock const SW_Weapon_BaseBlueprint[] = "snowwars/v110/weapon_base_blueprint";

/*--------------------------------[ Weapons Members ]--------------------------------*/

stock const SW_Weapon_Slingshot_Member_flChargeTime[] = "flChargeTime";
stock const SW_Weapon_HotDrink_Member_flReleaseDrink[] = "flReleaseDrink";
stock const SW_Weapon_BaseBlueprint_Member_flHeightStep[] = "flHeightStep";
stock const SW_Weapon_BaseBlueprint_Member_flDeployDistance[] = "flDeployDistance";
stock const SW_Weapon_BaseBlueprint_Member_vecInstallationMins[] = "vecInstallationMins";
stock const SW_Weapon_BaseBlueprint_Member_vecInstallationMaxs[] = "vecInstallationMaxs";
stock const SW_Weapon_BaseBlueprint_Member_iInstallationModelIndex[] = "iInstallationModelIndex";

/*--------------------------------[ Weapons Methods ]--------------------------------*/

stock const SW_Weapon_Slingshot_Method_GetPower[] = "GetPower";
stock const SW_Weapon_Slingshot_Method_GetChargeDuration[] = "GetChargeDuration";
stock const SW_Weapon_HotDrink_Method_ReleaseDrink[] = "ReleaseDrink";
stock const SW_Weapon_HotDrink_Method_Interrupt[] = "Interrupt";
stock const SW_Weapon_Shield_Method_HitFeedback[] = "HitFeedback";
stock const SW_Weapon_BaseBlueprint_Method_Build[] = "Build";
stock const SW_Weapon_BaseBlueprint_Method_CreateInstallation[] = "CreateInstallation";
stock const SW_Weapon_BaseBlueprint_Method_InitInstallationVars[] = "InitInstallationVars";

/*--------------------------------[ Entities ]--------------------------------*/

stock const SW_Entity_ArtifactItem[] = "sw_item_artifact";
stock const SW_Entity_Snowman[] = "sw_snowman";
stock const SW_Entity_FireworkRocket[] = "sw_fireworkrocket";
stock const SW_Entity_Snowball[] = "sw_snowball";
stock const SW_Entity_FireworksBox[] = "sw_fireworksbox";
stock const SW_Entity_Fireplace[] = "sw_fireplace";
stock const SW_Entity_FireworkEffect[] = "sw_firework_effect";

/*--------------------------------[ Entities Members ]--------------------------------*/

stock const SW_Entity_ArtifactItem_Member_szArtifactId[] = "szArtifactId";
stock const SW_Entity_Snowball_Member_flDamage[] = "flDamage";
stock const SW_Entity_Snowball_Member_flAutoGuidanceRange[] = "flAutoGuidanceRange";
stock const SW_Entity_Snowball_Member_flAutoGuidanceAngle[] = "flAutoGuidanceAngle";
stock const SW_Entity_Snowball_Member_bLemonJuice[] = "bLemonJuice";
stock const SW_Entity_FireworkRocket_Member_flSpeed[] = "flSpeed";
stock const SW_Entity_FireworksBox_Member_iMaxRocketsNum[] = "iMaxRocketsNum";
stock const SW_Entity_FireworksBox_Member_iRocketsNum[] = "iRocketsNum";
stock const SW_Entity_Fireplace_Member_flHealRate[] = "flHealRate";
stock const SW_Entity_Fireplace_Member_flHealAmount[] = "flHealAmount";
stock const SW_Entity_Fireplace_Member_flHealRange[] = "flHealRange";
stock const SW_Entity_Fireplace_Member_pFire[] = "pFire";
stock const SW_Entity_FireworkEffect_Member_iFramesNum[] = "iFramesNum";

/*--------------------------------[ Entities Methods ]--------------------------------*/

stock const SW_Entity_Snowball_Method_AutoGuidance[] = "AutoGuidance";
stock const SW_Entity_Snowman_Method_RespawnPlayer[] = "RespawnPlayer";
stock const SW_Entity_Snowman_Method_Effect[] = "Effect";
stock const SW_Entity_Snowman_Method_CanTakeDamage[] = "CanTakeDamage";
stock const SW_Entity_Snowman_Method_GetRelationship[] = "GetRelationship";
stock const SW_Entity_Snowman_Method_ShouldRespawnPlayer[] = "ShouldRespawnPlayer";
stock const SW_Entity_Snowman_Method_UnassignOwner[] = "UnassignOwner";
stock const SW_Entity_FireworkRocket_Method_ExplosionEffect[] = "ExplosionEffect";
stock const SW_Entity_FireworksBox_Method_SpawnRocket[] = "SpawnRocket";
stock const SW_Entity_Fireplace_Method_CanTakeDamage[] = "CanTakeDamage";
stock const SW_Entity_Fireplace_Method_GetRelationship[] = "GetRelationship";
stock const SW_Entity_FireworkEffect_Method_Play[] = "Play";

/*--------------------------------[ Artifacts ]--------------------------------*/

stock const SW_Artifact_Downjacket[] = "downjacket";
stock const SW_Artifact_LemonJuice[] = "lemonjuice";

/*--------------------------------[ Enums ]--------------------------------*/

enum SW_PlayerAttribute {
  SW_PlayerAttribute_Resistance = 0,
  SW_PlayerAttribute_Power
};

enum SW_EntityRelationship {
  SW_EntityRelationship_None = 0,
  SW_EntityRelationship_Shared,
  SW_EntityRelationship_Team,
  SW_EntityRelationship_Owner
};

enum {
  SW_WeaponsIds_Snowball = 1,
  SW_WeaponsIds_Slingshot = 3,
  SW_WeaponsIds_FireworksBox = 4,
  SW_WeaponsIds_Fireplace = 5,
  SW_WeaponsIds_Snowman = 9,
  SW_WeaponsIds_Shield = 23,
  SW_WeaponsIds_HotDrink = 25
};
