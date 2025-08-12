#pragma semicolon 1

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

#include <api_shops>
#include <api_custom_weapons>

#include <snowwars>

#define PLUGIN "[Snow Wars] Shop"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);

  register_clcmd("client_buy_open", "Command_ClientBuyOpen");
  register_clcmd("shop", "Command_Buy");
  register_clcmd("buy", "Command_Buy");
  register_clcmd("buyequip", "Command_Buy");

  Shop_Register(SW_SHOP);
  Shop_SetGuardCallback(SW_SHOP, "Callback_Shop_Guard");

  Shop_Item_Register(SW_SHOP_ITEM_SLINGSHOT);
  Shop_Item_SetTitle(SW_SHOP_ITEM_SLINGSHOT, "Slingshot");
  Shop_Item_SetPurchaseCallback(SW_SHOP_ITEM_SLINGSHOT, "Callback_Shop_Item_Purchase_Slingshot");
  Shop_AddItem(SW_SHOP, SW_SHOP_ITEM_SLINGSHOT, 4500);

  Shop_Item_Register(SW_SHOP_ITEM_LEMONJUICE);
  Shop_Item_SetTitle(SW_SHOP_ITEM_LEMONJUICE, "Lemon Juice");
  Shop_Item_SetPurchaseCallback(SW_SHOP_ITEM_LEMONJUICE, "Callback_Shop_Item_Purchase_LemonJuice");
  Shop_Item_SetGuardCallback(SW_SHOP_ITEM_LEMONJUICE, "Callback_Shop_Item_Guard_LemonJuice");
  Shop_AddItem(SW_SHOP, SW_SHOP_ITEM_LEMONJUICE, 2500);

  Shop_Item_Register(SW_SHOP_ITEM_DOWNJACKET);
  Shop_Item_SetTitle(SW_SHOP_ITEM_DOWNJACKET, "Down Jacket");
  Shop_Item_SetPurchaseCallback(SW_SHOP_ITEM_DOWNJACKET, "Callback_Shop_Item_Purchase_DownJacket");
  Shop_Item_SetGuardCallback(SW_SHOP_ITEM_DOWNJACKET, "Callback_Shop_Item_Guard_DownJacket");
  Shop_AddItem(SW_SHOP, SW_SHOP_ITEM_DOWNJACKET, 3100);

  Shop_Item_Register(SW_SHOP_ITEM_SNOWMAN);
  Shop_Item_SetTitle(SW_SHOP_ITEM_SNOWMAN, "Snowman");
  Shop_Item_SetPurchaseCallback(SW_SHOP_ITEM_SNOWMAN, "Callback_Shop_Item_Purchase_Snowman");
  Shop_AddItem(SW_SHOP, SW_SHOP_ITEM_SNOWMAN, 5000);

  Shop_Item_Register(SW_SHOP_ITEM_SURPRISEBOX);
  Shop_Item_SetTitle(SW_SHOP_ITEM_SURPRISEBOX, "Surprise Box");
  Shop_Item_SetPurchaseCallback(SW_SHOP_ITEM_SURPRISEBOX, "Callback_Shop_Item_Purchase_SurpriseBox");
  Shop_AddItem(SW_SHOP, SW_SHOP_ITEM_SURPRISEBOX, 10000);
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
  Shop_Player_OpenShop(this, SW_SHOP);
}

public Callback_Shop_Guard(const pPlayer) {
  if (!is_user_alive(pPlayer)) return false;
  if (!cs_get_user_buyzone(pPlayer)) return false;

  return true;
}

public Callback_Shop_Item_Purchase_Slingshot(const pPlayer) {
  CW_Give(pPlayer, SW_WEAPON_SLINGSHOT, true);
}

public Callback_Shop_Item_Purchase_LemonJuice(const pPlayer) {
  SW_Player_GiveArtifact(pPlayer, SW_ARTIFACT_LEMONJUICE);
}

public Callback_Shop_Item_Purchase_DownJacket(const pPlayer) {
  SW_Player_GiveArtifact(pPlayer, SW_ARTIFACT_DOWNJACKET);
}

public Callback_Shop_Item_Purchase_Snowman(const pPlayer) {
  CW_Give(pPlayer, SW_WEAPON_SNOWMAN, true);
}

public Callback_Shop_Item_Purchase_SurpriseBox(const pPlayer) {
  CW_Give(pPlayer, SW_WEAPON_FIREWORKSBOX, true);
}

public Callback_Shop_Item_Guard_LemonJuice(const pPlayer) {
  return !SW_Player_HasArtifact(pPlayer, SW_ARTIFACT_LEMONJUICE);
}

public Callback_Shop_Item_Guard_DownJacket(const pPlayer) {
  return !SW_Player_HasArtifact(pPlayer, SW_ARTIFACT_DOWNJACKET);
}
