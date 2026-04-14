/*
 * Function: FLO_fnc_logisticsNetworkPickHQObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Elects the logistics HQ objective for the managed side. Capitals outrank
 *   cities, then villages, then any remaining owned objective by priority.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   STRING - HQ objective ID or empty string
 */

params ["_net"];

private _friendlyObjectiveIds = _net get "_managedObjectiveIds";

if (count _friendlyObjectiveIds == 0) exitWith { "" };

private _bestObjectiveId = "";
private _bestScore = -1e12;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _score = switch (_objective get "subtype") do {
        case "capital": { 3000 };
        case "city": { 2000 };
        case "village": { 1000 };
        default { 0 };
    };
    _score = _score + (_objective get "priority");

    if (_score > _bestScore) then {
        _bestScore = _score;
        _bestObjectiveId = _objectiveId;
    };
} forEach _friendlyObjectiveIds;

_bestObjectiveId
