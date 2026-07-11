/*
 * Function: FLO_fnc_minefieldSerializeField
 * Author: Frontline Operations Development Group
 * Description:
 *   Serializes one tracked minefield into save-safe data.
 *
 * Arguments:
 * 0: Field data <HASHMAP>
 *
 * Return Value:
 * HASHMAP
 */

params [
    ["_field", createHashMap]
];

if (!(_field isEqualType createHashMap)) exitWith { createHashMap };
if ((keys _field) isEqualTo []) exitWith { createHashMap };

private _mineSpecs = [];
{
    if (isNull _x) then { continue };
    if !(mineActive _x) then { continue };

    _mineSpecs pushBack (createHashMapFromArray [
        ["type", _x getVariable ["FLO_MineType", typeOf _x]],
        ["posASL", getPosASL _x]
    ]);
} forEach (_field get "mineObjects");

if (_mineSpecs isEqualTo []) exitWith { createHashMap };

createHashMapFromArray [
    ["id", _field get "id"],
    ["objectiveId", _field get "objectiveId"],
    ["sideKey", _field get "sideKey"],
    ["threatSignature", _field get "threatSignature"],
    ["centerPos", _field get "centerPos"],
    ["anchorPos", _field get "anchorPos"],
    ["facingDir", _field get "facingDir"],
    ["frontageHalfWidth", _field get "frontageHalfWidth"],
    ["packetSummaries", _field get "packetSummaries"],
    ["mineSpecs", _mineSpecs]
]
