/*
 * Function: FLO_fnc_gtnBuildObjectiveDemandSignature
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a deterministic signature for friendly objective demand inputs used
 *   by commander maintenance passes such as baseline garrisons.
 *
 * Arguments:
 *   0: Objective state map <HASHMAP>
 *   1: Own side <SIDE>
 *   2: Enemy side <SIDE>
 *
 * Return Value:
 *   Signature <STRING>
 */

params ["_objectives", "_ownSide", "_enemySide"];

private _friendlyObjectiveIds = [];
{
    private _objective = _objectives get _x;
    if ((_objective get "owner") != _ownSide) then { continue };
    _friendlyObjectiveIds pushBack _x;
} forEach (keys _objectives);

_friendlyObjectiveIds sort true;

private _parts = [str (count _friendlyObjectiveIds)];
{
    private _objectiveId = _x;
    private _objective = _objectives get _objectiveId;
    private _enemyLinkedCount = 0;

    {
        private _linkedObjective = _objectives get _x;
        if (isNil "_linkedObjective") then { continue };
        if ((_linkedObjective get "owner") == _enemySide) then {
            _enemyLinkedCount = _enemyLinkedCount + 1;
        };
    } forEach (_objective get "linkedObjectives");

    _parts pushBack format [
        "%1|%2|%3|%4|%5|%6|%7",
        _objectiveId,
        _objective get "priority",
        _objective get "contested",
        _objective get "underAttack",
        _objective get "enemyCount",
        _objective get "friendlyCount",
        _enemyLinkedCount
    ];
} forEach _friendlyObjectiveIds;

_parts joinString ";"
