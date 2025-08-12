#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <api_shops>
#include <api_custom_weapons>

#include <snowwars>

#define PLUGIN "[Snow Wars] Bots Autobuy"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
}

public HamHook_Player_Spawn_Post(pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;
  if (!is_user_bot(pPlayer)) return HAM_IGNORED;

  remove_task(pPlayer);
  set_task(random_float(0.5, 2.0), "Task_PlayerAutoBuy", pPlayer);

  return HAM_HANDLED;
}

public Task_PlayerAutoBuy(iTaskId) {
  new pPlayer = iTaskId;

  @Player_AutoBuy(pPlayer);
}

@Player_AutoBuy(this) {
  if (
    random(100) < 80 &&
    !SW_Player_HasArtifact(this, SW_ARTIFACT_DOWNJACKET) &&
    Shop_Player_GetBalance(this, SW_SHOP) >= Shop_GetItemPrice(SW_SHOP, SW_SHOP_ITEM_DOWNJACKET)
  ) {
    Shop_Player_PurchaseItem(this, SW_SHOP, SW_SHOP_ITEM_DOWNJACKET);
  }

  if (
    random(100) < 50 &&
    !CW_PlayerHasWeapon(this, SW_WEAPON_SLINGSHOT) &&
    Shop_Player_GetBalance(this, SW_SHOP) >= Shop_GetItemPrice(SW_SHOP, SW_SHOP_ITEM_SLINGSHOT)
  ) {
    Shop_Player_PurchaseItem(this, SW_SHOP, SW_SHOP_ITEM_SLINGSHOT);
  }

  if (
    random(100) < 30 &&
    !SW_Player_HasArtifact(this, SW_ARTIFACT_LEMONJUICE) &&
    Shop_Player_GetBalance(this, SW_SHOP) >= Shop_GetItemPrice(SW_SHOP, SW_SHOP_ITEM_LEMONJUICE)
  ) {
    Shop_Player_PurchaseItem(this, SW_SHOP, SW_SHOP_ITEM_LEMONJUICE);
  }
}
