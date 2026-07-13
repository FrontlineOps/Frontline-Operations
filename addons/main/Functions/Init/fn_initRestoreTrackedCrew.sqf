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
    private _crewGroup = createVehicleCrew _entity;
    if (isNull _crewGroup || {(units _crewGroup) isEqualTo []}) exitWith {
        ["SAVE", 1, format ["Failed to restore crew for tracked player asset %1", _type]] call FLO_fnc_log;
    };

    private _sideCorrectedGroup = [_crewGroup, west] call FLO_fnc_setSide;
    if (isNull _sideCorrectedGroup) then {
        ["SAVE", 1, format ["Failed to commit restored tracked player asset %1 crew to WEST", _type]] call FLO_fnc_log;
        deleteVehicleCrew _entity;
    };
};
