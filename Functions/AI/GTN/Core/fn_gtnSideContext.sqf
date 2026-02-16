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

private _enemySide = if (_ownSide isEqualTo east) then { west } else { east };
private _sideKey = if (_ownSide isEqualTo east) then { "EAST" } else { "WEST" };
private _enemyKey = if (_enemySide isEqualTo east) then { "EAST" } else { "WEST" };

createHashMapFromArray [
    ["ownSide", _ownSide],
    ["enemySide", _enemySide],
    ["sideKey", _sideKey],
    ["enemyKey", _enemyKey],
    ["resourceKey", _sideKey],
    ["factionCatalogKey", _sideKey]
]
