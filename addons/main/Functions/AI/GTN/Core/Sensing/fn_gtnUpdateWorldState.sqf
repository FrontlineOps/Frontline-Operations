#pragma hemtt ignore_variables ["_self"]
/* _update implementation, bound directly to its GTN owner.
 * Native HashMapObject method dispatch supplies _self and the original arguments.
 */
private _now = diag_tickTime;
private _lastUpdate = _self get "_lastUpdate";
private _interval = _self get "_updateInterval";
private _lastSupportAssetsSense = _self get "_lastSupportAssetsSense";
private _supportAssetSenseInterval = _self get "_supportAssetSenseInterval";
private _lastEnemyIntelSense = _self get "_lastEnemyIntelSense";
private _enemyIntelSenseInterval = _self get "_enemyIntelSenseInterval";
private _perf = _self get "_perf";

// Throttle updates
if (_now - _lastUpdate < _interval) exitWith { false };

private _phaseMs = createHashMapFromArray [
    ["objectives", 0],
    ["forces", 0],
    ["supportAssets", 0],
    ["enemyIntel", 0],
    ["tacticalSituation", 0]
];
private _meta = createHashMapFromArray [
    ["objectiveCount", 0],
    ["availableGroups", 0],
    ["contactCount", 0],
    ["combatContactCount", 0],
    ["concentrationCount", 0],
    ["knownGroupCount", 0],
    ["knownGroupObjectiveCount", 0],
    ["supportSenseRan", false],
    ["enemyIntelSenseRan", false]
];
private _cycleStart = diag_tickTime;

// Each sensor publishes its own state atomically; suspend only between sensors.
private _commander = _self get "_commander";
private _cyclePerf = _commander get "_perf";
private _sensorStep = {
    params ["_code", "_arguments", "_name"];
    private _before = _cyclePerf get "cycleWorkMs";
    [_commander, _code, _arguments] call FLO_fnc_gtnRunCycleStep;
    _phaseMs set [_name, (_cyclePerf get "cycleWorkMs") - _before];
};
[{ params ["_world"]; _world call ["_senseObjectives", [true]] }, [_self], "objectives"] call _sensorStep;
[{ params ["_world"]; _world call ["_senseForces", []] }, [_self], "forces"] call _sensorStep;
if (_lastSupportAssetsSense < 0 || {_now - _lastSupportAssetsSense >= _supportAssetSenseInterval}) then {
    [{ params ["_world"]; _world call ["_senseSupportAssets", []] }, [_self], "supportAssets"] call _sensorStep;
    _meta set ["supportSenseRan", true];
    _self set ["_lastSupportAssetsSense", _now];
};
if (_lastEnemyIntelSense < 0 || {_now - _lastEnemyIntelSense >= _enemyIntelSenseInterval}) then {
    [{ params ["_world"]; _world call ["_senseEnemyIntel", []] }, [_self], "enemyIntel"] call _sensorStep;
    _meta set ["enemyIntelSenseRan", true];
    _self set ["_lastEnemyIntelSense", _now];
};
[FLO_fnc_gtnSenseVirtualScouts, [_self], "scouts"] call _sensorStep;
[FLO_fnc_gtnApplyObjectiveObservations, [_self], "objectiveIntel"] call _sensorStep;
[{ params ["_world"]; _world call ["_senseTacticalSituation", []] }, [_self], "tacticalSituation"] call _sensorStep;

_self set ["_lastUpdate", _now];

_meta set ["objectiveCount", count (keys (_self get "_objectives"))];
_meta set ["availableGroups", ((_self get "_ownForces") get "availableGroups")];
_meta set ["contactCount", count ((_self get "_enemyIntel") get "contactReports")];
_meta set ["combatContactCount", _self get "_lastCombatIntelAdded"];
_meta set ["concentrationCount", count ((_self get "_enemyIntel") get "concentrations")];
private _knownGroupPicture = (_self get "_enemyIntel") get "knownGroupPicture";
_meta set ["knownGroupCount", _knownGroupPicture get "groupCount"];
_meta set ["knownGroupObjectiveCount", _knownGroupPicture get "objectiveCount"];

private _dtMs = (diag_tickTime - _cycleStart) * 1000;
_perf set ["lastUpdateMs", _dtMs];
_perf set ["lastPhaseMs", _phaseMs];
_perf set ["lastMeta", _meta];
_perf set ["lastRanAt", _now];
if (_dtMs > (_perf get "peakUpdateMs")) then {
    _perf set ["peakUpdateMs", _dtMs];
};
if (_dtMs > 10) then {
    _perf set ["slowUpdates", (_perf get "slowUpdates") + 1];
};

["GTN", 4, "World state updated"] call FLO_fnc_log;
true
