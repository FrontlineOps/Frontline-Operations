/*
 * Author: Frontline Operations
 * Description:
 * Places a vehicle at a reference position and populates it with a crew.
 * 
 * Arguments:
 * 0: _vehicle (Object) - The vehicle to place
 * 1: _reference (Object) - The reference object (e.g., a helper sphere) used for positioning
 *
 * Return Value:
 * None
 */

params ["_vehicle", "_reference"];

detach _vehicle;
_vehicle setVehiclePosition [getPos _reference, [], 0, "CAN_COLLIDE"];
_vehicle enableSimulation true;
CursorTracker = false;
deleteVehicle _reference;
_vehicle enableSimulation true;
_vehicle allowDamage true;

private _group = createVehicleCrew _vehicle;
if (isNull _group || {(units _group) isEqualTo []}) exitWith {
    ["VEHICLE", 1, format ["Failed to create native crew for placed vehicle %1", typeOf _vehicle]] call FLO_fnc_log;
};

if (hasInterface && {!isNull player}) then {
    player hcSetGroup [_group];
};
