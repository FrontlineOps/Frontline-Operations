/*
 * Function: FLO_fnc_virtualizationParkIdleHelicopter
 * Author: Frontline Operations Development Group
 * Description:
 *   Parks active idle helicopters on the ground with engines off so nearby
 *   reserve or inactive air assets do not hover in place.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Real Group <GROUP>
 *
 * Return Value:
 * BOOL - True when the group is eligible for idle helicopter parking
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]]
];

if (!isServer) exitWith { false };
if (_groupId == "") exitWith { false };

if (isNull _realGroup) then {
    _realGroup = _groupData get "realGroup";
};
if (isNull _realGroup) exitWith { false };

private _groupType = _groupData get "groupType";
private _vehicleType = _groupData get "vehicleType";
if (_groupType != "helicopter" && { _vehicleType == "" || { !(_vehicleType isKindOf "Helicopter") } }) exitWith { false };

private _helicopters = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select {
    !isNull _x && { alive _x } && { _x isKindOf "Helicopter" }
};
if (_helicopters isEqualTo []) exitWith { false };

if ((_groupData get "missionLock") != "") exitWith { false };
if ((_groupData get "replacementState") != "") exitWith { false };
if ((_groupData get "attachedTo") != "") exitWith { false };
if ((_groupData get "mountedIn") != "") exitWith { false };
if (([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) isNotEqualTo []) exitWith { false };

private _isReserveTransport = _groupData get "transportRole";
private _state = _groupData get "state";
private _executionState = _groupData get "executionState";
private _waypoints = _groupData get "waypoints";
private _position = _groupData get "position";
private _alreadyParked = _groupData get "idleHelicopterParked";
private _basePos = if (_isReserveTransport) then {
    +(_groupData get "spawnPosition")
} else {
    +_position
};
private _clearRoute = false;
private _canPark = false;

if !([_basePos] call FLO_fnc_virtualizationIsValidPosition) then {
    _basePos = getPosATL (_helicopters select 0);
};
_basePos set [2, 0];

if (_waypoints isEqualTo []) then {
    _canPark = (_state == "idle") || { _isReserveTransport && { _executionState == "" } };
} else {
    if (_isReserveTransport && { _executionState == "RTB" }) then {
        private _targetWp = _waypoints select -1;
        private _targetPos = +(_targetWp select 0);
        private _completionRadius = (_targetWp param [6, 75]) max 75;
        private _atReserve = (_position distance2D _targetPos) <= _completionRadius || {
            (_position distance2D _basePos) <= _completionRadius
        };

        if (_atReserve) then {
            _basePos = _targetPos;
            _basePos set [2, 0];
            _clearRoute = true;
            _canPark = true;
        };
    };
};

if (!_canPark) exitWith { false };
if (_alreadyParked && {!_clearRoute}) exitWith { true };

if (_clearRoute) then {
    [_groupData] call FLO_fnc_virtualizationClearPathRequest;
    [_groupData] call FLO_fnc_virtualizationClearExecutionState;
    _groupData set ["waypoints", []];
    _groupData set ["currentWaypointIndex", 0];
    _groupData set ["virtualMoveCarryMeters", 0];
};

[_realGroup] call CBA_fnc_clearWaypoints;

private _needsParking = (_helicopters findIf {
    !(isTouchingGround _x) ||
    { ((getPosATL _x) select 2) > 1.5 } ||
    { (vectorMagnitude (velocity _x)) > 1 } ||
    { isEngineOn _x }
}) != -1;

[_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
[_groupId, getPosATL (_helicopters select 0)] call FLO_fnc_virtualizationUpdateGroupPosition;
_groupData set ["idleHelicopterParked", true];

if (!_needsParking) exitWith { true };

private _parkedVehicles = [];
{
    private _parkPos = [_basePos, typeOf _x, _forEachIndex, 600] call FLO_fnc_virtualizationResolveIdleHelicopterParkPos;
    private _heliDir = getDir _x;
    private _heliFuel = fuel _x;
    private _heliDamage = damage _x;
    private _heliType = typeOf _x;
    private _crewUnits = (crew _x) select { alive _x };
    private _crewRoles = _crewUnits apply {
        [_x, assignedVehicleRole _x]
    };

    {
        private _unit = _x select 0;
        unassignVehicle _unit;
        moveOut _unit;
        _unit setPosATL _parkPos;
    } forEach _crewRoles;

    deleteVehicle _x;

    private _parkedHeli = createVehicle [_heliType, _parkPos, [], 0, "NONE"];
    _parkedHeli setDir _heliDir;
    _parkedHeli setFuel _heliFuel;
    _parkedHeli setDamage _heliDamage;
    _parkedHeli setVectorUp [0, 0, 1];
    _parkedHeli setVelocity [0, 0, 0];
    _parkedHeli engineOn false;
    _parkedVehicles pushBack _parkedHeli;

    {
        private _unit = _x select 0;
        private _role = _x select 1;
        private _roleType = toUpper (_role param [0, ""]);

        switch (_roleType) do {
            case "DRIVER": {
                _unit moveInDriver _parkedHeli;
            };
            case "TURRET": {
                _unit moveInTurret [_parkedHeli, _role param [1, []]];
            };
            case "CARGO": {
                _unit moveInCargo _parkedHeli;
            };
            default {
                _unit moveInAny _parkedHeli;
            };
        };
    } forEach _crewRoles;

    _parkedHeli setVelocity [0, 0, 0];
    _parkedHeli engineOn false;
} forEach _helicopters;

if (_parkedVehicles isNotEqualTo []) then {
    [_groupData, [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles] call FLO_fnc_virtualizationSetRealVehicles;
    [_groupId, getPosATL (_parkedVehicles select 0)] call FLO_fnc_virtualizationUpdateGroupPosition;
};

true
