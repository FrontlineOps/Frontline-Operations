/*
 * Function: FLO_fnc_sideKey
 * Description:
 *   Converts an engine side or normalized side string to a stable key.
 */

params [["_side", sideUnknown, [sideUnknown, ""]]];

if (_side isEqualType "") exitWith {
    private _key = toUpper _side;
    if !(_key in ["EAST", "WEST", "GUER", "CIV", "UNKNOWN"]) then {
        _key = "UNKNOWN";
    };
    _key
};
if (_side isEqualTo east) exitWith { "EAST" };
if (_side isEqualTo west) exitWith { "WEST" };
if (_side isEqualTo resistance) exitWith { "GUER" };
if (_side isEqualTo civilian) exitWith { "CIV" };
"UNKNOWN"
