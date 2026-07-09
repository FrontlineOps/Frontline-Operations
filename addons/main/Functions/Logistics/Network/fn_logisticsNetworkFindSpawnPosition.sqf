/*
 * Function: FLO_fnc_logisticsNetworkFindSpawnPosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves a reinforcement spawn position from a managed-side source
 *   objective and returns both the spawn position and source objective ID.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Target objective ID <STRING>
 *   2: Blocked objective IDs <ARRAY> - Default []
 *
 * Return Value:
 *   ARRAY - [spawn position, source objective ID]
 */

params ["_net", "_targetObjId", ["_blockedObjectives", []]];

if (_targetObjId == "") exitWith { [[0, 0, 0], ""] };

private _sourceObjId = [_net, _targetObjId, _blockedObjectives] call FLO_fnc_logisticsNetworkPickSpawnSourceObjective;
if (_sourceObjId == "") exitWith { [[0, 0, 0], ""] };

private _spawnPos = [_net, _sourceObjId] call FLO_fnc_logisticsNetworkGetCachedSpawnPosition;
if (_spawnPos isEqualTo [0, 0, 0]) then {
    _spawnPos = (FLO_Objectives get _sourceObjId) get "position";
};

private _targetPos = (FLO_Objectives get _targetObjId) get "position";
private _sourceObjectivePos = (FLO_Objectives get _sourceObjId) get "position";

if ((_sourceObjectivePos distance2D _targetPos) > (_net get "SUPPLY_CHAIN_MAX_HOP_ROUTE_METERS")) exitWith { [[0, 0, 0], ""] };

[_spawnPos, _sourceObjId]
