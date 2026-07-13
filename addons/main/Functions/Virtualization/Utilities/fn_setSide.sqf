/*
 * Function: FLO_fnc_setSide
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Sets side of group or array of units by moving them to a new group of the target side.
 * Automatically updates virtualization tracking if the group is being tracked.
 *
 * Arguments:
 * 0: Units - <GROUP>, <OBJECT>, or <ARRAY> of <OBJECTS>
 * 1: New Side - <SIDE> or <NUMBER> (0=EAST, 1=WEST, 2=INDEPENDENT, 3=CIVILIAN)
 * 2: Existing Group - (Optional) <GROUP> or <OBJECT> - will use this group instead of creating new
 *
 * Return Value:
 * Group the units are now in - <GROUP>
 *
 * Example:
 * [group _unit, east] call FLO_fnc_setSide;
 * [_unit, 1] call FLO_fnc_setSide;
 * [[_unit1, _unit2], east, _existingGroup] call FLO_fnc_setSide;
 */

params [
    ["_units", [], [[], grpNull, objNull]],
    ["_side", east, [east, 0]],
    ["_targetGroup", grpNull, [grpNull, objNull]]
];

// Convert numeric side to side type
if (_side isEqualType 0) then {
    _side = _side call BIS_fnc_sideType;
};

private _inputGroup = grpNull;
private _movingUnits = [];

switch (true) do {
    case (_units isEqualType objNull): {
        if (!isNull _units) then {
            _inputGroup = group _units;
            _movingUnits = [_units];
        };
    };
    case (_units isEqualType []): {
        _movingUnits = _units select { !isNull _x };
        if (_movingUnits isNotEqualTo []) then { _inputGroup = group (_movingUnits select 0); };
    };
    case (_units isEqualType grpNull): {
        _inputGroup = _units;
        if (!isNull _inputGroup) then { _movingUnits = units _inputGroup; };
    };
};

if (_movingUnits isEqualTo []) exitWith {
    ["VIRTUALIZATION", 1, format ["setSide received no units for target side %1", _side]] call FLO_fnc_log;
    grpNull
};

private _oldGroups = [];
{
    private _unitGroup = group _x;
    if (!isNull _unitGroup) then {
        _oldGroups pushBackUnique _unitGroup;
    };
} forEach _movingUnits;

// Reuse the current group when its group-side is already correct. Rejoining
// still matters because individual units can retain their config-defined side.
private _newGroup = if (_targetGroup isEqualType grpNull && {!isNull _targetGroup}) then {
    _targetGroup
} else {
    if (_targetGroup isEqualType objNull && {!isNull _targetGroup}) then {
        group _targetGroup
    } else {
        if (!isNull _inputGroup && {(side _inputGroup) isEqualTo _side}) then {
            _inputGroup
        } else {
            createGroup [_side, true]
        }
    };
};

if (isNull _newGroup) exitWith {
    ["VIRTUALIZATION", 1, format [
        "setSide failed: engine refused createGroup for side %1",
        _side
    ]] call FLO_fnc_log;
    grpNull
};

if ((side _newGroup) isNotEqualTo _side) exitWith {
    ["VIRTUALIZATION", 1, format [
        "setSide target group has side %1 instead of requested side %2",
        side _newGroup,
        _side
    ]] call FLO_fnc_log;
    grpNull
};

private _unitsToJoin = _movingUnits select {
    (group _x) isNotEqualTo _newGroup || {(side _x) isNotEqualTo _side}
};
{
    [_x] joinSilent _newGroup;
} forEach _unitsToJoin;

private _failedIndex = _movingUnits findIf {
    (group _x) isNotEqualTo _newGroup || {(side _x) isNotEqualTo _side}
};
if (_failedIndex != -1) exitWith {
    private _failedUnit = _movingUnits select _failedIndex;
    ["VIRTUALIZATION", 1, format [
        "setSide failed for %1: expected=%2 actualUnit=%3 actualGroup=%4",
        typeOf _failedUnit,
        _side,
        side _failedUnit,
        side group _failedUnit
    ]] call FLO_fnc_log;
    grpNull
};

// Update virtualization tracking if a tracked group was replaced.
if (!isNil "FLO_VirtualForceRegistry" && {(_oldGroups findIf { _x isNotEqualTo _newGroup }) != -1}) then {
    private _groups = call FLO_fnc_virtualizationGetGroupMap;
    {
        private _groupId = _x;
        private _groupData = _y;
        private _trackedGroup = _groupData get "realGroup";

        if (_trackedGroup in _oldGroups && {_trackedGroup isNotEqualTo _newGroup}) then {
            [_groupData, _newGroup] call FLO_fnc_virtualizationSetRealGroup;
            _groupData set ["side", _side];

            ["VIRTUALIZATION", 3, format ["setSide updated tracking for %1 to %2", _groupId, _side]] call FLO_fnc_log;
        };
    } forEach _groups;
};

{
    if (_x isNotEqualTo _newGroup && {(units _x) isEqualTo []}) then {
        deleteGroup _x;
    };
} forEach _oldGroups;

_newGroup
