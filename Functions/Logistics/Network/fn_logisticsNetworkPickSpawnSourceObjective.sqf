/*
 * Function: FLO_fnc_logisticsNetworkPickSpawnSourceObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Picks a managed-side source objective near the defended objective while
 *   avoiding contested or frontline hubs.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Target objective ID <STRING>
 *   2: Blocked objective IDs <ARRAY> - Default []
 *
 * Return Value:
 *   STRING - Selected source objective ID or empty string
 */

params ["_net", "_targetObjId", ["_blockedObjectives", []]];

if (_targetObjId == "") exitWith { "" };

private _managedSide = _net get "_managedSide";
private _enemySide = _net get "_enemySide";
private _targetData = FLO_Objectives get _targetObjId;
private _targetPos = _targetData get "position";

private _enemyObjectiveIds = (keys FLO_Objectives) select {
    ((FLO_Objectives get _x) get "owner") isEqualTo _enemySide
};

private _candidates = (keys FLO_Objectives) select {
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;
    (_objData get "owner") isEqualTo _managedSide &&
    {_objId != _targetObjId} &&
    {!(_objId in _blockedObjectives)}
};

if (count _candidates == 0) exitWith { "" };

private _bestObjId = "";
private _bestScore = -1e12;

{
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;
    private _objPos = _objData get "position";
    private _distToTarget = _objPos distance2D _targetPos;
    if (_distToTarget > 3500) then { continue };

    private _nearestEnemyDist = 1e12;
    {
        private _enemyPos = (FLO_Objectives get _x) get "position";
        private _dist = _objPos distance2D _enemyPos;
        if (_dist < _nearestEnemyDist) then {
            _nearestEnemyDist = _dist;
        };
    } forEach _enemyObjectiveIds;

    if (_nearestEnemyDist < 800) then { continue };

    private _priority = _objData get "priority";
    private _score = (5000 - (_distToTarget min 5000)) + (_priority * 25) + ((_nearestEnemyDist min 3000) * 0.15);

    if (_score > _bestScore) then {
        _bestScore = _score;
        _bestObjId = _objId;
    };
} forEach _candidates;

if (_bestObjId == "") then {
    private _closestDist = 1e12;
    {
        private _objPos = (FLO_Objectives get _x) get "position";
        private _distToTarget = _objPos distance2D _targetPos;
        if (_distToTarget < _closestDist) then {
            _closestDist = _distToTarget;
            _bestObjId = _x;
        };
    } forEach _candidates;
};

if (_bestObjId == "") then { "" } else { _bestObjId }
