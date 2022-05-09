#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <snowwars>
#include <api_custom_entities>
#include <api_custom_weapons>

#define PLUGIN "[Snow Wars] Gamemode"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_precache() {
    RegisterHam(Ham_Spawn, "armoury_entity", "Ham_ArmouryEntity_Spawn_Post", .Post = 1);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed", .Post = 0);
    RegisterHam(Ham_Killed, "player", "Ham_Player_Killed_Post", .Post = 1);
    RegisterHam(Ham_Touch, "weaponbox", "Ham_WeaponBox_Touch", .Post = 0);

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip", .post = 0);
    RegisterHookChain(RG_CSGameRules_RestartRound, "HC_GameRules_RestartRound", .post = 0);
}

public client_disconnected(pPlayer) {
    @Player_DropItems(pPlayer);
    @Player_DropArtifacts(pPlayer);
}

public Ham_Player_Killed(this) {
    @Player_DropItems(this);
}

public Ham_Player_Killed_Post(this) {
    @Player_DropArtifacts(this);
}

public Ham_ArmouryEntity_Spawn_Post(this, pToucher) {
    set_pev(this, pev_flags, pev(this, pev_flags) | FL_KILLME);
    dllfunc(DLLFunc_Think, this);
}

public Ham_WeaponBox_Touch(this, pTarget) {
    if (!is_user_connected(pTarget)) {
        return HAM_IGNORED;
    }

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
            new pItem = get_member(this, m_WeaponBox_rgpPlayerItems, iSlot);
            new pPlayerItem = get_member(pTarget, m_rgpPlayerItems, iSlot);
            
            if (pItem != -1 && pPlayerItem != -1) {
                return HAM_SUPERCEDE;
            }
    }

    return HAM_HANDLED;
}

public HC_Player_SpawnEquip(this) {
    CW_GiveWeapon(this, "snowwars/v090/weapon_snowball");
    return HC_SUPERCEDE;
}

public HC_GameRules_RestartRound() {
    new bool:bCompleteReset = get_member_game(m_bCompleteReset);

    if (bCompleteReset) {
        for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
            if (!is_user_connected(pPlayer)) {
                continue;
            }

            static szId[16];
            new iSlot = -1;
            while ((iSlot = SW_Player_FindArtifact(pPlayer, iSlot, szId, charsmax(szId))) != -1) {
                SW_Player_TakeArtifactBySlot(pPlayer, iSlot);
            }
        }
    }
}

public @Player_DropArtifacts(this) {
    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    static szId[16];
    new iSlot = -1;
    while ((iSlot = SW_Player_FindArtifact(this, iSlot, szId, charsmax(szId))) != -1) {
        SW_Player_TakeArtifactBySlot(this, iSlot);

        new pArtifactItem = CE_Create("sw_item_artifact", vecOrigin);
        set_pev(pArtifactItem, pev_target, szId);
        dllfunc(DLLFunc_Spawn, pArtifactItem);

        static Float:vecVelocity[3];
        vecVelocity[0] = random_float(48.0, 64.0) * (random(2) ? -1.0 : 1.0);
        vecVelocity[1] = random_float(48.0, 64.0) * (random(2) ? -1.0 : 1.0);
        vecVelocity[2] = random_float(192.0, 256.0);
        set_pev(pArtifactItem, pev_velocity, vecVelocity);

        static Float:vecAngles[3];
        vecAngles[0] = 0.0;
        vecAngles[1] = random_float(-180.0, 180.0);
        vecAngles[2] = 0.0;
        set_pev(pArtifactItem, pev_angles, vecAngles);
    }
}

public @Player_DropItems(this) {
    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(this, m_rgpPlayerItems, iSlot);

        while (pItem != -1) {
            new pNextItem = get_member(pItem, m_pNext);

            if (ExecuteHamB(Ham_CS_Item_CanDrop, pItem)) {
                static szClassname[32];
                pev(pItem, pev_classname, szClassname, charsmax(szClassname));
                rg_drop_item(this, szClassname);
            }

            pItem = pNextItem;
        }
    }
}
