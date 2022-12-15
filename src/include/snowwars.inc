/*
  1.0.0
    Additions and improvements:
      Added snowman
      Reduced the max firing pitch for fireworks box rocket
      Reduced surprise box price

    Fixes:
      Fixed weapons secondary attack behavior
      Fixed snowball view model (by Psycrow)
      Fixed fireworks box player model (by Psycrow)
*/

#if defined _snowwars_included
  #endinput
#endif
#define _snowwars_included

#pragma reqlib snowwars

#include <snowwars_const>

enum SW_PlayerAttribute {
  SW_PlayerAttribute_Resistance = 0,
  SW_PlayerAttribute_Power
}

native any:SW_Player_GetAttribute(pPlayer, SW_PlayerAttribute:iAttrib);
native SW_Player_SetAttribute(pPlayer, SW_PlayerAttribute:iAttrib, any:value);

native SW_PlayerArtifact_Register(
  const szId[],
  const szActivateFunc[],
  const szDeactivateFunc[]
);
native SW_PlayerArtifact_GetHandler(const szId[]);

native bool:SW_Player_GiveArtifact(pPlayer, const szId[]);
native bool:SW_Player_TakeArtifact(pPlayer, const szId[]);
native bool:SW_Player_TakeArtifactBySlot(pPlayer, iSlot);
native bool:SW_Player_HasArtifact(pPlayer, const szId[]);
native SW_Player_FindArtifact(pPlayer, iOffset, szId[], iLen);
