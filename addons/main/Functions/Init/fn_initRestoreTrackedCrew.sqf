/*
 * Function: FLO_fnc_initRestoreTrackedCrew
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores AI crew for save-restored tracked air-defense support assets when
 *   the saved record allows crew restoration.
 *
 * Arguments:
 * 0: Entity <OBJECT>
 * 1: Vehicle class <STRING>
 * 2: Saved attributes <HASHMAP>
 * 3: Tracked crew type map <HASHMAP>
 *
 * Returns: None
 */
params ["_entity", "_type", "_attr", "_trackedCrewTypes"];

if !(_type in _trackedCrewTypes) exitWith {};

private _restoreCrew = if ("hadAICrew" in _attr) then { _attr get "hadAICrew" } else { true };
if (!_restoreCrew) exitWith {};

if (getText (configFile >> "CfgVehicles" >> _type >> "crew") != "") then {
    createVehicleCrew _entity;
};
