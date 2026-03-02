#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <snowwars_internal>

#define BIT(%1) (1 << (%1))

#define WEAPON_NAME WEAPON(BaseBlueprint)
#define MEMBER(%1) WEAPON_MEMBER<BaseBlueprint>(%1)
#define METHOD(%1) WEAPON_METHOD<BaseBlueprint>(%1)

#define MAX_DEPLOY_HEIGHT 16.0

/*--------------------------------[ Plugin Variables ]--------------------------------*/

new g_pTrace;
new g_pInstallationPreview = FM_NULLENT;
new g_pCurrentPlayer = FM_NULLENT;

new g_pfwfmUpdateClientData = 0;
new g_pfwfmCheckVisibility = 0;
new g_pfwfmAddToFullPackPost = 0;

/*--------------------------------[ Player State ]--------------------------------*/

new Float:g_rgflPlayerDeployDistances[MAX_PLAYERS + 1];
new Float:g_rgflPlayerDeployHeightSteps[MAX_PLAYERS + 1];
new Float:g_rgvecPlayerDeployMins[MAX_PLAYERS + 1][3];
new Float:g_rgvecPlayerDeployMaxs[MAX_PLAYERS + 1][3];
new Float:g_rgvecPlayerDeployOrigin[MAX_PLAYERS + 1][3];
new Float:g_rgvecPlayerDeployAngles[MAX_PLAYERS + 1][3];
new g_rgiPlayerInstallationModelIndex[MAX_PLAYERS + 1];
new Float:g_rgflPlayerNextUpdate[MAX_PLAYERS + 1];
new bool:g_rgbPlayerCanDeploy[MAX_PLAYERS + 1];
new g_iPlayerPreviewVisibilityBits = 0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();

  CW_RegisterClass(WEAPON_NAME, _, true);

  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Holster, "@Weapon_Holster");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_GetMaxSpeed, "@Weapon_GetMaxSpeed");

  CW_RegisterClassVirtualMethod(WEAPON_NAME, METHOD(Build), "@Weapon_Build");
  CW_RegisterClassVirtualMethod(WEAPON_NAME, METHOD(CreateInstallation), "@Weapon_CreateInstallation");
  CW_RegisterClassMethod(WEAPON_NAME, METHOD(InitInstallationVars), "@Weapon_InitInstallationVars");

  g_pInstallationPreview = CreateInstallationPreview();
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(BaseBlueprint), SW_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public client_connect(pPlayer) {
  @Player_SetPreviewVisibility(pPlayer, false);
}

/*--------------------------------[ Hooks ]--------------------------------*/

public FMHook_UpdateClientData(const pPlayer) {
  g_pCurrentPlayer = pPlayer;

  if (g_iPlayerPreviewVisibilityBits & BIT(pPlayer & 31)) {
    static Float:flGameTime; flGameTime = get_gametime();

    if (g_rgflPlayerNextUpdate[pPlayer] <= flGameTime) {
      @Player_UpdateDeployVars(pPlayer);
      g_rgflPlayerNextUpdate[pPlayer] = flGameTime + 0.1;
    }
  }

  return FMRES_HANDLED;
}

public FMHook_CheckVisibility(const pEntity) {
  if (pEntity == g_pInstallationPreview) {
    forward_return(FMV_CELL, (g_iPlayerPreviewVisibilityBits & BIT(g_pCurrentPlayer & 31)) ? 1 : 0);
    return FMRES_SUPERCEDE;
  }

  return FMRES_IGNORED;
}

