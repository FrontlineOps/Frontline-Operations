/*
 * Function: FLO_fnc_sideResourcesSerialize
 * Author: Frontline Operations Development Group
 * Description:
 *   Serializes one side resource object for save/publish use.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *
 * Return Value:
 *   Serialized state <HASHMAP>
 *
 * Example:
 *   private _saveData = [_resourceObj] call FLO_fnc_sideResourcesSerialize;
 */

params ["_resourceObj"];

createHashMapFromArray [
    ["resources", _resourceObj get "_resources"],
    ["lastUpdate", _resourceObj get "_lastUpdate"],
    ["efficiencies", _resourceObj get "_efficiencies"],
    ["sideKey", _resourceObj get "_sideKey"]
]
