#pragma semicolon 1

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <reapi>

#include <api_custom_weapons>
#include <snowwars>

#define PLUGIN "[Snow Wars] Bots Autobuy"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn_Post", .Post = 1);
}

public Ham_Player_Spawn_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!is_user_bot(pPlayer)) {
        return HAM_IGNORED;
    }

    remove_task(pPlayer);
    set_task(random_float(0.5, 2.0), "Task_PlayerAutoBuy", pPlayer);

    return HAM_HANDLED;
}

public Task_PlayerAutoBuy(iTaskId) {
    new pPlayer = iTaskId;

    @Player_AutoBuy(pPlayer);
}

public @Player_AutoBuy(this) {
    if (
        random(100) < 80 &&
        !SW_Player_HasArtifact(this, SW_ARTIFACT_DOWNJACKET) &&
        cs_get_user_money(this) >= SW_Shop_Item_GetPrice("Down Jacket")
    ) {
        SW_Shop_Player_BuyItem(this, "Down Jacket");
    }

    if (
        random(100) < 50 &&
        !@Player_HasWeapon(this, SW_WEAPON_SLINGSHOT) &&
        cs_get_user_money(this) >= SW_Shop_Item_GetPrice("Slingshot")
    ) {
        SW_Shop_Player_BuyItem(this, "Slingshot");
    }

    if (
        random(100) < 30 &&
        !SW_Player_HasArtifact(this, SW_ARTIFACT_LEMONJUICE) &&
        cs_get_user_money(this) >= SW_Shop_Item_GetPrice("Lemon Juice")
    ) {
        SW_Shop_Player_BuyItem(this, "Lemon Juice");
    }
}

public bool:@Player_HasWeapon(this, const szWeapon[]) {
    new CW:iCwHandler = CW_GetHandler(szWeapon);
    if (iCwHandler == CW_INVALID_HANDLER) {
        return false;
    }

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(this, m_rgpPlayerItems, iSlot);

        while (pItem != -1) {
            new pNextItem = get_member(pItem, m_pNext);

            if (CW_GetHandlerByEntity(pItem) == iCwHandler) {
                return true;
            }

            pItem = pNextItem;
        }
    }

    return false;
}
