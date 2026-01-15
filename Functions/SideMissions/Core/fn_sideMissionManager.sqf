/*
 * Function: FLO_fnc_sideMissionManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Central mission manager that handles the mission lifecycle.
 *   Replaces the broken fn_missionQueue with proper state tracking.
 *
 * Features:
 *   - Respects maximum active mission cap
 *   - Per-type cooldowns via template system
 *   - Polls mission state for success/failure
 *   - Handles completion rewards and cleanup
 *   - Convoy mission mutual exclusion
 *
 * Arguments:
 *   0: Operation (STRING) - "init", "start", "stop", "spawn", "tick"
 *   1: Arguments (ARRAY)
 *
 * Returns: Varies by operation
 */

params [["_operation", ""], ["_args", []]];

// Config
FLO_SM_MaxActive = 2;                               // Max concurrent missions
FLO_SM_TickInterval = 30;                           // Check interval
FLO_SM_SpawnInterval = 60 + random 1740;            // 1-30 min between spawns
if (isNil "FLO_SM_Running") then { FLO_SM_Running = false; };
if (isNil "FLO_SM_LastSpawnCheck") then { FLO_SM_LastSpawnCheck = 0; };

private _result = nil;

switch (toLower _operation) do {
    // Initialize the mission system
    case "init": {
        // Initialize all subsystems
        ["init"] call FLO_fnc_sideMissionState;
        ["init"] call FLO_fnc_sideMissionRegistry;
        ["init"] call FLO_fnc_sideMissionTemplate;

        diag_log "[FLO_SM] Mission Manager initialized";
        _result = true;
    };
    
    // Start the mission manager loop
    case "start": {
        if (FLO_SM_Running) exitWith {
            diag_log "[FLO_SM] Manager already running";
            _result = false;
        };

        FLO_SM_Running = true;
        diag_log "[FLO_SM] Starting mission manager loop";

        [] spawn {
            // Wait for objectives to be indexed before spawning missions
            // This prevents the race condition where missions try to spawn before objectives exist
            private _waitStart = diag_tickTime;
            private _timeout = 120;

            waitUntil {
                sleep 2;
                private _hasObjectives = !isNil "FLO_Objectives" && {count FLO_Objectives > 0};
                private _timedOut = (diag_tickTime - _waitStart) > _timeout;

                if (!_hasObjectives && !_timedOut) then {
                    diag_log "[FLO_SM] Waiting for objectives to be indexed...";
                };

                _hasObjectives || _timedOut || !FLO_SM_Running
            };

            if (!FLO_SM_Running) exitWith {
                diag_log "[FLO_SM] Manager stopped while waiting for objectives";
            };

            if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) then {
                diag_log "[FLO_SM] WARNING: No objectives available - side missions will not spawn properly";
            } else {
                diag_log format ["[FLO_SM] Objectives ready (%1 found) - starting mission loop", count FLO_Objectives];
            };

            // Main loop
            while {FLO_SM_Running} do {
                ["tick"] call FLO_fnc_sideMissionManager;
                sleep FLO_SM_TickInterval;
            };
            diag_log "[FLO_SM] Mission manager loop stopped";
        };

        _result = true;
    };
    
    // Stop the mission manager
    case "stop": {
        FLO_SM_Running = false;
        diag_log "[FLO_SM] Stopping mission manager";
        _result = true;
    };
    
    // Main tick - check missions and spawn new ones
    case "tick": {
        // Poll active missions for state changes
        private _activeMissions = ["getActive"] call FLO_fnc_sideMissionRegistry;
        
        {
            private _missionId = _x;
            private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
            if (isNil "_instance") then { continue; };
            
            private _state = ["get", [_missionId]] call FLO_fnc_sideMissionState;
            private _type = _instance get "type";
            private _template = ["get", [_type]] call FLO_fnc_sideMissionTemplate;
            
            if (isNil "_template") then { continue; };
            
            // Only check ACTIVE missions for success/fail
            if (_state == 2) then {
                // Check timeout
                private _timeout = _instance getOrDefault ["timeout", -1];
                private _startTime = _instance get "startTime";
                if (_timeout > 0 && {serverTime - _startTime > _timeout}) then {
                    ["complete", [_missionId, false, "Timeout"]] call FLO_fnc_sideMissionManager;
                    continue;
                };
                
                // Check success condition
                private _checkSuccess = _template getOrDefault ["fnc_checkSuccess", { false }];
                if ([_missionId, _instance] call _checkSuccess) then {
                    ["complete", [_missionId, true]] call FLO_fnc_sideMissionManager;
                    continue;
                };
                
                // Check fail condition
                private _checkFail = _template getOrDefault ["fnc_checkFail", { false }];
                if ([_missionId, _instance] call _checkFail) then {
                    ["complete", [_missionId, false]] call FLO_fnc_sideMissionManager;
                };
            };
        } forEach _activeMissions;
        
        // Check if we should try to spawn new missions
        if (serverTime - FLO_SM_LastSpawnCheck >= FLO_SM_SpawnInterval) then {
            FLO_SM_LastSpawnCheck = serverTime;
            
            private _activeCount = count _activeMissions;
            if (_activeCount < FLO_SM_MaxActive) then {
                private _needed = FLO_SM_MaxActive - _activeCount;
                private _spawnable = ["getSpawnable"] call FLO_fnc_sideMissionTemplate;
                _spawnable = _spawnable call BIS_fnc_arrayShuffle;
                
                private _spawned = 0;
                {
                    if (_spawned >= _needed) exitWith {};
                    private _typeName = _x;
                    
                    // Check convoy exclusion
                    private _template = ["get", [_typeName]] call FLO_fnc_sideMissionTemplate;
                    if (_template getOrDefault ["isConvoy", false]) then {
                        if (!isNil "ConVLocc" && {ConVLocc > 0}) then { continue; };
                    };
                    
                    if (["spawn", [_typeName]] call FLO_fnc_sideMissionManager) then {
                        _spawned = _spawned + 1;
                    };
                } forEach _spawnable;
            };
        };
        
        _result = true;
    };
    
    // Spawn a new mission of given type
    case "spawn": {
        _args params [["_typeName", ""]];

        private _template = ["get", [_typeName]] call FLO_fnc_sideMissionTemplate;
        if (isNil "_template") exitWith { _result = false; };

        // Run setup to get position and validate
        private _fnc_setup = _template getOrDefault ["fnc_setup", { [true, [0,0,0]] }];
        private _setupResult = [_typeName] call _fnc_setup;
        _setupResult params [["_canSpawn", false], ["_position", [0,0,0]]];

        if (!_canSpawn) exitWith { _result = false; };

        // Create mission instance
        private _timeout = _template getOrDefault ["timeout", 3600];
        private _missionId = ["create", [_typeName, _position, _timeout]] call FLO_fnc_sideMissionRegistry;

        if (_missionId == "") exitWith { _result = false; };

        // Set to PENDING (awaiting acceptance) or ACTIVE
        ["set", [_missionId, 2]] call FLO_fnc_sideMissionState; // Direct to ACTIVE for now

        // Call spawn function
        private _fnc_spawn = _template get "fnc_spawn";
        [_missionId] call _fnc_spawn;

        // Mark cooldown
        ["markCooldown", [_typeName]] call FLO_fnc_sideMissionTemplate;

        // Send notification
        private _name = _template getOrDefault ["name", _typeName];
        ["STR_FLO_INTEL_TITLE", format ["Mission Available: %1", _name], "intel"] call FLO_fnc_sendNotification;

        diag_log format ["[FLO_SM] Spawned mission: %1 (%2)", _missionId, _typeName];
        _result = true;
    };

    // Complete a mission (success or failure)
    case "complete": {
        _args params [["_missionId", ""], ["_success", false], ["_reason", ""]];

        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        if (isNil "_instance") exitWith { _result = false; };

        private _type = _instance get "type";
        private _template = ["get", [_type]] call FLO_fnc_sideMissionTemplate;

        // Set terminal state
        private _newState = if (_success) then { 3 } else { 4 }; // SUCCESS or FAILED
        ["set", [_missionId, _newState, true]] call FLO_fnc_sideMissionState;

        // Handle reward
        if (_success) then {
            private _reward = if (!isNil "_template") then { _template getOrDefault ["reward", 50] } else { 50 };
            [_reward] call FLO_fnc_addReward;
            private _name = if (!isNil "_template") then { _template getOrDefault ["name", _type] } else { _type };
            [_reward, format ["Mission Complete: %1", _name]] call FLO_fnc_sendRewardNotification;
            
            // Intel reward based on mission type
            private _intelReward = switch (true) do {
                case (_type in ["templateIntelGathering"]): { 25 };  // Intel missions give more
                case (_type in ["templateHVTConvoy", "templateConvoyInterdiction"]): { 20 };
                case (_type in ["templatePOWRescue", "templatePilotRescue", "templateSquadRescue"]): { 18 };
                default { 15 };
            };
            FLO_Intel_System call ["addIntel", [_intelReward, "mission_complete"]];
            ["INTEL", 3, format["Mission %1 complete: +%2 intel", _type, _intelReward]] call FLO_fnc_log;
        };

        // Run cleanup function
        if (!isNil "_template") then {
            private _fnc_cleanup = _template getOrDefault ["fnc_cleanup", {}];
            [_missionId, _instance] call _fnc_cleanup;
        };

        // Cleanup tracked entities
        ["cleanup", [_missionId]] call FLO_fnc_sideMissionEntityTracker;

        // Update task if exists
        private _taskId = _instance getOrDefault ["taskId", ""];
        if (_taskId != "") then {
            private _taskState = if (_success) then { "SUCCEEDED" } else { "FAILED" };
            [_taskId, _taskState] call BIS_fnc_taskSetState;
        };

        // Schedule registry and task cleanup
        [_missionId] spawn {
            params ["_id"];
            sleep 60;
            
            // Remove the BIS Task from UI (immediate deletion)
            [_id, 0, true] call FLO_fnc_sideMissionTaskCleanup;
            
            // Remove data from registry
            ["delete", [_id]] call FLO_fnc_sideMissionRegistry;
        };

        diag_log format ["[FLO_SM] Completed mission %1: %2 (%3)", _missionId, if (_success) then {"SUCCESS"} else {"FAILED"}, _reason];
        _result = true;
    };

    default {
        diag_log format ["[FLO_SM] Manager: Unknown operation: %1", _operation];
        _result = nil;
    };
};

_result

