#if defined _snowwars_artifacts_included
  #endinput
#endif
#define _snowwars_artifacts_included

#pragma reqlib snowwars_artifacts

native SW_PlayerArtifact_Register(const szId[],const szActivateFunc[],const szDeactivateFunc[]);

native SW_PlayerArtifact_GetHandle(const szId[]);

native bool:SW_PlayerArtifact_Give(const pPlayer, const szId[]);
native bool:SW_PlayerArtifact_Take(const pPlayer, const szId[]);
native bool:SW_PlayerArtifact_TakeAll(const pPlayer);
native bool:SW_PlayerArtifact_TakeBySlot(const pPlayer, iSlot);
native bool:SW_PlayerArtifact_Has(const pPlayer, const szId[]);
native SW_PlayerArtifact_Find(const pPlayer, iOffset, szId[], iLen);
