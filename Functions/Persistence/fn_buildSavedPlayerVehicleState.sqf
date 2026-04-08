/*
 * Function: FLO_fnc_buildSavedPlayerVehicleState
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the persistent save payload for a player-occupied vehicle that
 *   may not be covered by the normal installation-centric vehicle save.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *
 * Returns:
 *   HASHMAP
 */

params [["_vehicle", objNull, [objNull]]];

private _saveId = _vehicle getVariable ["FLO_SaveID", ""];
if (_saveId isEqualTo "") then {
    _saveId = [] call FLO_fnc_createUUID;
    _vehicle setVariable ["FLO_SaveID", _saveId, true];
};

private _result = createHashMapFromArray [
    ["saveId", _saveId],
    ["type", typeOf _vehicle],
    ["posATL", getPosATL _vehicle],
    ["fuel", fuel _vehicle],
    ["damage", damage _vehicle],
    ["damagedHitpoints", []],
    ["vectorDirAndUp", [vectorDir _vehicle, vectorUp _vehicle]],
    ["locked", locked _vehicle],
    ["engineOn", isEngineOn _vehicle],
    ["hadAICrew", ({ alive _x && {!isPlayer _x} } count (crew _vehicle)) > 0]
];

private _allDamage = getAllHitPointsDamage _vehicle;
if (count _allDamage >= 3) then {
    private _names = _allDamage # 0;
    private _values = _allDamage # 2;
    private _damagedHitpoints = [];
    {
        if ((_values # _forEachIndex) > 0.01) then {
            _damagedHitpoints pushBack [_x, _values # _forEachIndex];
        };
    } forEach _names;
    _result set ["damagedHitpoints", _damagedHitpoints];
};

_result
