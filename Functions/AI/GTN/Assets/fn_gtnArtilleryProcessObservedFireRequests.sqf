/*
 * Function: FLO_fnc_gtnArtilleryProcessObservedFireRequests
 * Author: Frontline Operations Development Group
 * Description:
 *   Processes a batched slice of real AI spotter groups and lets them request
 *   artillery against actually observed enemy groups when the target is safe.
 *
 * Arguments:
 * 0: Artillery Manager <HASHMAP>
 *
 * Return Value:
 * Boolean - True when processing completed
 *
 * Example:
 * [FLO_GTNArtilleryManager] call FLO_fnc_gtnArtilleryProcessObservedFireRequests;
 */

params ["_manager"];

private _spotters = _manager get "observedSpotters";
private _spotterIds = keys _spotters;
private _totalSpotters = count _spotterIds;
if (_totalSpotters == 0) exitWith {
    _manager set ["observedFireCursor", 0];
    true
};

private _batchSize = _manager get "observedFireBatchSize";
if (_batchSize > _totalSpotters) then {
    _batchSize = _totalSpotters;
};

private _cursor = _manager get "observedFireCursor";
if (_cursor >= _totalSpotters) then {
    _cursor = 0;
};

private _groups = FLO_virtualGroups get "_groups";
private _maxPerSide = _manager get "observedFireMaxPerSidePerCycle";
private _requestsBySide = createHashMapFromArray [
    ["EAST", 0],
    ["WEST", 0]
];
private _availableArtilleryBySide = createHashMapFromArray [
    ["EAST", nil],
    ["WEST", nil]
];

private _t0 = diag_tickTime;

for "_step" from 0 to (_batchSize - 1) do {
    private _idx = (_cursor + _step) mod _totalSpotters;
    private _groupId = _spotterIds select _idx;

    if !(_groupId in _groups) then {
        _spotters deleteAt _groupId;
        continue;
    };

    private _gData = _groups get _groupId;
    if !([_manager, _groupId, _gData] call FLO_fnc_gtnArtillerySyncObservedSpotter) then {
        continue;
    };

    if (_manager call ["_isSpotterOnCooldown", [_groupId]]) then { continue };

    private _requestSide = _gData get "side";
    private _sideKey = ([_requestSide] call FLO_fnc_gtnSideContext) get "sideKey";
    if ((_requestsBySide get _sideKey) >= _maxPerSide) then { continue };

    private _availableArtillery = _availableArtilleryBySide get _sideKey;
    if (isNil "_availableArtillery") then {
        _availableArtillery = [_manager, _requestSide] call FLO_fnc_gtnArtilleryGetAvailableGroups;
        _availableArtilleryBySide set [_sideKey, _availableArtillery];
    };
    if (count _availableArtillery == 0) then { continue };

    private _solution = [_manager, _gData] call FLO_fnc_gtnArtilleryEvaluateObservedTarget;
    if (count _solution == 0) then { continue };

    _solution params ["_targetPos", "_targetKey", "_rounds", "_accuracy", "_enemyCount", "_vehicleCount", "_armorCount"];

    if (_manager call ["_requestFireMission", [_targetPos, _rounds, _accuracy, _requestSide, "", "OBSERVED"]]) then {
        _manager call ["_markSpotterCooldown", [_groupId]];
        _manager call ["_markObservedTargetCooldown", [_targetKey]];
        _requestsBySide set [_sideKey, (_requestsBySide get _sideKey) + 1];
        _availableArtilleryBySide set [_sideKey, nil];

        ["GTN Artillery", 3, format [
            "Observed fire mission from %1 at %2 (enemy=%3, vehicles=%4, armor=%5)",
            _groupId,
            _targetPos,
            _enemyCount,
            _vehicleCount,
            _armorCount
        ]] call FLO_fnc_log;
    };
};

private _remainingSpotters = count (keys _spotters);
if (_remainingSpotters > 0) then {
    _manager set ["observedFireCursor", (_cursor + _batchSize) mod _remainingSpotters];
} else {
    _manager set ["observedFireCursor", 0];
};

private _dt = diag_tickTime - _t0;
if (_dt > 0.02) then {
    diag_log format [
        "[FLO][PERF] Observed artillery support processed %1 spotters in %2 ms",
        _batchSize,
        _dt * 1000
    ];
};

true
