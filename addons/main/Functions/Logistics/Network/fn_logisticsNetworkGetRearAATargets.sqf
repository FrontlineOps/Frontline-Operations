/*
 * Function: FLO_fnc_logisticsNetworkGetRearAATargets
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds managed-side objectives in the rear or midline that need static AA
 *   coverage and are not already covered.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   ARRAY - Objective IDs eligible for static AA deployment
 */

params ["_net"];

private _managedSide = _net get "_managedSide";
private _objectives = _net get "_managedObjectiveIds";
private _enemyObjectives = _net get "_enemyObjectiveIds";
if (_enemyObjectives isEqualTo []) exitWith { [] };

private _minEnemyDistance = 1500;
private _maxEnemyDistance = 3000;
private _targets = [];

{
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;
    if ((_objData get "owner") != _managedSide) then { continue };
    if ([_net, _objId] call FLO_fnc_logisticsNetworkObjectiveHasStaticAA) then { continue };

    private _objPos = _objData get "position";
    private _nearestEnemyDist = 1e12;

    {
        private _enemyPos = (FLO_Objectives get _x) get "position";
        private _dist = _objPos distance2D _enemyPos;
        if (_dist < _nearestEnemyDist) then {
            _nearestEnemyDist = _dist;
        };
    } forEach _enemyObjectives;

    if (_nearestEnemyDist >= _minEnemyDistance && {_nearestEnemyDist <= _maxEnemyDistance}) then {
        _targets pushBack _objId;
    };
} forEach _objectives;

_targets
