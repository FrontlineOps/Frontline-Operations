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
if (isNil "FLO_VirtUpdate") then {
    FLO_VirtUpdate = createHashMapFromArray [
        ["pfhId", -1],
        ["running", false],
        ["lastUpdateTime", 0],
        ["lastPlayerCacheTime", 0],
        ["lastGroupCacheTime", 0],
        ["cachedPlayerPositions", []],
        ["cachedGroupIds", []],
        ["currentBatchIndex", 0],
        ["batchSize", BATCH_SIZE],
        ["playerCacheInterval", PLAYER_CACHE_INTERVAL],
        ["groupUpdateTimes", createHashMap],  // groupId -> lastUpdateTime
        ["stats", createHashMapFromArray [
            ["cyclesRun", 0],
            ["groupsProcessedTotal", 0],
            ["groupsProcessedThisBatch", 0],
            ["totalGroupsLast", 0],
            ["activeGroupsLast", 0],
            ["inactiveGroupsLast", 0],
            ["lastBatchStart", 0],
            ["lastBatchEnd", -1],
            ["lastBatchMs", 0],
            ["peakBatchMs", 0],
            ["lastPlayerCacheMs", 0],
            ["peakPlayerCacheMs", 0],
            ["lastGroupCacheMs", 0],
            ["peakGroupCacheMs", 0],
            ["lastGroupProcessMs", 0],
            ["peakGroupProcessMs", 0],
            ["lastSlowGroupId", ""],
            ["lastSlowGroupType", ""],
            ["lastSlowGroupMs", 0],
            ["activationsTotal", 0],
            ["activationsThisBatch", 0],
            ["deactivationsTotal", 0],
            ["deactivationsThisBatch", 0],
            ["virtualMovesTotal", 0],
            ["virtualMovesThisBatch", 0],
            ["activePositionSyncsTotal", 0],
            ["activePositionSyncsThisBatch", 0],
            ["waypointAdvancesTotal", 0],
            ["waypointAdvancesThisBatch", 0],
            ["patrolAssignmentsTotal", 0],
            ["patrolAssignmentsThisBatch", 0],
            ["attachedSyncsTotal", 0],
            ["attachedSyncsThisBatch", 0],
            ["tierSkipsTotal", 0],
            ["tierSkipsThisBatch", 0],
            ["missionHoldSkipsTotal", 0],
            ["missionHoldSkipsThisBatch", 0],
            ["eliminatedGroupsTotal", 0],
            ["eliminatedGroupsThisBatch", 0],
            ["slowBatchCount", 0],
            ["slowGroupCount", 0]
        ]],
        ["perf", createHashMapFromArray [
            ["slowBatchThresholdMs", 8],
            ["slowGroupThresholdMs", 2],
            ["logCooldownSec", 5],
            ["nextSlowBatchLogAt", 0],
            ["nextSlowGroupLogAt", 0]
        ]]
    ];
};

if (isNil { FLO_VirtUpdate get "batchSize" }) then {
    FLO_VirtUpdate set ["batchSize", BATCH_SIZE];
};

if (isNil { FLO_VirtUpdate get "playerCacheInterval" }) then {
    FLO_VirtUpdate set ["playerCacheInterval", PLAYER_CACHE_INTERVAL];
};

