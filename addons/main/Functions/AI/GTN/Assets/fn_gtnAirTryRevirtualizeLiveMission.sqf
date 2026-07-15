/* Hands an unobserved physical air mission back to virtual ownership. */
params [
    ["_aircraft", objNull, [objNull]],
    ["_groupId", "", [""]],
    ["_missionType", "", [""]],
    ["_targetPos", [], [[]]],
    ["_remainingSeconds", 0, [0]],
    ["_noPlayerSince", -1, [0]]
];

if (isNull _aircraft || {!alive _aircraft}) exitWith { [false, _noPlayerSince] };
if (_groupId == "" || {_missionType == ""} || {count _targetPos < 2}) then {
    ["GTN Air Asset Manager", 1, format [
        "Live air revirtualization received invalid mission identity group=%1 type=%2 target=%3",
        _groupId,
        _missionType,
        _targetPos
    ]] call FLO_fnc_log;
    throw "Live air revirtualization requires group, mission type, and target";
};

private _manager = call FLO_fnc_gtnAirAssetManager;
private _aircraftAreaLive = _manager call ["_isLiveArea", [getPosATL _aircraft]];
private _targetAreaLive = _manager call ["_isLiveArea", [_targetPos]];
if (_aircraftAreaLive || {_targetAreaLive}) exitWith { [false, -1] };

private _graceSeconds = 60;
if (_noPlayerSince < 0) exitWith { [false, diag_tickTime] };
if ((diag_tickTime - _noPlayerSince) < _graceSeconds) exitWith { [false, _noPlayerSince] };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _missions = _manager get "missions";
if !(_groupId in _groups && {_groupId in _missions}) then {
    ["GTN Air Asset Manager", 1, format [
        "Live air revirtualization lost required ownership group=%1 registry=%2 mission=%3",
        _groupId,
        _groupId in _groups,
        _groupId in _missions
    ]] call FLO_fnc_log;
    throw format ["Live air mission %1 lost required ownership", _groupId];
};

private _groupData = _groups get _groupId;
private _missionRecord = _missions get _groupId;
private _mode = _missionRecord get "mode";
if (_mode != "REAL" || {!(_groupData get "isActive")}) then {
    ["GTN Air Asset Manager", 1, format [
        "Live air revirtualization found invalid state group=%1 mode=%2 active=%3",
        _groupId,
        _mode,
        _groupData get "isActive"
    ]] call FLO_fnc_log;
    throw format ["Live air mission %1 is not an active REAL mission", _groupId];
};

private _remaining = _remainingSeconds max 0;
if !([_groupId, false] call FLO_fnc_gtnAirParkCombatGroupOffMap) then {
    ["GTN Air Asset Manager", 1, format [
        "Live air revirtualization could not park group=%1 type=%2",
        _groupId,
        _missionType
    ]] call FLO_fnc_log;
    throw format ["Live air mission %1 could not transition to virtual ownership", _groupId];
};

_missionRecord set ["mode", "VIRTUAL"];
_missions set [_groupId, _missionRecord];
_manager call ["_scheduleVirtualMissionRelease", [_groupId, _remaining]];

["GTN Air Asset Manager", 3, format [
    "Revirtualized live %1 mission group=%2 remaining=%3s after %4s without nearby players",
    _missionType,
    _groupId,
    round _remaining,
    round (diag_tickTime - _noPlayerSince)
]] call FLO_fnc_log;

[true, _noPlayerSince]
