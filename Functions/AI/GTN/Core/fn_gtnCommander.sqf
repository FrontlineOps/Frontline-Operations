/*
 * Function: FLO_fnc_gtnCommander
 * Author: Frontline Operations Development Group
 * 
 * Description:
 * Goal Task Network Commander - Main integration point for GTN-based AI Commander.
 * Creates and manages all GTN subsystems (World State, Goal Library, Planner, Executor, Monitor).
 * Provides the main update loop that drives goal-driven behavior.
 *
 * Arguments:
 * 0: Commander Host <HASHMAP> - Host object for GTN integration
 * 1: Side Context <HASHMAP> - Normalized own/enemy side context
 *
 * Return Value:
 * GTN Commander HashMap Object <HASHMAP>
 *
 * Example:
 * private _gtnCmdr = [_host, [east] call FLO_fnc_gtnSideContext] call FLO_fnc_gtnCommander;
 * _gtnCmdr call ["_start", []];
 */

params [
    ["_commander", nil],
    ["_sideContext", createHashMap]
];

if (isNil "_commander") exitWith {
    ["GTN", 1, "GTN Commander requires commander reference"] call FLO_fnc_log;
    nil
};

if (isNil "_sideContext" || {!(_sideContext isEqualType createHashMap)} || {count _sideContext == 0}) then {
    _sideContext = [east] call FLO_fnc_gtnSideContext;
};

private _ownSide = _sideContext get "ownSide";
private _enemySide = _sideContext get "enemySide";
private _sideKey = _sideContext get "sideKey";

["GTN", 2, format["Initializing GTN Commander System (%1)", _sideKey]] call FLO_fnc_log;

// Create all subsystems
private _worldState = [_sideContext] call FLO_fnc_gtnWorldState;
private _goalLibrary = call FLO_fnc_gtnGoalLibrary;
private _planner = [_goalLibrary, _worldState] call FLO_fnc_gtnPlanner;
private _executor = [_commander, _sideContext] call FLO_fnc_gtnExecutor;
private _monitor = [_planner, _worldState] call FLO_fnc_gtnMonitor;
private _capabilityAnalyzer = call FLO_fnc_gtnCapabilityAnalyzer;
private _artilleryManager = call FLO_fnc_gtnArtilleryManager;

private _attackTrackCount = FLO_GTN_AttackLaneHandle get "value";
private _defenseCoverage = FLO_GTN_DefenseCoverageHandle get "value";
private _defenseTrackCount = 1;
private _tempoInterval = FLO_GTN_TempoHandle get "value";
private _difficultyValue = FLO_DifficultyHandle get "value";
private _garrisonHandle = FLO_GTN_GarrisonHandle;
private _aggressionValue = _difficultyValue / 1.5;
private _garrisonRearBaseGroups = _garrisonHandle get "rearBaseGroups";
private _garrisonFrontlineBaseGroups = _garrisonHandle get "frontlineBaseGroups";
private _garrisonPriorityBonusGroups = _garrisonHandle get "priorityBonusGroups";
private _garrisonHotBonusGroups = _garrisonHandle get "hotBonusGroups";

private _trackTotal = _attackTrackCount + _defenseTrackCount;
private _resourceShare = 1 / _trackTotal;
private _tracks = [];

for "_i" from 1 to _attackTrackCount do {
    _tracks pushBack (createHashMapFromArray [
        ["id", format["ATK_%1", _i]],
        ["goal", "capture_priority_objective"],
        ["resourceShare", _resourceShare],
        ["planner", nil],
        ["status", "IDLE"],
        ["groupPool", []],
        ["frontSectorObjectives", []],
        ["frontSectorAnchorPos", []],
        ["phase", "quiet"],
        ["phaseChangedAt", 0],
        ["phaseUntil", 0],
        ["phaseObjectiveId", ""],
        ["phaseStagingGoal", 0]
    ]);
};

for "_i" from 1 to _defenseTrackCount do {
    _tracks pushBack (createHashMapFromArray [
        ["id", format["DEF_%1", _i]],
        ["goal", "protect_critical_assets"],
        ["resourceShare", _resourceShare],
        ["planner", nil],
        ["status", "IDLE"],
        ["groupPool", []],
        ["frontSectorObjectives", []],
        ["frontSectorAnchorPos", []]
    ]);
};

_worldState set ["_updateInterval", _tempoInterval];

