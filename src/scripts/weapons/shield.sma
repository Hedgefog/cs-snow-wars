#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <reapi>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <snowwars_internal>

#define WEAPON_NAME WEAPON(Shield)
#define METHOD(%1) WEAPON_METHOD<Shield>(%1)

#define DEPLOY_HEIGHT_STEP 32.0
#define DEPLOY_DISTANCE 64.0

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];

new g_pTrace;

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Model_View, g_szVModel, charsmax(g_szVModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Model_Player, g_szPModel, charsmax(g_szPModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Model_World, g_szWModel, charsmax(g_szWModel));
  Asset_Precache(SW_AssetLibrary, SW_Asset_Weapon_Shield_Sound_Impact);

  CW_RegisterClass(WEAPON_NAME);

  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_GetMaxSpeed, "@Weapon_GetMaxSpeed");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");

  CW_RegisterClassMethod(WEAPON_NAME, METHOD(HitFeedback), "@Weapon_HitFeedback", CW_Type_Cell, CW_Type_Cell, CW_Type_Cell, CW_Type_Cell);
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Shield), SW_VERSION, "Hedgehog Fog");

  CE_RegisterClassNativeMethodHook(ENTITY(Snowball), CE_Method_Touch, "CEHook_Snowball_Touch");
}

public plugin_end() {
  free_tr2(g_pTrace);
}

public CEHook_Snowball_Touch(const pSnowball, const pToucher) {
  if (!IS_PLAYER(pToucher)) return CE_IGNORED;

  new pActiveItem = get_ent_data_entity(pToucher, "CBasePlayer", "m_pActiveItem");

  if (pActiveItem != FM_NULLENT && CW_IsInstanceOf(pActiveItem, WEAPON_NAME)) {
    static Float:vecOrigin[3]; pev(pToucher, pev_origin, vecOrigin);
    static Float:vecProjectileOrigin[3]; pev(pSnowball, pev_origin, vecProjectileOrigin);
    if (IsBlockedByShield(pToucher, pSnowball)) {
      CW_CallMethod(pActiveItem, METHOD(HitFeedback), pSnowball, pev(pSnowball, pev_owner), 0.0, 0);
      ExecuteHamB(Ham_Killed, pSnowball, pToucher, 0);

      return CE_SUPERCEDE;
    }


    return CE_HANDLED;
  }

  return CE_HANDLED;
}

@Weapon_HitFeedback(const this, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  new pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 21.0 / 35.0);
  rg_set_animation(pPlayer, PLAYER_ATTACK1);

  Asset_EmitSound(pPlayer, CHAN_ITEM, SW_AssetLibrary, SW_Asset_Weapon_Shield_Sound_Impact, .iPitch = 80 + random(20));
}

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iId, SW_WeaponsIds_Shield);
  CW_SetMember(this, CW_Member_iSlot, 1);
  CW_SetMember(this, CW_Member_iPosition, 1);
}

@Weapon_Idle(const this) {
  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 0.1);
}

@Weapon_Deploy(const this) {
  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 1, "shield");
  CW_SetMember(this, CW_Member_flTimeIdle, get_gametime() + 0.1);
}

@Weapon_PrimaryAttack(const this) {
  return true;
}

