#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <hamsandwich>
#include <xs>

#include <snowwars>
#include <api_custom_entities>

#define PLUGIN "[Entity] Firework Installation"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ENTITY_NAME "sw_fireworksbox"
#define ROCKET_COUNT 6

new const g_szSndMusic[] = "snowwars/v090/christmas_jingle.wav";

new g_iCeHandler;

public plugin_precache() {
  precache_sound(g_szSndMusic);

  g_iCeHandler = CE_Register(
    .szName = ENTITY_NAME,
    .vMins = Float:{-16.0, -16.0, 0.0},
    .vMaxs = Float:{16.0, 16.0, 32.0},
    .modelIndex = precache_model("models/snowwars/v090/weapons/w_fireworksbox.mdl"),
    .preset = CEPreset_Prop
  );

  CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
  CE_RegisterHook(CEFunction_Remove, ENTITY_NAME, "@Entity_Remove");
  RegisterHam(Ham_Think, CE_BASE_CLASSNAME, "Ham_Base_Think_Post", .Post = 1);
}

public plugin_init() {
  register_plugin(PLUGIN, VERSION, AUTHOR);
}

public @Entity_Spawn(this) {
  set_pev(this, pev_solid, SOLID_TRIGGER);
  set_pev(this, pev_movetype, MOVETYPE_TOSS);
  set_pev(this, pev_iuser4, ROCKET_COUNT);
  engfunc(EngFunc_DropToFloor, this);
  set_pev(this, pev_nextthink, get_gametime() + 7.0);
  emit_sound(this, CHAN_BODY, g_szSndMusic, VOL_NORM * 0.375, ATTN_IDLE, 0, PITCH_NORM);
}

public @Entity_Remove(this) {
  emit_sound(this, CHAN_BODY, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public Ham_Base_Think_Post(this) {
  if (CE_GetHandlerByEntity(this) != g_iCeHandler) {
    return HAM_IGNORED;
  }

  new iRocketCount = pev(this, pev_iuser4);
  
  if (iRocketCount <= 0) {
    CE_Kill(this);
    return HAM_HANDLED;
  }
  
  static Float:vecOrigin[3];
  pev(this, pev_origin, vecOrigin);


  new pRocket = SpawnRocket(vecOrigin, pev(this, pev_owner));
  if (iRocketCount == ROCKET_COUNT) {
    set_pev(this, pev_effects, pev(this, pev_effects) | EF_NODRAW);
    CE_Kill(pRocket);
  }

  set_pev(this, pev_iuser4, iRocketCount - 1);
  set_pev(this, pev_nextthink, get_gametime() + 0.125);

  return HAM_HANDLED;
}

SpawnRocket(const Float:vecOrigin[3], pOwner) {
    new pRocket = CE_Create("sw_fireworkrocket", vecOrigin);

    static Float:vecAngles[3];
    vecAngles[0] = random_float(0.0, 90.0);
    vecAngles[1] = random_float(-180.0, 180.0);
    vecAngles[2] = 0.0;
    set_pev(pRocket, pev_angles, vecAngles);
    set_pev(pRocket, pev_owner, pOwner);

    dllfunc(DLLFunc_Spawn, pRocket);

    return pRocket;
}
