/*
 * Function: FLO_fnc_transportResolveReserveSpawnContext
 * Description:
 *   Resolves the objective set transport reserves should stage from for a side.
 *   Runtime replenishment uses active supply nodes. Initial BLUFOR seeding can
 *   opt into all owned starting objectives so reserve carriers do not stack on
 *   the HQ before the supply network has promoted forward nodes.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Logistics network <HASHMAP>
 *   2: Include owned objectives <BOOL> - Default false
 *
 * Return Value:
 *   ARRAY - [spawn objective IDs, reserve objective ID, reserve position]
 */

params [
    ["_side", east, [east]],
    ["_net", createHashMap, [createHashMap]],
    ["_includeOwnedObjectives", false, [false]]
];

private _reserveData = [_side] call FLO_fnc_transportResolveReserveObjective;
_reserveData params ["_reserveObjectiveId", "_reservePos"];

if (_reserveObjectiveId isEqualTo "") exitWith { [[], "", []] };

private _activeSupplyNodes = _net get "_activeSupplyNodes";
if ((count (keys _activeSupplyNodes)) == 0) then {
    _activeSupplyNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
};

private _spawnObjectiveIds = if (_includeOwnedObjectives) then {
    if (_net get "_objectiveSideIndexDirty") then {
        [_net] call FLO_fnc_logisticsNetworkRefreshObjectiveSideIndex;
        _net set ["_objectiveSideIndexDirty", false];
    };
    +(_net get "_managedObjectiveIds")
} else {
    (keys _activeSupplyNodes) select {
        ((FLO_Objectives get _x) get "owner") isEqualTo _side
    }
};

_spawnObjectiveIds = _spawnObjectiveIds select {
    _x in FLO_Objectives && {((FLO_Objectives get _x) get "owner") isEqualTo _side}
};

if ((count _spawnObjectiveIds) == 0) then {
    _spawnObjectiveIds = [_reserveObjectiveId];
};

[_spawnObjectiveIds, _reserveObjectiveId, _reservePos]
