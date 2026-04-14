/*
 * Function: FLO_fnc_logisticsNetworkRefreshManagedSide
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves the logistics network's managed side from its explicit context or
 *   the current active player side.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   None
 */

params ["_net"];

private _context = _net get "_sideContext";
if (_context in [east, west]) exitWith {
    [_net, _context] call FLO_fnc_logisticsNetworkSetManagedSide;
};

private _playerSide = FLO_ActivePlayerSide;
private _managedSide = if (_playerSide isEqualTo east) then { west } else { east };
[_net, _managedSide] call FLO_fnc_logisticsNetworkSetManagedSide;
