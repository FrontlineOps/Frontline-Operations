/* Strategic work keeps its order, yielding only between owned transactions. */
params ["_commander"];
private _started = diag_tickTime;
private _startFrame = diag_frameNo;
private _perf = _commander get "_perf";
private _snapshotBefore = +(_perf get "snapshotTotals");
_perf set ["cycleWorkMs", 0];
_perf set ["cycleSliceFrame", -1];
_perf set ["cycleSliceMs", 0];
_perf set ["cyclePeakFrameMs", 0];
private _phaseMs = createHashMap;
private _world = _commander get "_worldState";
private _stats = _commander get "_stats";
_commander set ["_lastUpdate", _started];
_stats set ["cyclesRun", (_stats get "cyclesRun") + 1];
[_commander, {
    params ["_cmdr"];
    _cmdr call ["_resetStrategicOrderBudget", []];
    _cmdr call ["_normalizeTaskedGroups", []];
}, [_commander]] call FLO_fnc_gtnRunCycleStep;
_phaseMs set ["normalizeTasked", _perf get "cycleWorkMs"];
private _at = _perf get "cycleWorkMs";
_world call ["_update", []];
_phaseMs set ["worldState", (_perf get "cycleWorkMs") - _at];
_at = _perf get "cycleWorkMs";
private _strategicAt = _at;
private _strategicPhases = createHashMap;
[_commander, {
    params ["_cmdr"];
    private _objectives = (_cmdr get "_worldState") get "_objectives";
    private _signature = [_objectives, _cmdr get "_ownSide"] call FLO_fnc_gtnBuildFriendlyObjectiveOwnershipSignature;
    if (_signature != (_cmdr get "_lastFriendlyObjectiveOwnershipSignature")) then {
        _cmdr set ["_attackFrontlineDirty", true];
        _cmdr set ["_reserveBandsCache", createHashMap];
        _cmdr set ["_attackSourceObjectivesCache", createHashMap];
        _cmdr set ["_lastFriendlyObjectiveOwnershipSignature", _signature];
    };
    _cmdr call ["_refreshAttackFrontline", []];
}, [_commander]] call FLO_fnc_gtnRunCycleStep;
_strategicPhases set ["frontline", (_perf get "cycleWorkMs") - _strategicAt];
_strategicAt = _perf get "cycleWorkMs";
[_commander, { params ["_cmdr"]; _cmdr call ["_manageCompletedAttackAssignments", []] }, [_commander]] call FLO_fnc_gtnRunCycleStep;
_strategicPhases set ["completedAssignments", (_perf get "cycleWorkMs") - _strategicAt];
_strategicAt = _perf get "cycleWorkMs";
[_commander, { params ["_cmdr"]; _cmdr call ["_manageDefenseLeases", []] }, [_commander]] call FLO_fnc_gtnRunCycleStep;
_strategicPhases set ["defenseLeases", (_perf get "cycleWorkMs") - _strategicAt];
_strategicAt = _perf get "cycleWorkMs";
[_commander, FLO_fnc_gtnReleaseObsoleteHolds, [_commander]] call FLO_fnc_gtnRunCycleStep;
_strategicPhases set ["obsoleteHolds", (_perf get "cycleWorkMs") - _strategicAt];
_strategicAt = _perf get "cycleWorkMs";
[_commander, {
    params ["_cmdr"];
    _cmdr set ["_objectiveAssignmentCache", [_cmdr] call FLO_fnc_gtnBuildObjectiveAssignmentCache];
}, [_commander]] call FLO_fnc_gtnRunCycleStep;
_strategicPhases set ["assignmentIndex", (_perf get "cycleWorkMs") - _strategicAt];
_strategicAt = _perf get "cycleWorkMs";
[_commander, {
    params ["_cmdr", "_started"];
    private _supportDue = (_cmdr get "_frontlineSupportPictureBuiltAt") < 0
        || {_started - (_cmdr get "_frontlineSupportPictureBuiltAt") >= ((_cmdr get "_config") get "frontlineSupportPictureIntervalSeconds")};
    if (_supportDue) then {
        _cmdr set ["_frontlineSupportPicture", [_cmdr, _cmdr call ["_getAttackFrontlineEnemyObjectives", []]] call FLO_fnc_gtnBuildFrontlineSupportPicture];
        _cmdr set ["_frontlineSupportPictureBuiltAt", _started];
    };
}, [_commander, _started]] call FLO_fnc_gtnRunCycleStep;
_strategicPhases set ["supportPicture", (_perf get "cycleWorkMs") - _strategicAt];
_strategicAt = _perf get "cycleWorkMs";
[_commander] call FLO_fnc_gtnBuildStrategicPicture;
_strategicPhases set ["objectiveStrategy", (_perf get "cycleWorkMs") - _strategicAt];
_strategicAt = _perf get "cycleWorkMs";
[_commander, FLO_fnc_gtnManageFrontlineMinefields, [_commander]] call FLO_fnc_gtnRunCycleStep;
_strategicPhases set ["minefields", (_perf get "cycleWorkMs") - _strategicAt];
_phaseMs set ["strategicPicture", (_perf get "cycleWorkMs") - _at];
_at = _perf get "cycleWorkMs";
// These loops apply the same step boundary to each intent and admission.
private _execution = [_commander] call FLO_fnc_gtnExecuteIntents;
_phaseMs set ["execution", (_perf get "cycleWorkMs") - _at];
_at = _perf get "cycleWorkMs";
[_commander, FLO_fnc_gtnBuildGoalAgenda, [_commander]] call FLO_fnc_gtnRunCycleStep;
private _agenda = [_commander] call FLO_fnc_gtnAdmitGoalAgenda;
_phaseMs set ["agenda", (_perf get "cycleWorkMs") - _at];
_at = _perf get "cycleWorkMs";
private _playerSupport = [_commander, FLO_fnc_gtnProcessPlayerSupportRequests, [_commander]] call FLO_fnc_gtnRunCycleStep;
[_commander, {
    params ["_cmdr", "_started"];
    _cmdr call ["_manageStaticAANetwork", []];
    private _owners = [_cmdr get "_ownSide"] call FLO_fnc_gtnGetSideClientOwners;
    if (_owners isNotEqualTo [] && {(_cmdr get "_intelDirty") || {_started - (_cmdr get "_lastIntelPublishAt") >= ((_cmdr get "_config") get "intelPublishMinInterval")}}) then {
        private _published = [_cmdr, _owners] call FLO_fnc_gtnPublishCommanderIntel;
        if (_published get "published") then {
            _cmdr set ["_lastIntelPublishAt", _started];
            _cmdr set ["_intelDirty", false];
        };
    };
}, [_commander, _started]] call FLO_fnc_gtnRunCycleStep;
_phaseMs set ["services", (_perf get "cycleWorkMs") - _at];
private _elapsed = (diag_tickTime - _started) * 1000;
private _workMs = _perf get "cycleWorkMs";
private _snapshotMetrics = [];
{ _snapshotMetrics pushBack (_x - (_snapshotBefore select _forEachIndex)) } forEach (_perf get "snapshotTotals");
_perf set ["lastSnapshotMetrics", _snapshotMetrics];
_perf set ["lastCycleMs", _elapsed];
_perf set ["peakCycleMs", (_perf get "peakCycleMs") max _elapsed];
_perf set ["lastCycleWorkMs", _workMs];
_perf set ["lastCyclePeakFrameMs", _perf get "cyclePeakFrameMs"];
_perf set ["lastPhaseMs", _phaseMs];
_perf set ["lastStrategicPhaseMs", _strategicPhases];
_perf set ["lastCycleFrames", diag_frameNo - _startFrame];
_perf set ["lastMetrics", createHashMapFromArray [
    ["cycleIndex", _stats get "cyclesRun"], ["agenda", _agenda], ["execute", _execution],
    ["trackCount", count (_commander get "_tracks")], ["taskedCount", count (_commander get "_gtnTaskedGroups")],
    ["playerSupport", _playerSupport], ["strategicOrderBudget", _commander call ["_getStrategicOrderBudgetMetrics", []]]
]];
if (_workMs >= (_perf get "logThresholdMs")) then {
    _perf set ["slowCycles", (_perf get "slowCycles") + 1];
    ["GTN", 4, format ["[PERF] %1 cycle=%2 wallMs=%3 workMs=%11 peakFrameMs=%12 phases=%4 snapshots=%10 agenda=%5 active=%6 execution=%7 strategic=%8 frames=%9", _commander get "_sideKey", _stats get "cyclesRun", _elapsed, _phaseMs, _agenda, count (_commander get "_intents"), _execution, _strategicPhases, _perf get "lastCycleFrames", _snapshotMetrics, _workMs, _perf get "lastCyclePeakFrameMs"]] call FLO_fnc_log;
};
true
