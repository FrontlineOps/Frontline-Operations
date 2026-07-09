/*
 * Function: FLO_fnc_activateCivilian
 * Author: Frontline Operations Development Group
 * Description:
 *   Activates civilian virtual groups with role-aware ambient behavior.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group data <HASHMAP>
 * 2: Position <ARRAY>
 *
 * Return Value:
 * GROUP - Activated real group
 */

params ["_groupId", "_groupData", "_position"];

if (!isServer) exitWith { grpNull };

private _groupType = _groupData get "groupType";
private _unitCount = _groupData get "unitCount";
private _spawnClass = _groupData get "spawnClass";
private _civilianRole = _groupData get "civilianRole";
private _civilianObjective = _groupData get "civilianObjective";
private _civilianRoutineState = _groupData get "civilianRoutineState";
private _anchorPos = _groupData get "civilianAnchorPos";
private _routineAnchorPos = _groupData get "civilianRoutineAnchorPos";
private _realGroup = createGroup [civilian, true];
private _spawnedUnits = [];

switch (_groupType) do {
    case "civilian";
    case "civ_pedestrian";
    case "civ_building": {
        private _spawnBasis = if (_groupType == "civ_building") then {
            +_anchorPos
        } else {
            if ((_position distance2D _routineAnchorPos) > 80) then {
                +_routineAnchorPos
            } else {
                +_position
            }
        };

        for "_i" from 1 to _unitCount do {
            private _unitType = if (_spawnClass != "") then { _spawnClass } else { selectRandom CivMenArray };
            private _spawnPos = if (_groupType == "civ_building") then {
                +_anchorPos
            } else {
                [_spawnBasis, 3, 12, 1, 0, 0.5, 0] call BIS_fnc_findSafePos
            };

            private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
            _spawnedUnits pushBack _unit;
        };
    };

    case "civilianVehicle";
    case "civ_car": {
        private _vehicleType = selectRandom CivVehArray;
        private _spawnPos = if ((_position distance2D _routineAnchorPos) > 80) then {
            +_routineAnchorPos
        } else {
            +_position
        };
        private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "CAN_COLLIDE"];
        _vehicle setPos [_spawnPos select 0, _spawnPos select 1, 0];
        _vehicle setVectorUp [0, 0, 1];
        _vehicle setDir (_groupData getOrDefault ["direction", random 360]);
        _vehicle lock 0;
        _vehicle setFuel 1;
        _vehicle setDamage 0;

        private _driverType = if (_spawnClass != "") then { _spawnClass } else { selectRandom CivMenArray };
        private _driver = _realGroup createUnit [_driverType, [0, 0, 0], [], 0, "NONE"];
        _driver moveInDriver _vehicle;
        _spawnedUnits pushBack _driver;

        private _cargoPositions = fullCrew [_vehicle, "cargo", true];
        private _passengerCount = (count _cargoPositions) min (floor random 3);
        for "_i" from 0 to (_passengerCount - 1) do {
            private _passengerType = if (_spawnClass != "") then { _spawnClass } else { selectRandom CivMenArray };
            private _passenger = _realGroup createUnit [_passengerType, [0, 0, 0], [], 0, "NONE"];
            _passenger moveInCargo _vehicle;
            _spawnedUnits pushBack _passenger;
        };
    };

    default {
        deleteGroup _realGroup;
        _realGroup = grpNull;
    };
};

if (isNull _realGroup) exitWith { grpNull };

{
    _x setVariable ["FLO_VirtualGroupId", _groupId, true];
    _x setVariable ["FLO_CivilianObjective", _civilianObjective, true];
    _x setVariable ["FLO_CivilianRole", _civilianRole, true];
    _x setVariable ["FLO_CivilianRoutineState", _civilianRoutineState, true];
    _x setVariable ["FLO_CivilianLastIntelAt", _groupData get "civilianLastIntelAt", true];

    _x disableAI "AUTOCOMBAT";
    _x allowFleeing 1;
    _x setBehaviour (["CARELESS", "SAFE"] select (_civilianRole in ["watcher", "resident"]));
    _x setSpeedMode (["NORMAL", "LIMITED"] select (_civilianRole in ["worker", "wanderer", "driver"]));

    if (_groupType == "civ_building") then {
        _x disableAI "PATH";
        _x disableAI "MOVE";
        doStop _x;
    };
} forEach _spawnedUnits;

_realGroup setVariable ["FLO_VirtualGroupId", _groupId, true];
_groupData set ["realGroup", _realGroup];
_groupData set ["isActive", true];

[_spawnedUnits] call FLO_fnc_civilianActions;

_realGroup