private _virtStatsDefaults = createHashMapFromArray [
    ["cyclesRun", 0],
    ["groupsProcessedTotal", 0],
    ["groupsProcessedThisBatch", 0],
    ["totalGroupsLast", 0],
    ["activeGroupsLast", 0],
    ["inactiveGroupsLast", 0],
    ["lastBatchStart", 0],
    ["lastBatchEnd", -1],
    ["lastBatchMs", 0],
    ["peakBatchMs", 0],
    ["lastPlayerCacheMs", 0],
    ["peakPlayerCacheMs", 0],
    ["lastGroupCacheMs", 0],
    ["peakGroupCacheMs", 0],
    ["lastGroupProcessMs", 0],
    ["peakGroupProcessMs", 0],
    ["lastSlowGroupId", ""],
    ["lastSlowGroupType", ""],
    ["lastSlowGroupMs", 0],
    ["activationsTotal", 0],
    ["activationsThisBatch", 0],
    ["deactivationsTotal", 0],
    ["deactivationsThisBatch", 0],
    ["virtualMovesTotal", 0],
    ["virtualMovesThisBatch", 0],
    ["activePositionSyncsTotal", 0],
    ["activePositionSyncsThisBatch", 0],
    ["waypointAdvancesTotal", 0],
    ["waypointAdvancesThisBatch", 0],
    ["patrolAssignmentsTotal", 0],
    ["patrolAssignmentsThisBatch", 0],
    ["attachedSyncsTotal", 0],
    ["attachedSyncsThisBatch", 0],
    ["tierSkipsTotal", 0],
    ["tierSkipsThisBatch", 0],
    ["missionHoldSkipsTotal", 0],
    ["missionHoldSkipsThisBatch", 0],
    ["eliminatedGroupsTotal", 0],
    ["eliminatedGroupsThisBatch", 0],
    ["slowBatchCount", 0],
    ["slowGroupCount", 0]
];

if (isNil { FLO_VirtUpdate get "stats" }) then {
    FLO_VirtUpdate set ["stats", _virtStatsDefaults];
} else {
    private _stats = FLO_VirtUpdate get "stats";
    {
        if (isNil { _stats get _x }) then {
            _stats set [_x, _y];
        };
    } forEach _virtStatsDefaults;
};

private _virtPerfDefaults = createHashMapFromArray [
    ["slowBatchThresholdMs", 8],
    ["slowGroupThresholdMs", 2],
    ["logCooldownSec", 5],
    ["nextSlowBatchLogAt", 0],
    ["nextSlowGroupLogAt", 0]
];

