/*
 * Function: FLO_fnc_dateNumberAddSeconds
 * Description:
 *   Adds real seconds to a dateToNumber value and wraps at year end.
 */

params [
    ["_dateNumber", 0, [0]],
    ["_seconds", 0, [0]],
    ["_year", date select 0, [0]]
];

private _secondsPerYear = [_year] call FLO_fnc_dateNumberSecondsPerYear;
(_dateNumber + (_seconds / _secondsPerYear)) mod 1
