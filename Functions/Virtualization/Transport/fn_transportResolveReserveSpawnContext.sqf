/*
 * Function: FLO_fnc_transportResolveReserveSpawnContext
 * Description:
 *   Resolves the active objective set transport reserves should stage from for
 *   a side. Prefers active supply nodes and falls back to the reserve HQ
 *   objective when no active node set is available.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Logistics network <HASHMAP>
 *
 * Return Value:
 *   ARRAY - [spawn objective IDs, reserve objective ID, reserve position]
 */

params [["_side", east, [east]], ["_net", createHashMap, [createHashMap]]];

private _reserveData = [_side] call FLO_fnc_transportResolveReserveObjective;
_reserveData params ["_reserveObjectiveId", "_reservePos"];

if (_reserveObjectiveId isEqualTo "") exitWith { [[], "", []] };

private _activeSupplyNodes = _net get "_activeSupplyNodes";
if ((count (keys _activeSupplyNodes)) == 0) then {
    _activeSupplyNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
};

private _spawnObjectiveIds = (keys _activeSupplyNodes) select {
    ((FLO_Objectives get _x) get "owner") isEqualTo _side
};

if ((count _spawnObjectiveIds) == 0) then {
    _spawnObjectiveIds = [_reserveObjectiveId];
};

[_spawnObjectiveIds, _reserveObjectiveId, _reservePos]
