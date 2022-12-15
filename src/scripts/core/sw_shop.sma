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

new Array:g_irgShopItemTitles;
new Array:g_irgShopItemIds;
new Array:g_irgShopItemPrices;
new Array:g_irgShopItemTypes;
new Trie:g_iShopItemIdsMap;
new g_iShopItemCount = 0;

new g_iPlayerMenu[MAX_PLAYERS + 1];

public plugin_precache() {
    g_irgShopItemTitles = ArrayCreate(32);
    g_irgShopItemIds = ArrayCreate(64);
    g_irgShopItemPrices = ArrayCreate();
    g_irgShopItemTypes = ArrayCreate();
    g_iShopItemIdsMap = TrieCreate();
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("client_buy_open", "Command_ClientBuyOpen");
    register_clcmd("shop", "Command_Buy");
    register_clcmd("buy", "Command_Buy");
    register_clcmd("buyequip", "Command_Buy");

    RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", .Post = 1);

    RegisterItem("Slingshot", SW_WEAPON_SLINGSHOT, 4500, SW_ShopItemType_Weapon);
    RegisterItem("Lemon Juice", SW_ARTIFACT_LEMONJUICE, 2500, SW_ShopItemType_Artifact);
    RegisterItem("Down Jacket", SW_ARTIFACT_DOWNJACKET, 3100, SW_ShopItemType_Artifact);
    RegisterItem("Snowman", SW_WEAPON_SNOWMAN, 5000, SW_ShopItemType_Weapon);
    RegisterItem("Surprise Box", SW_WEAPON_FIREWORKSBOX, 10000, SW_ShopItemType_Weapon);
}

public plugin_destroy() {
    ArrayDestroy(g_irgShopItemTitles);
    ArrayDestroy(g_irgShopItemIds);
    ArrayDestroy(g_irgShopItemPrices);
    ArrayDestroy(g_irgShopItemTypes);
    TrieDestroy(g_iShopItemIdsMap);
}

public plugin_natives() {
    register_native("SW_Shop_Player_BuyItem", "Native_BuyItem");
    register_native("SW_Shop_Item_GetPrice", "Native_GetItemPrice");
    register_native("SW_Shop_Item_GetType", "Native_GetItemType");
}

public client_connect(pPlayer) {
    g_iPlayerMenu[pPlayer] = -1;
}

public client_disconnected(pPlayer) {
    @Player_CloseBuyMenu(pPlayer);
}

public bool:Native_BuyItem(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    static szItemName[32];
    get_string(2, szItemName, charsmax(szItemName));

    new iItem = GetItemId(szItemName);
    if (iItem == -1) {
        return false;
    }

    return @Player_BuyItem(pPlayer, iItem);
}

public Native_GetItemPrice(iPluginId, iArgc) {
    static szItemName[32];
    get_string(1, szItemName, charsmax(szItemName));

    new iItem = GetItemId(szItemName);
    if (iItem == -1) {
        return 0;
    }

    new iPrice = ArrayGetCell(g_irgShopItemPrices, iItem);

    return iPrice;
}

public SW_ShopItemType:Native_GetItemType(iPluginId, iArgc) {
    static szItemName[32];
    get_string(1, szItemName, charsmax(szItemName));

    new iItem = GetItemId(szItemName);
    if (iItem == -1) {
        return SW_ShopItemType_Invalid;
    }

    new SW_ShopItemType:iType = ArrayGetCell(g_irgShopItemTypes, iItem);

    return iType;
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

public bool:@Player_BuyItem(this, iItem) {
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

    new SW_ShopItemType:iType = ArrayGetCell(g_irgShopItemTypes, iItem);

    switch (iType) {
        case SW_ShopItemType_Weapon: {
            new iSlotId = CW_GetWeaponData(CW_GetHandler(szId), CW_Data_SlotId);
            new iClipSize = CW_GetWeaponData(CW_GetHandler(szId), CW_Data_ClipSize);
            new iPrimaryAmmoIndex = CW_GetWeaponData(CW_GetHandler(szId), CW_Data_PrimaryAmmoType);

            if (iClipSize != WEAPON_NOCLIP || iPrimaryAmmoIndex == -1) {
                rg_drop_items_by_slot(this, InventorySlotType:(iSlotId + 1));
            }

            CW_GiveWeapon(this, szId);
        }
        case SW_ShopItemType_Artifact: {
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
    new SW_ShopItemType:iType = ArrayGetCell(g_irgShopItemTypes, iItem);

    static szId[64];
    ArrayGetString(g_irgShopItemIds, iItem, szId, charsmax(szId));

    if (iType == SW_ShopItemType_Artifact && SW_Player_HasArtifact(pPlayer, szId)) {
        return ITEM_DISABLED;
    }

    return iPrice <= iMoney ? ITEM_ENABLED : ITEM_DISABLED;
}

RegisterItem(const szTitle[], const szId[], iPrice, SW_ShopItemType:iType) {
    ArrayPushString(g_irgShopItemTitles, szTitle);
    ArrayPushString(g_irgShopItemIds, szId);
    ArrayPushCell(g_irgShopItemPrices, iPrice);
    ArrayPushCell(g_irgShopItemTypes, iType);
    TrieSetCell(g_iShopItemIdsMap, szTitle, g_iShopItemCount);
    g_iShopItemCount++;
}

GetItemId(const szTitle[]) {
    static iItem;
    if (!TrieGetCell(g_iShopItemIdsMap, szTitle, iItem)) {
        return -1;
    }

    return iItem;
}
