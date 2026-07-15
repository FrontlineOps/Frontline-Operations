class FLO {
    class Functions {
        file = "\z\flo\addons\main\Functions";

        class MissionSave       {};
        class MissionStartup    {};
        class MissionLoad       {preInit = 1;};
        class initializeFOB     {};
        class initializeOP      {};
    };

    class Save {
        file = "\z\flo\addons\main\Functions\Save";

        class saveGetAllCargo {};
        class saveGetCompressedDamage {};
    };

    // === INITIALIZATION PHASE SYSTEM ===
    class Init {
        file = "\z\flo\addons\main\Functions\Init";

        class applyMissionConfigLocally {};
        class registerSettings      {};
        class detectSavedGame       {};
        class initFactionSplitMixedInfantryPool {};
        class initLoadFactionDefinition {};
        class initLoadFactionSelection {};
        class initMissionConfigEvents {};
        class initPhaseManager      {};
        class initPhase1_MissionConfig {};
        class initPhase2_Factions   {};
        class initPhase3_Objectives {};
        class initPhase4_Virtualization {};
        class initPhase5_MissionSystems {};
        class initRestoreTrackedCrew {};
        class initRunPhase {};
        class initSideResourcesUninitialized {};
        class initActivatePlayer    {};
        class initDeployPlayer      {};
        class initClientFinalize    {};
        class playerSideAdapterApply {};
        class playerSideAdapterInit {};
        class playerSideAdapterRequest {};
        class addonPostInit         {postInit = 1;};
    };

    // === GTN (Goal Task Network) SYSTEM ===
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

        class gtnAllocateBaselineGarrisons {};
        class gtnAllocateFrontlineAttacks {};
        class gtnAllocateFrontlineDefense {};
        class gtnReleaseCompletedAttackAssignments {};
        class gtnRetaskAttackRoute {};
        class gtnRequestFrontlineArtillery {};
        class gtnRequestFrontlineCAP {};
        class gtnRequestFrontlineCAS {};
    };

    class GTNCoreLogic {
        file = "\z\flo\addons\main\Functions\AI\GTN\Core\Logic";

        class gtnAllocateAttackTrackPools {};
        class gtnCreateAttackTrack {};
        class gtnBuildDefenseObjectiveProfiles {};
        class gtnBuildObjectiveDemandSignature {};
        class gtnBuildFriendlyObjectiveOwnershipSignature {};
        class gtnBuildObjectiveAssignmentCache {};
        class gtnGetSideClientOwners {};
        class gtnMarkCommanderStateDirty {};
        class gtnGetCachedReserveBands {};
        class gtnGetSideCommanderHandle {};
        class gtnGetTempoScaledAssignmentLimit {};
        class gtnBuildObjectiveReserveBands {};
        class gtnExecuteTrackCycle {};
        class gtnGetAttackPressureProfile {};
        class gtnGroupIsStrategicallyAssignable {};
        class gtnLogStrategicOrderPerf {};
        class gtnPickObjectiveGarrisonPosition {};
        class gtnUpdateAttackTrackPhases {};
    };

    class GTNIntel {
        file = "\z\flo\addons\main\Functions\AI\GTN\Intel";

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

    #include "Functions\AI\GTN\Combat\CfgFunctions.hpp"
    #include "Functions\AI\GTN\Operations\CfgFunctions.hpp"
    #include "Functions\Formations\CfgFunctions.hpp"
    #include "Functions\UI\CfgFunctions.hpp"
    #include "Functions\Notifications\CfgFunctions.hpp"

    class GTNTasks {
        file = "\z\flo\addons\main\Functions\AI\GTN\Tasks";

        class gtnClearPrimaryTaskState {};
        class gtnDeleteTaskIfPresent {};
        class gtnPlayerTaskBridge {};
        class gtnPlayerTaskDescription {};
        class gtnPlayerTaskTitle {};
        class gtnPublishPlayerTask {};
        class gtnMarkTaskFailed {};
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
        class gtnAirDefenseGetState {};
        class gtnAirDefenseProcessContacts {};
        class gtnAirDefenseResolveVirtualEngagement {};
        class gtnAirDefenseStartContactWorker {};
        class gtnAirDistancePointToSegment2D {};
        class gtnAirInitializeOffMapReserves {};
        class gtnAirParkCombatGroupOffMap {};
        class gtnAirResolveReserveRoutePositions {};
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
    
    class AITasks {
        file = "\z\flo\addons\main\Functions\AI\Tasks";

        class taskApplyRoute {};
        class taskPatrol {};
    };

    #include "Functions\Virtualization\CfgFunctions.hpp"
    #include "Functions\Transport\CfgFunctions.hpp"
    #include "Functions\ForceGeneration\CfgFunctions.hpp"
    #include "Functions\Civilian\CfgFunctions.hpp"

    #include "Functions\Objective\CfgFunctions.hpp"

    #include "Functions\AI\GTN\Minefields\CfgFunctions.hpp"

    #include "Functions\Economy\CfgFunctions.hpp"

    #include "Functions\Logistics\CfgFunctions.hpp"

    class Store {
        file = "\z\flo\addons\main\Functions\Store";

        class storeAddInventoryItem {};
        class storeAddKitsWebEventHandler {};
        class storeAddWebEventHandler {};
        class storeAppendCatalogItem {};
        class storeAppendContainerCargoItems {};
        class storeAppendGearMagazine {};
        class storeAppendGearWeapon {};
        class storeAppendSupportItems {};
        class storeAppendUnitGear {};
        class storeApplyKit {};
        class storeApplyWeaponLine {};
        class storeBuildCatalog {};
        class storeBuildCatalogItem {};
        class storeBuildCategoryPayload {};
        class storeBuildHydratePayload {};
        class storeBuildKitsPayload {};
        class storeCategoryForVehicle {};
        class storeCategoryForWeapon {};
        class storeCapabilityForCategory {};
        class storeCheckout {};
        class storeClearCargo {};
        class storeCurrentLoadoutKitItems {};
        class storeDeployBase {};
        class storeDropGearItems {};
        class storeDropGearAddCount {};
        class storeGearVisionTraits {};
        class storeHandleUiEvent {};
        class storeHandleKitsUiEvent {};
        class storeIsItemBackedMagazine {};
        class storeIsMineMagazine {};
        class storeCollectVehicleWeapons {};
        class storeKitAccumulateLine {};
        class storeKitAppendCargo {};
        class storeKitCategoryForClass {};
        class storeKitDisplayName {};
        class storeNormalizeRuntimeRadioClass {};
        class storeOpenDialog {};
        class storeOpenKitsDialog {};
        class storePreInit { preInit = 1; };
        class storeMagazineCombatTraits {};
        class storePriceAttachment {};
        class storePriceClass {};
        class storePriceVehicle {};
        class storeReadConfigVisionTree {};
        class storeReadVisionTraits {};
        class storeReceiveResponse {};
        class storeRecruitAI {};
        class storeRequestCategory {};
        class storeRequestCheckout {};
        class storeRequestHydrate {};
        class storeSavedKitsDelete {};
        class storeSavedKitsLoad {};
        class storeSavedKitsPersist {};
        class storeSavedKitsSave {};
        class storeSavedKitValidateItem {};
        class storeSavedKitValidateRecord {};
        class storeSendResponse {};
        class storeSpawnVehicle {};
        class storeSpawnSupplyShipment {};
        class storeThroughputCost {};
        class storeUpdateDialog {};
        class storeUpdateKitsDialog {};
        class storeValidateAccess {};
        class storeVehicleConfigTraits {};
        class storeWeaponCombatPrice {};
        class storeWeaponAttachments {};
        class storeWebAction {};
    };

    class Base {
        file = "\z\flo\addons\main\Functions\Base";

        class baseConfigureContainerActions {};
        class baseConfigureMainActions {};
        class baseCountSiegeForces {};
        class baseCreateMarker {};
        class baseCreateTriggers {};
        class baseDeployAddWebEventHandler {};
        class baseDeployBuildSnapshot {};
        class baseDeployClaimFirstFOB {};
        class baseDeployGetCost {};
        class baseDeployHandleUiEvent {};
        class baseDeployInitClient {};
        class baseDeployInitializeState {};
        class baseDeployOpenDialog {};
        class baseDeployPreInit { preInit = 1; };
        class baseDeployReceiveResult {};
        class baseDeployRequest {};
        class baseDeploySerializeState {};
        class baseDeployUpdateDialog {};
        class baseDeployValidateState {};
        class baseDeployWebAction {};
        class baseMonitorSiege {};
    };

    class Factions {
        file = "\z\flo\addons\main\Functions\Factions";

        class factionBuildAutoSelectionCatalog {};
        class factionBuildAutoCivilianCatalog {};
        class factionBuildAutoIndex {};
        class factionBuildMergedAutoCivilianCatalog {};
        class factionBuildMergedAutoMilitaryCatalog {};
        class factionBuildAutoMilitaryCatalog {};
        class factionBuildObjectiveGroupFieldSpecs {};
        class factionBuildTuningFieldSpecsFromIdcs {};
        class factionBuildVehiclePoolFromVariables {};
        class factionClassIsCombatInfantry {};
        class factionClassifyVehicle {};
        class factionCollectDirectUnitVariables {};
        class factionCompactNumericText {};
        class factionCompositionDefaultCaps {};
        class factionCompositionDefaultCounts {};
        class factionCompositionDefaultObjectiveGroups {};
        class factionCreateCompositionDefaultHandle {};
        class factionExtractVehicleClasses {};
        class factionGetCustomDefinition {};
        class factionGetGroupConfigs {};
        class factionGetCompositionDefaults {};
        class factionGetObjectiveGroupFieldSpecs {};
        class factionGetTuningFieldSpecs {};
        class factionGetVariableArray {};
        class factionBuildCompositionDefaultsHandle {};
        class factionBuildCustomCivilianCatalog {};
        class factionBuildCustomMilitaryCatalog {};
        class factionHandleSource {};
        class factionHandleSide {};
        class factionUnitIsOfficer {};
        class factionValidateCatalogSide {};
        class factionIsUnsignedInt {};
        class factionMergePairs {};
        class factionApplyTuningOverrides {};
        class factionBuildTuningHandle {};
        class factionPickUnitByRole {};
        class factionSanitizeCompositionForCatalog {};
    };

    #include "Functions\Utilities\CfgFunctions.hpp"

    class Misc {
        file = "\z\flo\addons\main\Functions\Misc";

        class ragequitBlocker     {};
        class disableSystemChat   {};
    };

    #include "Functions\Pathfinding\CfgFunctions.hpp"
};
