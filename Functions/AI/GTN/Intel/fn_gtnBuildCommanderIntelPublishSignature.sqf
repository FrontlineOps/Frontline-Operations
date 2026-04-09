/*
 * Function: FLO_fnc_gtnBuildCommanderIntelPublishSignature
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a deterministic signature string for the commander COP publish
 *   payload so unchanged pictures can be skipped.
 *
 * Arguments:
 *   0: Side key <STRING>
 *   1: Enemy group marker records <ARRAY>
 *   2: Enemy concentration marker records <ARRAY>
 *   3: Friendly group marker records <ARRAY>
 *   4: Support marker records <ARRAY>
 *
 * Return Value:
 *   Signature <STRING>
 */

params [
    ["_sideKey", "", [""]],
    ["_enemyGroupMarkers", [], [[]]],
    ["_enemyConcentrationMarkers", [], [[]]],
    ["_friendlyGroupMarkers", [], [[]]],
    ["_supportMarkers", [], [[]]]
];

private _fnc_normalizeValue = {
    params ["_value"];

    if (_value isEqualType 0) exitWith {
        str (round (_value * 10) / 10)
    };

    if (_value isEqualType []) exitWith {
        "[" + ((_value apply { [_x] call _fnc_normalizeValue }) joinString ",") + "]"
    };

    str _value
};

private _fnc_serializeRecords = {
    params ["_records"];

    private _serialized = _records apply {
        (_x apply { [_x] call _fnc_normalizeValue }) joinString "|"
    };
    _serialized sort true;
    _serialized joinString ";"
};

[
    _sideKey,
    [_enemyGroupMarkers] call _fnc_serializeRecords,
    [_enemyConcentrationMarkers] call _fnc_serializeRecords,
    [_friendlyGroupMarkers] call _fnc_serializeRecords,
    [_supportMarkers] call _fnc_serializeRecords
] joinString "||"