public FMHook_AddToFullPack_Post(const es, const e, const pEntity, const pHost, iHostFlags, iPlayer, pSet) {
  if (pEntity != g_pInstallationPreview) return FMRES_IGNORED;

  if (~g_iPlayerPreviewVisibilityBits & BIT(pHost & 31)) return FMRES_SUPERCEDE;

  static Float:vecOrigin[3]; pev(pHost, pev_origin, vecOrigin);
  static Float:vecVelocity[3]; pev(pHost, pev_velocity, vecVelocity);

  if (!g_rgbPlayerCanDeploy[pHost]) {
    set_es(es, ES_RenderColor, {255, 0, 0});
  }

  set_es(es, ES_Origin, g_rgvecPlayerDeployOrigin[pHost]);
  set_es(es, ES_Angles, g_rgvecPlayerDeployAngles[pHost]);
  set_es(es, ES_Velocity, vecVelocity);
  set_es(es, ES_ModelIndex, g_rgiPlayerInstallationModelIndex[pHost]);
  set_es(es, ES_Effects, 0);

  return FMRES_HANDLED;
}

public HamHook_Player_Killed_Post(const pPlayer) {
  @Player_SetPreviewVisibility(pPlayer, false);

  return HAM_HANDLED;
}

/*--------------------------------[ Weapon Methods ]--------------------------------*/

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iFlags, ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
  CW_SetMember(this, CW_Member_iSlot, 3);
  CW_SetMember(this, CW_Member_iDefaultAmmo, 1);
  CW_SetMember(this, CW_Member_bExhaustible, true);

  CW_SetMember(this, MEMBER(flHeightStep), 32.0);
  CW_SetMember(this, MEMBER(flDeployDistance), 64.0);

  CW_CallMethod(this, METHOD(InitInstallationVars));
}

@Weapon_Deploy(const this) {
  if (!CW_CallBaseMethod()) return false;

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  g_rgbPlayerCanDeploy[pPlayer] = false;

  CW_GetMemberVec(this, MEMBER(vecInstallationMins), g_rgvecPlayerDeployMins[pPlayer]);
  CW_GetMemberVec(this, MEMBER(vecInstallationMaxs), g_rgvecPlayerDeployMaxs[pPlayer]);
  g_rgflPlayerDeployHeightSteps[pPlayer] = CW_GetMember(this, MEMBER(flHeightStep));
  g_rgflPlayerDeployDistances[pPlayer] = CW_GetMember(this, MEMBER(flDeployDistance));
  g_rgiPlayerInstallationModelIndex[pPlayer] = CW_GetMember(this, MEMBER(iInstallationModelIndex));

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 0.5);
  CW_SetPlayerAnimation(pPlayer, PLAYER_IDLE);

  return true;
}

@Weapon_Idle(const this) {
  if (!CW_CallBaseMethod()) return false;

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);

  if (!iAmmo) {
    ExecuteHamB(Ham_Weapon_RetireWeapon, this);
    return false;
  }

  @Player_SetPreviewVisibility(pPlayer, true);
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 3.0);

  return true;
}

@Weapon_Holster(const this) {
  CW_CallBaseMethod();

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  @Player_SetPreviewVisibility(pPlayer, false);
}

@Weapon_PrimaryAttack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  if (!g_rgbPlayerCanDeploy[pPlayer]) return false;

  static iShotsFired; iShotsFired = CW_GetMember(this, CW_Member_iShotsFired);
  if (iShotsFired > 0) return false;

  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);

  if (iAmmo <= 0) return false;

  static Float:flGameTime; flGameTime = get_gametime();

  if (CW_CallMethod(this, METHOD(Build))) {
    set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", --iAmmo, iPrimaryAmmoType);
    CW_SetMember(this, CW_Member_iShotsFired, ++iShotsFired);
    CW_SetPlayerAnimation(pPlayer, PLAYER_ATTACK1);
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 0.5);
  }

  CW_SetMember(this, CW_Member_flNextPrimaryAttack, flGameTime + 0.5);
  CW_SetMember(this, CW_Member_flNextSecondaryAttack, flGameTime + 0.5);

  g_rgbPlayerCanDeploy[pPlayer] = false;
  @Player_SetPreviewVisibility(pPlayer, false);

  return true;
}

