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
private _phaseT0 = diag_tickTime;

// Restore only the exact current objective shape published by save detection.
if (FLO_IsLoadedSave) then {
    private _savedData = FLO_SavedGameData;
    private _restoreT0 = diag_tickTime;
    private _savedObjectives = _savedData get "objectives";
    if ((keys _savedObjectives) isEqualTo []) then {
        private _error = "Current mission save contains no objectives";
        ["INIT", 1, _error] call FLO_fnc_log;
        throw _error;
    };

    private _requiredObjectiveTypes = [
        ["type", ""], ["subtype", ""], ["position", []], ["priority", 0],
        ["radius", 0], ["polygon", []], ["usePolygon", true], ["structures", []],
        ["structureCount", 0], ["structurePositions", []], ["location", ""],
        ["locType", ""], ["owner", sideUnknown], ["captureProgress", 0],
        ["captureState", ""], ["captureSide", sideUnknown], ["captureSecureStartedAt", 0],
        ["captureSecureProgress", 0], ["captureSecureTime", 0],
        ["captureStatusChangedAt", 0], ["captureIntegratedAtDateNum", 0],
        ["bluforCount", 0], ["opforCount", 0], ["contested", true],
        ["underAttack", true], ["captureTime", 0], ["capturedAtDateNum", 0],
        ["capturedFrom", sideUnknown], ["captureGrowthEligibleAtDateNum", 0],
        ["captureGrowthPending", true], ["campaignIntegrationState", ""],
        ["campaignOperationId", ""], ["campaignCapturedBySideKey", ""],
        ["campaignBenefitsPending", true], ["name", ""], ["markerIds", []],
        ["linkedObjectives", []], ["mergedCount", 0], ["revenueLevel", 0],
        ["developmentLevel", 0], ["developmentProject", createHashMap]
    ];
    private _requiredObjectiveFields = _requiredObjectiveTypes apply { _x # 0 };
    {
        private _objId = _x;
        if !(_objId isEqualType "" && {_objId != ""}) then {
            throw format ["Current mission save has invalid objective key %1", _objId];
        };
        private _objData = _savedObjectives get _objId;
        if !(_objData isEqualType createHashMap) then {
            throw format ["Saved objective %1 has invalid record type %2", _objId, typeName _objData];
        };
        private _unexpectedObjectiveFields = (keys _objData) select {
            !(_x in _requiredObjectiveFields)
        };
        if (_unexpectedObjectiveFields isNotEqualTo []) then {
            throw format [
                "Saved objective %1 has unexpected fields %2",
                _objId,
                _unexpectedObjectiveFields
            ];
        };
        {
            _x params ["_field", "_prototype"];
            if !(_field in _objData) then {
                throw format ["Saved objective %1 is missing required field %2", _objId, _field];
            };
            private _value = _objData get _field;
            if !(_value isEqualType _prototype) then {
                throw format [
                    "Saved objective %1 field %2 has invalid type %3",
                    _objId,
                    _field,
                    typeName _value
                ];
            };
        } forEach _requiredObjectiveTypes;

        private _position = _objData get "position";
        if ((count _position) < 2 || {{!(_x isEqualType 0)} count _position > 0}) then {
            throw format ["Saved objective %1 has invalid position %2", _objId, _position];
        };
        if ((_objData get "location") != _objId) then {
            throw format ["Saved objective %1 has mismatched location field", _objId];
        };
        if !((_objData get "owner") in [east, west]) then {
            throw format ["Saved objective %1 has invalid owner %2", _objId, _objData get "owner"];
        };
        if !((_objData get "captureSide") in [east, west, sideUnknown]) then {
            throw format ["Saved objective %1 has invalid capture side", _objId];
        };
        if !((_objData get "capturedFrom") in [east, west, sideUnknown]) then {
            throw format ["Saved objective %1 has invalid captured-from side", _objId];
        };
        if !((_objData get "captureState") in ["held", "contested", "clearing", "securing", "integrating", "integrated"]) then {
            throw format ["Saved objective %1 has invalid capture state %2", _objId, _objData get "captureState"];
        };
        if !((_objData get "campaignIntegrationState") in ["INTEGRATED", "FOOTHOLD", "CONSOLIDATING"]) then {
            throw format [
                "Saved objective %1 has invalid campaign integration state %2",
                _objId,
                _objData get "campaignIntegrationState"
            ];
        };
        if !((_objData get "campaignCapturedBySideKey") in ["", "EAST", "WEST"]) then {
            throw format ["Saved objective %1 has invalid captured-by side key", _objId];
        };
        _savedObjectives set [
            _objId,
            [_objId, _objData] call FLO_fnc_objectiveDevelopmentInitializeObjective
        ];
    } forEach (keys _savedObjectives);

    FLO_Objectives = _savedObjectives;
    publicVariable "FLO_Objectives";
    private _runtimeT0 = diag_tickTime;
    FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
    [] call FLO_fnc_publishObjectiveRuntimeState;
    private _runtimeMs = (diag_tickTime - _runtimeT0) * 1000;
    private _restoreMs = (_runtimeT0 - _restoreT0) * 1000;

    ["INIT", 3, format ["Restored %1 current-version objectives", count FLO_Objectives]] call FLO_fnc_log;
    diag_log format [
        "[FLO][PERF] Phase3 save restore objectives=%1 restore=%2 ms runtime=%3 ms",
        count FLO_Objectives,
        _restoreMs,
        _runtimeMs
    ];
};

// If we already have objectives (from save), just start monitoring
if (!isNil "FLO_Objectives" && {FLO_Objectives isNotEqualTo []}) exitWith {
    diag_log format ["[FLO_INIT_P3] Using saved objectives: %1 total", count FLO_Objectives];

    // Build/rebuild objective graph
    diag_log "[FLO_INIT_P3] Rebuilding objective graph for saved game...";
    private _graphT0 = diag_tickTime;
    [false] call FLO_fnc_buildObjectiveGraph;
    private _graphMs = (diag_tickTime - _graphT0) * 1000;
    private _totalMs = (diag_tickTime - _phaseT0) * 1000;
    diag_log format [
        "[FLO][PERF] Phase3 saved objectives=%1 graph=%2 ms total=%3 ms",
        count FLO_Objectives,
        _graphMs,
        _totalMs
    ];

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
private _indexT0 = diag_tickTime;
[] call FLO_fnc_objectiveIndexer;
private _indexMs = (diag_tickTime - _indexT0) * 1000;

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
private _captureTime = ["get", "captureTime"] call FLO_fnc_objectiveConfig;
private _captureSecureTime = ["get", "captureSecureTime"] call FLO_fnc_objectiveConfig;
{
    private _objective = FLO_Objectives get _x;
    _objective set ["captureTime", _captureTime];
    _objective set ["captureSecureTime", _captureSecureTime];
} forEach (keys FLO_Objectives);
diag_log format ["[FLO_INIT_P3] Objective indexer created %1 objectives", count keys FLO_Objectives];
private _runtimeT0 = diag_tickTime;
FLO_ObjectiveRuntimeState = [] call FLO_fnc_buildObjectiveRuntimeState;
[] call FLO_fnc_publishObjectiveRuntimeState;
private _runtimeMs = (diag_tickTime - _runtimeT0) * 1000;

// Seed initial EAST/WEST ownership for new runs.
diag_log "[FLO_INIT_P3] Seeding initial objective ownership...";
private _seedT0 = diag_tickTime;
[FLO_MissionConfig get "startPosition", FLO_StartingTerritoryWestRatio, FLO_ActivePlayerSide] call FLO_fnc_seedObjectiveOwnership;
private _seedMs = (diag_tickTime - _seedT0) * 1000;

// Build objective graph
diag_log "[FLO_INIT_P3] Building objective graph...";
private _graphT0 = diag_tickTime;
[] call FLO_fnc_buildObjectiveGraph;
private _graphMs = (diag_tickTime - _graphT0) * 1000;

// Start objective graph
diag_log "[FLO_INIT_P3] Starting objective graph...";
[] spawn FLO_fnc_startObjectiveGraph;

// Start dominance monitoring
diag_log "[FLO_INIT_P3] Starting objective dominance monitoring...";
[] spawn FLO_fnc_monitorObjectiveDominance;

diag_log format ["[FLO_INIT_P3] Objectives phase complete: %1 objectives", count keys FLO_Objectives];
diag_log format [
    "[FLO][PERF] Phase3 fresh objectives=%1 index=%2 ms runtime=%3 ms seed=%4 ms graph=%5 ms total=%6 ms",
    count keys FLO_Objectives,
    _indexMs,
    _runtimeMs,
    _seedMs,
    _graphMs,
    (diag_tickTime - _phaseT0) * 1000
];

true
