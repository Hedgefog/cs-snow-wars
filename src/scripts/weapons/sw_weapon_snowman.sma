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

#define PLUGIN "[Snow Wars] Weapon Snowman"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define AMMO_INDEX 4
#define DEPLOY_HEIGHT_STEP 32.0
#define DEPLOY_DISTANCE 64.0

new CW:g_iCwHandler;
new g_pInstallationPreview = -1;

new Float:g_vecPlayerDeployOrigin[MAX_PLAYERS + 1][3];
new Float:g_vecPlayerDeployAngles[MAX_PLAYERS + 1][3];
new bool:g_bPlayerCanDeploy[MAX_PLAYERS + 1];
new bool:g_bPlayerShowDeployPreview[MAX_PLAYERS + 1];

public plugin_precache() {
    precache_generic(SW_WEAPON_SNOWMAN_HUD_TXT);
    // precache_model(SW_WEAPON_SNOWMAN_V_MODEL);
    // precache_model(SW_WEAPON_SNOWMAN_P_MODEL);
    precache_model(SW_WEAPON_SNOWMAN_W_MODEL);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_iCwHandler = CW_Register(SW_WEAPON_SNOWMAN, CSW_M249, _, AMMO_INDEX, _, _, _, 3, 2, _, "skull", CWF_NoBulletSmoke);
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");


    register_forward(FM_AddToFullPack, "FMForward_AddToFullPack", 0);
    register_forward(FM_AddToFullPack, "FMForward_AddToFullPack_Post", 1);

    InitInstallationPreview();
}

public FMForward_AddToFullPack(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
    if (pEntity != g_pInstallationPreview) {
        return FMRES_IGNORED;
    }

    if (!is_user_alive(pHost)) {
        return FMRES_SUPERCEDE;
    }

    new pActiveItem = get_member(pHost, m_pActiveItem);
    if (pActiveItem == -1 || CW_GetHandlerByEntity(pActiveItem) != g_iCwHandler) {
        return FMRES_SUPERCEDE;
    }

    if (!g_bPlayerShowDeployPreview[pHost]) {
        return FMRES_SUPERCEDE;
    }

    return FMRES_HANDLED;
}

public FMForward_AddToFullPack_Post(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
    if (pEntity != g_pInstallationPreview) {
        return FMRES_IGNORED;
    }

    if (!is_user_alive(pHost)) {
        return FMRES_IGNORED;
    }

    new pActiveItem = get_member(pHost, m_pActiveItem);
    if (pActiveItem == -1 || CW_GetHandlerByEntity(pActiveItem) != g_iCwHandler) {
        return FMRES_IGNORED;
    }

    static Float:vecOrigin[3];
    pev(pHost, pev_origin, vecOrigin);

    set_es(es, ES_Origin, g_vecPlayerDeployOrigin[pHost]);
    set_es(es, ES_Angles, g_vecPlayerDeployAngles[pHost]);

    static Float:vecVelocity[3];
    pev(pHost, pev_velocity, vecVelocity);
    set_es(es, ES_Velocity, vecVelocity);

    set_es(es, ES_Effects, 0);
    // set_es(es, ES_RenderMode, kRenderTransColor);
    set_es(es, ES_RenderMode, kRenderTransTexture);
    set_es(es, ES_RenderFx, kRenderFxGlowShell);
    set_es(es, ES_RenderAmt, 1);


    if (g_bPlayerCanDeploy[pHost]) {
        set_es(es, ES_RenderColor, {0, 255, 0});
    } else {
        set_es(es, ES_RenderColor, {255, 0, 0});
    }

    return FMRES_HANDLED;
}

public @Weapon_Idle(this) {
    new pPlayer = CW_GetPlayer(this);

    static Float:vecAngles[3];
    pev(pPlayer, pev_v_angle, vecAngles);
    vecAngles[0] = 0.0;
    vecAngles[1] -= 180.0;
    vecAngles[2] = 0.0;

    g_bPlayerShowDeployPreview[pPlayer] = true;
    g_bPlayerCanDeploy[pPlayer] = @Player_FindDeploymentPos(pPlayer, g_vecPlayerDeployOrigin[pPlayer]);
    xs_vec_copy(vecAngles, g_vecPlayerDeployAngles[pPlayer]);

    set_member(this, m_Weapon_flTimeWeaponIdle, 0.1);
}

public @Weapon_Deploy(this) {
    new pPlayer = CW_GetPlayer(this);
    CW_DefaultDeploy(this, SW_WEAPON_SNOWMAN_V_MODEL, SW_WEAPON_SNOWMAN_P_MODEL, 0, "c4");
    set_member(this, m_Weapon_flTimeWeaponIdle, 0.1);
    g_bPlayerCanDeploy[pPlayer] = false;
    g_bPlayerShowDeployPreview[pPlayer] = false;
}

