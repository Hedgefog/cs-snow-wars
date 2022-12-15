#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <snowwars>
#include <api_custom_entities>

new Float:g_vecSpawnRocketOrigin[3];

#define PLUGIN "[Snow Wars] Bomb"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHookChain(RG_CGrenade_ExplodeBomb, "HC_Grenade_ExplodeBomb", .post = 0);
}

public HC_Grenade_ExplodeBomb(pGrenade) {
    set_member(pGrenade, m_Grenade_bJustBlew, true);
    set_member_game(m_bTargetBombed, true);
    rg_check_win_conditions();

    pev(pGrenade, pev_origin, g_vecSpawnRocketOrigin);

    CE_Kill(SpawnRocket(g_vecSpawnRocketOrigin));

    for (new i = 0; i < 8; ++i) {
        set_task(0.125 * i, "Task_SpawnRocket");
    }

    set_pev(pGrenade, pev_flags, pev(pGrenade, pev_flags) | FL_KILLME);
    // dllfunc(DLLFunc_Think, pGrenade);

    return HC_SUPERCEDE;
}

public Task_SpawnRocket() {
    SpawnRocket(g_vecSpawnRocketOrigin);
}

SpawnRocket(const Float:vecOrigin[3]) {
    new pRocket = CE_Create("sw_fireworkrocket", vecOrigin);

    static Float:vecAngles[3];
    vecAngles[0] = random_float(0.0, 90.0);
    vecAngles[1] = random_float(-180.0, 180.0);
    vecAngles[2] = 0.0;
    set_pev(pRocket, pev_angles, vecAngles);

    dllfunc(DLLFunc_Spawn, pRocket);

    return pRocket;
}
