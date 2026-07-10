class CfgPatches {
    class flo_main {
        name = "FLO";
        author = "Frontline Operations Group";
        requiredVersion = 2.18;
        requiredAddons[] = {
            "cba_main",
            "cba_xeh",
            "cba_settings"
        };
        units[] = {};
        weapons[] = {};
    };
};

class Extended_PreInit_EventHandlers {
    class flo_main {
        init = "call compile preprocessFileLineNumbers '\z\flo\addons\main\XEH_preInit.sqf'";
    };
};

#include "UI\addon_defines.hpp"
#include "IDS_Logistics\CfgLogistics.hpp"
#include "IDS_Logistics\dialogs\BuildMenuDialog.hpp"

class CfgFunctions {
    #include "CfgFunctions.hpp"
    #include "IDS_Logistics\IDS_Logistics_Functions.hpp"
    #include "IDS_Notifications\IDS_Notifications_Functions.hpp"
};

class RscTitles {
    #include "IDS_Notifications\ui\RscNotifications.hpp"
    #include "UI\CaptureUI\CaptureDialog.hpp"

    titles[] = {};
};

#include "UI\Setup\SetupDialog.hpp"
#include "UI\Store\StoreDialog.hpp"
#include "UI\Deploy\DeployDialog.hpp"
#include "UI\Operations\OperationsDialog.hpp"

class CfgRemoteExec {
    class Functions {
        mode = 2;

        class BIS_fnc_debugConsoleExec { allowedTargets = 0; jip = 1; };
        class SpawnScript { allowedTargets = 0; jip = 1; };
        class FLO_fnc_displayNotification { allowedTargets = 0; jip = 0; };
        class FLO_fnc_showDynamicText { allowedTargets = 0; jip = 0; };
        class FLO_fnc_addIntelServer { allowedTargets = 2; jip = 0; };
        class FLO_fnc_gtnAlertCivilianReport { allowedTargets = 2; jip = 0; };
        class FLO_fnc_civilianRequestIntel { allowedTargets = 2; jip = 0; };
        class FLO_fnc_civilianRequestMission { allowedTargets = 2; jip = 0; };
        class FLO_fnc_civilianMissionManager { allowedTargets = 2; jip = 0; };
        class FLO_fnc_civilianMissionResolveAction { allowedTargets = 2; jip = 0; };
        class FLO_fnc_civilianDetaineeCommand { allowedTargets = 2; jip = 0; };
        class FLO_fnc_gtnCommanderRadioMessage { allowedTargets = 0; jip = 0; };
        class FLO_fnc_initClientFinalize { allowedTargets = 0; jip = 1; };
        class FLO_fnc_gtnSyncAlertBatch { allowedTargets = 0; jip = 0; };
        class FLO_fnc_gtnSyncCommanderIntelMarkers { allowedTargets = 0; jip = 0; };
        class FLO_fnc_gtnQueueArtilleryRadioMission { allowedTargets = 0; jip = 0; };
        class FLO_fnc_addMoney { allowedTargets = 2; jip = 0; };
        class FLO_fnc_vehicleMarket { allowedTargets = 2; jip = 0; };
        class FLO_fnc_bribeMilitia { allowedTargets = 2; jip = 0; };
        class FLO_fnc_syncObjectiveRuntimeState { allowedTargets = 1; jip = 0; };
        class FLO_fnc_storeApplyKit { allowedTargets = 1; jip = 0; };
        class FLO_fnc_storeReceiveResponse { allowedTargets = 1; jip = 0; };
        class FLO_fnc_storeRecruitAI { allowedTargets = 1; jip = 0; };
        class FLO_fnc_storeRequestHydrate { allowedTargets = 2; jip = 0; };
        class FLO_fnc_storeRequestCategory { allowedTargets = 2; jip = 0; };
        class FLO_fnc_storeRequestCheckout { allowedTargets = 2; jip = 0; };
        class FLO_fnc_baseDeployRequest { allowedTargets = 2; jip = 0; };
        class FLO_fnc_baseDeployReceiveResult { allowedTargets = 1; jip = 0; };
        class FLO_fnc_campaignRequestSnapshot { allowedTargets = 2; jip = 0; };
        class FLO_fnc_operationsReceiveSnapshot { allowedTargets = 1; jip = 0; };
        class FLO_fnc_randomizeWeather { allowedTargets = 2; jip = 0; };
    };
};
