#pragma semicolon 1

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <reapi>

#include <api_custom_weapons>
#include <snowwars>

#define PLUGIN "[Snow Wars] Shop"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

enum ShopItemType {
    ShopItem_Weapon,
    ShopItem_Artifact
}

new Array:g_irgShopItemTitles;
new Array:g_irgShopItemIds;
new Array:g_irgShopItemPrices;
new Array:g_irgShopItemTypes;
new g_iShopItemCount = 0;

new g_iPlayerMenu[MAX_PLAYERS + 1];

public plugin_precache() {
    g_irgShopItemTitles = ArrayCreate(32);
    g_irgShopItemIds = ArrayCreate(64);
    g_irgShopItemPrices = ArrayCreate();
    g_irgShopItemTypes = ArrayCreate();
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("client_buy_open", "Command_ClientBuyOpen");
    register_clcmd("shop", "Command_Buy");
    register_clcmd("buy", "Command_Buy");
    register_clcmd("buyequip", "Command_Buy");

    RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", .Post = 1);

    RegisterItem("Slingshot", SW_WEAPON_SLINGSHOT, 4500, ShopItem_Weapon);
    RegisterItem("Lemon Juice", SW_ARTIFACT_LEMONJUICE, 2500, ShopItem_Artifact);
    RegisterItem("Down Jacket", SW_ARTIFACT_DOWNJACKET, 3100, ShopItem_Artifact);
    RegisterItem("Surprise Box", SW_WEAPON_FIREWORKSBOX, 10000, ShopItem_Weapon);
}

public plugin_destroy() {
    ArrayDestroy(g_irgShopItemTitles);
    ArrayDestroy(g_irgShopItemIds);
    ArrayDestroy(g_irgShopItemPrices);
    ArrayDestroy(g_irgShopItemTypes);
}

public client_connect(pPlayer) {
    g_iPlayerMenu[pPlayer] = -1;
}

public client_disconnected(pPlayer) {
    @Player_CloseBuyMenu(pPlayer);
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

public Ham_Player_Spawn_Post(pPlayer) {
    @Player_CloseBuyMenu(pPlayer);
}

public Ham_Player_Killed_Post(pPlayer) {
    @Player_CloseBuyMenu(pPlayer);
}

public @Player_OpenBuyMenu(this) {
    if (!is_user_alive(this)) {
        return;
    }

    if (!cs_get_user_buyzone(this)) {
        return;
    }

    @Player_CloseBuyMenu(this);

    g_iPlayerMenu[this] = menu_create("Buy Item\R$ Cost", "ShopMenuHandler");
    new iMenuCallback = menu_makecallback("ShopMenuCallback");

    for (new i = 0; i < g_iShopItemCount; ++i) {
        static szTitle[32];
        ArrayGetString(g_irgShopItemTitles, i, szTitle, charsmax(szTitle));
        new iPrice = ArrayGetCell(g_irgShopItemPrices, i);
        format(szTitle, charsmax(szTitle), "%s\R\y$%d", szTitle, iPrice);
        menu_additem(g_iPlayerMenu[this], szTitle, _, _, iMenuCallback);
    }

    menu_display(this, g_iPlayerMenu[this]);
}

public @Player_CloseBuyMenu(this) {
    if (g_iPlayerMenu[this] == -1) {
        return;
    }

    show_menu(this, 0, "^n", 1);
}

public @Player_BuyItem(this, iItem) {
    if (!is_user_alive(this)) {
        return false;
    }

    if (!cs_get_user_buyzone(this)) {
        return false;
    }

    new iMoney = cs_get_user_money(this);
    new iPrice = ArrayGetCell(g_irgShopItemPrices, iItem);

    if (iPrice > iMoney) {
        return false;
    }

    static szId[64];
    ArrayGetString(g_irgShopItemIds, iItem, szId, charsmax(szId));

    new ShopItemType:iType = ArrayGetCell(g_irgShopItemTypes, iItem);

    switch (iType) {
        case ShopItem_Weapon: {
            new iSlotId = CW_GetWeaponData(CW_GetHandler(szId), CW_Data_SlotId);
            rg_drop_items_by_slot(this, InventorySlotType:(iSlotId + 1));
            CW_GiveWeapon(this, szId);
        }
        case ShopItem_Artifact: {
            if (SW_Player_HasArtifact(this, szId)) {
                return false;
            }

            SW_Player_GiveArtifact(this, szId);
        }
    }

    cs_set_user_money(this, iMoney - iPrice);

    return true;
}

public ShopMenuHandler(pPlayer, iMenu, iItem) {
    if (iItem != MENU_EXIT) {
        @Player_BuyItem(pPlayer, iItem);
    }

    menu_destroy(iMenu);
    g_iPlayerMenu[pPlayer] = -1;
    return PLUGIN_HANDLED;
}

public ShopMenuCallback(pPlayer, iMenu, iItem) {
    new iMoney = cs_get_user_money(pPlayer);
    new iPrice = ArrayGetCell(g_irgShopItemPrices, iItem);
    new ShopItemType:iType = ArrayGetCell(g_irgShopItemTypes, iItem);

    static szId[64];
    ArrayGetString(g_irgShopItemIds, iItem, szId, charsmax(szId));

    if (iType == ShopItem_Artifact && SW_Player_HasArtifact(pPlayer, szId)) {
        return ITEM_DISABLED;
    }

    return iPrice <= iMoney ? ITEM_ENABLED : ITEM_DISABLED;
}

RegisterItem(const szTitle[], const szId[], iPrice, ShopItemType:iType) {
    ArrayPushString(g_irgShopItemTitles, szTitle);
    ArrayPushString(g_irgShopItemIds, szId);
    ArrayPushCell(g_irgShopItemPrices, iPrice);
    ArrayPushCell(g_irgShopItemTypes, iType);
    g_iShopItemCount++;
}
