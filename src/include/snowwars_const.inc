#define SW_TITLE "Snow Wars"
#define SW_VERSION "1.0.0"

#define SW_ASSET_LIBRARY "snowwars"

#define SW_SHOP "snowwars"

#define SW_SHOP_ITEM_SLINGSHOT "sw-slingshot"
#define SW_SHOP_ITEM_LEMONJUICE "sw-lemon-juice"
#define SW_SHOP_ITEM_DOWNJACKET "sw-down-jacket"
#define SW_SHOP_ITEM_SNOWMAN "sw-snowman"
#define SW_SHOP_ITEM_SURPRISEBOX "sw-surprise-box"

#define WEAPON_SNOWBALL_HUD_TXT "WEAPON_SNOWBALL_HUD-txt"
#define WEAPON_SLINGSHOT_HUD_TXT "WEAPON_SLINGSHOT_HUD-txt"
#define WEAPON_FIREWORKSBOX_HUD_TXT "WEAPON_FIREWORKSBOX_HUD-txt"
#define WEAPON_SNOWMAN_HUD_TXT "WEAPON_SNOWMAN_HUD-txt"
#define SW_ASSET_SNOWMAN_MODEL "snowman-model"
#define SW_ASSET_SNOWBALL_V_MODEL "snowball-v-model"
#define SW_ASSET_SNOWBALL_P_MODEL "snowball-p-model"
#define SW_ASSET_SNOWBALL_W_MODEL "snowball-w-model"
#define SW_ASSET_SNOWBALL_LEMON_W_MODEL "snowball-lemon-w-model"
#define SW_ASSET_SLINGSHOT_V_MODEL "slingshot-v-model"
#define SW_ASSET_SLINGSHOT_P_MODEL "slingshot-p-model"
#define SW_ASSET_SLINGSHOT_W_MODEL "slingshot-w-model"
#define SW_ASSET_FIREWORKSBOX_V_MODEL "fireworksbox-v-model"
#define SW_ASSET_FIREWORKSBOX_P_MODEL "fireworksbox-p-model"
#define SW_ASSET_FIREWORKSBOX_W_MODEL "fireworksbox-w-model"
#define SW_ASSET_SNOWMAN_V_MODEL "snowman-v-model"
#define SW_ASSET_SNOWMAN_P_MODEL "snowman-p-model"
#define SW_ASSET_SNOWMAN_W_MODEL "snowman-w-model"
#define SW_ASSET_DOWNJACKET_W_MODEL "downjacket-w-model"
#define SW_ASSET_DOWNJACKET_P_MODEL "downjacket-p-model"
#define SW_ASSET_LEMONJUICE_W_MODEL "lemonjuice-w-model"
#define SW_ASSET_SNOWBALL_THROW_SOUND "snowball-throw-sound"
#define SW_ASSET_SNOWBALL_HIT_SOUND "snowball-hit-sound"
#define SW_ASSET_SNOWBALL_LEMON_HIT_SOUND "snowball-lemon-hit-sound"
#define SW_ASSET_JINGLE_MUSIC_SOUND "jingle-music-sound"
#define SW_ASSET_FIREWORK_ROCKET_SOUND "firework-rocket-sound"
#define SW_ASSET_DOWNJACKET_SOUND "downjacket-sound"
#define SW_ASSET_PLAYER_SPAWN_SOUND "player-spawn-sound"
#define SW_ASSET_RETURN_SOUND "return-sound"
#define SW_ASSET_PLAYER_HIT_SOUND "player-hit-sound"
#define SW_ASSET_ARTIFACT_MODEL "artifact-model"
#define SW_ASSET_FIREWORK_ROCKET_MODEL "firework-rocket-model"
#define SW_ASSET_ROCKET_TRAIL_SPRITE "rocket-trail-sprite"
#define SW_ASSET_FIREWORK_WAVE_SPRITE "firework-wave-sprite"
#define SW_ASSET_FIREWORK_PARTICLE_SPRITE "firework-particle-sprite"
#define SW_ASSET_SNOW_SPLASH_SPRITE "snow-splash-sprite"

stock const SW_WEAPON_SNOWBALL[] = "snowwars/v100/weapon_snowball";
stock const SW_WEAPON_SLINGSHOT[] = "snowwars/v100/weapon_slingshot";
stock const SW_WEAPON_FIREWORKSBOX[] = "snowwars/v100/weapon_fireworksbox";
stock const SW_WEAPON_SNOWMAN[] = "snowwars/v100/weapon_snowman";

stock const SW_ENTITY_ARTIFACT_ITEM[] = "sw_item_artifact";
stock const SW_ENTITY_SNOWMAN[] = "sw_snowman";
stock const SW_ENTITY_FIREWORK_ROCKET[] = "sw_fireworkrocket";
stock const SW_ENTITY_SNOWBALL[] = "sw_snowball";
stock const SW_ENTITY_FIREWORKS_BOX[] = "sw_fireworksbox";

stock const SW_ARTIFACT_DOWNJACKET[] = "downjacket";
stock const SW_ARTIFACT_LEMONJUICE[] = "lemonjuice";

enum SW_PlayerAttribute {
    SW_PlayerAttribute_Resistance = 0,
    SW_PlayerAttribute_Power
};

enum SW_Snowman_Relationship {
  SW_Snowman_Relationship_None = 0,
  SW_Snowman_Relationship_Shared,
  SW_Snowman_Relationship_Team,
  SW_Snowman_Relationship_Owner
};