public @Weapon_PrimaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);
    if (!g_bPlayerCanDeploy[pPlayer]) {
        return;
    }

    new iShotsFired = get_member(this, m_Weapon_iShotsFired);
    if (iShotsFired > 0) {
        return;
    }

    new iAmmo = get_member(pPlayer, m_rgAmmo, AMMO_INDEX);
    if (iAmmo <= 0) {
        return;
    }

    @Player_DeploySnowman(pPlayer);

    set_member(pPlayer, m_rgAmmo, --iAmmo, AMMO_INDEX);
    set_member(this, m_Weapon_iShotsFired, ++iShotsFired);
    
    if (iAmmo <= 0) {
        SetThink(this, "RemovePlayerItem");
        set_pev(this, pev_nextthink, get_gametime() + 0.1);
    }

    set_member(this, m_Weapon_flNextPrimaryAttack, 0.5);
    set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);

    g_bPlayerCanDeploy[pPlayer] = false;
    g_bPlayerShowDeployPreview[pPlayer] = false;
}

public Float:@Weapon_GetMaxSpeed(this) {
    return 250.0;
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
    engfunc(EngFunc_SetModel, pWeaponBox, SW_WEAPON_SNOWMAN_W_MODEL);
}

public @Player_DeploySnowman(this) {
    new pInstallation = CE_Create("sw_snowman", g_vecPlayerDeployOrigin[this]);
    set_pev(pInstallation, pev_owner, this);
    set_pev(pInstallation, pev_angles, g_vecPlayerDeployAngles[this]);
    set_pev(pInstallation, pev_team, get_member(this, m_iTeam));
    dllfunc(DLLFunc_Spawn, pInstallation);
}

InitInstallationPreview() {
    static Float:vecMins[3];
    static Float:vecMaxs[3];
    CE_GetSize("sw_snowman", vecMins, vecMaxs);

    g_pInstallationPreview = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    set_pev(g_pInstallationPreview, pev_mins, vecMins);
    set_pev(g_pInstallationPreview, pev_maxs, vecMaxs);
    set_pev(g_pInstallationPreview, pev_solid, SOLID_BBOX);
    set_pev(g_pInstallationPreview, pev_modelindex, CE_GetModelIndex("sw_snowman"));
    set_pev(g_pInstallationPreview, pev_flags, EF_NODRAW);
    dllfunc(DLLFunc_Spawn, g_pInstallationPreview);
}

bool:@Player_FindDeploymentPos(this, Float:vecOut[3]) {
    new bool:bCanDeploy = true;

    new pTr = create_tr2();

    static Float:vecSrc[3];
    static Float:vecTarget[3];

    if (bCanDeploy) {
        pev(this, pev_origin, vecSrc);
        vecSrc[2] += DEPLOY_HEIGHT_STEP;

        static Float:vecAngles[3];
        pev(this, pev_v_angle, vecAngles);
        vecAngles[0] = 0.0;
        vecAngles[2] = 0.0;

        angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecTarget);
        xs_vec_add_scaled(vecSrc, vecTarget, DEPLOY_DISTANCE, vecTarget);

        // engfunc(EngFunc_TraceLine, vecSrc, vecTarget, DONT_IGNORE_MONSTERS, HULL_HEAD, this, pTr);
        engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecSrc, vecTarget, DONT_IGNORE_MONSTERS, this, pTr);

        static Float:flFraction;
        get_tr2(pTr, TR_flFraction, flFraction);

        if (flFraction != 1.0) {
            get_tr2(pTr, TR_vecEndPos, vecTarget);
        }
    }

    // move down and check hull
    if (bCanDeploy) {
        static Float:vecOrigin[3];
        pev(this, pev_origin, vecOrigin);

        static Float:vecMins[3];
        pev(this, pev_mins, vecMins);

        xs_vec_copy(vecTarget, vecSrc);
        vecTarget[2] = vecOrigin[2] + vecMins[2] - DEPLOY_HEIGHT_STEP;
        engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecSrc, vecTarget, DONT_IGNORE_MONSTERS, this, pTr);

        static Float:flFraction;
        get_tr2(pTr, TR_flFraction, flFraction);

        if (flFraction != 1.0) {
            get_tr2(pTr, TR_vecEndPos, vecTarget);
        }
    }

    // check if stuck
    if (bCanDeploy) {
        engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecTarget, vecTarget, DONT_IGNORE_MONSTERS, this, pTr);
        bCanDeploy = !!get_tr2(pTr, TR_InOpen);
    }

    // can deploy only if on ground
    if (bCanDeploy) {
        xs_vec_copy(vecTarget, vecSrc);
        vecSrc[2] -= 1.0;
        engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, this, pTr);
        bCanDeploy = !get_tr2(pTr, TR_InOpen);
    }

    xs_vec_copy(vecTarget, vecOut);

    free_tr2(pTr);

    return bCanDeploy;
}

public RemovePlayerItem(this) {
    CW_RemovePlayerItem(this);
}
