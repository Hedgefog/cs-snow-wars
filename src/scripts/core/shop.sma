#pragma semicolon 1

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

#include <api_shops>
#include <api_custom_weapons>

#include <snowwars>
#include <snowwars_player_artifacts>
#include <snowwars_internal>

public plugin_init() {
  register_plugin(PLUGIN_NAME("Shop"), SW_VERSION, "Hedgehog Fog");

  register_clcmd("client_buy_open", "Command_ClientBuyOpen");
  register_clcmd("shop", "Command_Buy");
  register_clcmd("buy", "Command_Buy");
  register_clcmd("buyequip", "Command_Buy");

  Shop_Register(SW_Shop);
  Shop_SetGuardCallback(SW_Shop, "Callback_Shop_Guard");

  if (CW_IsClassRegistered(WEAPON(Slingshot))) {
    Shop_Item_Register(SHOP_ITEM(Slingshot));
    Shop_Item_SetTitle(SHOP_ITEM(Slingshot), "Slingshot");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(Slingshot), "Callback_Shop_Item_Purchase_Slingshot");
    Shop_Item_SetGuardCallback(SHOP_ITEM(Slingshot), "Callback_Shop_Item_Guard_Slingshot");
    Shop_AddItem(SW_Shop, SHOP_ITEM(Slingshot), 4500);
  }

  if (CW_IsClassRegistered(WEAPON(HotDrink))) {
    Shop_Item_Register(SHOP_ITEM(HotDrink));
    Shop_Item_SetTitle(SHOP_ITEM(HotDrink), "Hot Drink");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(HotDrink), "Callback_Shop_Item_Purchase_HotDrink");
    Shop_Item_SetGuardCallback(SHOP_ITEM(HotDrink), "Callback_Shop_Item_Guard_HotDrink");
    Shop_AddItem(SW_Shop, SHOP_ITEM(HotDrink), 3500);
  }

  if (SW_PlayerArtifact_IsRegistered(ARTIFACT(LemonJuice))) {
    Shop_Item_Register(SHOP_ITEM(LemonJuice));
    Shop_Item_SetTitle(SHOP_ITEM(LemonJuice), "Lemon Juice");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(LemonJuice), "Callback_Shop_Item_Purchase_LemonJuice");
    Shop_Item_SetGuardCallback(SHOP_ITEM(LemonJuice), "Callback_Shop_Item_Guard_LemonJuice");
    Shop_AddItem(SW_Shop, SHOP_ITEM(LemonJuice), 2500);
  }

  if (SW_PlayerArtifact_IsRegistered(ARTIFACT(Downjacket))) {
    Shop_Item_Register(SHOP_ITEM(DownJacket));
    Shop_Item_SetTitle(SHOP_ITEM(DownJacket), "Down Jacket");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(DownJacket), "Callback_Shop_Item_Purchase_DownJacket");
    Shop_Item_SetGuardCallback(SHOP_ITEM(DownJacket), "Callback_Shop_Item_Guard_DownJacket");
    Shop_AddItem(SW_Shop, SHOP_ITEM(DownJacket), 3100);
  }

  if (CW_IsClassRegistered(WEAPON(Shield))) {
    Shop_Item_Register(SHOP_ITEM(Shield));
    Shop_Item_SetTitle(SHOP_ITEM(Shield), "Shield");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(Shield), "Callback_Shop_Item_Purchase_Shield");
    Shop_Item_SetGuardCallback(SHOP_ITEM(Shield), "Callback_Shop_Item_Guard_Shield");
    Shop_AddItem(SW_Shop, SHOP_ITEM(Shield), 5000);
  }

  if (CW_IsClassRegistered(WEAPON(Snowman))) {
    Shop_Item_Register(SHOP_ITEM(Snowman));
    Shop_Item_SetTitle(SHOP_ITEM(Snowman), "Snowman");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(Snowman), "Callback_Shop_Item_Purchase_Snowman");
    Shop_Item_SetGuardCallback(SHOP_ITEM(Snowman), "Callback_Shop_Item_Guard_Snowman");
    Shop_AddItem(SW_Shop, SHOP_ITEM(Snowman), 5000);
  }

  if (CW_IsClassRegistered(WEAPON(Fireplace))) {
    Shop_Item_Register(SHOP_ITEM(Fireplace));
    Shop_Item_SetTitle(SHOP_ITEM(Fireplace), "Fireplace");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(Fireplace), "Callback_Shop_Item_Purchase_Fireplace");
    Shop_Item_SetGuardCallback(SHOP_ITEM(Fireplace), "Callback_Shop_Item_Guard_Fireplace");
    Shop_AddItem(SW_Shop, SHOP_ITEM(Fireplace), 6000);
  }

  if (CW_IsClassRegistered(WEAPON(FireworksBox))) {
    Shop_Item_Register(SHOP_ITEM(SurpriseBox));
    Shop_Item_SetTitle(SHOP_ITEM(SurpriseBox), "Surprise Box");
    Shop_Item_SetPurchaseCallback(SHOP_ITEM(SurpriseBox), "Callback_Shop_Item_Purchase_SurpriseBox");
    Shop_Item_SetGuardCallback(SHOP_ITEM(SurpriseBox), "Callback_Shop_Item_Guard_SurpriseBox");
    Shop_AddItem(SW_Shop, SHOP_ITEM(SurpriseBox), 8500);
  }
}

