class VirtualizationSystem {
    file = "\z\flo\addons\main\Functions\Virtualization\System";

    class initVirtualization          {};
    class virtualizationCreateUpdateState {};
    class virtualizationUpdatePFH     {};
    class virtualizationEnsureUpdateState {};
    class virtualizationGetUpdateStatsDefaults {};
    class virtualizationGetUpdatePerfDefaults {};
    class virtualizationCachePlayers  {};
    class virtualizationRefreshPlayerCache {};
    class virtualizationReconcileTransportState {};
    class virtualizationRefreshCachedGroups {};
    class virtualizationGetNearestCachedPlayerDistance {};
    class virtualizationIsPositionWithinActivationRange {};
    class virtualizationIsValidPosition {};
    class virtualizationResetBatchStats {};
    class virtualizationResetUpdateStats {};
    class virtualizationProcessGroupBatch {};
    class virtualizationLogSlowBatch {};
    class virtualizationRunUpdateCycle {};
    class virtualizationValidateUpdateState {};
};

class VirtualizationRegistry {
    file = "\z\flo\addons\main\Functions\Virtualization\Registry";

    class virtualizationCreateRegistry          {};
    class virtualizationCreateArchetype         {};
    class virtualizationCreateArchetypeCatalog  {};
    class virtualizationGetArchetype            {};
    class virtualizationRequireRegistry         {};
    class virtualizationGetGroupMap             {};
    class virtualizationGetConfigValue          {};
    class virtualizationSetConfigValue          {};
    class virtualizationGetSpatialState         {};
    class virtualizationCreateGroupRecordDefaults {};
    class virtualizationRequireGroup            {};
    class virtualizationFindGroup               {};
    class virtualizationFindGroupSnapshot       {};
    class virtualizationCloneValue              {};
    class virtualizationSnapshotGroup           {};
    class virtualizationPatchGroup              {};
    class virtualizationTouchRegistry           {};
    class createVirtualGroup              {};
    class virtualizationGenerateGroupId   {};
    class virtualizationBuildGroupData    {};
    class virtualizationSelectInitialAssetComposition {};
    class virtualizationGetOrganicPackageInfantryCount {};
    class virtualizationGetOrganicPackageInfantryCounts {};
    class virtualizationCreateOrganicPackageDismount {};
    class virtualizationRollbackOrganicPackageCreation {};
    class virtualizationSetEnabled       {};
    class virtualizationGetGroup         {};
    class virtualizationQueryGroupIds    {};
    class virtualizationAddGroup         {};
    class virtualizationRemoveGroup      {};
    class virtualizationUpdateOwnedGroupPosition {};
    class virtualizationUpdateGroupPosition {};
};

class VirtualizationIndex {
    file = "\z\flo\addons\main\Functions\Virtualization\Index";

    class virtualizationCreateSpatialState      {};
    class virtualizationSpatialIndex             {};
    class virtualizationSpatialInit              {};
    class virtualizationSpatialAdd               {};
    class virtualizationSpatialRemove            {};
    class virtualizationSpatialUpdate            {};
    class virtualizationSpatialQuery             {};
    class virtualizationSpatialQueryRadius       {};
    class virtualizationSpatialRebuild           {};
    class virtualizationSpatialGetCellKey        {};
    class virtualizationSpatialGetCellsInRadius  {};
    class virtualizationSpatialGetSideKey        {};
    class virtualizationSpatialRemoveFromGrid    {};
};

class VirtualizationLifecycle {
    file = "\z\flo\addons\main\Functions\Virtualization\Lifecycle";

    class activateVirtualGroup             {};
    class virtualizationTryActivateGroup   {};
    class deactivateVirtualGroup           {};
    class activateSavedVirtualGroup        {};
    class virtualizationCollectRealGroupVehicles {};
    class virtualizationConvertAssetCrewToInfantryRemnant {};
    class virtualizationDeactivateMountedPassengerGroup {};
    class virtualizationDeactivateMountedPassengers {};
    class virtualizationResolveTransportPassengerCasualty {};
    class virtualizationCaptureRealGroupPosition {};
    class virtualizationCaptureRealGroupRuntimeState {};
    class virtualizationCaptureRealGroupWaypoints {};
    class virtualizationDeleteRealGroupAssets {};
    class virtualizationForceActivateGroup {};
    class virtualizationCreateRealGroup {};
    class virtualizationResolveActiveStraggler {};
    class virtualizationRequirePoolEntries {};
    class virtualizationGetGroundCombatVehiclePool {};
    class virtualizationResolveCrewType    {};
    class virtualizationResolveGroundSpawnPos {};
    class virtualizationIsGroundSpawnPositionSafe {};
    class virtualizationSyncRealGroupOutcome {};
    class virtualizationAssignIntelItem {};
    class virtualizationCreateCrewedVehicle {};
    class virtualizationParkIdleHelicopter {};
    class virtualizationResolveIdleHelicopterParkPos {};
    class virtualizationSpawnFromComposition {};
    class virtualizationSpawnInfantryGroup {};
    class virtualizationSpawnGroundCombatGroup {};
    class virtualizationSpawnAirGroup      {};
    class virtualizationSpawnArtilleryGroup {};
    class virtualizationSpawnStaticAAGroup {};
    class virtualizationGetSpawnPools      {};
    class virtualizationGetRemainingWaypoints {};
    class virtualizationSpawnRealGroup     {};
    class virtualizationLoadTransportPassengers {};
    class virtualizationDistributeIntelItems {};
};

class VirtualizationRouting {
    file = "\z\flo\addons\main\Functions\Virtualization\Routing";