Float:@Weapon_GetMaxSpeed(const this) {
  return 250.0;
}

@Weapon_InitInstallationVars(const this) {
  new pTestInstallation = CW_CallMethod(this, METHOD(CreateInstallation));

  if (pTestInstallation != FM_NULLENT) {
    static Float:vecMins[3]; CE_GetMemberVec(pTestInstallation, CE_Member_vecMins, vecMins);
    static Float:vecMaxs[3]; CE_GetMemberVec(pTestInstallation, CE_Member_vecMaxs, vecMaxs);
    static szModel[MAX_RESOURCE_PATH_LENGTH]; CE_GetMemberString(pTestInstallation, CE_Member_szModel, szModel, charsmax(szModel));
    
    CW_SetMemberVec(this, MEMBER(vecInstallationMins), vecMins);
    CW_SetMemberVec(this, MEMBER(vecInstallationMaxs), vecMaxs);

    if (!equal(szModel, NULL_STRING)) {
      CW_SetMember(this, MEMBER(iInstallationModelIndex), engfunc(EngFunc_ModelIndex, szModel));
    }

    engfunc(EngFunc_RemoveEntity, pTestInstallation);
  } else {
    CW_SetMemberVec(this, MEMBER(vecInstallationMins), Float:{-16.0, -16.0, 0.0});
    CW_SetMemberVec(this, MEMBER(vecInstallationMaxs), Float:{16.0, 16.0, 72.0});
    CW_SetMember(this, MEMBER(iInstallationModelIndex), 0);
  }
}

bool:@Weapon_Build(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  new pInstallation = CW_CallMethod(this, METHOD(CreateInstallation));
  if (pInstallation == FM_NULLENT) return false;

  CE_SetMemberVec(pInstallation, CE_Member_vecOrigin, g_rgvecPlayerDeployOrigin[pPlayer]);
  // set_pev(pInstallation, pev_origin, g_rgvecPlayerDeployOrigin[pPlayer]);
  set_pev(pInstallation, pev_angles, g_rgvecPlayerDeployAngles[pPlayer]);
  set_pev(pInstallation, pev_owner, pPlayer);
  set_pev(pInstallation, pev_team, get_ent_data(pPlayer, "CBasePlayer", "m_iTeam"));
  dllfunc(DLLFunc_Spawn, pInstallation);

  return true;
}

@Weapon_CreateInstallation(const this) {
  return FM_NULLENT;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_UpdateDeployVars(const &this) {
  static Float:vecAngles[3]; pev(this, pev_v_angle, vecAngles);
  vecAngles[0] = 0.0;
  vecAngles[1] -= 180.0;
  vecAngles[2] = 0.0;

  g_rgbPlayerCanDeploy[this] = @Player_FindDeploymentPos(this, g_rgvecPlayerDeployOrigin[this]);
  xs_vec_copy(vecAngles, g_rgvecPlayerDeployAngles[this]);
}

bool:@Player_FindDeploymentPos(const &this, Float:vecTarget[3]) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(this, pev_v_angle, vecAngles);
  static Float:vecMins[3]; pev(this, pev_mins, vecMins);

  vecAngles[0] = 0.0;
  vecAngles[2] = 0.0;

  static Float:vecSrc[3]; xs_vec_set(vecSrc, vecOrigin[0], vecOrigin[1], vecOrigin[2] + g_rgflPlayerDeployHeightSteps[this]);

  set_pev(g_pInstallationPreview, pev_solid, SOLID_BBOX);
  set_pev(g_pInstallationPreview, pev_mins, g_rgvecPlayerDeployMins[this]);
  set_pev(g_pInstallationPreview, pev_maxs, g_rgvecPlayerDeployMaxs[this]);

  static bool:bCanDeploy; bCanDeploy = true;

  // Check forward direction
  angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecTarget);
  xs_vec_add_scaled(vecSrc, vecTarget, g_rgflPlayerDeployDistances[this], vecTarget);
  engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecSrc, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecSrc);

  // Moving installation to the ground
  xs_vec_set(vecTarget, vecSrc[0], vecSrc[1], vecSrc[2] + vecMins[2] - g_rgflPlayerDeployHeightSteps[this] - MAX_DEPLOY_HEIGHT);
  engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecSrc, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecTarget);

  if (bCanDeploy) {
    // Check if stuck in something
    engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecTarget, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
    bCanDeploy = !!get_tr2(g_pTrace, TR_InOpen);
  }

  if (bCanDeploy) {
    // Can only deploy if on ground
    xs_vec_copy(vecTarget, vecSrc);
    vecSrc[2] -= 1.0;
    engfunc(EngFunc_TraceMonsterHull, g_pInstallationPreview, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, this, g_pTrace);
    bCanDeploy = !get_tr2(g_pTrace, TR_InOpen);
  }

  set_pev(g_pInstallationPreview, pev_solid, SOLID_NOT);

  return bCanDeploy;
}

