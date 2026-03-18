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

private _spawnPos = [_sourceObjId, true] call FLO_fnc_getRandomObjectivePos;
if (_spawnPos isEqualTo [0, 0, 0]) then {
    _spawnPos = (FLO_Objectives get _sourceObjId) get "position";
};

private _targetPos = (FLO_Objectives get _targetObjId) get "position";

if ((_spawnPos distance2D _targetPos) > 4500) then {
    _spawnPos = [_targetObjId, true] call FLO_fnc_getRandomObjectivePos;
    if (_spawnPos isEqualTo [0, 0, 0]) then {
        _spawnPos = _targetPos;
    };
    _sourceObjId = _targetObjId;
};

[_spawnPos, _sourceObjId]
