#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>

#include <snowwars>
#include <api_custom_weapons>
#include <api_custom_entities>

#define PLUGIN "[Snow Wars] Weapon Fireworks Box"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

new CW:g_iCwHandler;

public plugin_precache() {
    precache_generic(SW_WEAPON_FIREWORKSBOX_HUD_TXT);
    precache_model(SW_MODEL_WEAPON_FIREWORKSBOX_V);
    precache_model(SW_MODEL_WEAPON_FIREWORKSBOX_P);
    precache_model(SW_MODEL_WEAPON_FIREWORKSBOX_W);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_iCwHandler = CW_Register(SW_WEAPON_FIREWORKSBOX, CSW_FAMAS, _, _, _, _, _, 4, 1, _, "skull", CWF_NoBulletSmoke);
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_Holster, "@Weapon_Holster");
    CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_SecondaryAttack, "@Weapon_SecondaryAttack");
    CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
}

public @Weapon_Idle(this) {
    set_member(this, m_Weapon_flTimeWeaponIdle, 0.5);
}

public @Weapon_Deploy(this) {
    // new pPlayer = CW_GetPlayer(this);
    CW_DefaultDeploy(this, SW_MODEL_WEAPON_FIREWORKSBOX_V, SW_MODEL_WEAPON_FIREWORKSBOX_P, 0, "c4");
}

public @Weapon_PrimaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);

    static Float:vecOrigin[3];
    ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecOrigin);

    static Float:vecAngles[3];
    pev(pPlayer, pev_v_angle, vecAngles);
    vecAngles[0] = 0.0;
    vecAngles[2] = 0.0;

    new pInstallation = CE_Create("sw_fireworksbox", vecOrigin);
    set_pev(pInstallation, pev_owner, pPlayer);
    set_pev(pInstallation, pev_angles, vecAngles);
    dllfunc(DLLFunc_Spawn, pInstallation);

    CW_RemovePlayerItem(this);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
    engfunc(EngFunc_SetModel, pWeaponBox, SW_MODEL_WEAPON_FIREWORKSBOX_W);
}

public Float:@Weapon_GetMaxSpeed(this) {
    return 250.0;
}

public RemovePlayerItem(this) {
    CW_RemovePlayerItem(this);
}
