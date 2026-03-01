#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_assets>
#include <api_custom_entities>

#include <snowwars_internal>

#define ENTITY_NAME ENTITY(FireworkEffect)
#define MEMBER(%1) ENTITY_MEMBER<FireworkEffect>(%1)
#define METHOD(%1) ENTITY_METHOD<FireworkEffect>(%1)

new g_szFireworkSprite[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Entity_FireworkEffect_Model), g_szFireworkSprite, charsmax(g_szFireworkSprite));
  Asset_Precache(ASSET_LIBRARY, ASSET(Entity_FireworkEffect_Sound_Explosion));

  CE_RegisterClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");

  CE_RegisterClassMethod(ENTITY_NAME, METHOD(Play), "@Entity_Play");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(FireworkEffect), SW_VERSION, "Hedgehog Fog");
}

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberString(this, CE_Member_szModel, g_szFireworkSprite);
  CE_SetMember(this, CE_Member_bForceVisible, true);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  CE_SetThink(this, METHOD(Play));

  set_pev(this, pev_nextthink, get_gametime()); 
}

@Entity_Play(const this) { 
  static Float:rgflColor[3]; pev(this, pev_rendercolor, rgflColor);
  static Float:flScale; pev(this, pev_scale, flScale);

  set_pev(this, pev_rendermode, kRenderTransAlpha);
  set_pev(this, pev_renderamt, 200.0);
  set_pev(this, pev_animtime, get_gametime());
  set_pev(this, pev_framerate, 16.0);
  set_pev(this, pev_frame, 0.0);

  CE_SetMember(this, MEMBER(iFramesNum), 16);

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_DLIGHT);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  write_byte(min(floatround(64 * flScale), 255));
  write_byte(floatround(rgflColor[0]));
  write_byte(floatround(rgflColor[1]));
  write_byte(floatround(rgflColor[2]));
  write_byte(10);
  write_byte(30);
  message_end();

  Asset_EmitSound(this, CHAN_STATIC, ASSET_LIBRARY, ASSET(Entity_FireworkEffect_Sound_Explosion), .iPitch = 90 + random(30), .flAttenuation = 0.25);

  CE_SetThink(this, NULL_STRING);

  set_pev(this, pev_ltime, get_gametime());
  set_pev(this, pev_nextthink, get_gametime()); 
}

@Entity_Think(const this) {
  CE_CallBaseMethod();

  static Float:flLastThink; pev(this, pev_ltime, flLastThink);
  static Float:flDelta; flDelta = flLastThink ? get_gametime() - flLastThink : 0.0;
  static Float:flFrame; pev(this, pev_frame, flFrame);
  static Float:flFrameRate; pev(this, pev_framerate, flFrameRate);
  static iFramesNum; iFramesNum = CE_GetMember(this, MEMBER(iFramesNum));
  static Float:flScale; pev(this, pev_scale, flScale);

  flFrame += flFrameRate * flDelta;

  if (flFrame >= float(iFramesNum)) {
    ExecuteHamB(Ham_Killed, this, 0, 0);
    return;
  }

  set_pev(this, pev_frame, flFrame);

  set_pev(this, pev_scale, flScale + (2.0 * flDelta));

  set_pev(this, pev_nextthink, get_gametime() + 0.0125);
  set_pev(this, pev_ltime, get_gametime());
}
