#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>
#include <api_custom_weapons>

#include <snowwars_const>

/*--------------------------------[ Helpers ]--------------------------------*/

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_ITEM_TYPES 6
#define MAX_AMMO_SLOTS 32

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_pItemInfo;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pItemInfo = CreateHamItemInfo();

  CE_ExtendClass("weaponbox");
  CE_ImplementClassMethod("weaponbox", CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod("weaponbox", CE_Method_Touch, "@Entity_Touch");
}

public plugin_init() {
  register_plugin("Entity Extension: WeaponBox", SW_VERSION, "Hedgehog Fog");
}

public plugin_end() {
  FreeHamItemInfo(g_pItemInfo);
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  static szModel[MAX_RESOURCE_PATH_LENGTH]; pev(this, pev_model, szModel, charsmax(szModel));

  if (equal(szModel, "models/w_weaponbox.mdl")) {
    CE_GetMemberString(this, CE_Member_szModel, szModel, charsmax(szModel));
    engfunc(EngFunc_SetModel, this, szModel);
  }

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
  set_pev(this, pev_friction, 0.8);
}

@Entity_Touch(const this, const pToucher) {
  if (~pev(this, pev_flags) & FL_ONGROUND) return;
  if (!IS_PLAYER(pToucher)) return;

  if (rg_get_weaponbox_id(this) == WEAPON_C4) {
    CE_CallBaseMethod(pToucher);
    return;
  }

  if (@Player_PickupWeaponBoxItems(pToucher, this)) {
    emit_sound(pToucher, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    @Player_PickupWeaponBoxAmmo(pToucher, this);
    set_pev(this, pev_flags, pev(this, pev_flags) | FL_KILLME);
  }
}

/*--------------------------------[ Player Methods ]--------------------------------*/

bool:@Player_PickupWeaponBoxItems(const &this, const &pWeaponBox) {
  new bool:bResult = true;

  for (new iSlot = 0; iSlot < MAX_ITEM_TYPES; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", iSlot);
    if (pItem == FM_NULLENT) continue;

    set_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", FM_NULLENT, iSlot);

    static pPrevItem; pPrevItem = FM_NULLENT;
    while (pItem != FM_NULLENT) {
      static pNextItem; pNextItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");

      set_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext", FM_NULLENT);

      if (@Player_PickupWeaponBoxItem(pWeaponBox, pItem, this)) {
        pItem = FM_NULLENT;
      }

      static pItemToLink; pItemToLink = pItem == FM_NULLENT ? pNextItem : pItem;
      
      if (pPrevItem != FM_NULLENT) {
        set_ent_data_entity(pPrevItem, "CBasePlayerItem", "m_pNext", pItemToLink);
      } else {
        set_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", pItemToLink, iSlot);
      }

      if (pItem != FM_NULLENT) {
        bResult = false;
        pPrevItem = pItem;
      }

      pItem = pNextItem;
    }
  }

  return bResult;
}

bool:@Player_PickupWeaponBoxItem(const &pWeaponBox, const &pItem, const &pPlayer) {
  new iId = get_ent_data(pItem, "CBasePlayerItem", "m_iId");
  
  new pOriginal = @Player_FindItemById(pPlayer, iId);
  if (pOriginal != FM_NULLENT) return false;

  if (!ExecuteHamB(Ham_AddPlayerItem, pPlayer, pItem)) return false;

  ExecuteHamB(Ham_Item_AttachToPlayer, pItem, pPlayer);

  return true;
}

bool:@Player_PickupWeaponBoxAmmo(const &this, const &pWeaponBox) {
  for (new iSlot = 0; iSlot < MAX_AMMO_SLOTS; ++iSlot) {
    static iAmount; iAmount = get_ent_data(pWeaponBox, "CWeaponBox", "m_rgAmmo", iSlot);
    if (!iAmount) continue;

    static iszAmmo; iszAmmo = get_ent_data(pWeaponBox, "CWeaponBox", "m_rgiszAmmo", iSlot);
    if (!iszAmmo) continue;

    static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; engfunc(EngFunc_SzFromIndex, iszAmmo, szAmmo, charsmax(szAmmo));

    if (equal(szAmmo, NULL_STRING)) continue;

    ExecuteHamB(Ham_GiveAmmo, this, iAmount, szAmmo, 255);

    set_ent_data(pWeaponBox, "CWeaponBox", "m_rgAmmo", 0, iSlot);
    set_ent_data(pWeaponBox, "CWeaponBox", "m_rgiszAmmo", 0, iSlot);
  }

  return true;
}

@Player_AddAmmo(const &this, const szAmmo[], iAmount) {
  new bool:bIsCustomAmmo = CW_Ammo_IsRegistered(szAmmo);

  new iAmmoType;
  new iMaxAmount; 

  if (bIsCustomAmmo) {
    iAmmoType = CW_Ammo_GetType(szAmmo);
    iMaxAmount = CW_Ammo_GetMaxAmount(szAmmo);
  } else {
    static pItem; pItem = @Player_FindItemByPrimaryAmmo(this, szAmmo);
    ExecuteHamB(Ham_Item_GetItemInfo, pItem, g_pItemInfo);
    iAmmoType = get_ent_data(pItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
    iMaxAmount = GetHamItemInfo(g_pItemInfo, Ham_ItemInfo_iMaxAmmo1);
  }

  if (iAmmoType == -1) return 0;

  new iCurrentAmount = get_ent_data(this, "CBasePlayer", "m_rgAmmo", iAmmoType);

  ExecuteHamB(Ham_GiveAmmo, this, iAmount, szAmmo, iMaxAmount);

  return get_ent_data(this, "CBasePlayer", "m_rgAmmo", iAmmoType) - iCurrentAmount;
}

@Player_FindItemById(const &this, iId) {
  for (new iSlot = 0; iSlot < MAX_ITEM_TYPES; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(this, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    
    while (pItem != FM_NULLENT) {
      if (iId == get_ent_data(pItem, "CBasePlayerItem", "m_iId")) return pItem;

      pItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");
    }
  }

  return -1;
}

@Player_FindItemByPrimaryAmmo(const &this, const szAmmo[]) {
  for (new iSlot = 0; iSlot < MAX_ITEM_TYPES; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(this, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    
    while (pItem != FM_NULLENT) {
      ExecuteHamB(Ham_Item_GetItemInfo, pItem, g_pItemInfo);

      static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; GetHamItemInfo(g_pItemInfo, Ham_ItemInfo_pszAmmo1, szAmmo, charsmax(szAmmo));
      if (equal(szAmmo, szAmmo)) return pItem;

      pItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");
    }
  }

  return FM_NULLENT;
}
