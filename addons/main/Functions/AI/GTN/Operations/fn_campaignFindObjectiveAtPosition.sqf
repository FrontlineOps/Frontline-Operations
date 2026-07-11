/*
 * Function: FLO_fnc_campaignFindObjectiveAtPosition
 * Description:
 *   Returns the objective containing a position, or an empty string.
 */

params [["_position", [], [[]]]];

if (count _position < 2) then {
    throw format ["FLO_fnc_campaignFindObjectiveAtPosition: invalid position %1", _position];
};

private _objectiveId = "";
{
    private _candidate = FLO_Objectives get _x;
    if ([_position, _candidate] call FLO_fnc_isPositionInObjective) exitWith {
        _objectiveId = _x;
    };
} forEach (keys FLO_Objectives);

_objectiveId
