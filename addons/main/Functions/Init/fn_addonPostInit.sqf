/*
 * Function: FLO_fnc_addonPostInit
 * Author: Frontline Operations Development Group
 * Description:
 *   Addon-owned mission bootstrap. This replaces the removed loose mission
 *   initServer/initPlayerLocal scripts so FLO can run from any thin mission
 *   shell that loads the addon.
 */

[] call FLO_fnc_playerSideAdapterInit;

if (isServer) then {
    [] spawn {
        if (missionNamespace getVariable ["FLO_AddonServerBootstrapStarted", false]) exitWith {
            diag_log "[FLO_INIT] Addon server bootstrap already started";
        };
        missionNamespace setVariable ["FLO_AddonServerBootstrapStarted", true, true];

        private _globalVars = createHashMapFromArray [
            ["FLO_StartingLocationComplete", 0],
            ["MarLOCC", 0],
            ["AVENGLOCC", 1],
            ["ConVLocc", 0],
            ["FLO_Objectives_Debug", false],
            ["StartingLocationDone", false],
            ["F_Init", false],
            ["InitializationOG", false],
            ["FLO_MissionReady", false],
            ["FLO_SideResources", createHashMap],
            ["FLO_SideResourceState", createHashMap],
            ["FLO_ActivePlayerSide", sideUnknown],
            ["FLO_MissionSides", [east, west]],
            ["FLO_FactionCatalog", createHashMap],
            ["FLO_GTN_CommandersBySide", createHashMap],
            ["FLO_GTN_CommandersBySideState", createHashMap],
            ["FLO_CampaignBases", []],
            ["FLO_CampaignSnapshotRequestAt", createHashMap],
            ["FLO_GTN_EnablePlayerTaskBridge", true],
            ["FLO_GTN_CommanderDebugEnabled", false],
            ["FLO_GTN_CommanderDebugRunning", false],
            ["FLO_GTN_CommanderDebugMarkers", createHashMap],
            ["FLO_GTN_CombatDebugEnabled", true],
            ["FLO_GTN_AttackHandle", createHashMapFromArray [["value", 4], ["name", "Conservative"]]],
            ["FLO_GTN_DefenseHandle", createHashMapFromArray [["value", 4], ["name", "Minimal Coverage"]]],
            ["FLO_GTN_TempoHandle", createHashMapFromArray [["value", 10], ["name", "10s"]]]
        ];

        {
            missionNamespace setVariable [_x, _y, true];
        } forEach _globalVars;

        FLO_GTN_IntelPickupRevealState = createHashMapFromArray [
            ["WEST", createHashMap],
            ["EAST", createHashMap]
        ];
        FLO_GTN_StrategicIntelBySide = createHashMapFromArray [
            ["WEST", createHashMap],
            ["EAST", createHashMap]
        ];
        FLO_Logistics_Networks = createHashMap;

        FLO_GTN_CombatEvents = [];
        FLO_GTN_CombatLastByObjective = createHashMap;
        Centerposition = [worldSize / 2, worldSize / 2, 0];

        [] spawn FLO_fnc_heartbeat;

        waitUntil {
            sleep 0.1;
            !isNil "MissionLoadedLitterally" && {MissionLoadedLitterally}
        };

        sleep 1;
        diag_log "[FLO_INIT] Addon bootstrap starting Phase Manager";

        private _success = [] call FLO_fnc_initPhaseManager;
        if (_success) then {
            diag_log "[FLO_INIT] Phase Manager completed successfully";
        } else {
            diag_log format ["[FLO_INIT] Phase Manager FAILED: %1", FLO_InitError];
            [format ["Mission initialization failed: %1", FLO_InitError]] remoteExec ["hint", 0];
        };
    };
};

if (hasInterface) then {
    [] spawn {
        if (missionNamespace getVariable ["FLO_AddonClientBootstrapStarted", false]) exitWith {
            diag_log "[FLO_INIT_CLIENT] Addon client bootstrap already started";
        };
        missionNamespace setVariable ["FLO_AddonClientBootstrapStarted", true, false];

        waitUntil {
            sleep 0.1;
            !isNull player && {player == player}
        };

        titleText ["Frontline Operations Group Presents...", "PLAIN", 3];

        StartingLocationDone = false;
        FLO_ClientFinalizeDone = false;
        FLO_ClientUiReady = false;

        [] call FLO_fnc_initMissionConfigEvents;
        [] spawn {
            waitUntil {
                sleep 1;
                !isNull player
                && {player == player}
                && {!isNil "FLO_MissionReady"}
                && {FLO_MissionReady}
            };

            if (!FLO_ClientFinalizeDone) then {
                ["INIT_CLIENT", 3, "Mission-ready watchdog firing local client finalize"] call FLO_fnc_log;
                ["FLO_INIT_COMPLETE", []] call FLO_fnc_initClientFinalize;
            };
        };

        private _loadTimeout = diag_tickTime + 300;
        waitUntil {
            sleep 0.1;
            (!isNil "MissionLoadedLitterally" && {MissionLoadedLitterally}) || {diag_tickTime > _loadTimeout}
        };

        if (diag_tickTime > _loadTimeout) then {
            ["INIT_CLIENT", 1, "Mission loading timeout reached"] call FLO_fnc_log;
        };

        private _phase0Timeout = diag_tickTime + 30;
        waitUntil {
            sleep 0.3;
            (!isNil "FLO_InitPhase" && {FLO_InitPhase >= 1}) || {diag_tickTime > _phase0Timeout}
        };

        sleep 1;

        private _isSavedGame = !isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave};
        if (_isSavedGame) exitWith {
            ["INIT_CLIENT", 3, "Server detected saved game - skipping setup dialog"] call FLO_fnc_log;
            StartingLocationDone = true;
        };

        private _configReady = !isNil "FLO_MissionConfig"
            && {FLO_MissionConfig isEqualType createHashMap}
            && {(keys FLO_MissionConfig) isNotEqualTo []};
        private _initClosed = !isNil "FLO_InitPhase" && {FLO_InitPhase > 1};
        private _missionReady = !isNil "FLO_MissionReady" && {FLO_MissionReady};
        private _setupStillPending = !_configReady && {!_initClosed && {!_missionReady}};

        if (!_setupStillPending) exitWith {
            ["INIT_CLIENT", 3, "Mission setup already in progress or complete - skipping setup dialog"] call FLO_fnc_log;
            StartingLocationDone = true;
        };

        if ([] call FLO_fnc_openFactionDialog) exitWith {};

        [] spawn {
            private _noticeLogged = false;

            while {
                private _configReady = !isNil "FLO_MissionConfig"
                    && {FLO_MissionConfig isEqualType createHashMap}
                    && {(keys FLO_MissionConfig) isNotEqualTo []};
                private _initClosed = !isNil "FLO_InitPhase" && {FLO_InitPhase > 1};
                private _missionReady = !isNil "FLO_MissionReady" && {FLO_MissionReady};

                !_configReady && {!_initClosed && {!_missionReady}}
            } do {
                if ([] call FLO_fnc_openFactionDialog) exitWith {};

                if (!_noticeLogged) then {
                    ["INIT_CLIENT", 3, "Fresh setup is waiting for a logged-in admin or hosted server"] call FLO_fnc_log;
                    _noticeLogged = true;
                };

                sleep 2;
            };
        };
    };
};