@Player_SetPreviewVisibility(const &this, bool:bValue) {
  static iOldBits; iOldBits = g_iPlayerPreviewVisibilityBits;

  if (bValue) {
    g_iPlayerPreviewVisibilityBits |= BIT(this & 31);
  } else {
    g_iPlayerPreviewVisibilityBits &= ~BIT(this & 31);
  }

  if (!!iOldBits != !!g_iPlayerPreviewVisibilityBits) {
    if (g_iPlayerPreviewVisibilityBits) {
      if (!g_pfwfmUpdateClientData) {
        g_pfwfmUpdateClientData = register_forward(FM_UpdateClientData, "FMHook_UpdateClientData", 1);
      }

      if (!g_pfwfmCheckVisibility) {
        g_pfwfmCheckVisibility = register_forward(FM_CheckVisibility, "FMHook_CheckVisibility", 0);
      }

      if (!g_pfwfmAddToFullPackPost) {
        g_pfwfmAddToFullPackPost = register_forward(FM_AddToFullPack, "FMHook_AddToFullPack_Post", 1);
      }
      set_pev(g_pInstallationPreview, pev_effects, 0);
    } else {
      unregister_forward(FM_UpdateClientData, g_pfwfmUpdateClientData, 1);
      g_pfwfmUpdateClientData = 0;

      unregister_forward(FM_CheckVisibility, g_pfwfmCheckVisibility, 0);
      g_pfwfmCheckVisibility = 0;

      unregister_forward(FM_AddToFullPack, g_pfwfmAddToFullPackPost, 1);
      g_pfwfmAddToFullPackPost = 0;

      set_pev(g_pInstallationPreview, pev_effects, EF_NODRAW);
    }
  }
}

/*--------------------------------[ Functions ]--------------------------------*/

CreateInstallationPreview() {
  static iszClassname = 0;
  if (!iszClassname) {
    iszClassname = engfunc(EngFunc_AllocString, "info_target");
  }

  new pInstallation = engfunc(EngFunc_CreateNamedEntity, iszClassname);
  dllfunc(DLLFunc_Spawn, pInstallation);
  set_pev(pInstallation, pev_classname, "__sw_blueprint_preview");
  set_pev(pInstallation, pev_solid, SOLID_NOT);
  set_pev(pInstallation, pev_rendermode, kRenderTransTexture);
  set_pev(pInstallation, pev_renderfx, kRenderFxGlowShell);
  set_pev(pInstallation, pev_renderamt, 1.0);
  set_pev(pInstallation, pev_rendercolor, {0.0, 100.0, 255.0});
  set_pev(pInstallation, pev_effects, EF_NODRAW);

  precache_model("models/w_c4.mdl");

  engfunc(EngFunc_SetModel, pInstallation, "models/w_c4.mdl");

  return pInstallation;
}
