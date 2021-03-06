#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <snowwars>
#include <api_custom_entities>

#define ARTIFACT_ID "downjacket"

new const g_szMdlPArtifact[] = "models/snowwars/v090/artifacts/p_downjacket.mdl";
new const g_szMdlWArtifact[] = "models/snowwars/v090/artifacts/w_downjacket.mdl";
new const g_szEquipArtifactSound[] = "snowwars/v090/pw_shield.wav";

new g_pPlayerJacket[MAX_PLAYERS + 1];

public plugin_precache() {
    precache_model(g_szMdlPArtifact);
    precache_model(g_szMdlWArtifact);
    precache_sound(g_szEquipArtifactSound);

    SW_PlayerArtifact_Register(ARTIFACT_ID, "@Artifact_Activated", "@Artifact_Deactivated");
}

public plugin_init() {
    register_plugin("[Snow Wars] Down Jacket Artifact", SW_VERSION, "Hedgehog Fog");

    register_event("ResetHUD", "Event_ResetHUD", "b");

    CE_RegisterHook(CEFunction_Spawn, "sw_item_artifact", "@ArtifactItem_Spawn");
}

public Event_ResetHUD(pPlayer) {
    @Player_UpdateStatusIcon(pPlayer);
}

public @Artifact_Activated(pPlayer) {
    new Float:flResistance = SW_Player_GetAttribute(pPlayer, SW_PlayerAttribute_Resistance);
    SW_Player_SetAttribute(pPlayer, SW_PlayerAttribute_Resistance, flResistance + 0.5);

    g_pPlayerJacket[pPlayer] = @Jacket_Create(pPlayer);
    @Player_UpdateStatusIcon(pPlayer);
    emit_sound(pPlayer, CHAN_ITEM, g_szEquipArtifactSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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

    engfunc(EngFunc_SetModel, this, g_szMdlWArtifact);
}

public @Player_UpdateStatusIcon(pPlayer) {
    static gmsgStatusIcon = 0;
    if (!gmsgStatusIcon) {
        gmsgStatusIcon = get_user_msgid("StatusIcon");
    }

    if (SW_Player_HasArtifact(pPlayer, ARTIFACT_ID)) {
        message_begin(MSG_ONE, gmsgStatusIcon, {0,0,0}, pPlayer);
        write_byte(1);
        write_string("suit_full");
        write_byte(255);
        write_byte(255);
        write_byte(255);
        message_end();
    } else {
        message_begin(MSG_ONE, gmsgStatusIcon, {0,0,0}, pPlayer);
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
    engfunc(EngFunc_SetModel, pEntity, g_szMdlPArtifact);
    set_pev(pEntity, pev_owner, pPlayer);
    set_pev(pEntity, pev_aiment, pPlayer);
    set_pev(pEntity, pev_movetype, MOVETYPE_FOLLOW);
    set_pev(pEntity, pev_skin, get_member(pPlayer, m_iTeam));

    return pEntity;
}
