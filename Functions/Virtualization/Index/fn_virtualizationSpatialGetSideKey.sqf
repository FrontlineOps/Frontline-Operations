/*
 * Function: FLO_fnc_virtualizationSpatialGetSideKey
 */

params [["_side", nil]];

if (isNil "_side") exitWith { "" };
if (_side isEqualType "") exitWith {
    private _sideKey = toUpper _side;
    if !(_sideKey in ["EAST", "WEST", "GUER", "CIV", "UNKNOWN"]) then {
        _sideKey = "UNKNOWN";
    };
    _sideKey
};
if (_side isEqualTo east) exitWith { "EAST" };
if (_side isEqualTo west) exitWith { "WEST" };
if (_side isEqualTo resistance) exitWith { "GUER" };
if (_side isEqualTo civilian) exitWith { "CIV" };
"UNKNOWN"
