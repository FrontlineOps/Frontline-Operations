class GTNPlanning {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core\Planning";
    class gtnResolvePlanParams {};
    class gtnPlanDecompose {};
    class gtnPlanSearch {};
    class gtnPlannerStep {};
    class gtnWorldStateChanges {};
    class gtnValidatePlanDefinition {};
    class gtnRegisterPlanHandlers {};
    class gtnObserveOwnGroup {};
    class gtnCreateIntent {};
    class gtnCanExploitOpening {};
    class gtnCreateIntentTrack {};
    class gtnIntentForceReady {};
    class gtnGetAssaultRequirement {};
    class gtnIntentGoalSatisfied {};
    class gtnIntentGoalValid {};
    class gtnIntentSnapshot {};
    class gtnHandleRemovedIntentGroup {};
    class gtnIssueIntentOrder {};
    class gtnPollIntentTask {};
    class gtnProjectIntentPhase {};
    class gtnRetireIntent {};
    class gtnSetIntentPhase {};
    class gtnRestoreCommanderIntents {};
    class gtnSerializeCommanderIntents {};
    class gtnValidateSavedIntents {};
};

class GTNCore {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core";

    class gtnSideContext        {};
    class gtnWorldState         {};
    class gtnGoalLibrary        {};
    class gtnPlanner            {};
    class gtnExecutor           {};
    class gtnMonitor            {};
    class gtnCommander          {};
    class gtnCollectTurretWeapons {};
    class gtnCapabilityAnalyzer {};
};

class GTNCoreActions {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core\Actions";

    class gtnReleaseCompletedAttackAssignments {};
    class gtnRequestFrontlineArtillery {};
    class gtnRequestFrontlineCAP {};
    class gtnRequestFrontlineCAS {};
};

class GTNCoreLogic {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core\Logic";

    class gtnBuildFriendlyObjectiveOwnershipSignature {};
    class gtnBuildObjectiveAssignmentCache {};
    class gtnBuildObjectiveGarrisonRoute {};
    class gtnGetSideClientOwners {};
    class gtnMarkCommanderStateDirty {};
    class gtnGetCachedReserveBands {};
    class gtnGetSideCommanderHandle {};

    class gtnBuildObjectiveReserveBands {};
    class gtnExecuteTrackCycle {};
    class gtnGroupIsStrategicallyAssignable {};
    class gtnLogStrategicOrderPerf {};
    class gtnPickObjectiveGarrisonPosition {};
    class gtnResolveAttackCoverageCap {};
    class gtnResolveAttackLandAnchor {};
    class gtnAdmitGoalAgenda {};
    class gtnAdmitGoal {};
    class gtnAnalyzeManeuverGroup {};

    class gtnBuildGoalAgenda {};
    class gtnBuildStrategicPicture {};
    class gtnExecuteIntents {};
    class gtnExecuteIntent {};
    class gtnRunCycleStep {};
    class gtnReleaseObsoleteHolds {};
    class gtnSelectIntentForces {};
    class gtnUpdateCommander {};
};

class GTNIntel {
    file = "\z\flo\addons\main\Functions\AI\GTN\Intel";
    class gtnApplyObjectiveObservations {};
    class gtnRecordAirDefenseContact {};
    class gtnGetKnownAirDefenseThreats {};

    class gtnApproximateCommanderMarkerPosition {};
    class gtnBuildFrontlineSupportPicture {};
    class gtnBuildKnownEnemyGroupPicture {};
    class gtnBuildObservedRealEnemyTarget {};
    class gtnBuildCommanderIntelPicture {};
    class gtnBuildCommanderIntelPublishSignature {};
    class gtnBuildEnemyLogisticsIntelSnapshot {};
    class gtnBuildFriendlyCommanderGroupMarkers {};
    class gtnBuildFriendlySupportMarkers {};
    class gtnNormalizeIntelSignatureValue {};
    class gtnCollectIntelPickupRevealCandidates {};
    class gtnCommanderIntelMarkerType {};
    class gtnInjectCombatEventContacts {};
    class gtnIntelPreInit { preInit = 1; };
    class gtnPublishCommanderIntel {};
    class gtnRemoveStaleIntelMarkers {};
    class gtnRevealIntelPickup {};
    class gtnSerializeIntelSignatureRecords {};
    class gtnSyncIntelConcentrationMarkers {};
    class gtnSyncCommanderIntelMarkers {};
    class gtnSyncIntelIconMarkers {};
    class gtnSyncIntelSupportMarkers {};
    class gtnBuildAirThreatPicture {};
    class gtnGroundVisibility {};
    class gtnSenseVirtualScouts {};
};

class GTNAlerts {
    file = "\z\flo\addons\main\Functions\AI\GTN\Alerts";

    class gtnCanSideObserveArea {};
    class gtnCanSideDetectAirThreat {};
    class gtnFlushAlertQueue {};
    class gtnPublishAlert {};
    class gtnSyncAlertMarkers {};
    class gtnSyncAlertBatch {};
    class gtnAlertIncomingArtillery {};
    class gtnAlertIncomingAircraft {};
    class gtnAlertCivilianReport {};
};

#include "Combat\CfgFunctions.hpp"
#include "Operations\CfgFunctions.hpp"
class GTNTasks {
    file = "\z\flo\addons\main\Functions\AI\GTN\Tasks";

