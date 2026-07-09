/*
 * Function: FLO_fnc_initPhase3_Objectives
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 3: Index all map objectives on the server.
 *   If loading from save, restores objectives from saved data.
 *   This is now done SERVER-SIDE instead of via client remoteExec.
 *
 * Arguments: None
 * Returns: Boolean - True if objectives indexed successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P3] Initializing objectives...";

// Check if loading from saved game
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_SavedGameData"}) then {
    private _savedData = FLO_SavedGameData;

    // Check if objectives exist in save
    if ("objectives" in _savedData) then {
        FLO_Objectives = _savedData get "objectives";

        private _captureTimeCfg = ["get", "captureTime"] call FLO_fnc_objectiveConfig;
        private _captureSecureTimeCfg = ["get", "captureSecureTime"] call FLO_fnc_objectiveConfig;
        {
            private _objId = _x;
            private _objData = FLO_Objectives get _objId;
            if (isNil {_objData get "owner"}) then { _objData set ["owner", east]; };
            private _owner = _objData get "owner";
            if (_owner isEqualType "") then {
                private _ownerKey = toUpper _owner;
                if (_ownerKey isEqualTo "EAST") then { _objData set ["owner", east]; };
                if (_ownerKey isEqualTo "WEST") then { _objData set ["owner", west]; };
            };
            if (isNil {_objData get "priority"}) then { _objData set ["priority", 0]; };
            if (isNil {_objData get "captureProgress"}) then { _objData set ["captureProgress", 0]; };
            if (isNil {_objData get "bluforCount"}) then { _objData set ["bluforCount", 0]; };
            if (isNil {_objData get "opforCount"}) then { _objData set ["opforCount", 0]; };
            if (isNil {_objData get "captureTime"}) then { _objData set ["captureTime", _captureTimeCfg]; };
            if (isNil {_objData get "captureState"}) then { _objData set ["captureState", "held"]; };
            if (isNil {_objData get "captureSide"}) then { _objData set ["captureSide", sideUnknown]; };
            if (isNil {_objData get "captureSecureStartedAt"}) then { _objData set ["captureSecureStartedAt", -1]; };
            if (isNil {_objData get "captureSecureProgress"}) then { _objData set ["captureSecureProgress", 0]; };
            if (isNil {_objData get "captureSecureTime"}) then { _objData set ["captureSecureTime", _captureSecureTimeCfg]; };
            if (isNil {_objData get "captureStatusChangedAt"}) then { _objData set ["captureStatusChangedAt", -1]; };
            if (isNil {_objData get "captureIntegratedAtDateNum"}) then { _objData set ["captureIntegratedAtDateNum", -1]; };
            FLO_Objectives set [_objId, _objData];
        } forEach (keys FLO_Objectives);

        publicVariable "FLO_Objectives";
        FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
        [] call FLO_fnc_publishObjectiveRuntimeState;

        diag_log format ["[FLO_INIT_P3] Restored %1 objectives from save", count FLO_Objectives];
    };
};

// If we already have objectives (from save), just start monitoring
if (!isNil "FLO_Objectives" && {FLO_Objectives isNotEqualTo []}) exitWith {
    diag_log format ["[FLO_INIT_P3] Using saved objectives: %1 total", count FLO_Objectives];

    // Build/rebuild objective graph
    diag_log "[FLO_INIT_P3] Rebuilding objective graph for saved game...";
    [false] call FLO_fnc_buildObjectiveGraph;

    // Start systems
    [] spawn FLO_fnc_startObjectiveGraph;
    [] spawn FLO_fnc_monitorObjectiveDominance;

    true
};

// Initialize objectives as HashMap
FLO_Objectives = createHashMap;
publicVariable "FLO_Objectives";
FLO_ObjectiveRuntimeState = createHashMap;
[] call FLO_fnc_publishObjectiveRuntimeState;

// Use objective indexer
diag_log "[FLO_INIT_P3] Calling FLO_fnc_objectiveIndexer...";
[] call FLO_fnc_objectiveIndexer;

// Verify objectives were indexed
if (isNil "FLO_Objectives") exitWith {
    FLO_InitError = "Objective indexing returned nil";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P3] ERROR: %1", FLO_InitError];
    false
};

if (!(FLO_Objectives isEqualType createHashMap)) exitWith {
    FLO_InitError = format ["Objective indexing returned wrong type: %1", typeName FLO_Objectives];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P3] ERROR: %1", FLO_InitError];
    false
};

if ((keys FLO_Objectives) isEqualTo []) exitWith {
    FLO_InitError = "Objective indexing returned no objectives";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P3] ERROR: %1", FLO_InitError];
    false
};
diag_log format ["[FLO_INIT_P3] Objective indexer created %1 objectives", count keys FLO_Objectives];
FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
[] call FLO_fnc_publishObjectiveRuntimeState;

// Seed initial EAST/WEST ownership for new runs.
diag_log "[FLO_INIT_P3] Seeding initial objective ownership...";
[FLO_MissionConfig get "startPosition", FLO_StartingTerritoryWestRatio] call FLO_fnc_seedObjectiveOwnership;

// Build objective graph
diag_log "[FLO_INIT_P3] Building objective graph...";
[] call FLO_fnc_buildObjectiveGraph;

// Start objective graph
diag_log "[FLO_INIT_P3] Starting objective graph...";
[] spawn FLO_fnc_startObjectiveGraph;

// Start dominance monitoring
diag_log "[FLO_INIT_P3] Starting objective dominance monitoring...";
[] spawn FLO_fnc_monitorObjectiveDominance;

diag_log format ["[FLO_INIT_P3] Objectives phase complete: %1 objectives", count keys FLO_Objectives];

true
