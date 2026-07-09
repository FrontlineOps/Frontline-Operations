/*
 * Function: FLO_fnc_gtnSideContext
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates a normalized side context for dual-commander GTN logic.
 *
 * Arguments:
 *   0: Own side <SIDE> - Defaults to east
 *
 * Returns:
 *   HashMap side context
 *
 * Example:
 *   private _ctx = [east] call FLO_fnc_gtnSideContext;
 */

params [["_ownSide", east]];

if !(_ownSide in [east, west]) exitWith {
    ["GTN", 1, format ["Invalid side passed to gtnSideContext: %1", _ownSide]] call FLO_fnc_log;
    nil
};

private _enemySide = [east, west] select (_ownSide isEqualTo east);
private _sideKey = ["WEST", "EAST"] select (_ownSide isEqualTo east);
private _enemyKey = ["WEST", "EAST"] select (_enemySide isEqualTo east);

createHashMapFromArray [
    ["ownSide", _ownSide],
    ["enemySide", _enemySide],
    ["sideKey", _sideKey],
    ["enemyKey", _enemyKey],
    ["resourceKey", _sideKey],
    ["factionCatalogKey", _sideKey]
]
