/*
 * Function: FLO_fnc_gtnCombatAveragePosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Calculates the average position of a set of combat group references.
 *
 * Arguments:
 *   0: Group references <ARRAY>
 *
 * Return Value:
 *   Average position <ARRAY>
 */

params ["_refs"];

private _sumX = 0;
private _sumY = 0;
private _countRefs = count _refs;

{
    private _pos = (_x select 1) get "position";
    _sumX = _sumX + (_pos select 0);
    _sumY = _sumY + (_pos select 1);
} forEach _refs;

[_sumX / _countRefs, _sumY / _countRefs, 0]
