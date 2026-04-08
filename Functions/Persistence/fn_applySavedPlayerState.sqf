/*
 * Function: FLO_fnc_applySavedPlayerState
 * Author: Frontline Operations Development Group
 * Description:
 *   Client-side player restore for loaded campaigns.
 *
 * Arguments:
 *   0: Saved player state <HASHMAP>
 *
 * Returns:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [["_state", createHashMap, [createHashMap]]];

if (missionNamespace getVariable ["FLO_PlayerStateRestored", false]) exitWith { true };

waitUntil { !isNull player };
waitUntil { player == player };

private _vehicleSaveId = _state get "vehicleSaveId";
private _targetVehicle = objNull;
private _restoredIntoVehicle = false;

if (_vehicleSaveId != "") then {
    private _vehicleLookupDeadline = diag_tickTime + 15;

    waitUntil {
        {
            if ((_x getVariable ["FLO_SaveID", ""]) isEqualTo _vehicleSaveId) exitWith {
                _targetVehicle = _x;
            };
        } forEach vehicles;

        !isNull _targetVehicle || {diag_tickTime > _vehicleLookupDeadline}
    };
};

player allowDamage false;
player setUnitLoadout (_state get "loadout");

if (!isNull _targetVehicle) then {
    private _vehicleRole = _state get "vehicleRole";

    if (count _vehicleRole > 0) then {
        switch (_vehicleRole select 0) do {
            case "Driver": { player moveInDriver _targetVehicle; };
            case "Commander": { player moveInCommander _targetVehicle; };
            case "Gunner": { player moveInGunner _targetVehicle; };
            case "Turret": { player moveInTurret [_targetVehicle, _vehicleRole select 1]; };
            case "Cargo": {
                if (count _vehicleRole > 1 && {(_vehicleRole select 1) isEqualType 0}) then {
                    player moveInCargo [_targetVehicle, _vehicleRole select 1];
                } else {
                    player moveInCargo _targetVehicle;
                };
            };
            default {
                player moveInAny _targetVehicle;
            };
        };
        };
    } else {
        player moveInAny _targetVehicle;
    };

    _restoredIntoVehicle = vehicle player == _targetVehicle;
};

if (!_restoredIntoVehicle) then {
    player setPosASL (_state get "positionASL");
    player setDir (_state get "direction");
};

player setDamage (_state get "damage");

private _savedUnitPos = _state get "unitPos";
if (_savedUnitPos in ["UP", "MIDDLE", "DOWN", "AUTO"]) then {
    player setUnitPos _savedUnitPos;
};

private _savedWeapon = _state get "currentWeapon";
if (_savedWeapon != "") then {
    player selectWeapon _savedWeapon;
};

player allowDamage true;
FLO_PlayerStateRestored = true;

["PERSIST", 3, format ["Applied saved player state for %1", name player]] call FLO_fnc_log;
true
