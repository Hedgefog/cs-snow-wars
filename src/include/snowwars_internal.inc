#if defined _snowwars_internal_included
  #endinput
#endif
#define _snowwars_internal_included

#include <snowwars_const>

/*--------------------------------[ Common Macros ]--------------------------------*/

#if !defined IS_PLAYER
  #define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)
#endif

/*--------------------------------[ CVar Macro ]--------------------------------*/

#define CVAR(%1) "snowwars_" + %1

/*--------------------------------[ Plugin Registration Macros ]--------------------------------*/

#define PLUGIN_NAME(%1) "[Snow Wars] " + %1
#define ENTITY_PLUGIN(%1) "[Entity] (Snow Wars) " + #%1
#define WEAPON_PLUGIN(%1) "[Weapon] (Snow Wars) " + #%1
#define ARTIFACT_PLUGIN(%1) "[Snow Wars Artifact] " + #%1
#define FEATURE_PLUGIN(%1) "[Snow Wars Feature] " + #%1

/*--------------------------------[ Namespace Macros ]--------------------------------*/

#define NAMESPACE(%1) SW_%1
#define NAMESPACE_FIELD<%1>(%2) NAMESPACE(%1)_%2

/*--------------------------------[ Entities Shortcuts ]--------------------------------*/

#define ENTITY(%1) NAMESPACE_FIELD<Entity>(%1)
#define ENTITY_DATA<%1>(%2,%3) ENTITY(%2)_%1_%3
#define ENTITY_METHOD<%1>(%2) ENTITY_DATA<Method>(%1,%2)
#define ENTITY_MEMBER<%1>(%2) ENTITY_DATA<Member>(%1,%2)

/*--------------------------------[ Weapons Shortcuts ]--------------------------------*/

#define WEAPON(%1) NAMESPACE_FIELD<Weapon>(%1)
#define WEAPON_DATA<%1>(%2,%3) WEAPON(%2)_%1_%3
#define WEAPON_METHOD<%1>(%2) WEAPON_DATA<Method>(%1,%2)
#define WEAPON_MEMBER<%1>(%2) WEAPON_DATA<Member>(%1,%2)

/*--------------------------------[ Assets Shortcuts ]--------------------------------*/

#define ASSET_LIBRARY NAMESPACE(AssetLibrary)
#define ASSET(%1) NAMESPACE_FIELD<Asset>(%1)

/*--------------------------------[ Shops Shortcuts ]--------------------------------*/

#define SHOP(%1) NAMESPACE_FIELD<Shop>(%1)
#define SHOP_ITEM(%1) NAMESPACE_FIELD<Shop_Item>(%1)

/*--------------------------------[ Artifacts Shortcuts ]--------------------------------*/

#define ARTIFACT(%1) NAMESPACE_FIELD<Artifact>(%1)
