/*
 * Function: FLO_fnc_transportResolveReserveObjective
 * Description:
 *   Resolves the side's reserve transport staging objective.
 *   Prefers a capital; otherwise uses the highest-priority owned objective.
 *
 * Arguments:
 *   0: Side <SIDE>
 *
 * Return Value:
 *   ARRAY - [objective ID, position]
 */

params [["_side", east, [east]]];

if !(_side in [east, west]) exitWith { ["", []] };

private _ownedObjectiveIds = [];
{
    if ((_y get "owner") isEqualTo _side) then {
        _ownedObjectiveIds pushBack _x;
    };
} forEach FLO_Objectives;

if (_ownedObjectiveIds isEqualTo []) exitWith { ["", []] };

private _capitalObjectives = _ownedObjectiveIds select {
    ((FLO_Objectives get _x) get "subtype") isEqualTo "capital"
};

private _reserveObjectiveId = if (_capitalObjectives isNotEqualTo []) then {
    _capitalObjectives select 0
} else {
    private _selectedObjectiveId = _ownedObjectiveIds select 0;
    private _bestPriority = (FLO_Objectives get _selectedObjectiveId) get "priority";

    {
        private _priority = (FLO_Objectives get _x) get "priority";
        if (_priority > _bestPriority) then {
            _bestPriority = _priority;
            _selectedObjectiveId = _x;
        };
    } forEach _ownedObjectiveIds;

    _selectedObjectiveId
};

private _reserveObjective = FLO_Objectives get _reserveObjectiveId;
[_reserveObjectiveId, _reserveObjective get "position"]