public CS_OnBuyAttempt(pPlayer) {
  return PLUGIN_HANDLED;
}

public Command_Buy(pPlayer) {
  @Player_OpenBuyMenu(pPlayer);

  return PLUGIN_HANDLED;
}

public Command_ClientBuyOpen(pPlayer) {
  message_begin(MSG_ONE, get_user_msgid("BuyClose"), _, pPlayer);
  message_end();

  @Player_OpenBuyMenu(pPlayer);

  return PLUGIN_HANDLED;
}

@Player_OpenBuyMenu(const &this) {
  Shop_Player_OpenShop(this, SW_Shop);
}

public Callback_Shop_Guard(const pPlayer) {
  if (!is_user_alive(pPlayer)) return false;
  if (!cs_get_user_buyzone(pPlayer)) return false;

  return true;
}

public Callback_Shop_Item_Purchase_Slingshot(const pPlayer) {
  CW_Give(pPlayer, WEAPON(Slingshot));
  return true;
}

public Callback_Shop_Item_Guard_Slingshot(const pPlayer) {
  return !CW_PlayerHasWeapon(pPlayer, WEAPON(Slingshot));
}

public Callback_Shop_Item_Purchase_LemonJuice(const pPlayer) {
  SW_PlayerArtifact_Give(pPlayer, ARTIFACT(LemonJuice));
  return true;
}

public Callback_Shop_Item_Purchase_DownJacket(const pPlayer) {
  SW_PlayerArtifact_Give(pPlayer, ARTIFACT(Downjacket));
  return true;
}

public Callback_Shop_Item_Purchase_Snowman(const pPlayer) {
  CW_Give(pPlayer, WEAPON(Snowman));
  return true;
}

public Callback_Shop_Item_Guard_Snowman(const pPlayer) {
  return !CW_PlayerHasWeapon(pPlayer, WEAPON(Snowman));
}

public Callback_Shop_Item_Purchase_SurpriseBox(const pPlayer) {
  CW_Give(pPlayer, WEAPON(FireworksBox));
  return true;
}

public Callback_Shop_Item_Guard_SurpriseBox(const pPlayer) {
  return !CW_PlayerHasWeapon(pPlayer, WEAPON(FireworksBox));
}

public Callback_Shop_Item_Guard_LemonJuice(const pPlayer) {
  return !SW_PlayerArtifact_Has(pPlayer, ARTIFACT(LemonJuice));
}

public Callback_Shop_Item_Guard_DownJacket(const pPlayer) {
  return !SW_PlayerArtifact_Has(pPlayer, ARTIFACT(Downjacket));
}

public Callback_Shop_Item_Purchase_Fireplace(const pPlayer) {
  CW_Give(pPlayer, WEAPON(Fireplace));
  return true;
}

public Callback_Shop_Item_Guard_Fireplace(const pPlayer) {
  return !CW_PlayerHasWeapon(pPlayer, WEAPON(Fireplace));
}

public Callback_Shop_Item_Purchase_Shield(const pPlayer) {
  CW_Give(pPlayer, WEAPON(Shield));
  return true;
}

public Callback_Shop_Item_Guard_Shield(const pPlayer) {
  return !CW_PlayerHasWeapon(pPlayer, WEAPON(Shield));
}

public Callback_Shop_Item_Purchase_HotDrink(const pPlayer) {
  CW_Give(pPlayer, WEAPON(HotDrink));
  return true;
}

public Callback_Shop_Item_Guard_HotDrink(const pPlayer) {
  return !CW_PlayerHasWeapon(pPlayer, WEAPON(HotDrink));
}
