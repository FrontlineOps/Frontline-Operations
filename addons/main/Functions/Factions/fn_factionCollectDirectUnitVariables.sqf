/*
 * Function: FLO_fnc_factionCollectDirectUnitVariables
 * Author: Frontline Operations Development Group
 * Description:
 *   Collects legacy direct unit class variables from mission namespace.
 *
 * Arguments:
 * 0: Variable names <ARRAY>
 *
 * Returns:
 * Unit classes <ARRAY>
 */
params [["_varNames", []]];

private _units = [];
{
    if (!isNil _x) then {
        private _u = missionNamespace getVariable [_x, ""];
        if (_u isEqualType "" && {_u != ""}) then {
            _units pushBack _u;
        };
    };
} forEach _varNames;

_units
