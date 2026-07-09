/*
 * Function: FLO_fnc_factionDialogFillCompositionDefaults
 * Author: Frontline Operations Development Group
 * Description:
 *   Loads default numeric force composition values into one side of the
 *   mission setup dialog.
 *
 * Arguments:
 *   0: Dialog display <DISPLAY>
 *   1: Side label <STRING> - "BLUFOR" or "OPFOR"
 *   2: Faction combo IDC <NUMBER>
 *
 * Return Value:
 *   None
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]],
    ["_sideLabel", "", [""]],
    ["_comboIdc", -1, [0]]
];

if (isNull _display) exitWith {
    ["UI", 1, format ["Cannot fill %1 composition defaults - display is null", _sideLabel]] call FLO_fnc_log;
};

private _combo = _display displayCtrl _comboIdc;
private _selectedIndexes = if ((ctrlType _combo) == 5) then {
    lbSelection _combo
} else {
    []
};
private _selectedIndex = if (_selectedIndexes isNotEqualTo []) then {
    _selectedIndexes select 0
} else {
    lbCurSel _combo
};
if (_selectedIndex < 0) exitWith {
    ["UI", 1, format ["Cannot fill %1 composition defaults - no faction selected", _sideLabel]] call FLO_fnc_log;
};

private _selection = _combo lbText _selectedIndex;
private _defaults = [_sideLabel, _selection] call FLO_fnc_factionGetCompositionDefaults;
private _capValues = createHashMapFromArray (_defaults get "objectiveGroupTypeCaps");
private _countValues = createHashMapFromArray (_defaults get "groupCounts");
private _objectiveGroups = _defaults get "objectiveGroups";
private _objectiveValues = createHashMap;
{
    _x params ["_subtype", "_groups"];
    _objectiveValues set [_subtype, createHashMapFromArray _groups];
} forEach _objectiveGroups;

{
    _x params ["_idc", "_category", "_key"];

    private _value = switch (_category) do {
        case "scalar": { _defaults get _key };
        case "cap": { _capValues get _key };
        case "count": { _countValues get _key };
        case "objective": {
            private _groupType = _x select 3;
            private _groups = _objectiveValues get _key;
            if (_groupType in _groups) then { _groups get _groupType } else { 0 }
        };
        default {
            ["UI", 1, format ["Unknown %1 composition category '%2' for %3", _sideLabel, _category, _key]] call FLO_fnc_log;
            0
        };
    };

    (_display displayCtrl _idc) ctrlSetText str _value;
} forEach ([_sideLabel] call FLO_fnc_factionGetTuningFieldSpecs);
