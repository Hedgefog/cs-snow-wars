#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <api_shops>
#include <api_custom_weapons>

#include <snowwars_player_artifacts>
#include <snowwars_internal>

public plugin_init() {
  register_plugin(PLUGIN_NAME("Bots Autobuy"), SW_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
}

public client_disconnected(pPlayer) {
  remove_task(pPlayer);
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
    !SW_PlayerArtifact_Has(this, ARTIFACT(Downjacket)) &&
    Shop_Player_GetBalance(this, SW_Shop) >= Shop_GetItemPrice(SW_Shop, SHOP_ITEM(DownJacket))
  ) {
    Shop_Player_PurchaseItem(this, SW_Shop, SHOP_ITEM(DownJacket));
  }

  if (
    random(100) < 50 &&
    !CW_PlayerHasWeapon(this, WEAPON(Slingshot)) &&
    Shop_Player_GetBalance(this, SW_Shop) >= Shop_GetItemPrice(SW_Shop, SHOP_ITEM(Slingshot))
  ) {
    Shop_Player_PurchaseItem(this, SW_Shop, SHOP_ITEM(Slingshot));
  }

  if (
    random(100) < 30 &&
    !SW_PlayerArtifact_Has(this, ARTIFACT(LemonJuice)) &&
    Shop_Player_GetBalance(this, SW_Shop) >= Shop_GetItemPrice(SW_Shop, SHOP_ITEM(LemonJuice))
  ) {
    Shop_Player_PurchaseItem(this, SW_Shop, SHOP_ITEM(LemonJuice));
  }
}
