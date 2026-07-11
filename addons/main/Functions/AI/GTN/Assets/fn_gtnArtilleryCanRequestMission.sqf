/*
 * Function: FLO_fnc_gtnArtilleryCanRequestMission
 * Description:
 *   Checks the shared side, objective, and battery cooldowns used by every
 *   artillery request path.
 *
 * Return Value:
 *   [allowed, denialCode, secondsRemaining]
 */

params [
    ["_manager", nil],
    ["_requestSide", sideUnknown],
    ["_objectiveId", "", [""]],
    ["_groupId", "", [""]]
];

if (isNil "_manager") then {
    throw "Artillery cooldown check requires a manager";
};
if !(_requestSide in [east, west]) exitWith { [false, "INVALID_SIDE", 0] };

private _now = diag_tickTime;
private _sideKey = [_requestSide] call FLO_fnc_sideKey;
private _sideCooldowns = _manager get "sideCooldowns";
private _sideLockedUntil = -1;

if (_sideKey in _sideCooldowns) then {
    _sideLockedUntil = _sideCooldowns get _sideKey;
};
if (_sideLockedUntil > _now) exitWith {
    [false, "SIDE_COOLDOWN", ceil (_sideLockedUntil - _now)]
};
if (_sideLockedUntil >= 0) then {
    _sideCooldowns deleteAt _sideKey;
};

private _objectiveCooldowns = _manager get "objectiveCooldowns";
private _objectiveKey = "";
private _objectiveLockedUntil = -1;
if (_objectiveId != "") then {
    _objectiveKey = format ["%1:%2", _sideKey, _objectiveId];
    if (_objectiveKey in _objectiveCooldowns) then {
        _objectiveLockedUntil = _objectiveCooldowns get _objectiveKey;
    };
};
if (_objectiveLockedUntil > _now) exitWith {
    [false, "OBJECTIVE_COOLDOWN", ceil (_objectiveLockedUntil - _now)]
};
if (_objectiveLockedUntil >= 0) then {
    _objectiveCooldowns deleteAt _objectiveKey;
};

private _batteryCooldowns = _manager get "batteryCooldowns";
private _batteryLockedUntil = -1;
if (_groupId != "") then {
    if (_groupId in _batteryCooldowns) then {
        _batteryLockedUntil = _batteryCooldowns get _groupId;
    };
};
if (_batteryLockedUntil > _now) exitWith {
    [false, "BATTERY_COOLDOWN", ceil (_batteryLockedUntil - _now)]
};
if (_batteryLockedUntil >= 0) then {
    _batteryCooldowns deleteAt _groupId;
};

[true, "", 0]