if (isNil { FLO_VirtUpdate get "perf" }) then {
    FLO_VirtUpdate set ["perf", _virtPerfDefaults];
} else {
    private _perf = FLO_VirtUpdate get "perf";
    {
        if (isNil { _perf get _x }) then {
            _perf set [_x, _y];
        };
    } forEach _virtPerfDefaults;
};

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
            private _stats = FLO_VirtUpdate get "stats";
            private _perf = FLO_VirtUpdate get "perf";
            private _batchStartTime = diag_tickTime;

            _stats set ["groupsProcessedThisBatch", 0];
            _stats set ["activationsThisBatch", 0];
            _stats set ["deactivationsThisBatch", 0];
            _stats set ["virtualMovesThisBatch", 0];
            _stats set ["activePositionSyncsThisBatch", 0];
            _stats set ["waypointAdvancesThisBatch", 0];
            _stats set ["patrolAssignmentsThisBatch", 0];
            _stats set ["attachedSyncsThisBatch", 0];
            _stats set ["tierSkipsThisBatch", 0];
            _stats set ["missionHoldSkipsThisBatch", 0];
            _stats set ["eliminatedGroupsThisBatch", 0];
            _stats set ["lastPlayerCacheMs", 0];
            _stats set ["lastGroupCacheMs", 0];
            
            // Update player cache if needed
            private _lastCache = FLO_VirtUpdate get "lastPlayerCacheTime";
            if (_now - _lastCache >= PLAYER_CACHE_INTERVAL) then {
                private _cachePlayersStart = diag_tickTime;
                [] call FLO_VirtUpdate_cachePlayers;
                private _cachePlayersMs = (diag_tickTime - _cachePlayersStart) * 1000;
                _stats set ["lastPlayerCacheMs", _cachePlayersMs];
                if (_cachePlayersMs > (_stats get "peakPlayerCacheMs")) then {
                    _stats set ["peakPlayerCacheMs", _cachePlayersMs];
                };
            };

            // Get groups
            private _groups = FLO_virtualGroups get "_groups";
            if ((count _groups) == 0) exitWith {
                FLO_VirtUpdate set ["cachedGroupIds", []];
                FLO_VirtUpdate set ["currentBatchIndex", 0];
                _stats set ["totalGroupsLast", 0];
                _stats set ["activeGroupsLast", 0];
                _stats set ["inactiveGroupsLast", 0];
                _stats set ["lastBatchStart", 0];
                _stats set ["lastBatchEnd", -1];
                _stats set ["lastBatchMs", (diag_tickTime - _batchStartTime) * 1000];
            };

            private _groupIds = FLO_VirtUpdate get "cachedGroupIds";
            private _lastGroupCache = FLO_VirtUpdate get "lastGroupCacheTime";
            if (_now - _lastGroupCache >= 1 || {count _groupIds != count _groups}) then {
                private _groupCacheStart = diag_tickTime;
                _groupIds = keys _groups;
                FLO_VirtUpdate set ["cachedGroupIds", _groupIds];
                FLO_VirtUpdate set ["lastGroupCacheTime", _now];

                private _activeGroups = 0;
                {
                    private _gData = _groups get _x;
                    if (_gData get "isActive") then {
                        _activeGroups = _activeGroups + 1;
                    };
                } forEach _groupIds;

                _stats set ["totalGroupsLast", count _groupIds];
                _stats set ["activeGroupsLast", _activeGroups];
                _stats set ["inactiveGroupsLast", (count _groupIds) - _activeGroups];

                private _groupCacheMs = (diag_tickTime - _groupCacheStart) * 1000;
                _stats set ["lastGroupCacheMs", _groupCacheMs];
                if (_groupCacheMs > (_stats get "peakGroupCacheMs")) then {
                    _stats set ["peakGroupCacheMs", _groupCacheMs];
                };
            };
            private _totalGroups = count _groupIds;
            private _activationDist = FLO_virtualGroups get "_activationDistance";
            private _groupUpdateTimes = FLO_VirtUpdate get "groupUpdateTimes";

            // Process batch of groups
            private _batchStart = FLO_VirtUpdate get "currentBatchIndex";
            if (_batchStart >= _totalGroups) then {
                _batchStart = 0;
                FLO_VirtUpdate set ["currentBatchIndex", 0];
            };
            private _batchEnd = (_batchStart + BATCH_SIZE - 1) min (_totalGroups - 1);
            private _processed = 0;
            _stats set ["lastBatchStart", _batchStart];
            _stats set ["lastBatchEnd", _batchEnd];

            for "_i" from _batchStart to _batchEnd do {
                private _groupId = _groupIds select _i;
                private _groupData = _groups get _groupId;
                private _groupStart = diag_tickTime;
                [_groupId, _groupData, _activationDist, _now, _groupUpdateTimes] 
                    call FLO_fnc_virtualizationProcessGroup;
                private _groupMs = (diag_tickTime - _groupStart) * 1000;
                _stats set ["lastGroupProcessMs", _groupMs];
                if (_groupMs > (_stats get "peakGroupProcessMs")) then {
                    _stats set ["peakGroupProcessMs", _groupMs];
                };

                if (_groupMs >= (_perf get "slowGroupThresholdMs") && {_now >= (_perf get "nextSlowGroupLogAt")}) then {
                    _stats set ["slowGroupCount", (_stats get "slowGroupCount") + 1];
                    _stats set ["lastSlowGroupId", _groupId];
                    _stats set ["lastSlowGroupType", _groupData get "groupType"];
                    _stats set ["lastSlowGroupMs", _groupMs];
                    _perf set ["nextSlowGroupLogAt", _now + (_perf get "logCooldownSec")];
                    diag_log format [
                        "[FLO][PERF] Virtualization group %1 type=%2 active=%3 missionLock=%4 in %5 ms",
                        _groupId,
                        _groupData get "groupType",
                        _groupData get "isActive",
                        _groupData get "missionLock",
                        _groupMs
                    ];
                };

                _processed = _processed + 1;
            };

            _stats set ["groupsProcessedThisBatch", _processed];
            _stats set ["groupsProcessedTotal", (_stats get "groupsProcessedTotal") + _processed];

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

            private _batchMs = (diag_tickTime - _batchStartTime) * 1000;
            _stats set ["lastBatchMs", _batchMs];
            if (_batchMs > (_stats get "peakBatchMs")) then {
                _stats set ["peakBatchMs", _batchMs];
            };

            if (_batchMs >= (_perf get "slowBatchThresholdMs") && {_now >= (_perf get "nextSlowBatchLogAt")}) then {
                _stats set ["slowBatchCount", (_stats get "slowBatchCount") + 1];
                _perf set ["nextSlowBatchLogAt", _now + (_perf get "logCooldownSec")];
                diag_log format [
                    "[FLO][PERF] Virtualization PFH processed %1 groups (batch %2-%3 of %4) in %5 ms | playerCache=%6 groupCache=%7 activations=%8 deactivations=%9 virtualMoves=%10 activeSyncs=%11 waypointAdv=%12 patrols=%13 attached=%14 tierSkips=%15 missionSkips=%16 eliminated=%17",
                    _processed,
                    _batchStart,
                    _batchEnd,
                    _totalGroups,
                    _batchMs,
                    _stats get "lastPlayerCacheMs",
                    _stats get "lastGroupCacheMs",
                    _stats get "activationsThisBatch",
                    _stats get "deactivationsThisBatch",
                    _stats get "virtualMovesThisBatch",
                    _stats get "activePositionSyncsThisBatch",
                    _stats get "waypointAdvancesThisBatch",
                    _stats get "patrolAssignmentsThisBatch",
                    _stats get "attachedSyncsThisBatch",
                    _stats get "tierSkipsThisBatch",
                    _stats get "missionHoldSkipsThisBatch",
                    _stats get "eliminatedGroupsThisBatch"
                ];
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

    case "stats": {
        FLO_VirtUpdate get "stats"
    };

    case "resetstats": {
        private _stats = FLO_VirtUpdate get "stats";
        {
            _stats set [_x, _y];
        } forEach (createHashMapFromArray [
            ["cyclesRun", 0],
            ["groupsProcessedTotal", 0],
            ["groupsProcessedThisBatch", 0],
            ["totalGroupsLast", 0],
            ["activeGroupsLast", 0],
            ["inactiveGroupsLast", 0],
            ["lastBatchStart", 0],
            ["lastBatchEnd", -1],
            ["lastBatchMs", 0],
            ["peakBatchMs", 0],
            ["lastPlayerCacheMs", 0],
            ["peakPlayerCacheMs", 0],
            ["lastGroupCacheMs", 0],
            ["peakGroupCacheMs", 0],
            ["lastGroupProcessMs", 0],
            ["peakGroupProcessMs", 0],
            ["lastSlowGroupId", ""],
            ["lastSlowGroupType", ""],
            ["lastSlowGroupMs", 0],
            ["activationsTotal", 0],
            ["activationsThisBatch", 0],
            ["deactivationsTotal", 0],
            ["deactivationsThisBatch", 0],
            ["virtualMovesTotal", 0],
            ["virtualMovesThisBatch", 0],
            ["activePositionSyncsTotal", 0],
            ["activePositionSyncsThisBatch", 0],
            ["waypointAdvancesTotal", 0],
            ["waypointAdvancesThisBatch", 0],
            ["patrolAssignmentsTotal", 0],
            ["patrolAssignmentsThisBatch", 0],
            ["attachedSyncsTotal", 0],
            ["attachedSyncsThisBatch", 0],
            ["tierSkipsTotal", 0],
            ["tierSkipsThisBatch", 0],
            ["missionHoldSkipsTotal", 0],
            ["missionHoldSkipsThisBatch", 0],
            ["eliminatedGroupsTotal", 0],
            ["eliminatedGroupsThisBatch", 0],
            ["slowBatchCount", 0],
            ["slowGroupCount", 0]
        ]);
        private _perf = FLO_VirtUpdate get "perf";
        _perf set ["nextSlowBatchLogAt", 0];
        _perf set ["nextSlowGroupLogAt", 0];
        true
    };

    default { false };
};
