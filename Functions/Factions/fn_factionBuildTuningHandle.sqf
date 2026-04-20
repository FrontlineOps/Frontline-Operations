/*
 * Function: FLO_fnc_factionBuildTuningHandle
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds validated faction tuning overrides from mission setup edit controls.
 *
 * Arguments:
 *   0: Dialog display <DISPLAY>
 *   1: Side label for errors <STRING>
 *   2: Field specs <ARRAY> of [idc, category, key]
 *
 * Return Value:
 *   HASHMAP with keys valid, errors, overrides
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]],
    ["_sideLabel", "", [""]],
    ["_fieldSpecs", [], [[]]]
];

private _errors = [];
private _overrides = createHashMap;
private _caps = [];
private _counts = [];

private _fnc_compact = {
    params ["_value"];
    toString ((toArray _value) select {!(_x in [9, 10, 13, 32])})
};

private _fnc_isUnsignedInt = {
    params ["_value"];
    if (_value == "") exitWith { false };
    ((toArray _value) findIf {_x < 48 || {_x > 57}}) < 0
};

{
    _x params ["_idc", "_category", "_key"];

    private _ctrl = _display displayCtrl _idc;
    private _text = [ctrlText _ctrl] call _fnc_compact;

    if (_text != "") then {
        if !([_text] call _fnc_isUnsignedInt) then {
            _errors pushBack format ["%1: %2 must be a non-negative whole number", _sideLabel, _key];
        } else {
            private _value = parseNumber _text;

            switch (_category) do {
                case "scalar": {
                    _overrides set [_key, _value];
                };
                case "cap": {
                    _caps pushBack [_key, _value];
                };
                case "count": {
                    _counts pushBack [_key, _value];
                };
                default {
                    _errors pushBack format ["%1: unknown tuning category '%2' for %3", _sideLabel, _category, _key];
                };
            };
        };
    };
} forEach _fieldSpecs;

if (_caps isNotEqualTo []) then {
    _overrides set ["objectiveGroupTypeCaps", _caps];
};
if (_counts isNotEqualTo []) then {
    _overrides set ["groupCounts", _counts];
};

createHashMapFromArray [
    ["valid", _errors isEqualTo []],
    ["errors", _errors],
    ["overrides", _overrides]
]
