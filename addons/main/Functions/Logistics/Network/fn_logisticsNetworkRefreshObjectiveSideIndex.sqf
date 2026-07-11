/*
 * Function: FLO_fnc_logisticsNetworkRefreshObjectiveSideIndex
 * Author: Frontline Operations Development Group
 * Description:
 *   Rebuilds the managed-side and enemy-side objective ID lists once for the
 *   current logistics tick so downstream helpers can reuse them.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   ARRAY - Managed objective IDs
 */

params ["_net"];

private _managedSide = _net get "_managedSide";
private _enemySide = _net get "_enemySide";
private _objectiveIds = keys FLO_Objectives;
private _managedObjectiveIds = [];
private _enemyObjectiveIds = [];

{
    private _objective = FLO_Objectives get _x;
    private _owner = _objective get "owner";

    if (_owner isEqualTo _managedSide && {[_x] call FLO_fnc_campaignIsObjectiveIntegrated}) then {
        _managedObjectiveIds pushBack _x;
        continue;
    };

    if (_owner isEqualTo _enemySide) then {
        _enemyObjectiveIds pushBack _x;
    };
} forEach _objectiveIds;

_net set ["_managedObjectiveIds", _managedObjectiveIds];
_net set ["_enemyObjectiveIds", _enemyObjectiveIds];

_managedObjectiveIds
