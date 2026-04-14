/*
 * Function: FLO_fnc_gtnProcessCounterBatteryRequests
 * Author: Frontline Operations Development Group
 * Description:
 *   Converts sufficiently exposed enemy artillery batteries into
 *   counter-battery fire missions for the opposite side.
 *
 * Arguments:
 *   0: Artillery Manager <HASHMAP>
 *
 * Return Value:
 *   BOOL
 */

params [["_manager", nil]];

if (isNil "_manager" || {isNil "FLO_virtualGroups"}) exitWith { false };

private _reports = _manager get "counterBatteryReports";
private _cooldowns = _manager get "counterBatteryCooldowns";
private _groups = FLO_virtualGroups get "_groups";
private _windowSeconds = _manager get "counterBatteryWindowSeconds";
private _threshold = _manager get "counterBatteryExposureThreshold";
private _minMissions = _manager get "counterBatteryMinMissionCount";
private _cooldownSeconds = _manager get "counterBatteryCooldownSeconds";
private _maxPerSide = _manager get "counterBatteryMaxPerSidePerCycle";
private _now = diag_tickTime;

private _bestBySide = createHashMapFromArray [
    ["EAST", []],
    ["WEST", []]
];
private _availableArtilleryBySide = createHashMapFromArray [
    ["EAST", nil],
    ["WEST", nil]
];
private _requestsBySide = createHashMapFromArray [
    ["EAST", 0],
    ["WEST", 0]
];

{
    private _reportKey = _x;
    private _report = _y;

    if ((_now - (_report get "lastSeen")) > _windowSeconds) then {
        _reports deleteAt _reportKey;
        continue;
    };

    private _requestSide = _report get "requestSide";
    if !(_requestSide in [east, west]) then {
        _reports deleteAt _reportKey;
        continue;
    };

    if (_manager call ["_isCooldownActive", [_cooldowns, _reportKey]]) then { continue };
    if ((_report get "missionCount") < _minMissions) then { continue };
    if ((_report get "exposure") < _threshold) then { continue };

    private _enemyGroupId = _report get "enemyGroupId";
    if !(_enemyGroupId in _groups) then {
        _reports deleteAt _reportKey;
        continue;
    };

    private _enemyGroupData = _groups get _enemyGroupId;
    if ((_enemyGroupData get "unitCount") <= 0 || {(_enemyGroupData get "groupType") != "artillery"}) then {
        _reports deleteAt _reportKey;
        continue;
    };

    private _actualPos = _enemyGroupData get "position";
    _report set ["sourcePos", _actualPos];
    _reports set [_reportKey, _report];

    private _exposure = _report get "exposure";
    private _precision = (260 - ((_exposure - _threshold) * 25)) max 90;
    private _targetPos = [_actualPos, _reportKey, _precision] call FLO_fnc_gtnApproximateCommanderMarkerPosition;
    private _accuracy = (_precision * 0.8) max 75;
    private _rounds = if ((_report get "missionCount") >= 3 || {_exposure >= (_threshold + 3)}) then { 8 } else { 6 };
    private _score = (_exposure * 100) + ((_report get "missionCount") * 60) - ((_now - (_report get "lastSeen")) * 0.8);
    private _sideKey = ([_requestSide] call FLO_fnc_gtnSideContext) get "sideKey";
    private _currentBest = _bestBySide get _sideKey;

    if (count _currentBest == 0 || {_score > (_currentBest select 0)}) then {
        _bestBySide set [_sideKey, [_score, _reportKey, _targetPos, _rounds, _accuracy, _enemyGroupId]];
    };
} forEach _reports;

{
    private _side = _x;
    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    private _selection = _bestBySide get _sideKey;

    if (count _selection == 0) then { continue };
    if ((_requestsBySide get _sideKey) >= _maxPerSide) then { continue };

    private _availableArtillery = _availableArtilleryBySide get _sideKey;
    if (isNil "_availableArtillery") then {
        _availableArtillery = [_manager, _side] call FLO_fnc_gtnArtilleryGetAvailableGroups;
        _availableArtilleryBySide set [_sideKey, _availableArtillery];
    };
    if (count _availableArtillery == 0) then { continue };

    _selection params ["_score", "_reportKey", "_targetPos", "_rounds", "_accuracy", "_enemyGroupId"];

    if (_manager call ["_requestFireMission", [_targetPos, _rounds, _accuracy, _side, "", "COUNTER_BATTERY"]]) then {
        _cooldowns set [_reportKey, _now + _cooldownSeconds];
        _reports deleteAt _reportKey;
        _requestsBySide set [_sideKey, (_requestsBySide get _sideKey) + 1];

        ["GTN Artillery", 3, format [
            "Counter-battery mission requested by %1 against %2 at %3 (score=%4, rounds=%5, accuracy=%6)",
            _sideKey,
            _enemyGroupId,
            _targetPos,
            _score,
            _rounds,
            _accuracy
        ]] call FLO_fnc_log;
    };
} forEach [east, west];

true
