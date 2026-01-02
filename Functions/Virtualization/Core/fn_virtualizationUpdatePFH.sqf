/*
 * Function: FLO_fnc_virtualizationUpdatePFH
 * Author: Frontline Operations Development Group
 * Description:
 *   Main virtualization update loop using CBA PerFrameHandler (unscheduled).
 *   Replaces the old spawn/while loop for reliable, non-blocking execution.
 *
 *   Features:
 *   - Self-throttling (configurable update interval)
 *   - Batch processing (N groups per cycle)
 *   - Tiered updates (near groups update faster)
 *   - Player position caching
 *
 * Arguments:
 * 0: Mode <STRING> - "start", "stop", "restart"
 *
 * Return Value:
 * Boolean - Success
 *
 * Example:
 * ["start"] call FLO_fnc_virtualizationUpdatePFH;
 */

params [["_mode", "start", [""]]];

// ============================================================================
// CONFIGURATION
// ============================================================================
#define UPDATE_INTERVAL_NEAR    2     // Groups within 1000m - every 2 seconds
#define UPDATE_INTERVAL_MID     5     // Groups 1000-2500m - every 5 seconds
#define UPDATE_INTERVAL_FAR     15    // Groups > 2500m - every 15 seconds
#define BATCH_SIZE              25    // Groups to process per update cycle
#define PLAYER_CACHE_INTERVAL   1     // Cache player positions every 1 second

// ============================================================================
// INITIALIZATION
// ============================================================================
FLO_VirtUpdate = createHashMapFromArray [
    ["pfhId", -1],
    ["running", false],
    ["lastUpdateTime", 0],
    ["lastPlayerCacheTime", 0],
    ["cachedPlayerPositions", []],
    ["currentBatchIndex", 0],
    ["groupUpdateTimes", createHashMap],  // groupId -> lastUpdateTime
    ["stats", createHashMapFromArray [
        ["cyclesRun", 0],
        ["groupsProcessed", 0],
        ["activationsThisCycle", 0],
        ["deactivationsThisCycle", 0]
    ]]
];

// ============================================================================
// HELPER FUNCTIONS (defined as variables for PFH access)
// ============================================================================

// Get nearest cached player distance to a position
FLO_VirtUpdate_getNearestPlayerDist = {
    params ["_pos"];
    private _cachedPlayers = FLO_VirtUpdate get "cachedPlayerPositions";
    private _nearest = 999999;
    
    {
        _x params ["_pPos", "_inAir"];
        if (!_inAir) then {  // Skip players in aircraft
            private _dist = _pos distance2D _pPos;
            if (_dist < _nearest) then { _nearest = _dist };
        };
    } forEach _cachedPlayers;
    
    _nearest
};

// Cache player positions (called at interval)
FLO_VirtUpdate_cachePlayers = {
    private _cached = [];
    {
        if (alive _x && side _x == west) then {
            private _veh = vehicle _x;
            private _inAir = (_veh != _x) && (_veh isKindOf "Air");
            _cached pushBack [getPosATL _x, _inAir];
        };
    } forEach allPlayers;
    
    FLO_VirtUpdate set ["cachedPlayerPositions", _cached];
    FLO_VirtUpdate set ["lastPlayerCacheTime", diag_tickTime];
};

// Validate position
FLO_VirtUpdate_isValidPos = {
    params ["_pos"];
    (_pos isEqualType []) && 
    {count _pos >= 2} && 
    {((_pos select 0) > 100) || ((_pos select 1) > 100)}
};

// ============================================================================
// MODE HANDLERS
// ============================================================================

switch (toLower _mode) do {

    // ------------------------------------------------------------------------
    // START - Begin the update PFH
    // ------------------------------------------------------------------------
    case "start": {
        if (FLO_VirtUpdate get "running") exitWith {
            ["VIRTUALIZATION", 3, "Update PFH already running"] call FLO_fnc_log;
            true
        };

        private _pfhId = [{
            // Exit early if virtualization not ready
            if !(FLO_virtualGroups get "_enabled") exitWith {};

            private _now = diag_tickTime;
            
            // Update player cache if needed
            private _lastCache = FLO_VirtUpdate get "lastPlayerCacheTime";
            if (_now - _lastCache >= PLAYER_CACHE_INTERVAL) then {
                [] call FLO_VirtUpdate_cachePlayers;
            };

            // Get groups
            private _groups = FLO_virtualGroups get "_groups";
            private _groupIds = keys _groups;
            private _totalGroups = count _groupIds;
            private _activationDist = FLO_virtualGroups get "_activationDistance";
            private _groupUpdateTimes = FLO_VirtUpdate get "groupUpdateTimes";

            // Process batch of groups
            private _batchStart = FLO_VirtUpdate get "currentBatchIndex";
            private _batchEnd = (_batchStart + BATCH_SIZE - 1) min (_totalGroups - 1);
            private _processed = 0;

            for "_i" from _batchStart to _batchEnd do {
                private _groupId = _groupIds select _i;
                private _groupData = _groups get _groupId;
                
                [_groupId, _groupData, _activationDist, _now, _groupUpdateTimes] 
                    call FLO_fnc_virtualizationProcessGroup;
                _processed = _processed + 1;
            };

            // Update batch index
            private _nextBatch = _batchEnd + 1;
            if (_nextBatch >= _totalGroups) then {
                FLO_VirtUpdate set ["currentBatchIndex", 0];
                // Full cycle complete - update stats
                private _stats = FLO_VirtUpdate get "stats";
                _stats set ["cyclesRun", (_stats get "cyclesRun") + 1];
            } else {
                FLO_VirtUpdate set ["currentBatchIndex", _nextBatch];
            };

        }, 0, []] call CBA_fnc_addPerFrameHandler;

        FLO_VirtUpdate set ["pfhId", _pfhId];
        FLO_VirtUpdate set ["running", true];
        FLO_VirtualGroupsUpdateLoopRunning = true;  // Compatibility flag

        ["VIRTUALIZATION", 3, "Update PFH started (unscheduled)"] call FLO_fnc_log;
        true
    };

    // ------------------------------------------------------------------------
    // STOP - Stop the update PFH
    // ------------------------------------------------------------------------
    case "stop": {
        private _pfhId = FLO_VirtUpdate get "pfhId";
        if (_pfhId >= 0) then {
            [_pfhId] call CBA_fnc_removePerFrameHandler;
            FLO_VirtUpdate set ["pfhId", -1];
        };
        
        FLO_VirtUpdate set ["running", false];
        FLO_VirtualGroupsUpdateLoopRunning = false;

        ["VIRTUALIZATION", 3, "Update PFH stopped"] call FLO_fnc_log;
        true
    };

    // ------------------------------------------------------------------------
    // RESTART - Stop and start fresh
    // ------------------------------------------------------------------------
    case "restart": {
        ["stop"] call FLO_fnc_virtualizationUpdatePFH;
        ["start"] call FLO_fnc_virtualizationUpdatePFH;
    };

    default { false };
};