private _gtnCommander = createHashMapObject [[
    // Subsystem references
    ["_commander", _commander],
    ["_sideContext", _sideContext],
    ["_ownSide", _ownSide],
    ["_enemySide", _enemySide],
    ["_sideKey", _sideKey],
    ["_worldState", _worldState],
    ["_goalLibrary", _goalLibrary],
    ["_planner", _planner],
    ["_executor", _executor],
    ["_monitor", _monitor],
    ["_capabilityAnalyzer", _capabilityAnalyzer],
    ["_artilleryManager", _artilleryManager],
    
    // State (using 0/1 for booleans to avoid parsing issues)
    ["_isRunning", 0],
    ["_updateInterval", _tempoInterval],
    ["_lastUpdate", 0],
    
    ["_tracks", _tracks],
    ["_nextTrackExecutionIndex", 0],
    ["_availabilityCacheDirty", true],
    ["_availabilityCandidates", []],
    ["_availabilityOwnSideTotal", 0],
    ["_forceBaselineTotalGroups", 0],
    ["_attackObjectiveReservations", createHashMap],
    ["_frontlineCAPLocks", createHashMap],
    ["_frontlineCASLocks", createHashMap],
    
    // Configuration
    ["_config", createHashMapFromArray [
        ["aggressiveness", _aggressionValue],      // 0-1, affects offensive vs defensive posture
        ["riskTolerance", _aggressionValue],       // 0-1, affects willingness to attack with lower ratios
        ["replanInterval", 60],       // Minimum seconds between replans
        ["casualtyThreshold", 0.2],   // Force loss ratio to trigger replan
        ["defenseLeaseSeconds", 300], // Release long-idle DEFEND groups back into the task pool
        ["defenseCoverageMultiplier", _defenseCoverage], // Scales per-objective defense caps without multiplying DEF tracks
        ["attackReservationSpreadMeters", 5000], // Distance penalty per reservation to distribute attack tracks
        ["attackCrossSectorPenaltyMeters", 2500], // Tracks prefer objectives linked to their assigned frontline sectors
        ["attackGroupsPerFrontLink", 6], // Scale live attack cap by number of direct friendly frontage links
        ["attackGroupsPerReserveObjective", 2], // Rear connected friendly objectives raise attack cap, but less than direct frontage links
        ["attackMinGroupCap", 8], // Never commit less than a meaningful assault package to one objective
        ["attackMaxGroupCap", 18], // Hard cap to stop theater-wide dogpiles on one objective
        ["attackDispatchMinGroups", 6], // Minimum group pull when opening an assault package
        ["attackDispatchMaxGroups", 14], // Upper bound per attack pull so one primitive does not consume the whole theater
        ["attackReserveGraphDepth", 4], // Attack reserve pulls follow friendly objective graph rings deep enough to mobilize connected rear sectors
        ["attackLaneStagingMinGroups", 6], // Tracks wait for a meaningful reserve package before opening an assault
        ["attackLaneStagingGoalFraction", 0.6], // Tracks stage toward a meaningful share of the current attack deficit, not just a flat minimum
        ["attackLaneCautiousStrengthRatio", 0.75], // Below this theater-wide force ratio, attacks become harder to launch even if one lane has local groups
        ["attackLaneExhaustedStrengthRatio", 0.5], // Below this ratio, the side is too depleted to begin new assaults
        ["attackLaneCautiousGoalMultiplier", 1.25], // Cautious posture needs a larger reserve package before opening an assault
        ["attackLaneTimeoutAssaultFraction", 0.75], // Timeout can only force an assault once most of the staged package is actually ready
        ["attackLaneMaxStagingSeconds", 480], // After this window, staging may assault with a reduced-but-still-meaningful package
        ["attackLaneAssaultDurationSeconds", 360], // Assault windows stay open long enough for one burst of committed attacks
        ["attackLaneSpentDurationSeconds", 240], // Cooldown after an assault so reserves and logistics can catch up
        ["garrisonRearBaseGroups", _garrisonRearBaseGroups], // Minimum standing rear garrison on owned quiet objectives
        ["garrisonFrontlineBaseGroups", _garrisonFrontlineBaseGroups], // Minimum standing garrison on owned objectives exposed to enemy adjacency
        ["garrisonPriorityBonusThreshold", 60], // Important objectives receive one extra standing garrison group
        ["garrisonPriorityBonusGroups", _garrisonPriorityBonusGroups], // High-priority objectives keep one more standing holder before surge defense fills
        ["garrisonHotBonusGroups", _garrisonHotBonusGroups], // Objectives already under pressure keep an extra baseline holder even before reactive defense fills
        ["frontlineCAPMinThreatScore", 70], // Only spend CAP when recent enemy air contacts near a frontline sector are meaningful
        ["frontlineCAPContactFreshSeconds", 360], // Ignore stale air contacts for CAP scoring
        ["frontlineCAPContactRadiusMeters", 4000], // Friendly frontline sectors only count air contacts in their local airspace
        ["frontlineCAPObjectiveLockSeconds", 720], // CAP missions loiter for a while; keep sectors locked longer than CAS
        ["frontlineCASMinAttackers", 4], // Do not spend CAS on token attacks with no meaningful committed assault package
        ["frontlineCASMinScore", 80], // Prevent trivial objectives from consuming air support
        ["frontlineCASObjectiveLockSeconds", 420], // Cooldown per objective so repeated cycles do not spam CAS on the same target
        ["defenseReserveGraphDepth", 2], // Defense reserve pulls stay on the friendly objective graph around the threatened sector
        ["defenseDispatchMinGroups", 4], // Minimum groups to commit when reinforcing a pressured sector
        ["defenseDispatchMaxGroups", 12], // Upper bound per defense pull; repeated tasks can still fill the cap
        ["garrisonDispatchMinGroups", 3], // Minimum garrison package once an objective is selected
        ["garrisonDispatchMaxGroups", 10], // Upper bound per garrison assignment pass
        ["maxTrackTasksPerCycle", 2], // Primitive burst cap per track per commander update
        ["debugMode", false]          // Enable verbose logging
    ]],
    
    // Statistics
    ["_stats", createHashMapFromArray [
        ["cyclesRun", 0],
        ["plansCreated", 0],
        ["tasksExecuted", 0],
        ["replans", 0],
        ["startTime", 0]
    ]],
    ["_perf", createHashMapFromArray [
        ["enabled", true],
        ["logThresholdMs", 20],
        ["lastCycleMs", 0],
        ["peakCycleMs", 0],
        ["slowCycles", 0],
        ["lastPhaseMs", createHashMapFromArray [
            ["normalizeTasked", 0],
            ["worldState", 0],
            ["attackAssignments", 0],
            ["allocateTracks", 0],
            ["executeTracks", 0],
            ["frontlineCAP", 0],
            ["frontlineCAS", 0],
            ["defenseLeases", 0],
            ["staticAA", 0],
            ["forcePreservation", 0]
        ]],
        ["lastMetrics", createHashMap]
    ]],
    
    // === MAIN CONTROL ===
    
    // Start the GTN commander
    ["_start", {
        if ((_self get "_isRunning") isEqualTo 1) exitWith {
            ["GTN", 3, "GTN Commander already running"] call FLO_fnc_log;
        };

        _self set ["_isRunning", 1];

        private _stats = _self get "_stats";
        _stats set ["startTime", diag_tickTime];

        // Initialize track system
        _self call ["_initializeTracks", []];

        private _tracks = _self get "_tracks";
        private _attackTracks = { (_x get "goal") == "capture_priority_objective" } count _tracks;
        private _defenseTracks = { (_x get "goal") == "protect_critical_assets" } count _tracks;
        ["GTN", 2, format[
            "GTN Commander started (attack tracks: %1, defense tracks: %2, defense coverage: %3, tempo: %4s)",
            _attackTracks,
            _defenseTracks,
            ((_self get "_config") get "defenseCoverageMultiplier"),
            _self get "_updateInterval"
        ]] call FLO_fnc_log;
    }],

    // Stop the GTN commander
    ["_stop", {
        _self set ["_isRunning", 0];
        ["GTN", 2, "GTN Commander stopped"] call FLO_fnc_log;
    }],

    // Main update cycle - call this from commander's update loop
    ["_update", {
        if ((_self get "_isRunning") isEqualTo 0) exitWith {};
        if (!(missionNamespace getVariable ["FLO_MissionReady", false])) exitWith {};
        
        private _now = diag_tickTime;
        _self set ["_lastUpdate", _now];
        private _perf = _self get "_perf";
        private _phaseMs = createHashMapFromArray [
            ["normalizeTasked", 0],
            ["worldState", 0],
            ["attackAssignments", 0],
            ["garrisons", 0],
            ["allocateTracks", 0],
            ["trackPhases", 0],
            ["executeTracks", 0],
            ["frontlineCAP", 0],
            ["frontlineCAS", 0],
            ["defenseLeases", 0],
            ["staticAA", 0],
            ["forcePreservation", 0]
        ];
        private _cycleStart = diag_tickTime;
        private _tPhase = diag_tickTime;
        private _normalizeMetrics = _self call ["_normalizeTaskedGroups", []];
        _phaseMs set ["normalizeTasked", (diag_tickTime - _tPhase) * 1000];
        _self set ["_availabilityCacheDirty", true];
        
        private _stats = _self get "_stats";
        _stats set ["cyclesRun", (_stats get "cyclesRun") + 1];
        private _cycleIndex = _stats get "cyclesRun";
        
        ["GTN", 3, format["GTN Cycle %1 starting", _cycleIndex]] call FLO_fnc_log;

        // Update world state
        private _ws = _self get "_worldState";
        _tPhase = diag_tickTime;
        private _wsRan = _ws call ["_update", []];
        _phaseMs set ["worldState", (diag_tickTime - _tPhase) * 1000];
        private _wsPerf = _ws call ["_getPerf", []];

        // Log world state summary
        private _forces = _ws call ["_getForces", []];
        private _situation = _ws call ["_getTacticalSituation", []];
        private _enemyObjs = _ws call ["_getEnemyObjectives", []];
        ["GTN", 3, format["World State: Available=%1, Momentum=%2, EnemyObjs=%3",
            _forces get "availableGroups",
            _situation get "momentum",
            count (keys _enemyObjs)
        ]] call FLO_fnc_log;

        // Reset per-cycle attack objective reservations so tracks spread within the same cycle.
        _self set ["_attackObjectiveReservations", createHashMap];

        // Release attack-tasked groups whose objective is no longer enemy-held.
        _tPhase = diag_tickTime;
        private _attackAssignmentMetrics = _self call ["_manageCompletedAttackAssignments", []];
        _phaseMs set ["attackAssignments", (diag_tickTime - _tPhase) * 1000];

        // Maintain standing garrisons before building mobile attack pools.
        _tPhase = diag_tickTime;
        private _garrisonMetrics = [_self] call FLO_fnc_gtnAllocateBaselineGarrisons;
        _phaseMs set ["garrisons", (diag_tickTime - _tPhase) * 1000];

        // Allocate groups to tracks (refreshes each cycle)
        _tPhase = diag_tickTime;
        private _allocationMetrics = _self call ["_allocateGroupsToTracks", []];
        _phaseMs set ["allocateTracks", (diag_tickTime - _tPhase) * 1000];

        // Update attack lane phases so assaults happen in bursts instead of every cycle.
        _tPhase = diag_tickTime;
        private _trackPhaseMetrics = [_self] call FLO_fnc_gtnUpdateAttackTrackPhases;
        _phaseMs set ["trackPhases", (diag_tickTime - _tPhase) * 1000];
        
        // Execute all tracks in parallel
        _tPhase = diag_tickTime;
        private _executeMetrics = _self call ["_executeAllTracks", []];
        _phaseMs set ["executeTracks", (diag_tickTime - _tPhase) * 1000];

        // Request one opportunistic CAP mission for the most threatened friendly frontline sector.
        _tPhase = diag_tickTime;
        private _frontlineCAPMetrics = [_self] call FLO_fnc_gtnRequestFrontlineCAP;
        _phaseMs set ["frontlineCAP", (diag_tickTime - _tPhase) * 1000];

        // Request one opportunistic CAS mission for the strongest active frontline attack.
        _tPhase = diag_tickTime;
        private _frontlineCASMetrics = [_self] call FLO_fnc_gtnRequestFrontlineCAS;
        _phaseMs set ["frontlineCAS", (diag_tickTime - _tPhase) * 1000];

        // Release DEFEND-tasked groups that sat idle too long in low-pressure sectors.
        _tPhase = diag_tickTime;
        private _leaseMetrics = _self call ["_manageDefenseLeases", []];
        _phaseMs set ["defenseLeases", (diag_tickTime - _tPhase) * 1000];

        // Static AA deployment finalization (creation is handled by logistics network)
        _tPhase = diag_tickTime;
        private _staticAAMetrics = _self call ["_manageStaticAANetwork", []];
        _phaseMs set ["staticAA", (diag_tickTime - _tPhase) * 1000];

        // Manage force preservation (Retreats & Replenishment)
        _tPhase = diag_tickTime;
        private _forcePreservationMetrics = _self call ["_manageForcePreservation", []];
        _phaseMs set ["forcePreservation", (diag_tickTime - _tPhase) * 1000];

        private _groups = FLO_virtualGroups get "_groups";
        private _registryGroupCount = count (keys _groups);
        private _dtMs = (diag_tickTime - _cycleStart) * 1000;
        private _metrics = createHashMapFromArray [
            ["cycleIndex", _cycleIndex],
            ["groupCount", _registryGroupCount],
            ["registryGroupCount", _registryGroupCount],
            ["ownSideGroupCount", _allocationMetrics get "ownSideGroups"],
            ["availableGroupCount", _allocationMetrics get "availableCount"],
            ["taskedCount", count (_self get "_gtnTaskedGroups")],
            ["trackCount", count (_self get "_tracks")],
            ["normalize", _normalizeMetrics],
            ["worldStateRan", _wsRan],
            ["worldState", _wsPerf],
            ["attackAssignments", _attackAssignmentMetrics],
            ["garrisons", _garrisonMetrics],
            ["allocation", _allocationMetrics],
            ["trackPhases", _trackPhaseMetrics],
            ["execute", _executeMetrics],
            ["frontlineCAP", _frontlineCAPMetrics],
            ["frontlineCAS", _frontlineCASMetrics],
            ["defenseLeases", _leaseMetrics],
            ["staticAA", _staticAAMetrics],
            ["forcePreservation", _forcePreservationMetrics]
        ];

        _perf set ["lastCycleMs", _dtMs];
        _perf set ["lastPhaseMs", _phaseMs];
        _perf set ["lastMetrics", _metrics];
        if (_dtMs > (_perf get "peakCycleMs")) then {
            _perf set ["peakCycleMs", _dtMs];
        };
        if (_dtMs > (_perf get "logThresholdMs")) then {
            _perf set ["slowCycles", (_perf get "slowCycles") + 1];

            diag_log format [
                "[FLO][PERF] GTN commander %1 cycle %2 groups registry=%3 own=%4 available=%5 tasked=%6 tracks=%7 in %8 ms | normalize=%9 ws=%10 attack=%11 garrisons=%12 allocate=%13 phases=%14 execute=%15 cap=%16 cas=%17 defense=%18 staticAA=%19 preserve=%20",
                _self get "_sideKey",
                _cycleIndex,
                _metrics get "registryGroupCount",
                _metrics get "ownSideGroupCount",
                _metrics get "availableGroupCount",
                _metrics get "taskedCount",
                _metrics get "trackCount",
                _dtMs,
                _phaseMs get "normalizeTasked",
                _phaseMs get "worldState",
                _phaseMs get "attackAssignments",
                _phaseMs get "garrisons",
                _phaseMs get "allocateTracks",
                _phaseMs get "trackPhases",
                _phaseMs get "executeTracks",
                _phaseMs get "frontlineCAP",
                _phaseMs get "frontlineCAS",
                _phaseMs get "defenseLeases",
                _phaseMs get "staticAA",
                _phaseMs get "forcePreservation"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 availability | cacheDirty=%2 registry=%3 own=%4 available=%5 scanMs=%6 roundRobinMs=%7 normalizeChanged=%8",
                _self get "_sideKey",
                (_allocationMetrics get "cacheDirty"),
                _allocationMetrics get "totalGroups",
                _allocationMetrics get "ownSideGroups",
                _allocationMetrics get "availableCount",
                _allocationMetrics get "scanMs",
                _allocationMetrics get "roundRobinMs",
                _normalizeMetrics get "changed"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 tracks | idle=%2 running=%3 empty=%4 phaseSkips=%5 planCalls=%6 plans=%7 planTasks=%8 planMs=%9 execCalls=%10 execMs=%11 execFail=%12 checkCalls=%13 checkMs=%14 sync=%15 tasks=%16 complete=%17 failed=%18",
                _self get "_sideKey",
                _executeMetrics get "idleTracks",
                _executeMetrics get "runningTracks",
                _executeMetrics get "emptyPoolSkips",
                _executeMetrics get "phaseSkips",
                _executeMetrics get "planCalls",
                _executeMetrics get "plansCreated",
                _executeMetrics get "planTaskTotal",
                _executeMetrics get "planMs",
                _executeMetrics get "primitiveExecCalls",
                _executeMetrics get "primitiveExecMs",
                _executeMetrics get "primitiveFailures",
                _executeMetrics get "checkCalls",
                _executeMetrics get "checkMs",
                _executeMetrics get "syncSuccesses",
                _executeMetrics get "tasksExecuted",
                _executeMetrics get "plansCompleted",
                _executeMetrics get "plansFailed"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 trackPhases | quiet=%2 staging=%3 assault=%4 spent=%5 transitions=%6 selected=%7 posture=%8 strength=%9 baseline=%10 current=%11",
                _self get "_sideKey",
                _trackPhaseMetrics get "quietCount",
                _trackPhaseMetrics get "stagingCount",
                _trackPhaseMetrics get "assaultCount",
                _trackPhaseMetrics get "spentCount",
                _trackPhaseMetrics get "transitionCount",
                _trackPhaseMetrics get "selectedObjectiveCount",
                _trackPhaseMetrics get "posture",
                _trackPhaseMetrics get "theaterStrengthRatio",
                _trackPhaseMetrics get "baselineTotalGroups",
                _trackPhaseMetrics get "currentTotalGroups"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 garrisons | existing=%2 released=%3 candidates=%4 eligible=%5 assigned=%6 opened=%7 reinforced=%8 reserveBands=%9 passes=%10",
                _self get "_sideKey",
                _garrisonMetrics get "existingGarrisons",
                _garrisonMetrics get "releasedGroups",
                _garrisonMetrics get "candidateObjectives",
                _garrisonMetrics get "eligibleGroups",
                _garrisonMetrics get "assignedGroups",
                _garrisonMetrics get "openedObjectives",
                _garrisonMetrics get "reinforcedObjectives",
                _garrisonMetrics get "reserveBandBuilds",
                _garrisonMetrics get "assignmentPasses"
            ];

            if (_wsRan) then {
                private _wsPhase = _wsPerf get "lastPhaseMs";
                private _wsMeta = _wsPerf get "lastMeta";
                diag_log format [
                    "[FLO][PERF] GTN commander %1 worldState | total=%2 objectives=%3 forces=%4 support=%5 intel=%6 tactical=%7 | objCount=%8 available=%9 contacts=%10 concentrations=%11 supportRan=%12 intelRan=%13",
                    _self get "_sideKey",
                    _wsPerf get "lastUpdateMs",
                    _wsPhase get "objectives",
                    _wsPhase get "forces",
                    _wsPhase get "supportAssets",
                    _wsPhase get "enemyIntel",
                    _wsPhase get "tacticalSituation",
                    _wsMeta get "objectiveCount",
                    _wsMeta get "availableGroups",
                    _wsMeta get "contactCount",
                    _wsMeta get "concentrationCount",
                    _wsMeta get "supportSenseRan",
                    _wsMeta get "enemyIntelSenseRan"
                ];
            };

            diag_log format [
                "[FLO][PERF] GTN commander %1 maintenance | defenseReleased=%2 defenseTrimmed=%3 defenseHolds=%4 defenseLost=%5 attackReleased=%6 aaMoving=%7 aaDeployed=%8 preserveScanned=%9 retreats=%10 arrivals=%11 replenishTicks=%12 returned=%13 vehicleRespawns=%14",
                _self get "_sideKey",
                _leaseMetrics get "releasedCount",
                _leaseMetrics get "trimmedExcess",
                _leaseMetrics get "holdRefreshCount",
                _leaseMetrics get "lostObjectiveReleaseCount",
                _attackAssignmentMetrics get "releasedCount",
                _staticAAMetrics get "movingStaticAACount",
                _staticAAMetrics get "deployedCount",
                _forcePreservationMetrics get "groupCount",
                _forcePreservationMetrics get "retreatOrders",
                _forcePreservationMetrics get "retreatArrivals",
                _forcePreservationMetrics get "replenishTicks",
                _forcePreservationMetrics get "returnedToDuty",
                _forcePreservationMetrics get "vehicleRespawns"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 frontlineCAP | asset=%2 contacts=%3 candidates=%4 eligible=%5 locked=%6 requested=%7 objective=%8 score=%9",
                _self get "_sideKey",
                _frontlineCAPMetrics get "assetAvailable",
                _frontlineCAPMetrics get "airContactCount",
                _frontlineCAPMetrics get "candidateCount",
                _frontlineCAPMetrics get "eligibleCount",
                _frontlineCAPMetrics get "lockedCount",
                _frontlineCAPMetrics get "requestedCount",
                _frontlineCAPMetrics get "selectedObjective",
                _frontlineCAPMetrics get "selectedScore"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 frontlineCAS | asset=%2 candidates=%3 eligible=%4 locked=%5 requested=%6 objective=%7 score=%8",
                _self get "_sideKey",
                _frontlineCASMetrics get "assetAvailable",
                _frontlineCASMetrics get "candidateCount",
                _frontlineCASMetrics get "eligibleCount",
                _frontlineCASMetrics get "lockedCount",
                _frontlineCASMetrics get "requestedCount",
                _frontlineCASMetrics get "selectedObjective",
                _frontlineCASMetrics get "selectedScore"
            ];
        };
        
        // Log decision summary for debugging
        //_self call ["_logDecisionSummary", []];
        //_self call ["_dumpStatus", []];
    }],
    
    // === TRACK SYSTEM ===
    
    // Initialize track planners
    ["_initializeTracks", {
        private _goalLib = _self get "_goalLibrary";
        private _ws = _self get "_worldState";
        private _tracks = _self get "_tracks";
        
        {
            private _track = _x;
            private _trackId = _track get "id";
            
            // Each track gets its own planner instance
            private _planner = [_goalLib, _ws] call FLO_fnc_gtnPlanner;
            _track set ["planner", _planner];
            
            ["GTN", 3, format["Track %1 initialized with goal: %2", _trackId, _track get "goal"]] call FLO_fnc_log;
        } forEach _tracks;
    }],
    
    // Assign attack tracks to distinct frontline source sectors before pool allocation.
    ["_buildAttackTrackSectors", {
        params [["_attackTracks", []]];

        {
            _x set ["frontSectorObjectives", []];
            _x set ["frontSectorAnchorPos", []];
        } forEach _attackTracks;

        if ((count _attackTracks) == 0) exitWith { createHashMap };

        private _ws = _self get "_worldState";
        private _ownSide = _self get "_ownSide";
        private _allObjectives = _ws call ["_getObjectives", []];
        private _frontlineEnemyObjectives = _ws call ["_getFrontlineEnemyObjectives", []];
        private _sourceScores = createHashMap;
        private _sourcePositions = createHashMap;

        {
            private _enemyObj = _frontlineEnemyObjectives get _x;
            private _scoreAdd = (_enemyObj get "priority")
                + ((_enemyObj get "enemyCount") * 2)
                + (_enemyObj get "friendlyCount")
                + (if (_enemyObj get "contested") then { 20 } else { 0 });

            {
                private _sourceObj = _allObjectives get _x;
                if (isNil "_sourceObj") then { continue };
                if ((_sourceObj get "owner") != _ownSide) then { continue };

                private _sourceScore = if (_x in _sourceScores) then {
                    _sourceScores get _x
                } else {
                    0
                };
                _sourceScores set [_x, _sourceScore + _scoreAdd];
                _sourcePositions set [_x, _sourceObj get "position"];
            } forEach (_enemyObj get "linkedObjectives");
        } forEach (keys _frontlineEnemyObjectives);

        if ((count (keys _sourceScores)) == 0) exitWith { createHashMap };

        private _rankedSources = [];
        {
            _rankedSources pushBack [-( _sourceScores get _x), _x];
        } forEach (keys _sourceScores);
        _rankedSources sort true;

        private _trackAssignments = [];
        {
            _trackAssignments pushBack [_x, []];
        } forEach _attackTracks;

        for "_i" from 0 to ((count _rankedSources) - 1) do {
            private _sourceObjId = (_rankedSources select _i) select 1;
            private _sourcePos = _sourcePositions get _sourceObjId;
            private _selectedIdx = -1;

            for "_j" from 0 to ((count _trackAssignments) - 1) do {
                if ((count ((_trackAssignments select _j) select 1)) == 0) exitWith {
                    _selectedIdx = _j;
                };
            };

            if (_selectedIdx < 0) then {
                private _bestDist = 1e12;
                private _bestAssignedCount = 1000000;

                for "_j" from 0 to ((count _trackAssignments) - 1) do {
                    private _pair = _trackAssignments select _j;
                    private _assignedSources = _pair select 1;
                    private _sumX = 0;
                    private _sumY = 0;

                    {
                        private _assignedPos = _sourcePositions get _x;
                        _sumX = _sumX + (_assignedPos select 0);
                        _sumY = _sumY + (_assignedPos select 1);
                    } forEach _assignedSources;

                    private _anchorPos = [_sumX / (count _assignedSources), _sumY / (count _assignedSources), 0];
                    private _dist = _anchorPos distance2D _sourcePos;

                    if (
                        _dist < _bestDist
                        || { _dist == _bestDist && { (count _assignedSources) < _bestAssignedCount } }
                    ) then {
                        _bestDist = _dist;
                        _bestAssignedCount = count _assignedSources;
                        _selectedIdx = _j;
                    };
                };
            };

            private _selectedPair = _trackAssignments select _selectedIdx;
            private _selectedSources = _selectedPair select 1;
            _selectedSources pushBack _sourceObjId;
            _selectedPair set [1, _selectedSources];
            _trackAssignments set [_selectedIdx, _selectedPair];
        };

        private _sectorMap = createHashMap;
        {
            _x params ["_track", "_sectorObjectives"];

            private _anchorPos = [];
            if ((count _sectorObjectives) > 0) then {
                private _sumX = 0;
                private _sumY = 0;

                {
                    private _objPos = _sourcePositions get _x;
                    _sumX = _sumX + (_objPos select 0);
                    _sumY = _sumY + (_objPos select 1);
                } forEach _sectorObjectives;

                _anchorPos = [_sumX / (count _sectorObjectives), _sumY / (count _sectorObjectives), 0];
            };

            _track set ["frontSectorObjectives", _sectorObjectives];
            _track set ["frontSectorAnchorPos", _anchorPos];
            _sectorMap set [_track get "id", _sectorObjectives];
        } forEach _trackAssignments;

        _sectorMap
    }],

    // Allocate available groups to tracks using frontline sectors instead of blind round-robin.
    ["_allocateGroupsToTracks", {
        private _tracks = _self get "_tracks";
        private _metrics = createHashMapFromArray [
            ["cacheDirty", _self get "_availabilityCacheDirty"],
            ["totalGroups", 0],
            ["ownSideGroups", _self get "_availabilityOwnSideTotal"],
            ["availableCount", 0],
            ["allocatedCount", 0],
            ["trackCount", count _tracks],
            ["frontSectorCount", 0],
            ["scanMs", 0],
            ["roundRobinMs", 0]
        ];
        
        // Get all available groups (not currently tasked)
        private _totalGroups = count (keys (FLO_virtualGroups get "_groups"));
        _metrics set ["totalGroups", _totalGroups];
        private _tScan = diag_tickTime;
        private _allAvailable = _self call ["_getAvailableGroups", [_totalGroups]];
        _metrics set ["scanMs", (diag_tickTime - _tScan) * 1000];
        _metrics set ["ownSideGroups", _self get "_availabilityOwnSideTotal"];
        private _totalCount = count _allAvailable;
        _metrics set ["availableCount", _totalCount];
        
        // Clear existing pools
        {
            _x set ["groupPool", []];
            _x set ["frontSectorObjectives", []];
            _x set ["frontSectorAnchorPos", []];
        } forEach _tracks;
        
        if (_totalCount == 0) exitWith {
            ["GTN", 2, "No available groups to allocate to tracks"] call FLO_fnc_log;
            _metrics
        };
        
        private _attackTracks = _tracks select { (_x get "goal") == "capture_priority_objective" };
        private _defenseTracks = _tracks select { (_x get "goal") == "protect_critical_assets" };
        private _defenseTrack = if ((count _defenseTracks) > 0) then { _defenseTracks select 0 } else { nil };
        private _ws = _self get "_worldState";
        private _allObjectives = _ws call ["_getObjectives", []];
        private _frontSectors = _self call ["_buildAttackTrackSectors", [_attackTracks]];
        _metrics set ["frontSectorCount", count (keys _frontSectors)];
        private _attackReserveGraphDepth = ((_self get "_config") get "attackReserveGraphDepth");
        private _trackReserveBands = createHashMap;

        {
            private _sectorObjectives = _x get "frontSectorObjectives";
            private _reserveBands = createHashMap;
            if ((count _sectorObjectives) > 0) then {
                _reserveBands = [_self, _sectorObjectives, _attackReserveGraphDepth] call FLO_fnc_gtnBuildObjectiveReserveBands;
            };

            _trackReserveBands set [_x get "id", _reserveBands];
        } forEach _attackTracks;

        // Front-aware allocation to tracks.
        private _tRoundRobin = diag_tickTime;
        private _ownSide = _self get "_ownSide";
        private _allGroups = FLO_virtualGroups get "_groups";
        private _fallbackAttackBand = _attackReserveGraphDepth + 1;

        {
            private _groupId = _x;
            private _gData = _allGroups get _groupId;
            if (isNil "_gData") then { continue };

            private _assignedTrack = nil;
            private _homeObjective = _gData get "homeObjective";
            private _currentOrder = _gData get "commanderOrder";
            private _groupPos = _gData get "position";

            if (!isNil "_defenseTrack") then {
                if (_currentOrder == "DEFEND") then {
                    _assignedTrack = _defenseTrack;
                };

                if (isNil "_assignedTrack" && {_homeObjective != ""} && {_homeObjective in _allObjectives}) then {
                    private _homeObj = _allObjectives get _homeObjective;
                    if ((_homeObj get "owner") == _ownSide && {(_homeObj get "underAttack") || (_homeObj get "contested")}) then {
                        _assignedTrack = _defenseTrack;
                    };
                };
            };

            if (isNil "_assignedTrack" && {(count _attackTracks) > 0}) then {
                private _bestTrack = nil;
                private _bestBand = 10;
                private _bestDist = 1e12;
                private _bestPool = 1000000;

                {
                    private _anchorPos = _x get "frontSectorAnchorPos";
                    private _reserveBands = _trackReserveBands get (_x get "id");
                    private _band = _fallbackAttackBand;
                    if (_homeObjective in _reserveBands) then {
                        _band = _reserveBands get _homeObjective;
                    };

                    private _dist = if ((count _anchorPos) >= 2) then { _groupPos distance2D _anchorPos } else { 1e12 };
                    private _poolSize = count (_x get "groupPool");

                    if (
                        _band < _bestBand
                        || { _band == _bestBand && { _dist < _bestDist } }
                        || { _band == _bestBand && { _dist == _bestDist && { _poolSize < _bestPool } } }
                    ) then {
                        _bestTrack = _x;
                        _bestBand = _band;
                        _bestDist = _dist;
                        _bestPool = _poolSize;
                    };
                } forEach _attackTracks;

                _assignedTrack = _bestTrack;
            };

            if (isNil "_assignedTrack" && {!isNil "_defenseTrack"}) then {
                _assignedTrack = _defenseTrack;
            };

            if (isNil "_assignedTrack" && {(count _attackTracks) > 0}) then {
                private _leastLoadedTrack = _attackTracks select 0;
                private _leastLoadedCount = count (_leastLoadedTrack get "groupPool");

                {
                    private _poolCount = count (_x get "groupPool");
                    if (_poolCount < _leastLoadedCount) then {
                        _leastLoadedTrack = _x;
                        _leastLoadedCount = _poolCount;
                    };
                } forEach _attackTracks;

                _assignedTrack = _leastLoadedTrack;
            };

            if (isNil "_assignedTrack") then { continue };

            private _pool = _assignedTrack get "groupPool";
            _pool pushBack _groupId;
            _assignedTrack set ["groupPool", _pool];
        } forEach _allAvailable;
        _metrics set ["roundRobinMs", (diag_tickTime - _tRoundRobin) * 1000];
        _metrics set ["allocatedCount", _totalCount];
        
        // Log allocation
        {
            private _track = _x;
            ["GTN", 3, format["Track %1 (%2) allocated %3 groups (front sectors=%4)",
                _track get "id",
                _track get "goal",
                count (_track get "groupPool"),
                count (_track get "frontSectorObjectives")
            ]] call FLO_fnc_log;
        } forEach _tracks;

        _metrics
    }],
    
    // Execute one ready defense track alongside one ready attack track per cycle.
    ["_executeAllTracks", {
        private _tracks = _self get "_tracks";
        private _trackCount = count _tracks;
        private _metrics = createHashMapFromArray [
            ["tracksTotal", _trackCount],
            ["idleTracks", { (_x get "status") == "IDLE" } count _tracks],
            ["runningTracks", { (_x get "status") == "RUNNING" } count _tracks],
            ["emptyPoolSkips", 0],
            ["phaseSkips", 0],
            ["planCalls", 0],
            ["plansCreated", 0],
            ["planTaskTotal", 0],
            ["planMs", 0],
            ["primitiveExecCalls", 0],
            ["primitiveExecMs", 0],
            ["primitiveFailures", 0],
            ["checkCalls", 0],
            ["checkMs", 0],
            ["syncSuccesses", 0],
            ["tasksExecuted", 0],
            ["plansCompleted", 0],
            ["plansFailed", 0],
            ["processedTrackId", ""],
            ["processedTrackIds", []]
        ];

        if (_trackCount == 0) exitWith { _metrics };

        private _startIdx = _self get "_nextTrackExecutionIndex";
        if (_startIdx >= _trackCount) then {
            _startIdx = 0;
        };

        private _selectedDefenseIdx = -1;
        {
            if ((_x get "goal") != "protect_critical_assets") then { continue };

            private _trackReady = (_x get "status") == "RUNNING";
            if (!_trackReady && {count (_x get "groupPool") > 0}) then {
                _trackReady = true;
            };

            if (_trackReady) exitWith {
                _selectedDefenseIdx = _forEachIndex;
            };
        } forEach _tracks;

        private _selectedAttackIdx = -1;
        for "_offset" from 0 to (_trackCount - 1) do {
            private _idx = (_startIdx + _offset) mod _trackCount;
            private _track = _tracks select _idx;
            private _trackGoal = _track get "goal";
            if (_trackGoal != "capture_priority_objective") then { continue };
            private _trackReady = (_track get "status") == "RUNNING";

            if (!_trackReady && {count (_track get "groupPool") > 0}) then {
                _trackReady = (_track get "phase") == "assault";
            };

            if (_trackReady) exitWith {
                _selectedAttackIdx = _idx;
            };
        };

        if (_selectedDefenseIdx < 0 && {_selectedAttackIdx < 0}) exitWith { _metrics };

        private _advanceIdx = if (_selectedAttackIdx >= 0) then {
            _selectedAttackIdx
        } else {
            _selectedDefenseIdx
        };
        _self set ["_nextTrackExecutionIndex", (_advanceIdx + 1) mod _trackCount];

        private _aggregateKeys = [
            "emptyPoolSkips",
            "phaseSkips",
            "planCalls",
            "plansCreated",
            "planTaskTotal",
            "planMs",
            "primitiveExecCalls",
            "primitiveExecMs",
            "primitiveFailures",
            "checkCalls",
            "checkMs",
            "syncSuccesses",
            "tasksExecuted",
            "plansCompleted",
            "plansFailed"
        ];

        if (_selectedDefenseIdx >= 0) then {
            private _defenseMetrics = [_self, _tracks select _selectedDefenseIdx] call FLO_fnc_gtnExecuteTrackCycle;
            {
                _metrics set [_x, (_metrics get _x) + (_defenseMetrics get _x)];
            } forEach _aggregateKeys;

            private _processedTrackIds = _metrics get "processedTrackIds";
            _processedTrackIds pushBack (_defenseMetrics get "processedTrackId");
            _metrics set ["processedTrackIds", _processedTrackIds];
            if ((_metrics get "processedTrackId") == "") then {
                _metrics set ["processedTrackId", _defenseMetrics get "processedTrackId"];
            };
        };

        if (_selectedAttackIdx >= 0) then {
            private _attackMetrics = [_self, _tracks select _selectedAttackIdx] call FLO_fnc_gtnExecuteTrackCycle;
            {
                _metrics set [_x, (_metrics get _x) + (_attackMetrics get _x)];
            } forEach _aggregateKeys;

            private _processedTrackIds = _metrics get "processedTrackIds";
            _processedTrackIds pushBack (_attackMetrics get "processedTrackId");
            _metrics set ["processedTrackIds", _processedTrackIds];
            if ((_metrics get "processedTrackId") == "") then {
                _metrics set ["processedTrackId", _attackMetrics get "processedTrackId"];
            };
        };

        _metrics
    }],
    
    // Get groups from a track's pool
    ["_getGroupsFromTrack", {
        params ["_track", "_count", ["_targetPos", []]];
        
        private _pool = _track get "groupPool";
        private _allGroups = FLO_virtualGroups get "_groups";
        private _tasked = _self get "_gtnTaskedGroups";
        private _filteredPool = [];
        {
            private _gData = _allGroups get _x;
            if (isNil "_gData") then { continue };
            if (_x in _tasked) then { continue };
            private _currentOrder = _gData get "commanderOrder";
            if (_currentOrder != "" && {!(_currentOrder in ["PATROL", "DEFEND", ""])}) then { continue };
            _filteredPool pushBack _x;
        } forEach _pool;
        _pool = _filteredPool;

        if (count _targetPos >= 2) then {
            private _scored = [];
            {
                private _gData = _allGroups get _x;
                _scored pushBack [((_gData get "position") distance2D _targetPos), _x];
            } forEach _pool;
            _scored sort true;
            _pool = _scored apply { _x select 1 };
        };

        private _result = [];
        
        {
            if (count _result >= _count) exitWith {};
            _result pushBack _x;
        } forEach _pool;
        
        // Remove consumed groups from pool
        {
            _pool deleteAt (_pool find _x);
        } forEach _result;
        _track set ["groupPool", _pool];
        
        ["GTN", 3, format["Track %1: Consumed %2 groups (requested %3, %4 remaining in pool)", 
            _track get "id", count _result, _count, count _pool]] call FLO_fnc_log;
        
        _result
    }],
    
    // Set a track's goal dynamically
    ["_setTrackGoal", {
        params ["_trackId", "_newGoal"];
        
        private _tracks = _self get "_tracks";
        {
            if ((_x get "id") == _trackId) exitWith {
                _x set ["goal", _newGoal];
                _x set ["status", "IDLE"];  // Force replan
                ["GTN", 2, format["Track %1 goal changed to: %2", _trackId, _newGoal]] call FLO_fnc_log;
            };
        } forEach _tracks;
    }],

    // === GOAL MANAGEMENT ===

    // Set a new strategic goal
    ["_setGoal", {
        params ["_goalId", ["_params", []]];

        _self set ["_currentGoal", _goalId];

        private _monitor = _self get "_monitor";
        _monitor call ["_setCurrentGoal", [_goalId, _params]];

        // Create new plan for new goal
        _self call ["_createPlan", []];

        ["GTN", 3, format["Goal set to: %1", _goalId]] call FLO_fnc_log;
    }],

    // === CONFIGURATION ===

    ["_configure", {
        params ["_key", "_value"];
        private _config = _self get "_config";
        _config set [_key, _value];

        // Apply relevant config to subsystems
        if (_key == "replanInterval") then {
            private _monitor = _self get "_monitor";
            _monitor call ["_setThresholds", [nil, _value, nil]];
        };

        if (_key == "casualtyThreshold") then {
            private _monitor = _self get "_monitor";
            _monitor call ["_setThresholds", [_value, nil, nil]];
        };
    }],

    // === QUERY METHODS ===

    ["_getWorldState", {
        _self get "_worldState"
    }],

    ["_getPlanner", {
        _self get "_planner"
    }],

    ["_getStats", {
        _self get "_stats"
    }],

    ["_getPerf", {
        _self get "_perf"
    }],

    ["_isRunning", {
        _self get "_isRunning"
    }],

    ["_getSideContext", {
        _self get "_sideContext"
    }],

    ["_getOwnSide", {
        _self get "_ownSide"
    }],

    ["_getEnemySide", {
        _self get "_enemySide"
    }],

    ["_getResourceObject", {
        private _sideKey = _self get "_sideKey";
        FLO_SideResources get _sideKey
    }],

    // === TACTICAL METHODS (used by executor handlers) ===

    ["_allocateFrontlineAttacks", {
        params [["_track", nil]];
        [_self, _track] call FLO_fnc_gtnAllocateFrontlineAttacks
    }],

    ["_allocateFrontlineDefense", {
        params [["_track", nil]];
        [_self, _track] call FLO_fnc_gtnAllocateFrontlineDefense
    }],

    ["_manageCompletedAttackAssignments", {
        [_self] call FLO_fnc_gtnReleaseCompletedAttackAssignments
    }],

    // Select nearest frontline enemy objective (priority only as a tie-breaker).
    ["_selectPriorityObjective", {
        params [["_trackId", ""]];
        private _ws = _self get "_worldState";
        private _ownSide = _self get "_ownSide";
        private _allObjectives = _ws call ["_getObjectives", []];
        private _objectives = _ws call ["_getFrontlineEnemyObjectives", []];
        private _reservations = _self get "_attackObjectiveReservations";
        private _spreadMeters = ((_self get "_config") get "attackReservationSpreadMeters");
        private _crossSectorPenalty = ((_self get "_config") get "attackCrossSectorPenaltyMeters");
        private _trackAnchorPos = [];
        private _trackSectorObjectives = [];
        private _phaseObjectiveId = "";

        if (count (keys _objectives) == 0) then {
            _objectives = _ws call ["_getEnemyObjectives", []];
            ["GTN", 3, "No frontline enemy objectives; falling back to all enemy objectives"] call FLO_fnc_log;
        };
        if (count (keys _objectives) == 0) exitWith { "" };

        if (_trackId != "") then {
            private _tracks = _self get "_tracks";
            private _trackPool = [];
            {
                if ((_x get "id") == _trackId) exitWith {
                    _trackPool = _x get "groupPool";
                    _trackSectorObjectives = _x get "frontSectorObjectives";
                    _trackAnchorPos = +(_x get "frontSectorAnchorPos");
                    _phaseObjectiveId = _x get "phaseObjectiveId";
                };
            } forEach _tracks;

            if (count _trackPool > 0) then {
                private _groupMap = FLO_virtualGroups get "_groups";
                private _sumX = 0;
                private _sumY = 0;
                private _count = 0;

                {
                    private _gData = _groupMap get _x;
                    if (isNil "_gData") then { continue };
                    private _pos = _gData get "position";
                    _sumX = _sumX + (_pos select 0);
                    _sumY = _sumY + (_pos select 1);
                    _count = _count + 1;
                } forEach _trackPool;

                if (_count > 0) then {
                    _trackAnchorPos = [_sumX / _count, _sumY / _count, 0];
                };
            };
        };

        if (_phaseObjectiveId != "" && {_phaseObjectiveId in _objectives}) exitWith {
            private _reserved = if (_phaseObjectiveId in _reservations) then {
                _reservations get _phaseObjectiveId
            } else {
                0
            };
            _reservations set [_phaseObjectiveId, _reserved + 1];
            _phaseObjectiveId
        };

        private _activeAttackCounts = createHashMap;
        {
            private _gData = _y;
            if ((_gData get "side") != _ownSide) then { continue };
            if ((_gData get "commanderOrder") != "ATTACK") then { continue };

            private _attackObjective = _gData get "attackObjective";
            if (_attackObjective == "") then { continue };

            private _activeAttackCount = if (_attackObjective in _activeAttackCounts) then {
                _activeAttackCounts get _attackObjective
            } else {
                0
            };
            _activeAttackCounts set [_attackObjective, _activeAttackCount + 1];
        } forEach (FLO_virtualGroups get "_groups");

        private _config = _self get "_config";
        private _attackCapByObjective = createHashMap;
        private _landCandidates = [];
        private _allCandidates = [];

        {
            private _objId = _x;
            private _obj = _objectives get _objId;
            private _links = _obj get "linkedObjectives";
            private _priority = _obj get "priority";

            private _bestAnyDist = 1e12;
            private _bestLandDist = 1e12;

            {
                private _linkedObj = _allObjectives get _x;
                if ((_linkedObj get "owner") != _ownSide) then { continue };

                private _route = _ws call ["_getObjectiveLinkRouteInfo", [_x, _objId]];
                private _routeDist = _route get "distance";
                private _crossesWater = _route get "crossesWater";

                if (_routeDist < _bestAnyDist) then {
                    _bestAnyDist = _routeDist;
                };
                if (!_crossesWater && {_routeDist < _bestLandDist}) then {
                    _bestLandDist = _routeDist;
                };
            } forEach _links;

            _allCandidates pushBack [_objId, _priority, _bestAnyDist];
            if (_bestLandDist < 1e12) then {
                _landCandidates pushBack [_objId, _priority, _bestLandDist];
            };
        } forEach (keys _objectives);

        private _selectionPool = if (count _landCandidates > 0) then {
            _landCandidates
        } else {
            _allCandidates
        };

        if (count _landCandidates == 0) then {
            ["GTN", 3, format["Priority selection fallback: no land-connected frontline objectives, using %1 cross-water candidates", count _allCandidates]] call FLO_fnc_log;
        };

        private _availableTargets = [];
        private _sectorAvailableTargets = [];
        private _saturatedTargets = [];
        private _sectorSaturatedTargets = [];
        {
            _x params ["_objId", "_priority", "_routeDist"];

            private _reserved = if (_objId in _reservations) then {
                _reservations get _objId
            } else {
                0
            };
            private _activeAttackers = if (_objId in _activeAttackCounts) then {
                _activeAttackCounts get _objId
            } else {
                0
            };
            private _attackCap = _attackCapByObjective getOrDefault [_objId, -1];
            if (_attackCap < 0) then {
                _attackCap = _self call ["_getAttackCapForObjective", [_objId]];
                _attackCapByObjective set [_objId, _attackCap];
            };
            private _committed = _reserved + _activeAttackers;
            private _selectionDist = _routeDist;
            if (count _trackAnchorPos >= 2) then {
                _selectionDist = _trackAnchorPos distance2D ((_objectives get _objId) get "position");
            };
            private _sectorMatch = (count _trackSectorObjectives == 0)
                || { (count (((_objectives get _objId) get "linkedObjectives") arrayIntersect _trackSectorObjectives)) > 0 };
            private _effectiveDist = _selectionDist + (_committed * _spreadMeters);
            if (!_sectorMatch) then {
                _effectiveDist = _effectiveDist + _crossSectorPenalty;
            };
            private _candidate = [_objId, _priority, _selectionDist, _effectiveDist, _reserved, _activeAttackers, _attackCap, _committed];

            if (_attackCap > 0 && {_committed < _attackCap}) then {
                _availableTargets pushBack _candidate;
                if (_sectorMatch) then {
                    _sectorAvailableTargets pushBack _candidate;
                };
            } else {
                _saturatedTargets pushBack _candidate;
                if (_sectorMatch) then {
                    _sectorSaturatedTargets pushBack _candidate;
                };
            };
        } forEach _selectionPool;

        private _candidatePool = if (count _sectorAvailableTargets > 0) then {
            _sectorAvailableTargets
        } else {
            if (count _availableTargets > 0) then {
                _availableTargets
            } else {
                if (count _sectorSaturatedTargets > 0) then {
                    _sectorSaturatedTargets
                } else {
                    _saturatedTargets
                }
            }
        };

        if (count _availableTargets == 0 && {count _saturatedTargets > 0}) then {
            ["GTN", 3, format["Priority selection fallback: all %1 candidate objectives already at attack cap", count _saturatedTargets]] call FLO_fnc_log;
        };
        if (_trackId != "" && {(count _trackSectorObjectives) > 0} && {count _sectorAvailableTargets == 0} && {count _sectorSaturatedTargets == 0}) then {
            ["GTN", 3, format["Priority selection fallback: %1 has no sector-linked enemy objective, widening search", _trackId]] call FLO_fnc_log;
        };

        private _bestObj = "";
        private _bestPriority = -1e12;
        private _bestDist = 1e12;
        private _bestEffectiveDist = 1e12;
        private _bestReserved = 1000000000;
        private _bestActiveAttackers = 0;
        private _bestAttackCap = 0;

        {
            _x params ["_objId", "_priority", "_selectionDist", "_effectiveDist", "_reserved", "_activeAttackers", "_attackCap", "_committed"];

            if (
                _effectiveDist < _bestEffectiveDist
                || { _effectiveDist == _bestEffectiveDist && { _selectionDist < _bestDist } }
                || { _effectiveDist == _bestEffectiveDist && { _selectionDist == _bestDist && { _reserved < _bestReserved } } }
                || { _effectiveDist == _bestEffectiveDist && { _selectionDist == _bestDist && { _reserved == _bestReserved && { _priority > _bestPriority } } } }
            ) then {
                _bestObj = _objId;
                _bestDist = _selectionDist;
                _bestEffectiveDist = _effectiveDist;
                _bestReserved = _reserved;
                _bestPriority = _priority;
                _bestActiveAttackers = _activeAttackers;
                _bestAttackCap = _attackCap;
            };
        } forEach _candidatePool;

        if (_bestObj != "") then {
            _reservations set [_bestObj, _bestReserved + 1];
            if (_trackId != "") then {
                ["GTN", 3, format[
                    "Nearest objective reserved for %1: %2 (dist=%3m, effective=%4, reservations=%5, active=%6/%7)",
                    _trackId,
                    _bestObj,
                    round _bestDist,
                    round _bestEffectiveDist,
                    _bestReserved + 1,
                    _bestActiveAttackers,
                    _bestAttackCap
                ]] call FLO_fnc_log;
            };
        };

        _bestObj
    }],

    // Groups currently tasked by GTN (prevent AI Commander from using them)
    ["_gtnTaskedGroups", []],

    ["_normalizeTaskedGroups", {
        private _tasked = _self get "_gtnTaskedGroups";
        private _normalized = [];
        private _beforeCount = count _tasked;

        {
            private _groupId = if (_x isEqualType []) then { _x param [0, ""] } else { _x };
            if (_groupId != "") then {
                _normalized pushBackUnique _groupId;
            };
        } forEach _tasked;

        private _afterCount = count _normalized;
        if (_afterCount != _beforeCount) then {
            _self set ["_gtnTaskedGroups", _normalized];
        };

        createHashMapFromArray [
            ["beforeCount", _beforeCount],
            ["afterCount", _afterCount],
            ["changed", _afterCount != _beforeCount]
        ]
    }],

    ["_rebuildAvailabilityCache", {
        private _groups = FLO_virtualGroups get "_groups";
        private _tasked = _self get "_gtnTaskedGroups";
        private _taskedSet = createHashMap;
        { _taskedSet set [_x, true]; } forEach _tasked;

        private _ownSide = _self get "_ownSide";
        private _available = [];
        private _ownSideGroupCount = 0;

        {
            private _groupId = _x;
            private _gData = _y;

            private _groupType = _gData get "groupType";
            if ((_gData get "side") != _ownSide) then { continue };
            _ownSideGroupCount = _ownSideGroupCount + 1;
            if (_groupType in ["civilian", "ambient", "helicopter", "jet", "air", "artillery", "static_aa"]) then { continue };
            if (_gData get "inCombat") then { continue };
            if (_taskedSet getOrDefault [_groupId, false]) then { continue };

            private _currentOrder = _gData get "commanderOrder";
            if (_currentOrder != "" && {!(_currentOrder in ["PATROL", "DEFEND", ""])}) then { continue };

            _available pushBack [_groupId, _gData];
        } forEach _groups;

        _self set ["_availabilityCandidates", _available];
        _self set ["_availabilityOwnSideTotal", _ownSideGroupCount];
        _self set ["_availabilityCacheDirty", false];
        _available
    }],

    // Get available groups for tasking from virtualization system
    ["_getAvailableGroups", {
        params [["_count", 4], ["_targetPos", []]];

        if (_self get "_availabilityCacheDirty") then {
            _self call ["_rebuildAvailabilityCache", []];
        };
        private _available = +(_self get "_availabilityCandidates");

        // Sort by distance to target if position provided.
        if (count _targetPos >= 2) then {
            private _scored = [];
            {
                _x params ["_groupId", "_gData"];
                _scored pushBack [((_gData get "position") distance2D _targetPos), _groupId, _gData];
            } forEach _available;
            _scored sort true;
            _available = _scored apply { [_x select 1, _x select 2] };
        };

        // Take requested count and extract just group IDs
        private _result = [];
        private _resultInfo = [];
        {
            if (count _result >= _count) exitWith {};
            _x params ["_groupId", "_gData"];
            _result pushBack _groupId;

            // Collect compact info for logging (cap to avoid heavy string work on large pools).
            if (count _resultInfo < 12) then {
                private _groupType = _gData get "groupType";
                private _vehicleType = _gData getOrDefault ["vehicleType", ""];
                private _unitCount = _gData get "unitCount";
                private _shortId = _groupId select [7, 6]; // Extract numeric part from "vgroup_123456"
                private _typeStr = if (_vehicleType != "") then { _vehicleType } else { _groupType };
                _resultInfo pushBack format["%1[%2](%3)", _shortId, _typeStr, _unitCount];
            };
        } forEach _available;

        private _extraCount = (count _result) - (count _resultInfo);
        private _preview = _resultInfo joinString ", ";
        if (_extraCount > 0) then {
            _preview = format ["%1 ... +%2 more", _preview, _extraCount];
        };
        ["GTN", 3, format["Found %1 groups (requested %2) near %3: %4", count _result, _count, _targetPos, _preview]] call FLO_fnc_log;

        _result
    }],

    // Mark groups as tasked by GTN
    ["_taskGroups", {
        params ["_groupIds"];
        private _tasked = _self get "_gtnTaskedGroups";
        { _tasked pushBackUnique _x; } forEach _groupIds;
        _self set ["_gtnTaskedGroups", _tasked];
        _self set ["_availabilityCacheDirty", true];
    }],

    // Remove stale group references after virtualization removes a group entry.
    ["_onVirtualGroupRemoved", {
        params ["_groupId"];

        private _tasked = _self get "_gtnTaskedGroups";
        if (_groupId in _tasked) then {
            _self set ["_gtnTaskedGroups", _tasked - [_groupId]];
        };

        {
            private _pool = _x get "groupPool";
            if (_groupId in _pool) then {
                _x set ["groupPool", _pool - [_groupId]];
            };
        } forEach (_self get "_tracks");

        private _executor = _self get "_executor";
        _executor call ["_pruneRemovedGroup", [_groupId]];

        _self set ["_availabilityCacheDirty", true];
    }],

    // Release groups from GTN tasking and clear their orders
    ["_releaseGroups", {
        params [["_groupIds", []], ["_newOrder", ""]];
        private _tasked = _self get "_gtnTaskedGroups";
        private _groups = FLO_virtualGroups get "_groups";
        
        {
            private _groupId = _x;
            _tasked = _tasked - [_groupId];
            
            // Clear the group's commanderOrder so it becomes available again
            private _gData = _groups get _groupId;
            if (!isNil "_gData") then {
                [_gData] call FLO_fnc_virtualizationClearCommanderOrder;
                if (_newOrder != "") then {
                    [_gData, _newOrder] call FLO_fnc_virtualizationSetCommanderOrder;
                };
                ["GTN", 3, format["Released group %1, order reset to '%2'", _groupId, _newOrder]] call FLO_fnc_log;
            };
        } forEach _groupIds;
        
        _self set ["_gtnTaskedGroups", _tasked];
        _self set ["_availabilityCacheDirty", true];
    }],

    // Dynamic cap for how many groups should defend a single objective.
    ["_getDefenseCapForObjective", {
        params ["_objectiveId"];

        private _ws = _self get "_worldState";
        private _objectives = _ws call ["_getObjectives", []];
        if !(_objectiveId in _objectives) exitWith { 0 };

        private _obj = _objectives get _objectiveId;
        private _enemyCount = _obj get "enemyCount";
        private _friendlyCount = _obj get "friendlyCount";
        private _underAttack = _obj get "underAttack";
        private _contested = _obj get "contested";
        private _coverage = (_self get "_config") get "defenseCoverageMultiplier";

        private _cap = (4 max (ceil (_enemyCount * 1.25))) min 24;
        if (_underAttack) then { _cap = (_cap + 4) min 32; };
        if (_contested) then { _cap = (_cap + 2) min 32; };

        private _deficit = (_enemyCount - _friendlyCount) max 0;
        if (_deficit > 0) then {
            _cap = (_cap + (ceil (_deficit * 0.5))) min 32;
        };

        _cap = ceil (_cap * _coverage);
        _cap = (_cap max 4) min 32;

        _cap
    }],

    // Baseline standing garrison cap for owned objectives.
    ["_getGarrisonCapForObjective", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { 0 };

        private _ws = _self get "_worldState";
        private _objectives = _ws call ["_getObjectives", []];
        if !(_objectiveId in _objectives) exitWith { 0 };

        private _obj = _objectives get _objectiveId;
        private _ownSide = _self get "_ownSide";
        if ((_obj get "owner") != _ownSide) exitWith { 0 };

        private _config = _self get "_config";
        private _cap = _config get "garrisonRearBaseGroups";
        private _enemyLinkedCount = 0;

        {
            private _linkedObjective = _objectives get _x;
            if (isNil "_linkedObjective") then { continue };
            if ((_linkedObjective get "owner") == (_self get "_enemySide")) then {
                _enemyLinkedCount = _enemyLinkedCount + 1;
            };
        } forEach (_obj get "linkedObjectives");

        if (_enemyLinkedCount > 0) then {
            _cap = _config get "garrisonFrontlineBaseGroups";
        };

        if ((_obj get "priority") >= (_config get "garrisonPriorityBonusThreshold")) then {
            _cap = _cap + (_config get "garrisonPriorityBonusGroups");
        };

        if ((_obj get "underAttack") || (_obj get "contested")) then {
            _cap = _cap + (_config get "garrisonHotBonusGroups");
        };

        private _defenseCap = _self call ["_getDefenseCapForObjective", [_objectiveId]];
        (_cap max 0) min _defenseCap
    }],

    // Friendly-held objectives that directly front the enemy objective.
    ["_getFriendlyAttackSourceObjectives", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { [] };

        private _ws = _self get "_worldState";
        private _objectives = _ws call ["_getObjectives", []];
        if !(_objectiveId in _objectives) exitWith { [] };

        private _obj = _objectives get _objectiveId;
        private _ownSide = _self get "_ownSide";
        private _sources = [];

        {
            private _linkedObj = _objectives get _x;
            if (isNil "_linkedObj") then { continue };
            if ((_linkedObj get "owner") != _ownSide) then { continue };
            _sources pushBackUnique _x;
        } forEach (_obj get "linkedObjectives");

        _sources
    }],

    // Dynamic cap for how many groups should actively attack a single objective.
    ["_getAttackCapForObjective", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { 0 };

        private _sourceObjectives = _self call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
        private _config = _self get "_config";
        private _reserveBands = [_self, _sourceObjectives, (_config get "attackReserveGraphDepth")] call FLO_fnc_gtnBuildObjectiveReserveBands;
        private _sourceCount = count _sourceObjectives;
        private _reserveObjectiveCount = ((count (keys _reserveBands)) - _sourceCount) max 0;
        private _cap = (_sourceCount * (_config get "attackGroupsPerFrontLink"))
            + (_reserveObjectiveCount * (_config get "attackGroupsPerReserveObjective"));

        _cap = (_cap max (_config get "attackMinGroupCap")) min (_config get "attackMaxGroupCap");
        _cap
    }],

    // How many groups one attack primitive should pull right now for this objective.
    ["_estimateAttackDispatchCount", {
        params ["_objectiveId", ["_minimum", 0], ["_track", nil]];
        if (_objectiveId == "") exitWith { 0 };

        private _attackCap = _self call ["_getAttackCapForObjective", [_objectiveId]];
        if (_attackCap <= 0) exitWith { 0 };

        private _activeAttackers = _self call ["_countObjectiveAttackers", [_objectiveId]];
        private _slotsRemaining = (_attackCap - _activeAttackers) max 0;
        if (_slotsRemaining <= 0) exitWith { 0 };

        private _config = _self get "_config";
        private _requestCount = ceil (_slotsRemaining * 0.75);
        private _minDispatch = if (_minimum > 0) then { _minimum } else { _config get "attackDispatchMinGroups" };

        if (_slotsRemaining > _minDispatch) then {
            _requestCount = _requestCount max _minDispatch;
        } else {
            _requestCount = _slotsRemaining;
        };

        _requestCount = _requestCount min (_config get "attackDispatchMaxGroups");

        if (!isNil "_track") then {
            _requestCount = _requestCount min (count (_track get "groupPool"));
        };

        _requestCount min _slotsRemaining
    }],

    // How many groups one defense primitive should pull right now for this objective.
    ["_estimateDefenseDispatchCount", {
        params ["_objectiveId", ["_minimum", 0], ["_track", nil]];
        if (_objectiveId == "") exitWith { 0 };

        private _cap = _self call ["_getDefenseCapForObjective", [_objectiveId]];
        if (_cap <= 0) exitWith { 0 };

        private _assigned = _self call ["_countObjectiveDefenders", [_objectiveId]];
        private _slotsRemaining = (_cap - _assigned) max 0;
        if (_slotsRemaining <= 0) exitWith { 0 };

        private _ws = _self get "_worldState";
        private _objectives = _ws call ["_getObjectives", []];
        if !(_objectiveId in _objectives) exitWith { 0 };

        private _obj = _objectives get _objectiveId;
        private _underAttack = _obj get "underAttack";
        private _contested = _obj get "contested";
        private _enemyCount = _obj get "enemyCount";
        private _friendlyCount = _obj get "friendlyCount";
        private _forceDeficit = (_enemyCount - _friendlyCount) max 0;
        private _requestCount = ceil (_slotsRemaining * (if (_underAttack || _contested) then { 0.75 } else { 0.5 }));
        private _config = _self get "_config";
        private _minDispatch = if (_minimum > 0) then { _minimum } else { _config get "defenseDispatchMinGroups" };

        if (_slotsRemaining > _minDispatch) then {
            _requestCount = _requestCount max _minDispatch;
        } else {
            _requestCount = _slotsRemaining;
        };

        _requestCount = _requestCount + ((ceil (_forceDeficit * 0.35)) min 3);
        _requestCount = _requestCount min (_config get "defenseDispatchMaxGroups");

        if (!isNil "_track") then {
            _requestCount = _requestCount min (count (_track get "groupPool"));
        };

        _requestCount min _slotsRemaining
    }],

    // How many groups one garrison pass should commit to an owned objective.
    ["_estimateGarrisonDispatchCount", {
        params ["_objectiveId", ["_threatLevel", 0], ["_frontline", false], ["_track", nil]];
        if (_objectiveId == "") exitWith { 0 };

        private _cap = _self call ["_getDefenseCapForObjective", [_objectiveId]];
        if (_cap <= 0) exitWith { 0 };

        private _assigned = _self call ["_countObjectiveDefenders", [_objectiveId]];
        private _slotsRemaining = (_cap - _assigned) max 0;
        if (_slotsRemaining <= 0) exitWith { 0 };

        private _config = _self get "_config";
        private _requestCount = (ceil (_threatLevel / 1.5)) max (_config get "garrisonDispatchMinGroups");
        if (_frontline) then {
            _requestCount = _requestCount + 2;
        };
        _requestCount = _requestCount min (_config get "garrisonDispatchMaxGroups");

        if (!isNil "_track") then {
            _requestCount = _requestCount min (count (_track get "groupPool"));
        };

        _requestCount min _slotsRemaining
    }],

    // Count current attackers assigned to a specific objective.
    ["_countObjectiveAttackers", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { 0 };

        private _groups = FLO_virtualGroups get "_groups";
        private _ownSide = _self get "_ownSide";
        private _count = 0;

        {
            private _gData = _y;
            if ((_gData get "side") != _ownSide) then { continue };
            if ((_gData get "commanderOrder") != "ATTACK") then { continue };
            if ((_gData get "attackObjective") != _objectiveId) then { continue };
            _count = _count + 1;
        } forEach _groups;

        _count
    }],

    // Count current standing garrisons assigned to a specific objective.
    ["_countObjectiveGarrisons", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { 0 };

        private _groups = FLO_virtualGroups get "_groups";
        private _ownSide = _self get "_ownSide";
        private _count = 0;

        {
            private _gData = _y;
            if ((_gData get "side") != _ownSide) then { continue };
            if ((_gData get "groupType") == "static_aa") then { continue };
            if ((_gData get "commanderOrder") != "GARRISON") then { continue };
            if ((_gData get "garrisonObjective") != _objectiveId) then { continue };
            _count = _count + 1;
        } forEach _groups;

        _count
    }],

    // Count current defenders assigned to a specific objective.
    ["_countObjectiveDefenders", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { 0 };

        private _groups = FLO_virtualGroups get "_groups";
        private _ownSide = _self get "_ownSide";
        private _count = 0;

        {
            private _gData = _y;
            if ((_gData get "side") != _ownSide) then { continue };
            if ((_gData get "groupType") == "static_aa") then { continue };
            private _order = _gData get "commanderOrder";
            if (_order == "DEFEND") then {
                if ((_gData get "defendObjective") != _objectiveId) then { continue };
            } else {
                if (_order != "GARRISON") then { continue };
                if ((_gData get "garrisonObjective") != _objectiveId) then { continue };
            };
            _count = _count + 1;
        } forEach _groups;

        _count
    }],

    // Release DEFEND groups that are idle past lease expiry and not under pressure.
    ["_manageDefenseLeases", {
        private _tasked = +(_self get "_gtnTaskedGroups");
        private _metrics = createHashMapFromArray [
            ["taskedCount", count _tasked],
            ["leaseIssuedCount", 0],
            ["holdRefreshCount", 0],
            ["lostObjectiveReleaseCount", 0],
            ["invalidObjectiveCount", 0],
            ["trimmedExcess", 0],
            ["releasedCount", 0]
        ];
        if ((count _tasked) == 0) exitWith { _metrics };

        private _groups = FLO_virtualGroups get "_groups";
        private _ownSide = _self get "_ownSide";
        private _ws = _self get "_worldState";
        private _objectives = _ws call ["_getObjectives", []];
        private _leaseSeconds = (_self get "_config") get "defenseLeaseSeconds";
        private _now = diag_tickTime;
        private _releaseIds = [];

        {
            private _groupId = _x;
            private _gData = _groups get _groupId;

            if (isNil "_gData") then {
                _releaseIds pushBack _groupId;
                continue;
            };
            if ((_gData get "side") != _ownSide) then { continue };
            if ((_gData get "groupType") == "static_aa") then { continue };
            if ((_gData get "commanderOrder") != "DEFEND") then { continue };
            if (_gData getOrDefault ["inCombat", false]) then { continue };

            private _objId = _gData get "defendObjective";
            if !(_objId in _objectives) then {
                _metrics set ["invalidObjectiveCount", (_metrics get "invalidObjectiveCount") + 1];
                ["GTN", 2, format["Defense lease: group %1 has invalid defendObjective (%2), releasing", _groupId, _objId]] call FLO_fnc_log;
                _releaseIds pushBack _groupId;
                continue;
            };

            private _obj = _objectives get _objId;
            if ((_obj get "owner") != _ownSide) then {
                _metrics set ["lostObjectiveReleaseCount", (_metrics get "lostObjectiveReleaseCount") + 1];
                ["GTN", 2, format["Defense lease: group %1 releasing from lost objective %2", _groupId, _objId]] call FLO_fnc_log;
                _releaseIds pushBack _groupId;
                continue;
            };

            private _leaseUntil = _gData get "defendLeaseUntil";
            if (_leaseUntil < 0) then {
                [_gData, _now, _now + _leaseSeconds] call FLO_fnc_virtualizationRefreshDefendLease;
                _metrics set ["leaseIssuedCount", (_metrics get "leaseIssuedCount") + 1];
                continue;
            };
            if (_now < _leaseUntil) then { continue };

            private _hold = false;
            _hold = (_obj get "contested") || (_obj get "underAttack");

            if (_hold) then {
                [_gData, _now, _now + _leaseSeconds] call FLO_fnc_virtualizationRefreshDefendLease;
                _metrics set ["holdRefreshCount", (_metrics get "holdRefreshCount") + 1];
            } else {
                _releaseIds pushBack _groupId;
            };
        } forEach _tasked;

        // Trim excess defenders above per-objective cap (idle only).
        private _idleDefendersByObjective = createHashMap;
        {
            private _groupId = _x;
            if (_groupId in _releaseIds) then { continue };

            private _gData = _groups get _groupId;
            if (isNil "_gData") then { continue };
            if ((_gData get "side") != _ownSide) then { continue };
            if ((_gData get "groupType") == "static_aa") then { continue };
            if ((_gData get "commanderOrder") != "DEFEND") then { continue };
            if (_gData getOrDefault ["inCombat", false]) then { continue };

            private _objId = _gData get "defendObjective";
            if (_objId == "") then { continue };

            private _bucket = _idleDefendersByObjective getOrDefault [_objId, []];
            _bucket pushBack _groupId;
            _idleDefendersByObjective set [_objId, _bucket];
        } forEach _tasked;

        {
            private _objId = _x;
            private _bucket = +(_idleDefendersByObjective get _objId);
            private _cap = _self call ["_getDefenseCapForObjective", [_objId]];
            if (_cap <= 0) then { continue };

            private _excess = (count _bucket) - _cap;
            if (_excess <= 0) then { continue };

            for "_i" from 1 to _excess do {
                if ((count _bucket) == 0) exitWith {};
                _releaseIds pushBackUnique (_bucket deleteAt ((count _bucket) - 1));
            };
            _metrics set ["trimmedExcess", (_metrics get "trimmedExcess") + _excess];

            ["GTN", 3, format[
                "Defense cap trim at %1: released %2 excess defenders (cap=%3)",
                _objId,
                _excess,
                _cap
            ]] call FLO_fnc_log;
        } forEach (keys _idleDefendersByObjective);

        if ((count _releaseIds) == 0) exitWith { _metrics };

        {
            private _gData = _groups get _x;
            if (isNil "_gData") then { continue };
            [_gData] call FLO_fnc_virtualizationClearMissionLock;
                    [_gData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
        } forEach _releaseIds;

        _self call ["_releaseGroups", [_releaseIds, ""]];
        _metrics set ["releasedCount", count _releaseIds];
        ["GTN", 3, format["Defense lease release: %1 groups returned to pool", count _releaseIds]] call FLO_fnc_log;

        _metrics
    }],

    // Order group to move using virtualization waypoints
    ["_orderGroupMove", {
        params ["_groupId", "_pos", ["_mode", "AWARE"]];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order move - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if !(_pos isEqualType [] && {count _pos >= 2}) exitWith {
            ["GTN", 2, format["Cannot order move - invalid destination for %1: %2", _groupId, _pos]] call FLO_fnc_log;
            false
        };

        private _existingTarget = _gData get "orderTargetPos";
        private _existingMode = _gData get "orderMode";
        private _hasRouteContext = (count (_gData get "waypoints") > 0) || {(_gData get "pathToken") >= 0};
        if ((_gData get "commanderOrder") == "MOVE" && {_existingMode == _mode} && {_hasRouteContext} && {count _existingTarget >= 2} && {_existingTarget distance2D _pos < 35}) exitWith {
            if (isNil "FLO_GTN_OrderNoOps") then { FLO_GTN_OrderNoOps = createHashMap; };
            FLO_GTN_OrderNoOps set ["MOVE", (FLO_GTN_OrderNoOps getOrDefault ["MOVE", 0]) + 1];
            _self call ["_taskGroups", [[_groupId]]];
            true
        };

        private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];

        private _waypoints = [
            [_pos, "MOVE", "SAFE", "FULL", _formation, "GREEN", 30]
        ];

        [_groupId, _waypoints, false, true, "GTN_MOVE"] call FLO_fnc_updateVirtualGroupWaypoints;
        [_gData, _pos, _mode] call FLO_fnc_virtualizationAssignMoveOrder;

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 3, format["Ordered group %1 to move to %2 (%3)", _groupId, _pos, _mode]] call FLO_fnc_log;
        true
    }],

    // Order group to attack using virtualization waypoints
    ["_orderGroupAttack", {
        params ["_groupId", "_pos", ["_objectiveId", ""]];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order attack - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if !(_pos isEqualType [] && {count _pos >= 2}) exitWith {
            ["GTN", 2, format["Cannot order attack - invalid destination for %1: %2", _groupId, _pos]] call FLO_fnc_log;
            false
        };

        private _attackPos = _pos;
        if (_objectiveId != "") then {
            private _randomAttackPos = [_objectiveId] call FLO_fnc_getRandomObjectivePos;
            if !(_randomAttackPos isEqualTo [0, 0, 0]) then {
                _attackPos = _randomAttackPos;
            };
        };

        private _existingTarget = _gData get "orderTargetPos";
        private _existingAttackObjective = _gData get "attackObjective";
        private _hasRouteContext = (count (_gData get "waypoints") > 0) || {(_gData get "pathToken") >= 0};
        if (
            (_gData get "commanderOrder") == "ATTACK"
            && {_hasRouteContext}
            && {
                (_objectiveId != "" && {_existingAttackObjective == _objectiveId})
                || {count _existingTarget >= 2 && {_existingTarget distance2D _attackPos < 60}}
            }
        ) exitWith {
            if (isNil "FLO_GTN_OrderNoOps") then { FLO_GTN_OrderNoOps = createHashMap; };
            FLO_GTN_OrderNoOps set ["ATTACK", (FLO_GTN_OrderNoOps getOrDefault ["ATTACK", 0]) + 1];
            _self call ["_taskGroups", [[_groupId]]];
            true
        };

        private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];

        private _waypoints = [
            [_attackPos, "MOVE", "SAFE", "FULL", _formation, "GREEN", 75],
            [_attackPos, "MOVE", "SAFE", "FULL", _formation, "GREEN", 50]
        ];

        [_groupId, _waypoints, false, true, "GTN_ATTACK"] call FLO_fnc_updateVirtualGroupWaypoints;
        [_gData, _attackPos, _objectiveId] call FLO_fnc_virtualizationAssignAttackOrder;

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 3, format["Ordered group %1 to attack %2 (%3)", _groupId, _attackPos, _objectiveId]] call FLO_fnc_log;
        true
    }],

    // Order group to defend using virtualization waypoints
    ["_orderGroupDefend", {
        params ["_groupId", "_pos", ["_objectiveId", ""]];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order defend - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if !(_pos isEqualType [] && {count _pos >= 2}) exitWith {
            ["GTN", 2, format["Cannot order defend - invalid destination for %1: %2", _groupId, _pos]] call FLO_fnc_log;
            false
        };

        private _alreadyAssigned = false;
        private _saturated = false;
        if (_objectiveId != "") then {
            private _hasRouteContext = (count (_gData get "waypoints") > 0) || {(_gData get "pathToken") >= 0};
            _alreadyAssigned = ((_gData get "commanderOrder") == "DEFEND") && {(_gData get "defendObjective") == _objectiveId} && {_hasRouteContext};
            if (!_alreadyAssigned) then {
                private _assigned = _self call ["_countObjectiveDefenders", [_objectiveId]];
                private _cap = _self call ["_getDefenseCapForObjective", [_objectiveId]];
                if (_cap > 0 && {_assigned >= _cap}) then {
                    ["GTN", 3, format[
                        "Defend order skipped for %1: %2 already saturated (%3/%4)",
                        _groupId,
                        _objectiveId,
                        _assigned,
                        _cap
                    ]] call FLO_fnc_log;
                    _saturated = true;
                };
            };
        };

        if (_alreadyAssigned) exitWith {
            if (isNil "FLO_GTN_OrderNoOps") then { FLO_GTN_OrderNoOps = createHashMap; };
            FLO_GTN_OrderNoOps set ["DEFEND", (FLO_GTN_OrderNoOps getOrDefault ["DEFEND", 0]) + 1];
            private _leaseSeconds = (_self get "_config") get "defenseLeaseSeconds";
            [_gData, diag_tickTime, diag_tickTime + _leaseSeconds] call FLO_fnc_virtualizationRefreshDefendLease;
            true
        };

        if (_saturated) exitWith { false };

        private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];

        private _waypoints = [
            [_pos, "MOVE", "SAFE", "FULL", _formation, "GREEN", 40],
            [_pos, "GUARD", "SAFE", "FULL", _formation, "GREEN", 60]
        ];

        [_groupId, _waypoints, false, true, "GTN_DEFEND"] call FLO_fnc_updateVirtualGroupWaypoints;
        private _leaseSeconds = (_self get "_config") get "defenseLeaseSeconds";
        [_gData, _pos, _objectiveId, diag_tickTime, diag_tickTime + _leaseSeconds] call FLO_fnc_virtualizationAssignDefendOrder;

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 3, format["Ordered group %1 to defend %2", _groupId, _pos]] call FLO_fnc_log;
        true
    }],

    // Order group to hold a standing garrison on an owned objective.
    ["_orderGroupGarrison", {
        params ["_groupId", "_pos", ["_objectiveId", ""]];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order garrison - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if !(_pos isEqualType [] && {count _pos >= 2}) exitWith {
            ["GTN", 2, format["Cannot order garrison - invalid destination for %1: %2", _groupId, _pos]] call FLO_fnc_log;
            false
        };

        private _hasRouteContext = (count (_gData get "waypoints") > 0) || {(_gData get "pathToken") >= 0};
        private _currentGarrisonPos = _gData get "garrisonPosition";
        private _sameHoldPos = _currentGarrisonPos isEqualType [] && {count _currentGarrisonPos >= 2} && {(_currentGarrisonPos distance2D _pos) < 20};
        if (
            (_gData get "commanderOrder") == "GARRISON"
            && {(_gData get "garrisonObjective") == _objectiveId}
            && {_hasRouteContext}
            && {_sameHoldPos}
        ) exitWith {
            if (isNil "FLO_GTN_OrderNoOps") then { FLO_GTN_OrderNoOps = createHashMap; };
            FLO_GTN_OrderNoOps set ["GARRISON", (FLO_GTN_OrderNoOps getOrDefault ["GARRISON", 0]) + 1];
            _self call ["_taskGroups", [[_groupId]]];
            true
        };

        private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];
        private _waypoints = [
            [_pos, "MOVE", "SAFE", "FULL", _formation, "GREEN", 35],
            [_pos, "GUARD", "SAFE", "LIMITED", _formation, "GREEN", 50]
        ];

        [_groupId, _waypoints, false, true, "GTN_GARRISON"] call FLO_fnc_updateVirtualGroupWaypoints;
        [_gData, _pos, _objectiveId] call FLO_fnc_virtualizationAssignGarrisonOrder;

        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 3, format["Ordered group %1 to garrison %2", _groupId, _objectiveId]] call FLO_fnc_log;
        true
    }],

    // Request an air mission using the GTN air support system.
    ["_requestAirMission", {
        params ["_pos", ["_missionType", "CAS"]];
        private _ownSide = _self get "_ownSide";

        private _ato = call FLO_fnc_gtnAirTaskOrder;
        private _altitude = 150;

        _ato call ["_addTask", [_pos, _missionType, "", _altitude, _ownSide]];
        private _assignedCount = _ato call ["_processTasks", []];
        private _success = _assignedCount > 0;

        if (_success) then {
            ["GTN", 3, format["Air mission queued: %1 at %2", _missionType, _pos]] call FLO_fnc_log;
        } else {
            ["GTN", 2, format["Air mission request failed - no available air assets for %1 at %2", _missionType, _pos]] call FLO_fnc_log;
        };

        _success
    }],

    // Request CAS using the GTN air support system
    ["_requestCAS", {
        params ["_pos", ["_missionType", "CAS"]];
        _self call ["_requestAirMission", [_pos, _missionType]]
    }],

    // Request CAP using the GTN air support system
    ["_requestCAP", {
        params ["_pos"];
        _self call ["_requestAirMission", [_pos, "CAP"]]
    }],

    // Check if groups have arrived at a position (within threshold)
    ["_checkGroupsArrived", {
        params ["_groupIds", "_pos", ["_threshold", 100]];

        if !(_pos isEqualType [] && {count _pos >= 2}) exitWith { false };

        private _groups = FLO_virtualGroups get "_groups";
        private _arrivedCount = 0;
        private _validCount = 0;

        {
            private _gData = _groups get _x;
            if (isNil "_gData") then { continue };
            _validCount = _validCount + 1;

            private _groupPos = _gData get "position";
            if (_groupPos distance2D _pos <= _threshold) then {
                _arrivedCount = _arrivedCount + 1;
            };
        } forEach _groupIds;

        // All surviving groups must arrive (don't wait for dead/deleted groups)
        if (_validCount == 0) exitWith { true };
        _arrivedCount >= _validCount
    }],

    // Identify objective with weakest defense (for opportunistic attacks)
    ["_identifyWeakSector", {
        private _ws = _self get "_worldState";
        private _enemyObjs = _ws call ["_getEnemyObjectives", []];

        if (count (keys _enemyObjs) == 0) exitWith { "" };

        // Find objective with lowest defense strength
        private _weakest = "";
        private _lowestStrength = 1000;

        {
            private _obj = _enemyObjs get _x;
            private _strength = _obj getOrDefault ["defenseStrength", 50];

            // Prefer lower strength
            if (_strength < _lowestStrength) then {
                _lowestStrength = _strength;
                _weakest = _x;
            };
        } forEach (keys _enemyObjs);

        _weakest
    }],

    // Static AA deployment finalization
    // - Static AA groups are created by logistics network
    // - Commander only finalizes deployment when movers reach target
    ["_manageStaticAANetwork", {
        private _groups = FLO_virtualGroups get "_groups";
        private _ownSide = _self get "_ownSide";
        private _metrics = createHashMapFromArray [
            ["groupCount", count (keys _groups)],
            ["movingStaticAACount", 0],
            ["deployedCount", 0]
        ];

        // Phase 1: finalize in-transit static AA deployments
        {
            private _groupId = _x;
            private _gData = _groups get _groupId;
            if (isNil "_gData") then { continue };

            if ((_gData get "groupType") != "static_aa") then { continue };
            if ((_gData get "side") != _ownSide) then { continue };
            if (([_gData] call FLO_fnc_virtualizationGetAADeployState) != "MOVING") then { continue };
            _metrics set ["movingStaticAACount", (_metrics get "movingStaticAACount") + 1];

            private _targetPos = [_gData] call FLO_fnc_virtualizationGetAATargetPos;
            if (count _targetPos < 2) then { continue };
            if ((_gData get "position") distance2D _targetPos > 120) then { continue };

            [_gData, "AA_HOLD"] call FLO_fnc_virtualizationClearReplacementTransit;
            _gData set ["forceVirtual", false];
            _gData set ["waypoints", []];
            _gData set ["currentWaypointIndex", 0];
            _gData set ["alwaysActive", true];
            _gData set ["noWaypoints", true];
            [_gData, "DEPLOYED", _targetPos, [_gData] call FLO_fnc_virtualizationGetAATargetObjective, _gData get "isStrategicAA"] call FLO_fnc_virtualizationSetAADeployState;

            if !(_gData get "isActive") then {
                [_groupId, _gData] call FLO_fnc_activateVirtualGroup;
            } else {
                private _realGroup = _gData get "realGroup";
                if (!isNull _realGroup) then {
                    [_realGroup] call CBA_fnc_clearWaypoints;
                };
            };

            ["GTN", 3, format[
                "Static AA %1 deployed at %2 (objective %3)",
                _groupId,
                _targetPos,
                [_gData] call FLO_fnc_virtualizationGetAATargetObjective
            ]] call FLO_fnc_log;
            _metrics set ["deployedCount", (_metrics get "deployedCount") + 1];
        } forEach (keys _groups);

        _metrics
    }],

    // Force Preservation Management
    // Handles retreating damaged groups, ordering dismounted pilots RTB, and replenishing forces.
    ["_manageForcePreservation", {
        private _groups = FLO_virtualGroups get "_groups";
        private _replenishInterval = 300; // 5 minutes for replenishment tick
        private _metrics = createHashMapFromArray [
            ["groupCount", count (keys _groups)],
            ["activeChecks", 0],
            ["retreatOrders", 0],
            ["retreatArrivals", 0],
            ["replenishChecks", 0],
            ["replenishTicks", 0],
            ["returnedToDuty", 0],
            ["vehicleRespawns", 0]
        ];

        {
            private _gId = _x;
            private _gData = _groups get _gId;   
            private _currentOrder = _gData get "commanderOrder";
            private _state = _gData getOrDefault ["preservationState", "ACTIVE"]; // ACTIVE, RETREATING, REPLENISHING
            private _groupType = _gData get "groupType";

            // === CHECK FOR RETREAT CRITERIA ===
            if (_state == "ACTIVE") then {
                _metrics set ["activeChecks", (_metrics get "activeChecks") + 1];
                // Dismounted Pilot
                // If group type was air but unit count > 0 and vehicle count == 0 (or all vehicles dead), treat as dismounted
                private _isPilot = false;
                if (_groupType in ["helicopter", "jet", "air"]) then {
                     // Check if they are on foot
                    private _realGroup = _gData get "realGroup";
                    if (!isNull _realGroup) then {
                        private _hasAirVehicle = false;
                        {
                            if (vehicle _x isKindOf "Air" && alive vehicle _x) then { _hasAirVehicle = true; };
                        } forEach units _realGroup;
                         
                        if (!_hasAirVehicle && {count units _realGroup > 0}) then {
                            _isPilot = true;
                        };
                    };
                };

                // Significant Damage (< 50% strength)
                private _unitCount = _gData get "unitCount";
                private _template = _gData getOrDefault ["template", []];
                private _originalCount = count _template;
                
                // If template missing, assume current is original (fallback)
                if (_originalCount == 0) then { _originalCount = _unitCount max 1; };

                private _isDamaged = (_unitCount / _originalCount) < 0.5;

                if (_isPilot || _isDamaged) then {
                    _metrics set ["retreatOrders", (_metrics get "retreatOrders") + 1];
                    ["GTN", 3, format["Force Preservation: Group %1 (%2) retreating. Pilot: %3, Damage: %4/%5", 
                        _gId, _groupType, _isPilot, _unitCount, _originalCount]] call FLO_fnc_log;
                    
                    // Release from Air Manager so it doesn't crash if this group dies/deletes
                    if (!isNil "FLO_GTNAirAssetManager") then {
                         FLO_GTNAirAssetManager call ["_releaseAirAsset", [_gId]];
                    };
                    
                    _gData set ["preservationState", "RETREATING"];
                    [_gData, "PRESERVATION", "RETREAT"] call FLO_fnc_virtualizationSetMissionLock;
                    [_gData] call FLO_fnc_virtualizationClearCommanderOrder;
                    
                    // Find nearest friendly objective
                    private _ws = _self get "_worldState";
                    private _friendlyObjs = _ws call ["_getFriendlyObjectives", []];
                    private _gPos = _gData get "position";
                    private _retreatObj = "";
                    private _bestDist = 999999;
                    
                    {
                        private _objPos = [_x] call FLO_fnc_getObjectivePosition;
                        private _dist = _gPos distance2D _objPos;
                        
                        // Prioritize objectives > 5km away
                        // If we find one > 5km, track the *nearest* of those deep objectives
                        if (_dist > 5000) then {
                            if (_dist < _bestDist) then {
                                _bestDist = _dist;
                                _retreatObj = _x;
                            };
                        };
                    } forEach (keys _friendlyObjs);

                    // Fallback: If no deep objective found, just go to the furthest one available (or nearest if map is small)
                    // Actually, let's just go to the nearest friendly if no >5km option exists, to ensure safety
                    if (_retreatObj == "") then {
                         _bestDist = 999999;
                         {
                            private _objPos = [_x] call FLO_fnc_getObjectivePosition;
                            private _dist = _gPos distance2D _objPos;
                            if (_dist < _bestDist) then {
                                _bestDist = _dist;
                                _retreatObj = _x;
                            };
                        } forEach (keys _friendlyObjs);
                    };

                    if (_retreatObj != "") then {
                        private _retreatPos = [_retreatObj] call FLO_fnc_getObjectivePosition;
                        _gData set ["retreatPos", _retreatPos];
                         
                        private _retreatFormation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];
                        private _wps = [[_retreatPos, "MOVE", "SAFE", "FULL", _retreatFormation, "GREEN", 0]];
                        [_gId, _wps, false, true, "GTN_RETREAT"] call FLO_fnc_updateVirtualGroupWaypoints;
                    };
                };
            };
            
            // === HANDLE RETREATING MOVEMENT ===
            if (_state == "RETREATING") then {
                private _retreatPos = _gData getOrDefault ["retreatPos", []];
                if (count _retreatPos == 0) exitWith { _gData set ["preservationState", "ACTIVE"]; };
                
                private _gPos = _gData get "position";
                if (_gPos distance2D _retreatPos < 150) then {
                    _metrics set ["retreatArrivals", (_metrics get "retreatArrivals") + 1];
                    ["GTN", 3, format["Group %1 arrived at safe haven. Beginning replenishment.", _gId]] call FLO_fnc_log;
                    _gData set ["preservationState", "REPLENISHING"];
                    _gData set ["lastReplenishTime", diag_tickTime];
                };
            };

            // === HANDLE REPLENISHMENT ===
            if (_state == "REPLENISHING") then {
                _metrics set ["replenishChecks", (_metrics get "replenishChecks") + 1];
                private _lastRep = _gData getOrDefault ["lastReplenishTime", 0];
                
                if (diag_tickTime - _lastRep >= _replenishInterval) then {
                    // Check resources before replenishing
                    private _cost = 15;
                    private _canAfford = true;
                    private _resources = _self call ["_getResourceObject", []];
                    
                    if (isNil "_resources") then {
                        _canAfford = false;
                    } else {
                        if !(_resources call ["canAfford", [_cost, "reinforcement"]]) then {
                            _canAfford = false;
                            ["GTN", 3, format["Group %1 replenishment paused - insufficient resources", _gId]] call FLO_fnc_log;
                        };
                    };

                    if (_canAfford) then {
                        _metrics set ["replenishTicks", (_metrics get "replenishTicks") + 1];
                        // Dedect cost
                        _resources call ["spendResources", [_cost, "reinforcement"]];
                    
                        // Trickle replenishment
                        private _unitCount = _gData get "unitCount";
                        private _template = _gData getOrDefault ["template", []];
                        private _originalCount = count _template;
                        
                        if (_originalCount == 0) then { _originalCount = _unitCount max 1; }; // Fallback
                        
                        // Add 10% or 1 man, whichever is greater
                        private _increase = ceil(_originalCount * 0.1) max 1;
                        private _newCount = (_unitCount + _increase) min _originalCount;
                        
                        _gData set ["unitCount", _newCount];
                        _gData set ["strength", _newCount / _originalCount]; // Update strength multiplier
                        _gData set ["lastReplenishTime", diag_tickTime];
                        
                        ["GTN", 3, format["Group %1 replenish tick: %2 -> %3 (Target: %4)", _gId, _unitCount, _newCount, _originalCount]] call FLO_fnc_log;
                        
                        // Apply to real group if active
                        if (_gData get "isActive") then {
                            // Note: Spawning units into live group is complex (loadouts etc). 
                            // For now, we simulate success by healing existing units.
                            // Full respawn happens when revirtualized and activated again.
                            private _realGroup = _gData get "realGroup";
                            { _x setDamage 0; } forEach units _realGroup; 
                        };

                        if (_newCount >= _originalCount) then {
                            // Check if we need to respawn vehicle (Air groups without vehicles)
                            private _needsRespawn = false;
                            if (_groupType in ["helicopter", "jet", "air"]) then {
                                private _realGroup = _gData get "realGroup";
                                if (!isNull _realGroup) then {
                                    // Re-use logic: check if purely infantry
                                    private _hasAirVehicle = false;
                                    { if (vehicle _x isKindOf "Air") then { _hasAirVehicle = true; }; } forEach units _realGroup;
                                    if (!_hasAirVehicle) then { _needsRespawn = true; };
                                };
                            };

                            if (_needsRespawn) then {
                                _metrics set ["vehicleRespawns", (_metrics get "vehicleRespawns") + 1];
                                ["GTN", 3, format["Group %1 fully replenished but needs vehicle. Deactivating to respawn.", _gId]] call FLO_fnc_log;
                                [_gId] call FLO_fnc_deactivateVirtualGroup;
                                _gData set ["preservationState", "ACTIVE"]; 
                                [_gData] call FLO_fnc_virtualizationClearMissionLock;
                                [_gData] call FLO_fnc_virtualizationClearCommanderOrder;
                            } else {
                                _metrics set ["returnedToDuty", (_metrics get "returnedToDuty") + 1];
                                ["GTN", 3, format["Group %1 fully replenished. Returning to duty.", _gId]] call FLO_fnc_log;
                                _gData set ["preservationState", "ACTIVE"];
                                [_gData] call FLO_fnc_virtualizationClearMissionLock;
                                [_gData] call FLO_fnc_virtualizationClearCommanderOrder;
                                // Also reset their behavior/combat mode if active
                                if (_gData get "isActive") then {
                                    private _realGroup = _gData get "realGroup";
                                    _realGroup setBehaviour "AWARE";
                                    _realGroup setCombatMode "YELLOW";
                                };
                            };
                        };
                    };
                };
            };
            
        } forEach (keys _groups);

        _metrics
    }],

    // Get staging position for an objective (offset from target)
    ["_getStagingPosition", {
        params ["_objId"];

        private _targetPos = [_objId] call FLO_fnc_getObjectivePosition;
        if (isNil "_targetPos") exitWith { nil };

        // Find nearest friendly (OPFOR) objective to stage at
        private _ws = _self get "_worldState";
        private _friendlyObjs = _ws call ["_getFriendlyObjectives", []];

        if (count (keys _friendlyObjs) == 0) exitWith {
            // No friendly objectives - fall back to offset from target
            ["GTN", 2, "No friendly objectives for staging - using offset position"] call FLO_fnc_log;
            private _offset = 500 + random 300;
            private _dir = random 360;
            _targetPos getPos [_offset, _dir]
        };

        // Find closest friendly objective to the target
        private _bestObj = "";
        private _bestDist = 999999;

        {
            private _objData = _friendlyObjs get _x;
            private _objPos = [_x] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") then { continue };

            private _dist = _objPos distance2D _targetPos;
            if (_dist < _bestDist) then {
                _bestDist = _dist;
                _bestObj = _x;
            };
        } forEach (keys _friendlyObjs);

        if (_bestObj == "") exitWith {
            ["GTN", 2, "Could not find valid friendly objective for staging"] call FLO_fnc_log;
            nil
        };

        private _stagingPos = [_bestObj] call FLO_fnc_getObjectivePosition;

        ["GTN", 3, format["Staging at friendly objective %1 (%2m from target)", _bestObj, round _bestDist]] call FLO_fnc_log;

        _stagingPos
    }],

    // === DEBUG ===
    
    // Per-cycle decision summary - single line showing all track states
    ["_logDecisionSummary", {
        private _tracks = _self get "_tracks";
        private _tasked = _self get "_gtnTaskedGroups";
        private _summary = [];
        
        {
            private _track = _x;
            private _trackId = _track get "id";
            private _goal = _track get "goal";
            private _status = _track get "status";
            private _pool = count (_track get "groupPool");
            private _planner = _track get "planner";
            private _phase = if (_goal == "capture_priority_objective") then { _track get "phase" } else { "-" };
            private _phaseObjective = if (_goal == "capture_priority_objective") then { _track get "phaseObjectiveId" } else { "" };
            
            private _planStatus = if (!isNil "_planner") then {
                _planner call ["_getPlanStatus", []]
            } else { "NO_PLAN" };
            
            private _taskInfo = if (!isNil "_planner") then {
                private _task = _planner call ["_getCurrentTask", []];
                if (!isNil "_task") then {
                    _task get "taskId"
                } else { "-" }
            } else { "-" };
            
            // Short format: TRACK_1(capture):RUNNING|ph=staging|p=3|t=prim_attack|o=obj
            private _shortGoal = _goal select [0, 12]; // First 12 chars
            private _phaseInfo = if (_phaseObjective != "") then {
                format ["|o=%1", _phaseObjective]
            } else {
                ""
            };
            _summary pushBack format["%1(%2):%3|ph=%4|p=%5|t=%6%7",
                _trackId, _shortGoal, _planStatus, _phase, _pool, _taskInfo, _phaseInfo];
        } forEach _tracks;
        
        ["GTN", 3, format["DECISION[tasked=%1]: %2", count _tasked, _summary joinString " | "]] call FLO_fnc_log;
    }],
    
    // Debug why groups aren't available - call this when commander seems stuck
    ["_debugGroupAvailability", {
        private _groups = FLO_virtualGroups get "_groups";
        private _gtnTasked = _self get "_gtnTaskedGroups";
        private _ownSide = _self get "_ownSide";
        
        private _stats = createHashMapFromArray [
            ["total", 0],
            ["wrongSide", 0],
            ["wrongType", 0],
            ["airArtillery", 0],
            ["inCombat", 0],
            ["gtnTasked", 0],
            ["busyOrder", 0],
            ["available", 0]
        ];
        
        private _orderBreakdown = createHashMap;
        
        {
            private _groupId = _x;
            private _gData = _y;
            
            _stats set ["total", (_stats get "total") + 1];
            
            private _groupType = _gData get "groupType";
            private _currentOrder = _gData get "commanderOrder";
            private _side = _gData get "side";
            private _inCombat = _gData getOrDefault ["inCombat", false];
            
            // Track order distribution
            private _orderKey = if (_currentOrder == "") then { "IDLE" } else { _currentOrder };
            private _orderCount = if (_orderKey in _orderBreakdown) then {
                _orderBreakdown get _orderKey
            } else {
                0
            };
            _orderBreakdown set [_orderKey, _orderCount + 1];
            
            // Check filters
            if (_side != _ownSide) exitWith { _stats set ["wrongSide", (_stats get "wrongSide") + 1] };
            if (_groupType in ["civilian", "ambient"]) exitWith { _stats set ["wrongType", (_stats get "wrongType") + 1] };
            if (_groupType in ["helicopter", "jet", "air", "artillery"]) exitWith { _stats set ["airArtillery", (_stats get "airArtillery") + 1] };
            if (_inCombat) exitWith { _stats set ["inCombat", (_stats get "inCombat") + 1] };
            if (_groupId in _gtnTasked) exitWith { _stats set ["gtnTasked", (_stats get "gtnTasked") + 1] };
            if (_currentOrder != "" && {!(_currentOrder in ["PATROL", "GARRISON", "DEFEND", ""])}) exitWith { 
                _stats set ["busyOrder", (_stats get "busyOrder") + 1] 
            };
            
            _stats set ["available", (_stats get "available") + 1];
        } forEach _groups;
        
        // Build order breakdown string
        private _orderStr = [];
        { _orderStr pushBack format["%1=%2", _x, _y]; } forEach _orderBreakdown;
        
        ["GTN", 3, format["GROUP AVAILABILITY: total=%1—wrongSide=%2,wrongType=%3,air/arty=%4,gtnTasked=%5,busyOrder=%6—AVAILABLE=%7",
            _stats get "total",
            _stats get "wrongSide",
            _stats get "wrongType",
            _stats get "airArtillery",
            _stats get "gtnTasked",
            _stats get "busyOrder",
            _stats get "available"
        ]] call FLO_fnc_log;
        
        ["GTN", 3, format["GROUP AVAILABILITY DETAIL: inCombat=%1", _stats get "inCombat"]] call FLO_fnc_log;
        ["GTN", 3, format["ORDER BREAKDOWN: %1", _orderStr joinString ", "]] call FLO_fnc_log;
        
        // Return stats for programmatic use
        _stats
    }],
    
    // List all groups with their current orders
    ["_debugListOrders", {
        private _groups = FLO_virtualGroups get "_groups";
        private _gtnTasked = _self get "_gtnTaskedGroups";
        private _ownSide = _self get "_ownSide";
        
        ["GTN", 3, "=== GROUP ORDER LISTING ==="] call FLO_fnc_log;
        
        {
            private _groupId = _x;
            private _gData = _y;
            
            private _side = _gData get "side";
            if (_side != _ownSide) then { continue };
            
            private _groupType = _gData get "groupType";
            private _currentOrder = _gData get "commanderOrder";
            private _unitCount = _gData get "unitCount";
            private _isTasked = _groupId in _gtnTasked;
            
            private _shortId = _groupId select [7, 8];
            ["GTN", 3, format["  %1: type=%2, order=%3, units=%4, gtnTasked=%5",
                _shortId, _groupType, _currentOrder, _unitCount, _isTasked
            ]] call FLO_fnc_log;
        } forEach _groups;
    }],

    ["_debugPrint", {
        private _stats = _self get "_stats";
        private _planner = _self get "_planner";
        private _ws = _self get "_worldState";
        private _monitor = _self get "_monitor";

        private _planDebug = _planner call ["_debugPrint", []];
        private _wsDebug = _ws call ["_debugPrint", []];
        private _monitorDebug = _monitor call ["_debugPrint", []];

        format[
            "=== GTN Commander ===\nRunning: %1\nCycles: %2, Plans: %3, Tasks: %4, Replans: %5\n\n%6\n\n%7\n\n%8",
            _self get "_isRunning",
            _stats get "cyclesRun",
            _stats get "plansCreated",
            _stats get "tasksExecuted",
            _stats get "replans",
            _wsDebug,
            _planDebug,
            _monitorDebug
        ]
    }],

    // Full status dump for debugging
    ["_dumpStatus", {
        ["GTN", 3, "========== GTN COMMANDER DEBUG DUMP =========="] call FLO_fnc_log;
        
        // Core stats
        private _debug = _self call ["_debugPrint", []];
        ["GTN", 3, _debug] call FLO_fnc_log;
        
        // Group availability analysis
        _self call ["_debugGroupAvailability", []];
        
        // Track details
        private _tracks = _self get "_tracks";
        {
            private _track = _x;
            ["GTN", 3, format["TRACK %1: goal=%2, status=%3, poolSize=%4",
                _track get "id",
                _track get "goal",
                _track get "status",
                count (_track get "groupPool")
            ]] call FLO_fnc_log;
        } forEach _tracks;
        
        // List all group orders
        _self call ["_debugListOrders", []];
        
        ["GTN", 3, "========== END DEBUG DUMP =========="] call FLO_fnc_log;
        
        _debug
    }]
]];

// Link executor back to GTN commander (circular reference needed for handlers)
_executor call ["_setGTNCommander", [_gtnCommander]];
_worldState call ["_setCommander", [_gtnCommander]];

["GTN", 2, "GTN Commander System initialized"] call FLO_fnc_log;

_gtnCommander
