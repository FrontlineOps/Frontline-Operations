/*
 * Function: FLO_fnc_gtnCountAliveTaskTargets
 * Author: Frontline Operations Development Group
 * Description:
 *   Counts alive target objects still owned by the expected enemy side.
 *
 * Arguments:
 *   0: Targets <ARRAY>
 *   1: Enemy side <SIDE>
 *
 * Return Value:
 *   Target count <NUMBER>
 */

params ["_targets", "_enemySide"];

{
    if (isNull _x || {!alive _x}) then { false } else {
        private _targetSide = side _x;
        if (isPlayer _x) then {
            _targetSide = side group _x;
        };
        _targetSide isEqualTo _enemySide
    }
} count _targets