Float:@Weapon_GetMaxSpeed(const this) {
  return 250.0;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

#define SHIELD_WIDTH 36.0
#define SHIELD_HEIGHT 48.0
#define SHIELD_DISTANCE 16.0
#define SHIELD_OFFSET_Z 16.0

bool:IsBlockedByShield(const &pPlayer, const &pProjectile) {
  static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
  static Float:vecProjectileOrigin[3]; pev(pProjectile, pev_origin, vecProjectileOrigin);
  static Float:vecAbsMin[3]; pev(pPlayer, pev_absmin, vecAbsMin);
  static Float:vecAbsMax[3]; pev(pPlayer, pev_absmax, vecAbsMax);

  static Float:vecHitOrigin[3]; xs_vec_set(
    vecHitOrigin,
    floatclamp(vecProjectileOrigin[0], vecAbsMin[0], vecAbsMax[0]),
    floatclamp(vecProjectileOrigin[1], vecAbsMin[1], vecAbsMax[1]),
    floatclamp(vecProjectileOrigin[2], vecAbsMin[2], vecAbsMax[2])
  );

  // Half of pitch (max 45 degrees)
  vecAngles[0] *= 0.5;

  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

  static Float:vecVelocity[3]; pev(pPlayer, pev_velocity, vecVelocity);
  static Float:vecProjectileVelocity[3]; pev(pProjectile, pev_velocity, vecProjectileVelocity);

  static Float:vecDirection[3];
  xs_vec_sub(vecProjectileVelocity, vecVelocity, vecDirection);
  // xs_vec_sub(vecHitOrigin, vecProjectileOrigin, vecDirection);
  xs_vec_normalize(vecDirection, vecDirection);

  static Float:flDirDot; flDirDot = xs_vec_dot(vecDirection, vecForward);
  if (flDirDot >= 0.0) return false;

  static Float:vecUp[3]; angle_vector(vecAngles, ANGLEVECTOR_UP, vecUp);
  static Float:vecRight[3]; angle_vector(vecAngles, ANGLEVECTOR_RIGHT, vecRight);

  static Float:vecShieldOrigin[3];
  xs_vec_add_scaled(vecOrigin, vecForward, SHIELD_DISTANCE, vecShieldOrigin);
  xs_vec_add_scaled(vecShieldOrigin, vecUp, SHIELD_OFFSET_Z, vecShieldOrigin);

  // static Float:vecDelta[3]; xs_vec_sub(vecProjectileOrigin, vecShieldOrigin, vecDelta);

  // GetHitOriginClampedToPlayerFrame(pPlayer, vecProjectileOrigin, vecForward, vecRight, vecUp, vecHitOrigin, false);

  // static Float:vecProjAbsMin[3]; pev(pProjectile, pev_absmin, vecProjAbsMin);
  // static Float:vecProjAbsMax[3]; pev(pProjectile, pev_absmax, vecProjAbsMax);

  // static Float:vecFrontDir[3]; xs_vec_neg(vecDirection, vecFrontDir);

  static Float:vecDelta[3]; xs_vec_sub(vecProjectileOrigin, vecShieldOrigin, vecDelta);

  // static Float:vecSize[3]; xs_vec_sub(vecAbsMax, vecAbsMin, vecSize);

  // // межі рамки гравця в осях right/up
  // static Float:halfUp; halfUp = 0.5 * ((floatabs(vecUp[0]) * vecSize[0]) + (floatabs(vecUp[1]) * vecSize[1]) + (floatabs(vecUp[2]) * vecSize[2]));
  // static Float:halfRight; halfRight = 0.5 * ((floatabs(vecRight[0]) * vecSize[0]) + (floatabs(vecRight[1]) * vecSize[1]) + (floatabs(vecRight[2]) * vecSize[2]));

  // // clamp x/y до рамки гравця
  // static Float:vecTemp[3];
  // static bool:bStickToShieldPlane = true;
  // xs_vec_set(
  //   vecTemp,
  //   floatclamp(xs_vec_dot(vecDelta, vecRight), -halfRight, halfRight),
  //   floatclamp(xs_vec_dot(vecDelta, vecUp), -halfUp,    halfUp),
  //   bStickToShieldPlane ? 0.0 : xs_vec_dot(vecDelta, vecForward)
  // );

  // // відновити world point
  // vecHitOrigin[0] = vecShieldOrigin[0] + vecRight[0]*vecTemp[0] + vecUp[0]*vecTemp[1] + vecForward[0]*vecTemp[2];
  // vecHitOrigin[1] = vecShieldOrigin[1] + vecRight[1]*vecTemp[0] + vecUp[1]*vecTemp[1] + vecForward[1]*vecTemp[2];
  // vecHitOrigin[2] = vecShieldOrigin[2] + vecRight[2]*vecTemp[0] + vecUp[2]*vecTemp[1] + vecForward[2]*vecTemp[2];

  // client_print(0, print_chat, "%.3f", xs_vec_dot(vecDelta, vecUp));
  // client_print(0, print_chat, "%.3f", xs_vec_dot(vecDelta, vecForward));

  // xs_vec_sub(vecHitOrigin, vecShieldOrigin, vecDelta);

  // Проєктуємо vecHitOrigin на площину щита
  // static Float:vecToPlane[3]; xs_vec_sub(vecHitOrigin, vecShieldOrigin, vecToPlane);
  // static Float:depth; depth = xs_vec_dot(vecToPlane, vecForward);
  // static Float:vecHitOnPlane[3]; xs_vec_sub_scaled(vecHitOrigin, vecForward, depth, vecHitOnPlane);

  // UTIL_DrawLine(vecHitOrigin, vecHitOrigin, {255, 0, 0});

  // Далі тестуємо vecHitOnPlane, а не projectileOrigin
  // xs_vec_sub(vecHitOrigin, vecShieldOrigin, vecDelta);

  if (floatabs(xs_vec_dot(vecDelta, vecUp)) > SHIELD_HEIGHT * 0.5) return false;
  if (floatabs(xs_vec_dot(vecDelta, vecRight)) > SHIELD_WIDTH * 0.5) return false;

  // UTIL_DrawRect(vecShieldOrigin, vecRight, vecUp, Float:{SHIELD_WIDTH, SHIELD_HEIGHT}, {0, 0, 255});

  return true;
}

// Float:AabbAxisHalf(const Float:axis[3], const Float:ext[3])
// {
//     return floatabs(axis[0]) * ext[0]
//          + floatabs(axis[1]) * ext[1]
//          + floatabs(axis[2]) * ext[2];
// }

// GetHitOriginClampedToPlayerFrame(
//     const &pPlayer,
//     const Float:vecProjectileOrigin[3],
//     const Float:vecForward[3],
//     const Float:vecRight[3],
//     const Float:vecUp[3],
//     Float:outHitOrigin[3],
//     bool:stickToPlayerCenterPlane // true => z=0 (чистий 2D clamp), false => зберігаємо depth
// ){
//     static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
//     static Float:vecAbsMin[3]; pev(pPlayer, pev_absmin, vecAbsMin);
//     static Float:vecAbsMax[3]; pev(pPlayer, pev_absmax, vecAbsMax);

//     static Float:vecExt[3];
//     vecExt[0] = (vecAbsMax[0] - vecAbsMin[0]) * 0.5;
//     vecExt[1] = (vecAbsMax[1] - vecAbsMin[1]) * 0.5;
//     vecExt[2] = (vecAbsMax[2] - vecAbsMin[2]) * 0.5;

//     static Float:halfRight; halfRight = AabbAxisHalf(vecRight, vecExt);
//     static Float:halfUp; halfUp    = AabbAxisHalf(vecUp,    vecExt);

//     static Float:vecDelta[3]; xs_vec_sub(vecProjectileOrigin, vecOrigin, vecDelta);

//     static Float:vecTemp[3]; xs_vec_set(
//       vecTemp,
//       floatclamp(xs_vec_dot(vecDelta, vecRight), -halfRight, halfRight),
//       floatclamp(xs_vec_dot(vecDelta, vecUp),    -halfUp,    halfUp),
//       stickToPlayerCenterPlane ? 0.0 : xs_vec_dot(vecDelta, vecForward)
//     );

//     static Float:rgSize[2];
//     rgSize[0] = halfRight * 2;
//     rgSize[1] = halfUp * 2;

//     static Float:vecBoxOrigin[3]; xs_vec_add_scaled(vecOrigin, vecForward, xs_vec_dot(vecDelta, vecForward), vecBoxOrigin);
//     UTIL_DrawRect(vecBoxOrigin, vecRight, vecUp, rgSize, {255, 0, 0});

//     for (new i = 0; i < 3; ++i) {
//       outHitOrigin[i] = vecOrigin[i] + vecRight[i]*vecTemp[0] + vecUp[i]*vecTemp[1] + vecForward[i]*vecTemp[2];
//     }
// }

// Float:GetAabbProjectionHalf(const Float:axis[3], const Float:absMin[3], const Float:absMax[3])
// {
//     static Float:ext[3];
//     ext[0] = (absMax[0] - absMin[0]) * 0.5;
//     ext[1] = (absMax[1] - absMin[1]) * 0.5;
//     ext[2] = (absMax[2] - absMin[2]) * 0.5;

//     return floatabs(axis[0]) * ext[0]
//          + floatabs(axis[1]) * ext[1]
//          + floatabs(axis[2]) * ext[2];
// }

// Float:ProjRadiusOnAxis(const Float:axis[3], const Float:ext[3])
// {
//     return floatabs(axis[0]) * ext[0]
//          + floatabs(axis[1]) * ext[1]
//          + floatabs(axis[2]) * ext[2];
// }

// bool:RayAabbEnterPoint(
//     const Float:rayOrigin[3],
//     const Float:rayDir[3],
//     const Float:boxMin[3],
//     const Float:boxMax[3],
//     Float:outEnter[3]
// ){
//     new Float:tmin = 0.0;
//     new Float:tmax = 999999.0;

//     for (new i = 0; i < 3; i++)
//     {
//         if (floatabs(rayDir[i]) < 0.0001)
//         {
//             // промінь паралельний осі, має бути всередині slab
//             if (rayOrigin[i] < boxMin[i] || rayOrigin[i] > boxMax[i])
//                 return false;
//         }
//         else
//         {
//             new Float:inv = 1.0 / rayDir[i];
//             new Float:t1 = (boxMin[i] - rayOrigin[i]) * inv;
//             new Float:t2 = (boxMax[i] - rayOrigin[i]) * inv;

//             if (t1 > t2) { new Float:tmp = t1; t1 = t2; t2 = tmp; }

//             if (t1 > tmin) tmin = t1;
//             if (t2 < tmax) tmax = t2;

//             if (tmin > tmax) return false;
//         }
//     }

//     // tmin — вхід
//     outEnter[0] = rayOrigin[0] + rayDir[0] * tmin;
//     outEnter[1] = rayOrigin[1] + rayDir[1] * tmin;
//     outEnter[2] = rayOrigin[2] + rayDir[2] * tmin;
//     return true;
// }

// stock UTIL_DrawRect(const Float:vecCenter[3], const Float:vecRight[3], const Float:vecUp[3], const Float:rgSize[2], const rgColor[3]) {
//   static Float:vecLeftTop[3];
//   xs_vec_sub_scaled(vecCenter, vecRight, rgSize[0] * 0.5, vecLeftTop);
//   xs_vec_add_scaled(vecLeftTop, vecUp, rgSize[1] * 0.5, vecLeftTop);

//   static Float:vecRightTop[3];
//   xs_vec_add_scaled(vecCenter, vecRight, rgSize[0] * 0.5, vecRightTop);
//   xs_vec_add_scaled(vecRightTop, vecUp, rgSize[1] * 0.5, vecRightTop);

//   static Float:vecLeftBottom[3];
//   xs_vec_sub_scaled(vecCenter, vecRight, rgSize[0] * 0.5, vecLeftBottom);
//   xs_vec_sub_scaled(vecLeftBottom, vecUp, rgSize[1] * 0.5, vecLeftBottom);

//   static Float:vecRightBottom[3];
//   xs_vec_add_scaled(vecCenter, vecRight, rgSize[0] * 0.5, vecRightBottom);
//   xs_vec_sub_scaled(vecRightBottom, vecUp, rgSize[1] * 0.5, vecRightBottom);

//   UTIL_DrawLine(vecLeftTop, vecRightTop, rgColor);
//   UTIL_DrawLine(vecRightTop, vecRightBottom, rgColor);
//   UTIL_DrawLine(vecRightBottom, vecLeftBottom, rgColor);
//   UTIL_DrawLine(vecLeftBottom, vecLeftTop, rgColor);
// }

stock UTIL_DrawLine(const Float:vecSrc[3], const Float:vecDest[3], const rgColor[3]) {
  message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecSrc);
  write_byte(TE_LINE);
  write_coord_f(vecDest[0]);
  write_coord_f(vecDest[1]);
  write_coord_f(vecDest[2]);
  write_coord_f(vecSrc[0]);
  write_coord_f(vecSrc[1]);
  write_coord_f(vecSrc[2]);
  write_short(10);
  write_byte(rgColor[0]);
  write_byte(rgColor[1]);
  write_byte(rgColor[2]);
  message_end();
}