    class virtualizationApplyDirectWaypointUpdate {};
    class updateVirtualGroupWaypoints      {};
    class virtualizationApplyRealRoute     {};
    class virtualizationRequestPathRouteUpdate {};
    class virtualizationRefreshCurrentWaypointSpeed {};
    class virtualizationResolveMovePlatformClass {};
    class virtualizationResolveMoveSpeedMps {};
    class virtualizationSanitizeWaypoints  {};
    class virtualizationComputeVirtualSpeed {};
    class virtualizationSetRouteState      {};
    class virtualizationApplyBootstrapWaypoint {};
    class virtualizationHandlePathResolved {};
};

class VirtualizationCore {
    file = "\z\flo\addons\main\Functions\Virtualization\Core";

    class virtualizationScheduleNextProcess {};
    class virtualizationAdvanceDefaultWaypoint {};
    class virtualizationAdvanceLoiterWaypoint {};
    class virtualizationAdvanceTerminalWaypoint {};
    class virtualizationRepairOrphanedActiveGroup {};
    class virtualizationProcessAttachedGroup {};
    class virtualizationProcessInactiveMovement {};
    class virtualizationProcessActivationState {};
    class virtualizationProcessActiveState {};
    class virtualizationProcessGroup    {};
    class virtualizationAdvanceWaypoint {};
};

class VirtualizationLogic {
    file = "\z\flo\addons\main\Functions\Virtualization\Logic";

    class virtualizationCanAutoPatrol  {};
    class virtualizationBuildPatrolPlan {};
    class virtualizationAssignAutoPatrol {};
};

class VirtualizationState {
    file = "\z\flo\addons\main\Functions\Virtualization\State";

    class virtualizationGetPersistentFields {};
    class virtualizationValidateGroup {};
    class virtualizationValidateSavedGroup {};
    class virtualizationValidateRegistry {};
    class virtualizationMigrateSavedGroup {};
    class virtualizationSerializeRegistry {};
    class virtualizationRestoreRegistry {};
    class virtualizationRebuildDerivedState {};
    class virtualizationGetEffectiveState {};
    class virtualizationSetAssetComposition {};
    class virtualizationSetAssetCompositionById {};
    class virtualizationClearCommanderOrder {};
    class virtualizationSetCommanderOrder {};
    class virtualizationCommitCommanderOrder {};
    class virtualizationAssignMoveOrder {};
    class virtualizationAssignAttackOrder {};
    class virtualizationAssignDefendOrder {};
    class virtualizationAssignGarrisonOrder {};
    class virtualizationRefreshDefendLease {};
    class virtualizationSetMissionLock {};
    class virtualizationClearMissionLock {};
    class virtualizationSetExecutionState {};
    class virtualizationClearExecutionState {};
    class virtualizationSetRuntimeState {};
    class virtualizationSetRealGroup {};
    class virtualizationClearRealGroup {};
    class virtualizationSetRealVehicles {};
    class virtualizationClearRealVehicles {};
    class virtualizationSetAADeployState {};
    class virtualizationClearAADeployState {};
    class virtualizationGetAADeployState {};
    class virtualizationGetAATargetPos {};
    class virtualizationGetAATargetObjective {};
    class virtualizationSetPendingPathRequest {};
    class virtualizationClearPathRequest {};
    class virtualizationSetTransportAttachment {};
    class virtualizationClearTransportAttachment {};
    class virtualizationSetTransportPassengers {};
    class virtualizationAddTransportPassenger {};
    class virtualizationRemoveTransportPassenger {};
    class virtualizationGetTransportAttachment {};
    class virtualizationGetTransportPassengers {};
    class virtualizationIsTransportCarrier {};
    class virtualizationSetMountedIn {};
    class virtualizationClearMountedIn {};
    class virtualizationGetMountedTransport {};
    class virtualizationTransportChainContains {};
    class virtualizationLinkTransportGroups {};
    class virtualizationUnlinkTransportGroups {};
    class virtualizationPruneTransportPassenger {};
    class virtualizationSetMountedTransportById {};
    class virtualizationFinalizeReinforcement {};
    class virtualizationResumeSavedRoutes {};
    class virtualizationMarkReinforcementTransit {};
    class virtualizationMarkStaticAAReplacementTransit {};
    class virtualizationClearReplacementTransit {};
    class virtualizationSerializeGroup {};
    class virtualizationRestoreSavedGroup {};
    class virtualizationRestoreCommanderState {};
    class virtualizationRestoreMissionState {};
    class virtualizationRestorePathState {};
    class virtualizationRestoreAAState {};
    class virtualizationRestoreTransportState {};
    class virtualizationRestoreReplacementState {};
};

class VirtualizationDebug {
    file = "\z\flo\addons\main\Functions\Virtualization\Debug";

    class virtualizationCreateDebugState   {};
    class virtualizationDebugManager      {};
    class virtualizationDebugRunBatch      {};
    class virtualizationProbe             {};
    class virtualizationProbeOwnership    {};
    class virtualizationWarnSuspiciousActivation {};
    class virtualizationDebugUpdateMarker {};
};

class VirtualizationUtilities {
    file = "\z\flo\addons\main\Functions\Virtualization\Utilities";

    class filterNonCivGroups      {};
    class getGroupTypeCount       {};
    class getRoadParkingPos       {};
    class getSafeLandPos          {};
    class getSafeUnvirtualizePos  {};
    class virtualizationNormalizePosition {};
    class virtualizationEstimateVehicleCrewCount {};
    class virtualizationGetGroupUnitLoad {};
    class virtualizationGetRealAssetVehicles {};
    class virtualizationUsesAssetStrength {};
    class validateGroupPosition   {};
};
