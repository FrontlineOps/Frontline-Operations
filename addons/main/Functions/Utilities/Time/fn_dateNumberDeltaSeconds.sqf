/*
 * Function: FLO_fnc_dateNumberDeltaSeconds
 * Description:
 *   Converts the signed shortest delta between two dateToNumber values into
 *   real seconds. FLO timer windows are always shorter than half a year.
 */

params [
    ["_fromDateNumber", 0, [0]],
    ["_toDateNumber", 0, [0]],
    ["_year", -1, [0]]
];

if (_year < 0) then {
    _year = FLO_OperationalClock get "year";
};

private _delta = _toDateNumber - _fromDateNumber;
if (_delta < -0.5) then { _delta = _delta + 1; };
if (_delta > 0.5) then { _delta = _delta - 1; };

_delta * ([_year] call FLO_fnc_dateNumberSecondsPerYear)