    class gtnClearPrimaryTaskState {};
    class gtnDeleteTaskIfPresent {};
    class gtnPlayerTaskBridge {};
    class gtnPlayerTaskDescription {};
    class gtnPlayerTaskTitle {};
    class gtnPublishPlayerTask {};

    class gtnMarkTaskSucceeded {};
    class gtnTaskEnemySide {};
    class gtnTaskMissing {};
    class gtnTaskSideKey {};
    class gtnTaskTypeFromKind {};
};

class GTNPlayerSupport {
    file = "\z\flo\addons\main\Functions\AI\GTN\PlayerSupport";

    class gtnBuildSupportCooldownKey {};
    class gtnProcessPlayerSupportRequests {};
    class gtnRegisterPlayerSupportEvents {};
    class gtnResolveSupportObjective {};
    class gtnSubmitPlayerSupportRequest {};
    class gtnSubmitPlayerSupportRequestServer {};
    class gtnValidatePlayerSupportRequest {};
};

class GTNResourceManager {
    file = "\z\flo\addons\main\Functions\AI\GTN\ResourceManager";

    class gtnResourceManager    {};
    class gtnResourceManagerProxy {};
    class gtnGetResourceManager {};
    class gtnGetCommandersBySide {};
    class gtnGetCommanderBySide {};
    class gtnConfig             {};
};

class GTNDebug {
    file = "\z\flo\addons\main\Functions\AI\GTN\Debug";

    class gtnCommanderDebugClearAll {};
    class gtnCommanderDebugSideColor {};
    class gtnCommanderDebugSideLabel {};
    class gtnCommanderDebugUpsertMarker {};
    class gtnCommanderVisualDebug {};
};

class GTNAssets {
    file = "\z\flo\addons\main\Functions\AI\GTN\Assets";

    class gtnAirAssetManager        {};
    class gtnAirTaskOrder           {};
    class gtnAirApplyVirtualCASEffect {};
    class gtnAirAuthorizeSortie {};
    class gtnAirDefenseActivateAgainstLiveAircraft {};
    class gtnAirDefenseBuildContactIndex {};
    class gtnAirDefenseGetState {};
    class gtnAirDefenseGetGroupRange {};
    class gtnAirDefenseHandoffActivatedAircraft {};
    class gtnAirDefenseIsObservedEngagement {};
    class gtnAirDefenseProcessContacts {};
    class gtnAirDefenseResolveVirtualEngagement {};
    class gtnAirDefenseStartContactWorker {};
    class gtnAirDistancePointToSegment2D {};
    class gtnAirInitializeOffMapReserves {};
    class gtnAirParkCombatGroupOffMap {};
    class gtnAirResolveReserveRoutePositions {};
    class gtnAirRouteHasKnownThreat {};
    class gtnAirTryRevirtualizeLiveMission {};
    class gtnBroadcastCommanderRadioMessage {};
    class gtnBroadcastArtilleryRadio {};
    class gtnBuildArtilleryMissionRecord {};
    class gtnCollectArtilleryVehicles {};
    class gtnBuildArtilleryFirePlan {};
    class gtnCommanderRadioMessage {};
    class gtnProcessArtilleryRadioQueue {};
    class gtnQueueArtilleryRadioMission {};
    class gtnArtilleryGetAvailableGroups {};
    class gtnArtillerySelectLiveBattery {};
    class gtnArtilleryCanRequestMission {};
    class gtnArtilleryCalculateMissionCost {};
    class gtnArtilleryApplyVirtualFireEffect {};
    class gtnArtilleryAuthorizeMission {};
    class gtnArtilleryEvaluateObservedTarget {};
    class gtnArtilleryManager       {};
    class gtnArtilleryFireMission   {};
    class gtnArtilleryProcessObservedFireRequests {};
    class gtnProcessCounterBatteryRequests {};
    class gtnRecordCounterBatteryExposure {};
    class gtnSupportAssetCanProvideAbstractSupport {};
    class gtnArtillerySyncCachedGroup {};
    class gtnArtillerySyncObservedSpotter {};
};

#include "Minefields\CfgFunctions.hpp"

class GTNOrders {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core\Orders";
    class gtnOrderGroupMove {};
    class gtnOrderGroupAttack {};
    class gtnOrderGroupDefend {};
    class gtnOrderGroupGarrison {};
};

class GTNDefense {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core\Defense";
    class gtnGetDefenseCapForObjective {};
    class gtnGetGarrisonCapForObjective {};
    class gtnCountObjectiveDefenders {};
    class gtnManageDefenseLeases {};
    class gtnManageStaticAANetwork {};
};

class GTNSensing {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core\Sensing";
    class gtnSenseObjectives {};
    class gtnSenseForces {};
    class gtnSenseSupportAssets {};
    class gtnSenseEnemyIntel {};
    class gtnSenseTacticalSituation {};
    class gtnUpdateWorldState {};
};

class GTNCapabilities {
    file = "\z\flo\addons\main\Functions\AI\GTN\Core\Capabilities";
    class gtnAnalyzeWeaponAmmo {};
    class gtnGetAirDefenseRange {};
    class gtnGetVehicleWeapons {};
    class gtnClassifyVehicle {};
    class gtnAnalyzeVehicle {};
    class gtnGetArtilleryStatus {};
    class gtnGetAirAssetStatus {};
    class gtnRevealIntelToUnits {};
};
