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
// Assuming CursorTracker is a global variable used in the caller context.
CursorTracker = false;
deleteVehicle _reference;
_vehicle enableSimulation true;
_vehicle allowDamage true;

// Create crew
// Create crew - Professional crew resolving
private _crewType = if (!isNil "F_Crew") then { F_Crew } else { [west, _vehicleConfig] call BIS_fnc_selectCrew };
private _crewFull = createVehicleCrew _vehicle;
private _crewSelCnt = count (units _crewFull) - 1;
deleteVehicleCrew _vehicle;

private _group = createGroup West;
for "_x" from 0 to _crewSelCnt do {
    private _unit = _group createUnit [_crewType, [0,0,0], [], 0, "CAN_COLLIDE"];
};

{_x moveInAny _vehicle} forEach units _group;

// Add to high command
if (!isNil "TheCommander") then {
    TheCommander hcSetGroup [_group];
} else {
    player hcSetGroup [_group];
};
