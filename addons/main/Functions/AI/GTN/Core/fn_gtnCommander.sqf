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

if (isNil "_sideContext" || {(!(_sideContext isEqualType createHashMap))} || {_sideContext isEqualTo []}) then {
    _sideContext = [east] call FLO_fnc_gtnSideContext;
};

private _ownSide = _sideContext get "ownSide";
private _enemySide = _sideContext get "enemySide";
private _sideKey = _sideContext get "sideKey";

["GTN", 3, format["Initializing GTN Commander System (%1)", _sideKey]] call FLO_fnc_log;

// Create all subsystems
private _worldState = [_sideContext] call FLO_fnc_gtnWorldState;
private _goalLibrary = call FLO_fnc_gtnGoalLibrary;
private _planner = [_goalLibrary, _worldState] call FLO_fnc_gtnPlanner;
private _executor = [_commander, _sideContext] call FLO_fnc_gtnExecutor;
private _monitor = [_planner, _worldState] call FLO_fnc_gtnMonitor;
private _capabilityAnalyzer = call FLO_fnc_gtnCapabilityAnalyzer;
private _artilleryManager = call FLO_fnc_gtnArtilleryManager;

// Defense & Offensive Data
private _tempoInterval = ([_ownSide, "tempo"] call FLO_fnc_gtnGetSideCommanderHandle) get "value";
private _attackCoverage = ([_ownSide, "attackCoverage"] call FLO_fnc_gtnGetSideCommanderHandle) get "value";
private _defenseCoverage = ([_ownSide, "defenseCoverage"] call FLO_fnc_gtnGetSideCommanderHandle) get "value";
private _defenseTrackCount = 1;
private _garrisonHandle = [_ownSide, "garrison"] call FLO_fnc_gtnGetSideCommanderHandle;
private _garrisonRearBaseGroups = _garrisonHandle get "rearBaseGroups";
private _garrisonFrontlineBaseGroups = _garrisonHandle get "frontlineBaseGroups";
private _garrisonPriorityBonusGroups = _garrisonHandle get "priorityBonusGroups";
private _garrisonHotBonusGroups = _garrisonHandle get "hotBonusGroups";

private _defenseResourceShare = 0.40;
private _tracks = [];

