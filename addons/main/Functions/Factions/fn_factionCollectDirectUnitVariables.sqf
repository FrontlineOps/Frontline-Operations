/*
 * Function: FLO_fnc_factionCollectDirectUnitVariables
 * Author: Frontline Operations Development Group
 * Description:
 *   Collects current custom BLUFOR unit-role inputs from mission namespace.
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
    if (isNil _x) then {
        throw format ["Custom BLUFOR definition is missing required unit role %1", _x];
    };

    private _unitClass = missionNamespace getVariable _x;
    if !(_unitClass isEqualType "") then {
        throw format ["Custom BLUFOR role %1 must be text, got %2", _x, typeName _unitClass];
    };
    if (_unitClass != "") then {
        _units pushBack _unitClass;
    };
} forEach _varNames;

_units
