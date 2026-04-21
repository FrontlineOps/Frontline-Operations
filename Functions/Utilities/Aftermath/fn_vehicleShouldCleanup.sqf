/*
 * Function: FLO_fnc_vehicleShouldCleanup
 * Author: Frontline Operations Development Group
 * Description:
 *   Determines whether an empty vehicle should be treated as an abandoned
 *   derelict and become eligible for FLO-owned live vehicle cleanup.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Tracked vehicle keys <HASHMAP>
 * 2: Player positions <ARRAY>
 * 3: Installation positions <ARRAY>
 * 4: Player safe radius <NUMBER>
 * 5: Installation safe radius <NUMBER>
 *
 * Return Value:
 * BOOL - True when the vehicle is an eligible cleanup candidate
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_trackedVehicleKeys", createHashMap, [createHashMap]],
    ["_playerPositions", [], [[]]],
    ["_installationPositions", [], [[]]],
    ["_playerSafeRadius", 0, [0]],
    ["_installationSafeRadius", 0, [0]]
];

if (isNull _vehicle || {!alive _vehicle}) exitWith { false };
if !(_vehicle isKindOf "LandVehicle" || {_vehicle isKindOf "Air"} || {_vehicle isKindOf "Ship"}) exitWith { false };
if (_vehicle isKindOf "StaticWeapon") exitWith { false };
if ((crew _vehicle) isNotEqualTo []) exitWith { false };
if (_vehicle getVariable ["FLO_NoVehicleCleanup", false]) exitWith { false };
if (_vehicle getVariable ["IDS_Logistics_isPlacedEntity", false]) exitWith { false };

if (_vehicle getVariable ["FLO_MobileRespawnVehicle", false]) exitWith { false };

private _vehicleKey = str _vehicle;
if !(isNil { _trackedVehicleKeys get _vehicleKey }) exitWith { false };

private _vehiclePos = getPosATL _vehicle;
if ((_playerPositions findIf { _vehiclePos distance2D _x <= _playerSafeRadius }) > -1) exitWith { false };

if ((_installationPositions findIf { _vehiclePos distance2D _x <= _installationSafeRadius }) > -1) exitWith { false };
if ([_vehiclePos] call FLO_fnc_aftermathIsPositionInHotObjective) exitWith { false };

private _combatVehicle = _vehicle isKindOf "Tank"
    || {_vehicle isKindOf "Wheeled_APC_F"}
    || {_vehicle isKindOf "Tracked_APC_F"}
    || {_vehicle isKindOf "Air"}
    || {count (allTurrets [_vehicle, false]) > 0};

private _heavilyDamaged = damage _vehicle >= 0.85;
private _immobile = !canMove _vehicle;
private _combatDisabled = _combatVehicle && {!canFire _vehicle};

_heavilyDamaged || {_immobile} || {_combatDisabled}
