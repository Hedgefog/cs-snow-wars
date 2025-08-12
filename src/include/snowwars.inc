/*
  1.1.0
    General:
      Reworked mod using AMXX Modding Kit

    Additions and improvements:
      Reduced snowball attack rate 
      Players can now have multiple snowmans and surprise boxes
      Firework rockets are now explode randomly based on impact angle
      Increased snowman health
      Auto-guidance for snowballs is now ignoring Z axis

    Fixes:
      Fix attack rate for all weapons
      Fix exploit when player can respawn using snowman after changing team
      Fix win conditions check for snowman entity
      Players are no longer drop defuser kit on death

  1.0.0
    Additions and improvements:
      Added snowman
      Increased Lemon Juice splash damage
      CTs team now has a defuse kit by default
      Reduced the max firing pitch for fireworks box rocket
      Reduced surprise box price

    Fixes:
      Fixed a bug where the down jacket had the wrong skin after auto team change
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