for "_i" from 1 to _defenseTrackCount do {
    _tracks pushBack (createHashMapFromArray [
        ["id", format["DEF_%1", _i]],
        ["goal", "protect_critical_assets"],
        ["resourceShare", _defenseResourceShare],
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
    ["_strategicOrderBudgetRemaining", 0],
    ["_strategicOrderBudgetIssued", 0],
    ["_strategicOrderBudgetSkipped", 0],
    ["_strategicOrderBudgetByType", createHashMap],
    ["_availabilityCacheDirty", true],
    ["_availabilityCandidates", []],
    ["_availabilityOwnSideTotal", 0],
    ["_availabilityCacheBuiltAt", -1],
    ["_attackFrontlineObjectives", createHashMap],
    ["_attackFrontlineDirty", true],
    ["_attackSourceObjectivesCache", createHashMap],
    ["_lastFriendlyObjectiveOwnershipSignature", ""],
    ["_objectiveAssignmentCache", createHashMapFromArray [
        ["attackCounts", createHashMap],
        ["attackGroupIds", []],
        ["orderedGroupIds", []],
        ["garrisonCounts", createHashMap],
        ["defenderCounts", createHashMap],
        ["garrisonGroupsByObjective", createHashMap],
        ["garrisonPositionsByObjective", createHashMap],
        ["claimedPositionsByObjective", createHashMap]
    ]],
    ["_reserveBandsCache", createHashMap],
    ["_frontlineCAPLocks", createHashMap],
    ["_frontlineArtilleryLocks", createHashMap],
    ["_frontlineCASLocks", createHashMap],
    ["_frontlineSupportPicture", createHashMap],
    ["_frontlineSupportPictureBuiltAt", -1],
    ["_playerSupportRequests", []],
    ["_playerSupportPlayerCooldowns", createHashMap],
    ["_playerSupportObjectiveLocks", createHashMap],
    ["_intelDirty", true],
    ["_lastIntelPublishAt", -1],
    ["_lastIntelDirtyAt", -1],
    ["_lastIntelDirtyReason", ""],
    ["_lastCommanderIntelPublishSignature", ""],
    ["_lastCommanderIntelOwnerSignature", ""],
    ["_lastCommanderIntelPublishedAt", -1],
    ["_lastGarrisonRunAt", -1],
    ["_lastGarrisonSignature", ""],
    ["_minefieldDirty", true],
    ["_lastMinefieldRunAt", -1],
    
    // Configuration
    ["_config", createHashMapFromArray [
        ["replanInterval", 60],       // Minimum seconds between replans
        ["casualtyThreshold", 0.2],   // Force loss ratio to trigger replan
        ["defenseLeaseSeconds", 300], // Release long-idle DEFEND groups back into the task pool
        ["availabilityCacheMaxAgeSeconds", 20], // Rebuild the availability scan on a cadence even if no direct dirty event fired
        ["intelPublishMinInterval", 30], // Commander COP publishing is player-facing and does not need a full refresh every cycle
        ["intelPublishForceRefreshInterval", 180], // Re-send unchanged commander COP state periodically so late-joining clients catch up
        ["garrisonRefreshMinSeconds", 30], // Baseline garrison floor only needs a strategic refresh cadence unless objective demand changed
        ["minefieldRefreshMinSeconds", 90], // Frontline obstacle fields are strategic shaping work and should not rebuild every commander cycle
        ["minefieldMaxFields", 4], // Limit tracked defensive fields per side so the commander shapes the front instead of blanketing the map
        ["minefieldPlacementsPerCycle", 2], // Limit how many new fields one commander can lay on a single strategic update
        ["attackCoverageMultiplier", _attackCoverage], // Selects the direct per-objective ATTACK cap within the hard six-group ceiling
        ["defenseCoverageMultiplier", _defenseCoverage], // Scales per-objective defense caps without multiplying DEF tracks
        ["defenseObjectiveBaseMin", 2], // Quiet or low-contact objectives should not automatically pull four-plus defenders
        ["defenseObjectiveEnemyMultiplier", 1.0], // Defense scaling should follow enemy strength more conservatively than before
        ["defenseObjectiveUnderAttackBonus", 2], // Active pressure raises the cap, but not by an entire extra squad stack
        ["defenseObjectiveContestedBonus", 1], // Contested ownership gets a small cap bump instead of a large dogpile bonus
        ["defenseObjectiveDeficitMultiplier", 0.25], // Local force deficits should raise defense demand gradually, not explosively
        ["defenseObjectiveHardCap", 8], // Hard ceiling for total defenders on one objective
        ["attackObjectiveGroupCap", 6], // Exact concurrent direct ATTACK cap per enemy objective
        ["attackReserveGraphDepth", 2], // Prefer surplus groups from the connected source axis before widening
        ["garrisonRearBaseGroups", _garrisonRearBaseGroups], // Minimum standing rear garrison on owned quiet objectives
        ["garrisonFrontlineBaseGroups", _garrisonFrontlineBaseGroups], // Minimum standing garrison on owned objectives exposed to enemy adjacency
        ["garrisonPriorityBonusThreshold", 60], // Important objectives receive one extra standing garrison group
        ["garrisonPriorityBonusGroups", _garrisonPriorityBonusGroups], // High-priority objectives keep one more standing holder before surge defense fills
        ["garrisonHotBonusGroups", _garrisonHotBonusGroups], // Objectives already under pressure keep an extra baseline holder even before reactive defense fills
        ["garrisonObjectiveHardCap", 4], // Baseline garrisons should stay lean so defense reserves can move instead of ossifying
        ["frontlineCAPMinThreatScore", 70], // Only spend CAP when recent enemy air contacts near a frontline sector are meaningful
        ["frontlineCAPContactFreshSeconds", 360], // Ignore stale air contacts for CAP scoring
        ["frontlineCAPContactRadiusMeters", 4000], // Friendly frontline sectors only count air contacts in their local airspace
        ["frontlineCAPObjectiveLockSeconds", 720], // CAP missions loiter for a while; keep sectors locked longer than CAS
        ["frontlineSupportPictureIntervalSeconds", 30], // Re-associate maintained contacts with the current direct frontline on a bounded cadence
        ["frontlineSupportMinimumConfidence", 0.25], // Autonomous fires require maintained contact confidence
        ["frontlineSupportContactMaxAgeSeconds", 900], // Match the maintained World State contact retention window
        ["frontlineSupportContactFreshSeconds", 240], // Exact virtual target identities require recent maintained contact
        ["frontlineSupportAssociationRadius", 2000], // Associate reported contacts with their nearest reachable frontline axis
        ["frontlineArtilleryMinScore", 55], // Avoid spending a battery mission on one weak, low-confidence report
        ["frontlineArtilleryObjectiveLockSeconds", 300], // Keep one axis from consuming every side-level artillery window
        ["frontlineArtilleryRetrySeconds", 60], // Failed authorization retries are paced instead of attempted every commander cycle
        ["frontlineArtilleryRounds", 6], // Autonomous frontline missions use the standard six-round battery package
        ["frontlineArtilleryFreshAccuracy", 100], // Fresh observed contacts receive ordinary dispersion
        ["frontlineArtilleryStaleAccuracy", 190], // Old contact areas widen as positional uncertainty grows
        ["frontlineCASMinAttackers", 0], // Maintained contacts remain eligible without an existing ground commitment; active attackers increase target score
        ["frontlineCASMinScore", 80], // Prevent trivial objectives from consuming air support
        ["frontlineCASObjectiveLockSeconds", 420], // Cooldown per objective so repeated cycles do not spam CAS on the same target
        ["frontlineCASRetrySeconds", 90], // Failed sortie authorization is retried on a bounded cadence
        ["playerSupportRequestExpireSeconds", 150], // Player support requests should expire instead of sitting forever in the queue
        ["playerSupportMaxQueuedRequests", 12], // Per-side player support queue cap so spam does not crowd out the commander
        ["playerSupportMaxAssignmentsPerCycle", 1], // One player support assignment per commander cycle keeps support spending paced
        ["playerSupportObjectiveSnapRadiusMeters", 600], // Free-point support requests still attach to a nearby sector for context when one is close enough
        ["playerSupportMapCooldownBucketMeters", 500], // Free-point support requests lock a coarse local map bucket when no sector context exists
        ["playerSupportArtilleryDangerCloseMeters", 250], // Artillery requests must clear a larger safety bubble
        ["playerSupportCASDangerCloseMeters", 175], // CAS requests still need a friendlies exclusion radius
        ["playerSupportArtilleryRounds", 6], // Default player-requested artillery salvo size
        ["playerSupportArtilleryAccuracy", 100], // Default player-requested artillery dispersion in meters
        ["playerSupportPlayerCooldownArtillerySeconds", 120], // Repeat artillery asks from one player should pace out
        ["playerSupportPlayerCooldownCASSeconds", 240], // Repeat CAS asks from one player should pace out
        ["playerSupportPlayerCooldownCAPSeconds", 300], // Repeat CAP asks from one player should pace out
        ["playerSupportObjectiveCooldownArtillerySeconds", 180], // Prevent repeated artillery hits on the same sector or map area from player spam
        ["playerSupportObjectiveCooldownCASSeconds", 300], // Prevent repeated CAS cycling on the same sector or map area from player spam
        ["playerSupportObjectiveCooldownCAPSeconds", 360], // Keep one sector or map area from monopolizing CAP coverage
        ["defenseReserveGraphDepth", 2], // Defense reserve pulls stay on the friendly objective graph around the threatened sector
        ["defenseContestedCollapseForceRatio", 0.65], // Below this friendly/enemy ratio on a contested owned objective, surge defense stops feeding a collapse
        ["defenseContestedCollapseCap", 5], // Collapse-level contested objectives are stabilized with a limited holding force instead of full-cap dogpiles
        ["strategicOrderAssignmentsPerCycle", 16], // Shared bounded order work after garrison ownership
        ["attackAssignmentsPerCycle", 12], // May open several six-group objective attacks in one cycle
        ["defenseAssignmentsPerCycle", 3], // 10-second baseline defense assignment cap for one commander slice
        ["garrisonAssignmentsPerCycle", 16], // Baseline defense may consume the full slice so attacks cannot strip still-ungarrisoned objectives
        ["maxTrackTasksPerCycle", 2] // Primitive burst cap per track per commander update
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
        ["orderLogThresholdMs", 8],
        ["lastCycleMs", 0],
        ["peakCycleMs", 0],
        ["slowCycles", 0],
        ["lastPhaseMs", createHashMapFromArray [
            ["normalizeTasked", 0],
            ["worldState", 0],
            ["intelPublish", 0],
            ["attackAssignments", 0],
            ["frontlineSupport", 0],
            ["garrisons", 0],
            ["allocateTracks", 0],
            ["executeTracks", 0],
            ["frontlineCAP", 0],
            ["frontlineArtillery", 0],
            ["frontlineCAS", 0],
            ["playerSupport", 0],
            ["defenseLeases", 0],
            ["minefields", 0],
            ["staticAA", 0]
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

        private _restoredAssignmentCache = [_self] call FLO_fnc_gtnBuildObjectiveAssignmentCache;
        _self set ["_objectiveAssignmentCache", _restoredAssignmentCache];
        _self set ["_gtnTaskedGroups", +(_restoredAssignmentCache get "orderedGroupIds")];

        private _defenseTracks = count (_self get "_tracks");
        ["GTN", 3, format[
            "GTN Commander started (direct attack hard cap: %1, attack coverage: %2, defense tracks: %3, defense coverage: %4, tempo: %5s)",
            ((_self get "_config") get "attackObjectiveGroupCap"),
            ((_self get "_config") get "attackCoverageMultiplier"),
            _defenseTracks,
            ((_self get "_config") get "defenseCoverageMultiplier"),
            _self get "_updateInterval"
        ]] call FLO_fnc_log;
    }],

    // Stop the GTN commander
    ["_stop", {
        _self set ["_isRunning", 0];
        ["GTN", 3, "GTN Commander stopped"] call FLO_fnc_log;
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
            ["intelPublish", 0],
            ["attackAssignments", 0],
            ["frontlineSupport", 0],
            ["garrisons", 0],
            ["allocateTracks", 0],
            ["executeTracks", 0],
            ["frontlineCAP", 0],
            ["frontlineArtillery", 0],
            ["frontlineCAS", 0],
            ["playerSupport", 0],
            ["defenseLeases", 0],
            ["minefields", 0],
            ["staticAA", 0]
        ];
        private _cycleStart = diag_tickTime;
        private _tPhase = diag_tickTime;
        private _normalizeMetrics = _self call ["_normalizeTaskedGroups", []];
        _phaseMs set ["normalizeTasked", (diag_tickTime - _tPhase) * 1000];
        if (_normalizeMetrics get "changed") then {
            _self set ["_availabilityCacheDirty", true];
        };

        private _availabilityCacheBuiltAt = _self get "_availabilityCacheBuiltAt";
        if (
            _availabilityCacheBuiltAt < 0
            || {_now - _availabilityCacheBuiltAt >= (((_self get "_config") get "availabilityCacheMaxAgeSeconds") max 1)}
        ) then {
            _self set ["_availabilityCacheDirty", true];
        };
        
        private _stats = _self get "_stats";
        _stats set ["cyclesRun", (_stats get "cyclesRun") + 1];
        private _cycleIndex = _stats get "cyclesRun";
        _self call ["_resetStrategicOrderBudget", []];
        
        ["GTN", 4, format["GTN Cycle %1 starting", _cycleIndex]] call FLO_fnc_log;

        // Update world state
        private _ws = _self get "_worldState";
        _tPhase = diag_tickTime;
        private _wsRan = _ws call ["_update", []];
        _phaseMs set ["worldState", (diag_tickTime - _tPhase) * 1000];
        private _wsPerf = _ws call ["_getPerf", []];
        private _wsMeta = _wsPerf get "lastMeta";
        private _enemyIntelSensed = _wsRan && { _wsMeta get "enemyIntelSenseRan" };
        private _supportAssetsSensed = _wsRan && { _wsMeta get "supportSenseRan" };
        private _objectives = _ws call ["_getObjectives", []];
        private _friendlyOwnershipSignature = [_objectives, _self get "_ownSide"] call FLO_fnc_gtnBuildFriendlyObjectiveOwnershipSignature;
        private _friendlyOwnershipChanged = _friendlyOwnershipSignature != (_self get "_lastFriendlyObjectiveOwnershipSignature");
        private _garrisonSignature = [_objectives, _self get "_ownSide", _self get "_enemySide"] call FLO_fnc_gtnBuildObjectiveDemandSignature;
        private _garrisonSignatureChanged = _garrisonSignature != (_self get "_lastGarrisonSignature");

        // Log world state summary
        private _forces = _ws call ["_getForces", []];
        private _situation = _ws call ["_getTacticalSituation", []];
        private _enemyObjs = _ws call ["_getEnemyObjectives", []];
        ["GTN", 4, format["World State: Available=%1, Momentum=%2, EnemyObjs=%3",
            _forces get "availableGroups",
            _situation get "momentum",
            count (keys _enemyObjs)
        ]] call FLO_fnc_log;

        _self call ["_refreshAttackFrontline", []];
        if (_friendlyOwnershipChanged) then {
            _self set ["_reserveBandsCache", createHashMap];
            _self set ["_attackSourceObjectivesCache", createHashMap];
            _self set ["_lastFriendlyObjectiveOwnershipSignature", _friendlyOwnershipSignature];
        };

        // Publish the maintained commander COP to players as non-debug local intel markers.
        private _intelPublishMetrics = createHashMapFromArray [
            ["published", false],
            ["groupCount", 0],
            ["concentrationCount", 0],
            ["friendlyGroupCount", 0],
            ["supportMarkerCount", 0]
        ];
        private _intelDirty = _self get "_intelDirty";
        private _intelOwners = [_self get "_ownSide"] call FLO_fnc_gtnGetSideClientOwners;
        private _intelOwnerParts = _intelOwners apply { str _x };
        _intelOwnerParts sort true;
        private _intelOwnerSignature = _intelOwnerParts joinString ",";
        private _intelPublishDue = (_self get "_lastIntelPublishAt") < 0
            || {_intelDirty}
            || {_enemyIntelSensed}
            || {_supportAssetsSensed}
            || {_intelOwnerSignature != (_self get "_lastCommanderIntelOwnerSignature")}
            || {_now - (_self get "_lastIntelPublishAt") >= (((_self get "_config") get "intelPublishMinInterval") max 1)};
        _tPhase = diag_tickTime;
        if (_intelPublishDue && {_intelOwners isNotEqualTo []}) then {
            _intelPublishMetrics = [_self, _intelOwners] call FLO_fnc_gtnPublishCommanderIntel;
            if (_intelPublishMetrics get "published") then {
                _self set ["_lastIntelPublishAt", _now];
                _self set ["_intelDirty", false];
            };
        };
        _phaseMs set ["intelPublish", (diag_tickTime - _tPhase) * 1000];

        // Release attack-tasked groups whose objective is no longer enemy-held.
        _tPhase = diag_tickTime;
        private _attackAssignmentMetrics = _self call ["_manageCompletedAttackAssignments", []];
        _phaseMs set ["attackAssignments", (diag_tickTime - _tPhase) * 1000];
        _self set ["_objectiveAssignmentCache", [_self] call FLO_fnc_gtnBuildObjectiveAssignmentCache];

        // Re-associate maintained contacts with the current direct enemy frontline.
        _tPhase = diag_tickTime;
        private _supportPictureRan = (_self get "_frontlineSupportPictureBuiltAt") < 0
            || {_now - (_self get "_frontlineSupportPictureBuiltAt") >= (((_self get "_config") get "frontlineSupportPictureIntervalSeconds") max 1)};
        if (_supportPictureRan) then {
            private _frontline = _self call ["_getAttackFrontlineEnemyObjectives", []];
            _self set ["_frontlineSupportPicture", [_self, _frontline] call FLO_fnc_gtnBuildFrontlineSupportPicture];
            _self set ["_frontlineSupportPictureBuiltAt", _now];
        };
        _phaseMs set ["frontlineSupport", (diag_tickTime - _tPhase) * 1000];

        // Maintain standing garrisons before building mobile attack pools.
        private _garrisonMetrics = createHashMapFromArray [
            ["run", false],
            ["signatureChanged", _garrisonSignatureChanged],
            ["existingGarrisons", 0],
            ["releasedGroups", 0],
            ["candidateObjectives", 0],
            ["eligibleGroups", 0],
            ["assignedGroups", 0],
            ["openedObjectives", 0],
            ["reinforcedObjectives", 0],
            ["reserveBandBuilds", 0],
            ["assignmentPasses", 0]
        ];
        private _garrisonRunDue = (_self get "_lastGarrisonRunAt") < 0
            || {_garrisonSignatureChanged}
            || {(_attackAssignmentMetrics get "releasedCount") > 0}
            || {_now - (_self get "_lastGarrisonRunAt") >= (((_self get "_config") get "garrisonRefreshMinSeconds") max 1)};
        _tPhase = diag_tickTime;
        if (_garrisonRunDue) then {
            _garrisonMetrics = [_self] call FLO_fnc_gtnAllocateBaselineGarrisons;
            _garrisonMetrics set ["run", true];
            _garrisonMetrics set ["signatureChanged", _garrisonSignatureChanged];
            _self set ["_lastGarrisonRunAt", _now];
            _self set ["_lastGarrisonSignature", _garrisonSignature];
        };
        _phaseMs set ["garrisons", (diag_tickTime - _tPhase) * 1000];

        // Let the commander shape owned frontline objectives with defensive minefields.
        _tPhase = diag_tickTime;
        private _minefieldMetrics = _self call ["_manageFrontlineMinefields", []];
        _phaseMs set ["minefields", (diag_tickTime - _tPhase) * 1000];

        // Protect mobile defense, then issue direct ATTACK orders from the surplus pool.
        _tPhase = diag_tickTime;
        private _allocationMetrics = _self call ["_allocateGroupsToTracks", []];
        _phaseMs set ["allocateTracks", (diag_tickTime - _tPhase) * 1000];

        // Execute the ordinary mobile-defense track within the shared order budget.
        _tPhase = diag_tickTime;
        private _executeMetrics = _self call ["_executeAllTracks", []];
        _phaseMs set ["executeTracks", (diag_tickTime - _tPhase) * 1000];

        // Request one opportunistic CAP mission for the most threatened friendly frontline sector.
        _tPhase = diag_tickTime;
        private _frontlineCAPMetrics = [_self] call FLO_fnc_gtnRequestFrontlineCAP;
        _phaseMs set ["frontlineCAP", (diag_tickTime - _tPhase) * 1000];

        // Request one paid artillery mission against the strongest maintained contact axis.
        _tPhase = diag_tickTime;
        private _frontlineArtilleryMetrics = [_self] call FLO_fnc_gtnRequestFrontlineArtillery;
        _phaseMs set ["frontlineArtillery", (diag_tickTime - _tPhase) * 1000];

        // Request one paid CAS mission against the strongest maintained contact axis.
        _tPhase = diag_tickTime;
        private _frontlineCASMetrics = [_self] call FLO_fnc_gtnRequestFrontlineCAS;
        _phaseMs set ["frontlineCAS", (diag_tickTime - _tPhase) * 1000];

        // Process queued player support requests through the same commander-owned support systems.
        _tPhase = diag_tickTime;
        private _playerSupportMetrics = [_self] call FLO_fnc_gtnProcessPlayerSupportRequests;
        _phaseMs set ["playerSupport", (diag_tickTime - _tPhase) * 1000];

        // Release DEFEND-tasked groups that sat idle too long in low-pressure sectors.
        _tPhase = diag_tickTime;
        private _leaseMetrics = _self call ["_manageDefenseLeases", []];
        _phaseMs set ["defenseLeases", (diag_tickTime - _tPhase) * 1000];

        // Static AA deployment finalization (creation is handled by logistics network)
        _tPhase = diag_tickTime;
        private _staticAAMetrics = _self call ["_manageStaticAANetwork", []];
        _phaseMs set ["staticAA", (diag_tickTime - _tPhase) * 1000];

        private _groups = call FLO_fnc_virtualizationGetGroupMap;
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
            ["intelPublish", _intelPublishMetrics],
            ["attackAssignments", _attackAssignmentMetrics],
            ["frontlineSupportPictureRan", _supportPictureRan],
            ["garrisons", _garrisonMetrics],
            ["allocation", _allocationMetrics],
            ["execute", _executeMetrics],
            ["frontlineCAP", _frontlineCAPMetrics],
            ["frontlineArtillery", _frontlineArtilleryMetrics],
            ["frontlineCAS", _frontlineCASMetrics],
            ["playerSupport", _playerSupportMetrics],
            ["defenseLeases", _leaseMetrics],
            ["minefields", _minefieldMetrics],
            ["staticAA", _staticAAMetrics],
            ["strategicOrderBudget", _self call ["_getStrategicOrderBudgetMetrics", []]]
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
                "[FLO][PERF] GTN commander %1 cycle %2 groups registry=%3 own=%4 available=%5 tasked=%6 tracks=%7 in %8 ms | normalize=%9 ws=%10 intel=%11 attackRelease=%12 support=%13 garrisons=%14 minefields=%15 allocate=%16 execute=%17 cap=%18 artillery=%19 cas=%20 playerSupport=%21 defense=%22 staticAA=%23",
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
                _phaseMs get "intelPublish",
                _phaseMs get "attackAssignments",
                _phaseMs get "frontlineSupport",
                _phaseMs get "garrisons",
                _phaseMs get "minefields",
                _phaseMs get "allocateTracks",
                _phaseMs get "executeTracks",
                _phaseMs get "frontlineCAP",
                _phaseMs get "frontlineArtillery",
                _phaseMs get "frontlineCAS",
                _phaseMs get "playerSupport",
                _phaseMs get "defenseLeases",
                _phaseMs get "staticAA"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 intel | published=%2 enemyGroups=%3 concentrations=%4 friendlyGroups=%5 support=%6",
                _self get "_sideKey",
                _intelPublishMetrics get "published",
                _intelPublishMetrics get "groupCount",
                _intelPublishMetrics get "concentrationCount",
                _intelPublishMetrics get "friendlyGroupCount",
                _intelPublishMetrics get "supportMarkerCount"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 availability | cacheDirty=%2 registry=%3 own=%4 available=%5 scanMs=%6 allocationMs=%7 defense=%8 attackPool=%9 attackAssigned=%10 fronts=%11 eligible=%12 full=%13 disconnected=%14 noLand=%15 routeRejected=%16 normalizeChanged=%17",
                _self get "_sideKey",
                (_allocationMetrics get "cacheDirty"),
                _allocationMetrics get "totalGroups",
                _allocationMetrics get "ownSideGroups",
                _allocationMetrics get "availableCount",
                _allocationMetrics get "scanMs",
                _allocationMetrics get "roundRobinMs",
                _allocationMetrics get "defenseAllocated",
                _allocationMetrics get "attackPoolTarget",
                _allocationMetrics get "attackAllocated",
                (_allocationMetrics get "directAttack") get "frontlineObjectives",
                (_allocationMetrics get "directAttack") get "candidateObjectives",
                (_allocationMetrics get "directAttack") get "saturatedObjectives",
                (_allocationMetrics get "directAttack") get "disconnectedObjectives",
                (_allocationMetrics get "directAttack") get "landRejectedObjectives",
                (_allocationMetrics get "directAttack") get "routeRejected",
                _normalizeMetrics get "changed"
            ];

            diag_log format [
                "[FLO][PERF] GTN commander %1 defense | idle=%2 running=%3 empty=%4 planCalls=%5 plans=%6 planTasks=%7 planMs=%8 execCalls=%9 execMs=%10 execFail=%11 checkCalls=%12 checkMs=%13 sync=%14 tasks=%15 complete=%16 failed=%17",
                _self get "_sideKey",
                _executeMetrics get "idleTracks",
                _executeMetrics get "runningTracks",
                _executeMetrics get "emptyPoolSkips",
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
                "[FLO][PERF] GTN commander %1 garrisons | run=%2 signatureChanged=%3 existing=%4 released=%5 candidates=%6 eligible=%7 assigned=%8 opened=%9 reinforced=%10 reserveBands=%11 passes=%12",
                _self get "_sideKey",
                _garrisonMetrics get "run",
                _garrisonMetrics get "signatureChanged",
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

            private _orderBudgetMetrics = _metrics get "strategicOrderBudget";
            diag_log format [
                "[FLO][PERF] GTN commander %1 orderBudget | limit=%2 issued=%3 remaining=%4 skipped=%5 byType=%6",
                _self get "_sideKey",
                _orderBudgetMetrics get "limit",
                _orderBudgetMetrics get "issued",
                _orderBudgetMetrics get "remaining",
                _orderBudgetMetrics get "skipped",
                _orderBudgetMetrics get "byType"
            ];

            if (_wsRan) then {
                private _wsPhase = _wsPerf get "lastPhaseMs";
                private _wsMeta = _wsPerf get "lastMeta";
                diag_log format [
                    "[FLO][PERF] GTN commander %1 worldState | total=%2 objectives=%3 forces=%4 support=%5 intel=%6 tactical=%7 | objCount=%8 available=%9 contacts=%10 combatContacts=%11 concentrations=%12 knownGroups=%13 knownGroupObjectives=%14 supportRan=%15 intelRan=%16",
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
                    _wsMeta get "combatContactCount",
                    _wsMeta get "concentrationCount",
                    _wsMeta get "knownGroupCount",
                    _wsMeta get "knownGroupObjectiveCount",
                    _wsMeta get "supportSenseRan",
                    _wsMeta get "enemyIntelSenseRan"
                ];
            };

            diag_log format [
                "[FLO][PERF] GTN commander %1 maintenance | defenseReleased=%2 defenseTrimmed=%3 defenseHolds=%4 defenseLost=%5 attackReleased=%6 aaMoving=%7 aaDeployed=%8",
                _self get "_sideKey",
                _leaseMetrics get "releasedCount",
                _leaseMetrics get "trimmedExcess",
                _leaseMetrics get "holdRefreshCount",
                _leaseMetrics get "lostObjectiveReleaseCount",
                _attackAssignmentMetrics get "releasedCount",
                _staticAAMetrics get "movingStaticAACount",
                _staticAAMetrics get "deployedCount"
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

            diag_log format [
                "[FLO][PERF] GTN commander %1 playerSupport | queued=%2 remaining=%3 approved=%4 expired=%5 rejected=%6 waiting=%7 locked=%8 dispatchFail=%9 abandoned=%10",
                _self get "_sideKey",
                _playerSupportMetrics get "queueCount",
                _playerSupportMetrics get "queueCountAfter",
                _playerSupportMetrics get "approvedCount",
                _playerSupportMetrics get "expiredCount",
                _playerSupportMetrics get "rejectedCount",
                _playerSupportMetrics get "waitingAssetCount",
                _playerSupportMetrics get "lockedCount",
                _playerSupportMetrics get "dispatchFailCount",
                _playerSupportMetrics get "abandonedCount"
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
    
    // Protect mobile defense, then assign the surviving pool directly to frontline attacks.
    ["_allocateGroupsToTracks", {
        private _tracks = _self get "_tracks";
        private _metrics = createHashMapFromArray [
            ["cacheDirty", _self get "_availabilityCacheDirty"],
            ["totalGroups", 0],
            ["ownSideGroups", _self get "_availabilityOwnSideTotal"],
            ["availableCount", 0],
            ["allocatedCount", 0],
            ["defensePoolTarget", 0],
            ["attackPoolTarget", 0],
            ["defenseAllocated", 0],
            ["attackAllocated", 0],
            ["trackCount", count _tracks],
            ["directAttack", createHashMapFromArray [
                ["frontlineObjectives", 0],
                ["candidateObjectives", 0],
                ["saturatedObjectives", 0],
                ["disconnectedObjectives", 0],
                ["landRejectedObjectives", 0],
                ["assignedGroups", 0],
                ["routeRejected", 0]
            ]],
            ["scanMs", 0],
            ["roundRobinMs", 0]
        ];
        
        // Get all available groups (not currently tasked)
        private _totalGroups = count (keys (call FLO_fnc_virtualizationGetGroupMap));
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
        } forEach _tracks;
        
        if (_totalCount == 0) then {
            ["GTN", 4, "No unassigned groups available"] call FLO_fnc_log;
        };
        
        private _defenseTracks = _tracks select { (_x get "goal") == "protect_critical_assets" };
        private _defenseTrack = if (_defenseTracks isNotEqualTo []) then { _defenseTracks select 0 } else { nil };
        private _ws = _self get "_worldState";
        private _allObjectives = _ws call ["_getObjectives", []];
        // Front-aware defense reservation before direct attack assignment.
        private _tRoundRobin = diag_tickTime;
        private _ownSide = _self get "_ownSide";
        private _enemySide = _self get "_enemySide";
        private _allGroups = call FLO_fnc_virtualizationGetGroupMap;
        private _defenseObjectiveProfiles = [_allObjectives, _ownSide, _enemySide] call FLO_fnc_gtnBuildDefenseObjectiveProfiles;
        private _defenseShare = 0;
        { _defenseShare = _defenseShare + (_x get "resourceShare"); } forEach _defenseTracks;

        private _stickyDefenseCount = 0;
        private _rankedDefenseCandidates = [];
        {
            private _groupId = _x;
            private _gData = _allGroups get _groupId;
            if (isNil "_gData") then { continue };

            private _homeObjective = _gData get "homeObjective";
            private _currentOrder = _gData get "commanderOrder";
            private _groupPos = _gData get "position";
            private _priorityBand = 3;
            private _priorityDist = 1e12;

            if (_currentOrder == "DEFEND") then {
                _priorityBand = 0;
                _stickyDefenseCount = _stickyDefenseCount + 1;
            };

            if (_homeObjective in _defenseObjectiveProfiles) then {
                private _homeObj = _allObjectives get _homeObjective;
                _priorityDist = _groupPos distance2D (_homeObj get "position");
                _priorityBand = (_defenseObjectiveProfiles get _homeObjective) min _priorityBand;
            };

            _rankedDefenseCandidates pushBack [_priorityBand, _priorityDist, _groupId];
        } forEach _allAvailable;

        _rankedDefenseCandidates sort true;

        private _defensePoolTarget = 0;
        if (!isNil "_defenseTrack") then {
            _defensePoolTarget = ceil (_totalCount * _defenseShare);
            _defensePoolTarget = (_defensePoolTarget max _stickyDefenseCount) min _totalCount;
        };

        private _assignedToDefense = createHashMap;
        for "_i" from 0 to (_defensePoolTarget - 1) do {
            private _groupId = (_rankedDefenseCandidates select _i) select 2;
            private _pool = _defenseTrack get "groupPool";
            _pool pushBack _groupId;
            _defenseTrack set ["groupPool", _pool];
            _assignedToDefense set [_groupId, true];
        };

        _metrics set ["defensePoolTarget", _defensePoolTarget];
        _metrics set ["defenseAllocated", _defensePoolTarget];

        private _attackCandidates = [];
        {
            if (_x in _assignedToDefense) then { continue };
            _attackCandidates pushBack _x;
        } forEach _allAvailable;

        private _attackMetrics = [_self, _attackCandidates] call FLO_fnc_gtnAllocateFrontlineAttacks;

        _metrics set ["attackPoolTarget", count _attackCandidates];
        _metrics set ["attackAllocated", _attackMetrics get "assignedGroups"];
        _metrics set ["directAttack", _attackMetrics];
        _metrics set ["roundRobinMs", (diag_tickTime - _tRoundRobin) * 1000];
        _metrics set ["allocatedCount", _defensePoolTarget + (_attackMetrics get "assignedGroups")];

        if (FLO_Debug_Level >= 4) then {
            {
                private _track = _x;
                ["GTN", 4, format["Track %1 (%2) allocated %3 groups",
                    _track get "id",
                    _track get "goal",
                    count (_track get "groupPool")
                ]] call FLO_fnc_log;
            } forEach _tracks;
        };

        _metrics
    }],
    
    // Execute the ready mobile-defense track; attacks were committed directly above.
    ["_executeAllTracks", {
        private _tracks = _self get "_tracks";
        private _trackCount = count _tracks;
        private _metrics = createHashMapFromArray [
            ["tracksTotal", _trackCount],
            ["idleTracks", { (_x get "status") == "IDLE" } count _tracks],
            ["runningTracks", { (_x get "status") == "RUNNING" } count _tracks],
            ["emptyPoolSkips", 0],
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

        private _selectedDefenseIdx = -1;
        {
            if ((_x get "goal") != "protect_critical_assets") then { continue };

            private _trackReady = (_x get "status") == "RUNNING";
            if (!_trackReady && {(_x get "groupPool") isNotEqualTo []}) then {
                _trackReady = true;
            };

            if (_trackReady) exitWith {
                _selectedDefenseIdx = _forEachIndex;
            };
        } forEach _tracks;

        if (_selectedDefenseIdx < 0) exitWith { _metrics };
        _self set ["_nextTrackExecutionIndex", (_selectedDefenseIdx + 1) mod _trackCount];

        private _aggregateKeys = [
            "emptyPoolSkips",
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

        _metrics
    }],
    
    // Get groups from a track's pool
    ["_getGroupsFromTrack", {
        params ["_track", "_count", ["_targetPos", []]];
        
        private _pool = _track get "groupPool";
        private _allGroups = call FLO_fnc_virtualizationGetGroupMap;
        private _tasked = _self get "_gtnTaskedGroups";
        private _ownSide = _self get "_ownSide";
        private _assignableGroupTypes = ["infantry", "motorized", "mechanized", "armor"];
        private _idleStrategicOrders = ["PATROL", "DEFEND", ""];
        private _filteredPool = [];
        {
            private _gData = _allGroups get _x;
            if (isNil "_gData") then { continue };
            if (_x in _tasked) then { continue };
            if !([_gData, _ownSide, _assignableGroupTypes, _idleStrategicOrders] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then { continue };
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
        
        ["GTN", 4, format["Track %1: Consumed %2 groups (requested %3, %4 remaining in pool)",
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
                ["GTN", 3, format["Track %1 goal changed to: %2", _trackId, _newGoal]] call FLO_fnc_log;
            };
        } forEach _tracks;
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

    // === TACTICAL METHODS (used by executor handlers) ===

    ["_allocateFrontlineDefense", {
        params [["_track", nil]];
        [_self, _track] call FLO_fnc_gtnAllocateFrontlineDefense
    }],

    ["_manageFrontlineMinefields", {
        [_self] call FLO_fnc_gtnManageFrontlineMinefields
    }],

    ["_manageCompletedAttackAssignments", {
        [_self] call FLO_fnc_gtnReleaseCompletedAttackAssignments
    }],

    ["_resetStrategicOrderBudget", {
        private _limit = [_self, "strategicOrderAssignmentsPerCycle"] call FLO_fnc_gtnGetTempoScaledAssignmentLimit;
        _self set ["_strategicOrderBudgetRemaining", _limit];
        _self set ["_strategicOrderBudgetIssued", 0];
        _self set ["_strategicOrderBudgetSkipped", 0];
        _self set ["_strategicOrderBudgetByType", createHashMap];
    }],

    ["_hasStrategicOrderBudget", {
        (_self get "_strategicOrderBudgetRemaining") > 0
    }],

    ["_consumeStrategicOrderBudget", {
        params [["_orderType", "UNKNOWN", [""]]];

        private _remaining = _self get "_strategicOrderBudgetRemaining";
        if (_remaining <= 0) exitWith {
            _self set ["_strategicOrderBudgetSkipped", (_self get "_strategicOrderBudgetSkipped") + 1];
            false
        };

        _self set ["_strategicOrderBudgetRemaining", _remaining - 1];
        _self set ["_strategicOrderBudgetIssued", (_self get "_strategicOrderBudgetIssued") + 1];

        private _byType = _self get "_strategicOrderBudgetByType";
        private _count = if (_orderType in _byType) then { _byType get _orderType } else { 0 };
        _byType set [_orderType, _count + 1];
        true
    }],

    ["_refundStrategicOrderBudget", {
        params [["_orderType", "UNKNOWN", [""]]];

        private _issued = _self get "_strategicOrderBudgetIssued";
        private _byType = _self get "_strategicOrderBudgetByType";
        if (_issued <= 0 || {!(_orderType in _byType)} || {(_byType get _orderType) <= 0}) then {
            throw format ["Cannot refund unissued strategic %1 order budget", _orderType];
        };
        _self set ["_strategicOrderBudgetRemaining", (_self get "_strategicOrderBudgetRemaining") + 1];
        _self set ["_strategicOrderBudgetIssued", _issued - 1];
        private _typeCount = (_byType get _orderType) - 1;
        if (_typeCount == 0) then {
            _byType deleteAt _orderType;
        } else {
            _byType set [_orderType, _typeCount];
        };
        true
    }],

    ["_getStrategicOrderBudgetMetrics", {
        private _limit = [_self, "strategicOrderAssignmentsPerCycle"] call FLO_fnc_gtnGetTempoScaledAssignmentLimit;
        createHashMapFromArray [
            ["limit", _limit],
            ["issued", _self get "_strategicOrderBudgetIssued"],
            ["remaining", _self get "_strategicOrderBudgetRemaining"],
            ["skipped", _self get "_strategicOrderBudgetSkipped"],
            ["byType", _self get "_strategicOrderBudgetByType"]
        ]
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
        private _groups = call FLO_fnc_virtualizationGetGroupMap;
        private _tasked = _self get "_gtnTaskedGroups";
        private _taskedSet = createHashMap;
        { _taskedSet set [_x, true]; } forEach _tasked;

        private _ownSide = _self get "_ownSide";
        private _available = [];
        private _ownSideGroupCount = 0;
        private _assignableGroupTypes = ["infantry", "motorized", "mechanized", "armor"];
        private _idleStrategicOrders = ["PATROL", "DEFEND", ""];

        {
            private _groupId = _x;
            private _gData = _y;

            if ((_gData get "side") != _ownSide) then { continue };
            _ownSideGroupCount = _ownSideGroupCount + 1;
            if (_taskedSet getOrDefault [_groupId, false]) then { continue };
            if !([_gData, _ownSide, _assignableGroupTypes, _idleStrategicOrders] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then { continue };

            _available pushBack [_groupId, _gData];
        } forEach _groups;

        _self set ["_availabilityCandidates", _available];
        _self set ["_availabilityOwnSideTotal", _ownSideGroupCount];
        _self set ["_availabilityCacheDirty", false];
        _self set ["_availabilityCacheBuiltAt", diag_tickTime];
        _available
    }],

    // Get available groups for tasking from virtualization system
    ["_getAvailableGroups", {
        params [["_count", 4], ["_targetPos", []]];

        private _availabilityCacheBuiltAt = _self get "_availabilityCacheBuiltAt";
        if (
            (_self get "_availabilityCacheDirty")
            || {_availabilityCacheBuiltAt < 0}
            || {diag_tickTime - _availabilityCacheBuiltAt >= (((_self get "_config") get "availabilityCacheMaxAgeSeconds") max 1)}
        ) then {
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

        // Extract cached IDs without rebuilding per-group debug strings.
        private _result = [];
        private _takeCount = _count min (count _available);
        if (_takeCount > 0) then {
            for "_index" from 0 to (_takeCount - 1) do {
                _result pushBack ((_available select _index) select 0);
            };
        };

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

        _self set ["_availabilityCacheDirty", true];
    }],

    // Release groups from GTN tasking and clear their orders
    ["_releaseGroups", {
        params [["_groupIds", []], ["_newOrder", ""]];
        private _tasked = _self get "_gtnTaskedGroups";
        private _groups = call FLO_fnc_virtualizationGetGroupMap;
        
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
                ["GTN", 5, format["Released group %1, order reset to '%2'", _groupId, _newOrder]] call FLO_fnc_log;
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
        private _config = _self get "_config";
        private _coverage = _config get "defenseCoverageMultiplier";

        private _cap = (_config get "defenseObjectiveBaseMin") max (ceil (_enemyCount * (_config get "defenseObjectiveEnemyMultiplier")));
        if (_underAttack) then { _cap = _cap + (_config get "defenseObjectiveUnderAttackBonus"); };
        if (_contested) then { _cap = _cap + (_config get "defenseObjectiveContestedBonus"); };

        private _deficit = (_enemyCount - _friendlyCount) max 0;
        if (_deficit > 0) then {
            _cap = _cap + (ceil (_deficit * (_config get "defenseObjectiveDeficitMultiplier")));
        };

        _cap = ceil (_cap * _coverage);
        _cap = (_cap max (_config get "defenseObjectiveBaseMin")) min (_config get "defenseObjectiveHardCap");

        if (_contested && {_enemyCount > 0}) then {
            private _forceRatio = _friendlyCount / _enemyCount;
            if (_forceRatio < (_config get "defenseContestedCollapseForceRatio")) then {
                _cap = _cap min (_config get "defenseContestedCollapseCap");
            };
        };

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
        if !([_ownSide, _objectiveId] call FLO_fnc_campaignCanSupportObjective) exitWith { 0 };

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
        (_cap max 0) min ((_config get "garrisonObjectiveHardCap") min _defenseCap)
    }],

    // Friendly-held linked objectives that can directly source an attack on this enemy objective.
    ["_getFriendlyAttackSourceObjectives", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { [] };

        private _ws = _self get "_worldState";
        private _objectives = _ws get "_objectives";
        private _objective = _objectives get _objectiveId;
        private _ownSide = _self get "_ownSide";
        private _linkedObjectives = _objective get "linkedObjectives";
        private _cache = _self get "_attackSourceObjectivesCache";

        if (_objectiveId in _cache) exitWith {
            _cache get _objectiveId
        };

        private _sourceObjectives = _linkedObjectives select {
            ((_objectives get _x) get "owner") isEqualTo _ownSide
            && {[_x] call FLO_fnc_campaignIsObjectiveIntegrated}
        };
        _cache set [_objectiveId, _sourceObjectives];

        _sourceObjectives
    }],

    ["_refreshAttackFrontline", {
        private _ws = _self get "_worldState";
        private _strictFrontlineObjectives = _ws call ["_getFrontlineEnemyObjectives", []];
        _self set ["_attackFrontlineObjectives", _strictFrontlineObjectives];
        _self set ["_attackFrontlineDirty", false];
        _strictFrontlineObjectives
    }],

    ["_getAttackFrontlineEnemyObjectives", {
        if (_self get "_attackFrontlineDirty") exitWith {
            _self call ["_refreshAttackFrontline", []]
        };

        _self get "_attackFrontlineObjectives"
    }],

    // Count current defenders assigned to a specific objective.
    ["_countObjectiveDefenders", {
        params ["_objectiveId"];
        if (_objectiveId == "") exitWith { 0 };

        private _groups = call FLO_fnc_virtualizationGetGroupMap;
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
        if (_tasked isEqualTo []) exitWith { _metrics };

        private _groups = call FLO_fnc_virtualizationGetGroupMap;
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
                if (_bucket isEqualTo []) exitWith {};
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

        if (_releaseIds isEqualTo []) exitWith { _metrics };

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

        private _groups = call FLO_fnc_virtualizationGetGroupMap;
        private _gData = _groups get _groupId;
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order move - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if (!(_pos isEqualType []) || {count _pos < 2}) exitWith {
            ["GTN", 2, format["Cannot order move - invalid destination for %1: %2", _groupId, _pos]] call FLO_fnc_log;
            false
        };

        private _existingTarget = _gData get "orderTargetPos";
        private _existingMode = _gData get "orderMode";
        private _hasRouteContext = ((_gData get "waypoints") isNotEqualTo []) || {(_gData get "pathToken") >= 0};
        if ((_gData get "commanderOrder") == "MOVE" && {_existingMode == _mode} && {_hasRouteContext} && {count _existingTarget >= 2} && {_existingTarget distance2D _pos < 35}) exitWith {
            if (isNil "FLO_GTN_OrderNoOps") then { FLO_GTN_OrderNoOps = createHashMap; };
            FLO_GTN_OrderNoOps set ["MOVE", (FLO_GTN_OrderNoOps getOrDefault ["MOVE", 0]) + 1];
            _self call ["_taskGroups", [[_groupId]]];
            true
        };

        private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];

        private _waypoints = [
            [_pos, "MOVE", _mode, "FULL", _formation, "YELLOW", 30]
        ];

        private _commitResult = [_groupId, _gData, "MOVE", _waypoints, _pos, "GTN_MOVE", "", _mode] call FLO_fnc_virtualizationCommitCommanderOrder;
        if !(_commitResult select 0) exitWith { false };

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 5, format["Ordered group %1 to move to %2 (%3)", _groupId, _pos, _mode]] call FLO_fnc_log;
        true
    }],

    // Order group to attack using virtualization waypoints
    ["_orderGroupAttack", {
        params [
            "_groupId",
            "_attackPos",
            ["_objectiveId", ""],
            ["_consumeAssignmentBudget", false, [true]]
        ];

        if (_objectiveId == "") then {
            throw "GTN ATTACK requires an objective";
        };

        private _groups = call FLO_fnc_virtualizationGetGroupMap;
        private _gData = _groups get _groupId;
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order attack - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if (!(_attackPos isEqualType []) || {count _attackPos < 2}) then {
            throw format ["GTN ATTACK has invalid target position for %1: %2", _groupId, _attackPos];
        };

        private _ownSide = _self get "_ownSide";
        if !([_gData, _ownSide, ["infantry", "motorized", "mechanized", "armor"]] call FLO_fnc_gtnGroupIsStrategicallyAssignable) exitWith {
            ["GTN", 2, format[
                "Cannot order attack - group %1 not strategically assignable (type=%2 lock=%3 replacement=%4 transport=%5 attached=%6 mounted=%7)",
                _groupId,
                _gData get "groupType",
                _gData get "missionLock",
                _gData get "replacementState",
                _gData get "transportRole",
                _gData get "attachedTo",
                _gData get "mountedIn"
            ]] call FLO_fnc_log;
            false
        };

        private _existingAttackObjective = _gData get "attackObjective";
        private _hasRouteContext = ((_gData get "waypoints") isNotEqualTo []) || {(_gData get "pathToken") >= 0};
        if (
            (_gData get "commanderOrder") == "ATTACK"
            && {_hasRouteContext}
            && {_existingAttackObjective == _objectiveId}
        ) exitWith {
            if (isNil "FLO_GTN_OrderNoOps") then { FLO_GTN_OrderNoOps = createHashMap; };
            FLO_GTN_OrderNoOps set ["ATTACK", (FLO_GTN_OrderNoOps getOrDefault ["ATTACK", 0]) + 1];
            _self call ["_taskGroups", [[_groupId]]];
            true
        };

        if (_consumeAssignmentBudget && {!(_self call ["_consumeStrategicOrderBudget", ["ATTACK"]])}) exitWith {
            ["GTN", 4, format["Skipped ATTACK order for %1: strategic order budget exhausted", _groupId]] call FLO_fnc_log;
            false
        };

        private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];

        private _waypoints = [
            [_attackPos, "MOVE", "AWARE", "FULL", _formation, "YELLOW", 75],
            [_attackPos, "MOVE", "AWARE", "FULL", _formation, "YELLOW", 50]
        ];

        private _commitResult = [
            _groupId,
            _gData,
            "ATTACK",
            _waypoints,
            _attackPos,
            "GTN_ATTACK",
            _objectiveId,
            "",
            -1,
            -1
        ] call FLO_fnc_virtualizationCommitCommanderOrder;
        _commitResult params ["_commitSuccess", "_routeMs", "_assignMs", "_transportMs", "_orderMs"];
        if (!_commitSuccess) exitWith {
            if (_consumeAssignmentBudget) then {
                _self call ["_refundStrategicOrderBudget", ["ATTACK"]];
            };
            false
        };

        [_self, "ATTACK", _groupId, _gData get "groupType", _objectiveId, _routeMs, _assignMs, _transportMs, _orderMs] call FLO_fnc_gtnLogStrategicOrderPerf;

        private _assignmentCache = _self get "_objectiveAssignmentCache";
        private _attackCounts = _assignmentCache get "attackCounts";
        private _count = if (_objectiveId in _attackCounts) then { _attackCounts get _objectiveId } else { 0 };
        _attackCounts set [_objectiveId, _count + 1];

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 5, format["Ordered group %1 to attack %2 (%3)", _groupId, _attackPos, _objectiveId]] call FLO_fnc_log;
        true
    }],

    // Order group to defend using virtualization waypoints
    ["_orderGroupDefend", {
        params ["_groupId", "_pos", ["_objectiveId", ""], ["_skipSaturationCheck", false, [true]], ["_consumeAssignmentBudget", false, [true]]];

        private _groups = call FLO_fnc_virtualizationGetGroupMap;
        private _gData = _groups get _groupId;
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order defend - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if (!(_pos isEqualType []) || {count _pos < 2}) exitWith {
            ["GTN", 2, format["Cannot order defend - invalid destination for %1: %2", _groupId, _pos]] call FLO_fnc_log;
            false
        };

        private _ownSide = _self get "_ownSide";
        if !([_gData, _ownSide, ["infantry", "motorized", "mechanized", "armor"], []] call FLO_fnc_gtnGroupIsStrategicallyAssignable) exitWith {
            ["GTN", 2, format[
                "Cannot order defend - group %1 not strategically assignable (type=%2 lock=%3 replacement=%4 transport=%5 attached=%6 mounted=%7)",
                _groupId,
                _gData get "groupType",
                _gData get "missionLock",
                _gData get "replacementState",
                _gData get "transportRole",
                _gData get "attachedTo",
                _gData get "mountedIn"
            ]] call FLO_fnc_log;
            false
        };

        private _alreadyAssigned = false;
        private _saturated = false;
        if (_objectiveId != "") then {
            private _hasRouteContext = ((_gData get "waypoints") isNotEqualTo []) || {(_gData get "pathToken") >= 0};
            private _sameObjectiveAssigned = ((_gData get "commanderOrder") == "DEFEND") && {(_gData get "defendObjective") == _objectiveId} && {_hasRouteContext};
            private _currentDefendPos = _gData get "orderTargetPos";
            private _sameHoldPos = _currentDefendPos isEqualType [] && {count _currentDefendPos >= 2} && {(_currentDefendPos distance2D _pos) < 20};
            _alreadyAssigned = _sameObjectiveAssigned && {_sameHoldPos};
            if (!_sameObjectiveAssigned && {!_skipSaturationCheck}) then {
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

        if (_consumeAssignmentBudget && {!(_self call ["_consumeStrategicOrderBudget", ["DEFEND"]])}) exitWith {
            ["GTN", 4, format["Skipped DEFEND order for %1: strategic order budget exhausted", _groupId]] call FLO_fnc_log;
            false
        };

        private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];

        private _waypoints = [
            [_pos, "MOVE", "AWARE", "FULL", _formation, "YELLOW", 40],
            [_pos, "GUARD", "AWARE", "FULL", _formation, "YELLOW", 60]
        ];

        private _leaseSeconds = (_self get "_config") get "defenseLeaseSeconds";
        private _commitResult = [_groupId, _gData, "DEFEND", _waypoints, _pos, "GTN_DEFEND", _objectiveId, "", diag_tickTime, diag_tickTime + _leaseSeconds] call FLO_fnc_virtualizationCommitCommanderOrder;
        _commitResult params ["_commitSuccess", "_routeMs", "_assignMs", "_transportMs", "_orderMs"];
        if (!_commitSuccess) exitWith {
            if (_consumeAssignmentBudget) then {
                _self call ["_refundStrategicOrderBudget", ["DEFEND"]];
            };
            false
        };
        [_self, "DEFEND", _groupId, _gData get "groupType", _objectiveId, _routeMs, _assignMs, _transportMs, _orderMs] call FLO_fnc_gtnLogStrategicOrderPerf;

        if (_objectiveId != "") then {
            private _assignmentCache = _self get "_objectiveAssignmentCache";
            private _defenderCounts = _assignmentCache get "defenderCounts";
            private _claimedPositions = _assignmentCache get "claimedPositionsByObjective";

            private _count = if (_objectiveId in _defenderCounts) then {
                _defenderCounts get _objectiveId
            } else {
                0
            };
            _defenderCounts set [_objectiveId, _count + 1];

            private _bucket = if (_objectiveId in _claimedPositions) then {
                _claimedPositions get _objectiveId
            } else {
                []
            };
            _bucket pushBack _pos;
            _claimedPositions set [_objectiveId, _bucket];
        };

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 5, format["Ordered group %1 to defend %2", _groupId, _pos]] call FLO_fnc_log;
        true
    }],

    // Order group to hold a standing garrison on an owned objective.
    ["_orderGroupGarrison", {
        params ["_groupId", "_routePlan", ["_objectiveId", ""], ["_consumeAssignmentBudget", false, [true]]];

        private _groups = call FLO_fnc_virtualizationGetGroupMap;
        private _gData = _groups get _groupId;
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order garrison - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        if !(_routePlan isEqualType createHashMap) then {
            throw format ["Cannot order garrison %1 with route-plan type %2", _groupId, typeName _routePlan];
        };
        private _pos = _routePlan get "targetPos";
        private _waypoints = _routePlan get "waypoints";
        private _orderMode = _routePlan get "orderMode";
        if (!(_pos isEqualType []) || {count _pos < 2}) exitWith {
            ["GTN", 2, format["Cannot order garrison - invalid destination for %1: %2", _groupId, _pos]] call FLO_fnc_log;
            false
        };
        if (_waypoints isEqualTo [] || {!(_orderMode in ["GARRISON_BUILDING", "GARRISON_PATROL"])}) then {
            throw format ["Cannot order garrison %1 with invalid route mode/topology %2/%3", _groupId, _orderMode, count _waypoints];
        };

        private _ownSide = _self get "_ownSide";
        if !([_gData, _ownSide, ["infantry", "motorized", "mechanized", "armor"], []] call FLO_fnc_gtnGroupIsStrategicallyAssignable) exitWith {
            ["GTN", 2, format[
                "Cannot order garrison - group %1 not strategically assignable (type=%2 lock=%3 replacement=%4 transport=%5 attached=%6 mounted=%7)",
                _groupId,
                _gData get "groupType",
                _gData get "missionLock",
                _gData get "replacementState",
                _gData get "transportRole",
                _gData get "attachedTo",
                _gData get "mountedIn"
            ]] call FLO_fnc_log;
            false
        };

        private _hasRouteContext = ((_gData get "waypoints") isNotEqualTo []) || {(_gData get "pathToken") >= 0};
        private _currentGarrisonPos = _gData get "garrisonPosition";
        private _sameHoldPos = _currentGarrisonPos isEqualType [] && {count _currentGarrisonPos >= 2} && {(_currentGarrisonPos distance2D _pos) < 20};
        if (
            (_gData get "commanderOrder") == "GARRISON"
            && {(_gData get "garrisonObjective") == _objectiveId}
            && {(_gData get "orderMode") == _orderMode}
            && {_hasRouteContext}
            && {_sameHoldPos}
        ) exitWith {
            if (isNil "FLO_GTN_OrderNoOps") then { FLO_GTN_OrderNoOps = createHashMap; };
            FLO_GTN_OrderNoOps set ["GARRISON", (FLO_GTN_OrderNoOps getOrDefault ["GARRISON", 0]) + 1];
            _self call ["_taskGroups", [[_groupId]]];
            true
        };

        if (_consumeAssignmentBudget && {!(_self call ["_consumeStrategicOrderBudget", ["GARRISON"]])}) exitWith {
            ["GTN", 4, format["Skipped GARRISON order for %1: strategic order budget exhausted", _groupId]] call FLO_fnc_log;
            false
        };

        private _commitResult = [
            _groupId,
            _gData,
            "GARRISON",
            _waypoints,
            _pos,
            _orderMode,
            _objectiveId,
            _orderMode
        ] call FLO_fnc_virtualizationCommitCommanderOrder;
        _commitResult params ["_commitSuccess", "_routeMs", "_assignMs", "_transportMs", "_orderMs"];
        if (!_commitSuccess) exitWith {
            if (_consumeAssignmentBudget) then {
                _self call ["_refundStrategicOrderBudget", ["GARRISON"]];
            };
            false
        };
        [_self, "GARRISON", _groupId, _gData get "groupType", _objectiveId, _routeMs, _assignMs, _transportMs, _orderMs] call FLO_fnc_gtnLogStrategicOrderPerf;

        if (_objectiveId != "") then {
            private _assignmentCache = _self get "_objectiveAssignmentCache";
            private _garrisonCounts = _assignmentCache get "garrisonCounts";
            private _defenderCounts = _assignmentCache get "defenderCounts";
            private _claimedPositions = _assignmentCache get "claimedPositionsByObjective";

            private _garrisonCount = if (_objectiveId in _garrisonCounts) then {
                _garrisonCounts get _objectiveId
            } else {
                0
            };
            _garrisonCounts set [_objectiveId, _garrisonCount + 1];

            private _defenderCount = if (_objectiveId in _defenderCounts) then {
                _defenderCounts get _objectiveId
            } else {
                0
            };
            _defenderCounts set [_objectiveId, _defenderCount + 1];

            private _bucket = if (_objectiveId in _claimedPositions) then {
                _claimedPositions get _objectiveId
            } else {
                []
            };
            _bucket pushBack _pos;
            _claimedPositions set [_objectiveId, _bucket];
        };

        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 5, format["Ordered group %1 to garrison %2 mode=%3", _groupId, _objectiveId, _orderMode]] call FLO_fnc_log;
        true
    }],

    // Request an air mission using the GTN air support system.
    ["_requestAirMission", {
        params ["_pos", ["_missionType", "CAS"], ["_meta", createHashMap]];
        private _ownSide = _self get "_ownSide";

        private _ato = call FLO_fnc_gtnAirTaskOrder;
        private _altitude = 150;

        _ato call ["_addTask", [_pos, _missionType, "", _altitude, _ownSide, _meta]];
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
        params ["_pos", ["_missionType", "CAS"], ["_meta", createHashMap]];
        _self call ["_requestAirMission", [_pos, _missionType, _meta]]
    }],

    // Request CAP using the GTN air support system
    ["_requestCAP", {
        params ["_pos", ["_meta", createHashMap]];
        _self call ["_requestAirMission", [_pos, "CAP", _meta]]
    }],

    // Static AA deployment finalization
    // - Static AA groups are created by logistics network
    // - Commander only finalizes deployment when movers reach target
    ["_manageStaticAANetwork", {
        private _groups = call FLO_fnc_virtualizationGetGroupMap;
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

            if !([_groupId, [], true, "GTN_AA_DEPLOYED"] call FLO_fnc_updateVirtualGroupWaypoints) then {
                throw format ["Static AA %1 route clear was rejected", _groupId];
            };
            [
                _groupId,
                createHashMapFromArray [
                    ["forceVirtual", false],
                    ["noWaypoints", true],
                    ["alwaysActive", false]
                ]
            ] call FLO_fnc_virtualizationPatchGroup;
            [_gData, "AA_HOLD"] call FLO_fnc_virtualizationClearReplacementTransit;
            [_gData, "DEPLOYED", _targetPos, [_gData] call FLO_fnc_virtualizationGetAATargetObjective, _gData get "isStrategicAA"] call FLO_fnc_virtualizationSetAADeployState;

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
            private _pool = count (_track get "groupPool");
            private _planner = _track get "planner";
            
            private _planStatus = if (!isNil "_planner") then {
                _planner call ["_getPlanStatus", []]
            } else { "NO_PLAN" };
            
            private _taskInfo = if (!isNil "_planner") then {
                private _task = _planner call ["_getCurrentTask", []];
                if (!isNil "_task") then {
                    _task get "taskId"
                } else { "-" }
            } else { "-" };
            
            private _shortGoal = _goal select [0, 12]; // First 12 chars
            _summary pushBack format["%1(%2):%3|p=%4|t=%5",
                _trackId, _shortGoal, _planStatus, _pool, _taskInfo];
        } forEach _tracks;
        
        ["GTN", 3, format["DECISION[tasked=%1]: %2", count _tasked, _summary joinString " | "]] call FLO_fnc_log;
    }],
    
    // Debug why groups aren't available - call this when commander seems stuck
    ["_debugGroupAvailability", {
        private _groups = call FLO_fnc_virtualizationGetGroupMap;
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
            private _orderKey = [_currentOrder, "IDLE"] select (_currentOrder == "");
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
        private _groups = call FLO_fnc_virtualizationGetGroupMap;
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

["GTN", 3, "GTN Commander System initialized"] call FLO_fnc_log;

_gtnCommander
