/*
 * Function: FLO_fnc_gtnCombatMarkClassificationDirty
 * Author: Frontline Operations Development Group
 * Description:
 *   Marks the cached combat classification as dirty so it will be rebuilt on
 *   the next resolver pass.
 *
 * Arguments:
 *   0: BOOL - true for a hard invalidate, false for a soft invalidate
 *
 * Return Value:
 *   BOOL - true when marked dirty
 */

params [["_hard", true, [true]]];

private _state = call FLO_fnc_gtnCombatGetState;
if (_hard) then {
    _state set ["classificationDirty", true];
} else {
    _state set ["classificationSoftDirty", true];
};
true
