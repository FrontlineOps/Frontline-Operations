/*
 * Function: FLO_fnc_dateNumberSecondsPerYear
 * Description:
 *   Returns the number of seconds represented by one dateToNumber unit for
 *   the supplied Gregorian year.
 */

params [["_year", date select 0, [0]]];

private _isLeapYear = (_year mod 4) == 0
    && {(_year mod 100) != 0 || {(_year mod 400) == 0}};

[31536000, 31622400] select _isLeapYear
