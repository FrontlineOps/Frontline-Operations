/*
 * Function: FLO_fnc_buildSavedPlayerState
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the persistent save payload for a human player.
 *
 * Arguments:
 *   0: Unit <OBJECT>
 *
 * Returns:
 *   HASHMAP
 */

params [["_unit", objNull, [objNull]]];

private _vehicle = vehicle _unit;
private _vehicleSaveId = "";
private _vehicleRole = [];

if (_vehicle != _unit) then {
    _vehicleSaveId = _vehicle getVariable ["FLO_SaveID", ""];
    if (_vehicleSaveId isEqualTo "") then {
        _vehicleSaveId = [] call FLO_fnc_createUUID;
        _vehicle setVariable ["FLO_SaveID", _vehicleSaveId, true];
    };
    _vehicleRole = assignedVehicleRole _unit;
};

createHashMapFromArray [
    ["uid", getPlayerUID _unit],
    ["name", name _unit],
    ["sideKey", ([(side group _unit)] call FLO_fnc_gtnSideContext) get "sideKey"],
    ["positionASL", getPosASL _unit],
    ["direction", getDir _unit],
    ["vectorDir", vectorDir _unit],
    ["vectorUp", vectorUp _unit],
    ["damage", damage _unit],
    ["lifeState", lifeState _unit],
    ["unitPos", unitPos _unit],
    ["currentWeapon", currentWeapon _unit],
    ["loadout", getUnitLoadout _unit],
    ["vehicleSaveId", _vehicleSaveId],
    ["vehicleRole", _vehicleRole]
]
