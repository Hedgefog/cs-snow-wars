#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <snowwars>
#include <api_custom_entities>

#define PLUGIN "[Snow Wars] Down Jacket Artifact"
#define VERSION SW_VERSION
#define AUTHOR "Hedgehog Fog"

#define ARTIFACT_ID SW_ARTIFACT_DOWNJACKET

new g_pPlayerJacket[MAX_PLAYERS + 1];

public plugin_precache() {
    precache_model(SW_ARTIFACT_DOWNJACKET_P_MODEL);
    precache_model(SW_ARTIFACT_DOWNJACKET_W_MODEL);
    precache_sound(SW_SOUND_DOWNJACKET);

    SW_PlayerArtifact_Register(ARTIFACT_ID, "@Artifact_Activated", "@Artifact_Deactivated");
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_event("ResetHUD", "Event_ResetHUD", "b");
    RegisterHam(Ham_Spawn, "player", "Ham_Player_Spawn", .Post = 1);

    CE_RegisterHook(CEFunction_Spawn, "sw_item_artifact", "@ArtifactItem_Spawn");
}

public Ham_Player_Spawn(pPlayer) {
    if (g_pPlayerJacket[pPlayer]) {
        set_pev(g_pPlayerJacket[pPlayer], pev_skin, get_member(pPlayer, m_iTeam));
    }
}

public Event_ResetHUD(pPlayer) {
    @Player_UpdateStatusIcon(pPlayer);
}

public @Artifact_Activated(pPlayer) {
    new Float:flResistance = SW_Player_GetAttribute(pPlayer, SW_PlayerAttribute_Resistance);
    SW_Player_SetAttribute(pPlayer, SW_PlayerAttribute_Resistance, flResistance + 0.5);

    g_pPlayerJacket[pPlayer] = @Jacket_Create(pPlayer);
    @Player_UpdateStatusIcon(pPlayer);
    emit_sound(pPlayer, CHAN_ITEM, SW_SOUND_DOWNJACKET, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public @Artifact_Deactivated(pPlayer) {
    new Float:flResistance = SW_Player_GetAttribute(pPlayer, SW_PlayerAttribute_Resistance);
    SW_Player_SetAttribute(pPlayer, SW_PlayerAttribute_Resistance, flResistance - 0.5);

    if (g_pPlayerJacket[pPlayer]) {
        engfunc(EngFunc_RemoveEntity, g_pPlayerJacket[pPlayer]);
        g_pPlayerJacket[pPlayer] = 0;
    }

    @Player_UpdateStatusIcon(pPlayer);
}

public @ArtifactItem_Spawn(this) {
    static szId[16];
    pev(this, pev_target, szId, charsmax(szId));
    if (!equal(szId, ARTIFACT_ID)) {
        return;
    }

    engfunc(EngFunc_SetModel, this, SW_ARTIFACT_DOWNJACKET_W_MODEL);
}

public @Player_UpdateStatusIcon(this) {
    static gmsgStatusIcon = 0;
    if (!gmsgStatusIcon) {
        gmsgStatusIcon = get_user_msgid("StatusIcon");
    }

    if (SW_Player_HasArtifact(this, ARTIFACT_ID)) {
        message_begin(MSG_ONE, gmsgStatusIcon, {0,0,0}, this);
        write_byte(1);
        write_string("suit_full");
        write_byte(255);
        write_byte(255);
        write_byte(255);
        message_end();
    } else {
        message_begin(MSG_ONE, gmsgStatusIcon, {0,0,0}, this);
        write_byte(0);
        write_string("suit_full");
        message_end();
    }
}

public @Jacket_Create(pPlayer) {
    static s_ptrClassname = 0;
    if (!s_ptrClassname) {
        s_ptrClassname = engfunc(EngFunc_AllocString, "info_target");
    }

    new pEntity = engfunc(EngFunc_CreateNamedEntity, s_ptrClassname);
    dllfunc(DLLFunc_Spawn, pEntity);

    set_pev(pEntity, pev_classname, "player_downjacket");
    engfunc(EngFunc_SetModel, pEntity, SW_ARTIFACT_DOWNJACKET_P_MODEL);
    set_pev(pEntity, pev_owner, pPlayer);
    set_pev(pEntity, pev_aiment, pPlayer);
    set_pev(pEntity, pev_movetype, MOVETYPE_FOLLOW);
    set_pev(pEntity, pev_skin, get_member(pPlayer, m_iTeam));

    return pEntity;
}
