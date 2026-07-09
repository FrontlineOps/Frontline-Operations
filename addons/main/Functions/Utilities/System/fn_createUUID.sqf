/*
 * Function: FLO_fnc_createUUID
 * Author: Frontline Operations Development Group
 * Description:
 * Generates a UUID-like unique identifier string
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Unique identifier string <STRING>
 *
 * Example:
 * private _id = [] call FLO_fnc_createUUID;
 */

// Generate a UUID-like string using random numbers and time
private _time = systemTime;
private _timeStr = format ["%1%2%3%4%5%6", 
    _time select 0,  // year
    _time select 1,  // month
    _time select 2,  // day
    _time select 3,  // hour
    _time select 4,  // minute
    _time select 5   // second
];

// Generate random components
private _random1 = floor(random 65536); // 0-65535
private _random2 = floor(random 65536);
private _random3 = floor(random 65536);
private _random4 = floor(random 65536);

// Create UUID-like format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
private _part1 = format ["%1%2", [_random1] call FLO_fnc_toHex, [_random2] call FLO_fnc_toHex];
private _part2 = [_random3] call FLO_fnc_toHex;
private _part3 = [_random4] call FLO_fnc_toHex;
private _part4 = [floor(random 65536)] call FLO_fnc_toHex;
private _part5 = format ["%1%2", _timeStr, [floor(random 65536)] call FLO_fnc_toHex];

_part1 = [_part1, 8] call FLO_fnc_padHex;
_part2 = [_part2, 4] call FLO_fnc_padHex;
_part3 = [_part3, 4] call FLO_fnc_padHex;
_part4 = [_part4, 4] call FLO_fnc_padHex;
_part5 = [_part5, 12] call FLO_fnc_padHex;

// Combine into UUID format
private _uuid = format ["%1-%2-%3-%4-%5", _part1, _part2, _part3, _part4, _part5];

_uuid
