/*
  1.1.0
    General:
      Reworked mod using AMXX Modding Kit

    Additions and improvements:
      Added "Hot Drink" item
      Added "Fireplace" item
      Added "Shield" item
      Added custom player animations
      Added new sounds
      Reworked fireworks effects
      Increased snowman health
      Players can now have multiple snowmen and surprise boxes
      Firework rockets now explode randomly based on impact angle
      Auto-guidance for snowballs is now ignoring the Z axis
      Reduced snowball attack rate

    Fixes:
      Fixed a bug where snow particles would get stuck in walls
      Fix the attack rate for all weapons
      Fix the exploit when the player can respawn using a snowman after changing team
      Fix win conditions check for the snowman entity
      Players no longer drop the defuser kit on death

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

forward SW_OnConfigLoaded();
