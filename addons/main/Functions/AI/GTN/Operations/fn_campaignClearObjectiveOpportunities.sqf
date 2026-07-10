/*
 * Function: FLO_fnc_campaignClearObjectiveOpportunities
 * Description:
 *   Removes player-opportunity records consumed by an operation or objective
 *   integration.
 */

params ["_director", "_objectiveId"];

private _state = _director get "_state";
private _opportunities = _state get "opportunities";
private _removed = 0;

{
    private _record = _opportunities get _x;
    if ((_record get "objectiveId") == _objectiveId) then {
        _opportunities deleteAt _x;
        _removed = _removed + 1;
    };
} forEach +(keys _opportunities);

if (_removed > 0) then {
    _state set ["revision", (_state get "revision") + 1];
};

_removed
