class VirtualizationSystem {
    file = "Functions\Virtualization\System";

    class initVirtualization          {};
    class virtualizationCreateEventHandlerState {};
    class virtualizationCreateUpdateState {};
    class virtualizationUpdatePFH     {};
    class virtualizationEvents        {};
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
    class virtualizationRegisterEventHandlers {};
    class virtualizationRemoveEventHandlers {};
    class virtualizationResetBatchStats {};
    class virtualizationResetUpdateStats {};
    class virtualizationProcessGroupBatch {};
    class virtualizationLogSlowBatch {};
    class virtualizationRunUpdateCycle {};
    class virtualizationValidateUpdateState {};
};

class VirtualizationSeeding {
    file = "Functions\Virtualization\Seeding";

    class initializeObjectiveGroups {};
    class initializeTransportReserveGroups {};
    class distributeVirtualGroups   {};
};

class VirtualizationRegistry {
    file = "Functions\Virtualization\Registry";

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
    class virtualizationAddGroup         {};
    class virtualizationRemoveGroup      {};
    class virtualizationUpdateGroupPosition {};
    class virtualizationReserveGroup     {};
    class virtualizationReleaseGroup     {};
    class virtualizationGetGroupsBy      {};
};

class VirtualizationIndex {
    file = "Functions\Virtualization\Index";

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
    file = "Functions\Virtualization\Lifecycle";

    class activateVirtualGroup             {};
    class virtualizationTryActivateGroup   {};
    class deactivateVirtualGroup           {};
    class activateSavedVirtualGroup        {};
    class virtualizationCollectRealGroupVehicles {};
    class virtualizationDeactivateMountedPassengerGroup {};
    class virtualizationDeactivateMountedPassengers {};
    class virtualizationCaptureRealGroupPosition {};
    class virtualizationCaptureRealGroupRuntimeState {};
    class virtualizationCaptureRealGroupWaypoints {};
    class virtualizationDeleteRealGroupAssets {};
    class virtualizationRequirePoolEntries {};
    class virtualizationGetGroundCombatVehiclePool {};
    class virtualizationResolveCrewType    {};
    class virtualizationResolveGroundSpawnPos {};
    class virtualizationSyncRealGroupOutcome {};
    class virtualizationCreateCrewedVehicle {};
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
    file = "Functions\Virtualization\Routing";

    class virtualizationApplyDirectWaypointUpdate {};
    class updateVirtualGroupWaypoints      {};
    class virtualizationApplyRealRoute     {};
    class virtualizationRequestPathRouteUpdate {};
    class virtualizationSanitizeWaypoints  {};
    class virtualizationComputeVirtualSpeed {};
    class virtualizationSetRouteState      {};
    class virtualizationApplyBootstrapWaypoint {};
    class virtualizationHandlePathResolved {};
};

class VirtualizationTransport {
    file = "Functions\Virtualization\Transport";

    class transportConfig       {};
    class transportGetCapacity  {};
    class transportGetGroupCapacity {};
    class transportGetPassengerLoad {};
    class transportGetTrackedGroup {};
    class transportHasKnownEnemyNearby {};
    class transportBuildMissionPlan {};
    class transportClearInsertState {};
    class transportPool         {};
    class transportPoolClaim    {};
    class transportPoolFind     {};
    class transportPoolFindExisting {};
    class transportPoolRelease  {};
    class transportAttach       {};
    class transportApplyPostDismountWaypoint {};
    class transportDetach       {};
    class transportDetachAll    {};
    class transportParadropActivePassengerGroup {};
    class transportProcessActiveCarrier {};
    class transportProcessVirtualCarrier {};
    class transportMountActivePassengerGroup {};
    class transportPrepareCarrierForPickup {};
    class transportMaybeRequestReassignmentPickup {};
    class transportRequest      {};
    class transportDismount     {};
    class transportShouldThreatDismount {};
    class transportSyncActivePassengerGroup {};
};

class VirtualizationCore {
    file = "Functions\Virtualization\Core";

    class virtualizationAdvanceDefaultWaypoint {};
    class virtualizationAdvanceLoiterWaypoint {};
    class virtualizationAdvanceTerminalWaypoint {};
    class virtualizationApplyTieredUpdateWindow {};
    class virtualizationProcessAttachedGroup {};
    class virtualizationProcessInactiveMovement {};
    class virtualizationComputeDeferredActivationPos {};
    class virtualizationProcessActivationState {};
    class virtualizationProcessActiveState {};
    class virtualizationProcessGroup    {};
    class virtualizationAdvanceWaypoint {};
};

class VirtualizationLogic {
    file = "Functions\Virtualization\Logic";

    class virtualizationCanAutoPatrol  {};
    class virtualizationBuildPatrolPlan {};
    class virtualizationAssignAutoPatrol {};
};

class VirtualizationState {
    file = "Functions\Virtualization\State";

    class virtualizationGetEffectiveState {};
    class virtualizationSetAssetComposition {};
    class virtualizationClearCommanderOrder {};
    class virtualizationSetCommanderOrder {};
    class virtualizationAssignMoveOrder {};
    class virtualizationAssignAttackOrder {};
    class virtualizationAssignDefendOrder {};
    class virtualizationAssignGarrisonOrder {};
    class virtualizationRefreshDefendLease {};
    class virtualizationSetMissionLock {};
    class virtualizationClearMissionLock {};
    class virtualizationSetExecutionState {};
    class virtualizationClearExecutionState {};
    class virtualizationSetEngagementState {};
    class virtualizationClearEngagementState {};
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
    class virtualizationRestoreEngagementState {};
};

class VirtualizationDebug {
    file = "Functions\Virtualization\Debug";

    class virtualizationCreateDebugState   {};
    class virtualizationDebugManager      {};
    class virtualizationDebugRunBatch      {};
    class virtualizationProbe             {};
    class virtualizationProbeOwnership    {};
    class virtualizationDebugUpdateMarker {};
};

class VirtualizationUtilities {
    file = "Functions\Virtualization\Utilities";

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
    class setSide                 {};
};
