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

// Get the old group before we move units (for virtualization lookup)
private _oldGroup = grpNull;
private _inputGroup = grpNull;

switch (true) do {
    case (_units isEqualType objNull): {
        if (!isNull _units) then { _inputGroup = group _units; };
    };
    case (_units isEqualType []): {
        if (count _units > 0) then { _inputGroup = group (_units select 0); };
    };
    case (_units isEqualType grpNull): {
        _inputGroup = _units;
    };
};

if (
    isNull _targetGroup
    && {!isNull _inputGroup}
    && {(side _inputGroup) isEqualTo _side}
) exitWith {
    _inputGroup
};

// Determine target group - use provided or create new
private _newGroup = if (_targetGroup isEqualType grpNull && {!isNull _targetGroup}) then {
    _targetGroup
} else {
    if (_targetGroup isEqualType objNull && {!isNull _targetGroup}) then {
        group _targetGroup
    } else {
        createGroup [_side, true]
    };
};

if (isNull _newGroup) exitWith {
    ["VIRTUALIZATION", 1, format [
        "setSide failed: engine refused createGroup for side %1",
        _side
    ]] call FLO_fnc_log;
    grpNull
};

// Move units based on input type
switch (true) do {
    case (_units isEqualType objNull): {
        _oldGroup = group _units;
        [_units] joinSilent _newGroup;
    };
    case (_units isEqualType []): {
        if (count _units > 0) then {
            _oldGroup = group (_units select 0);
        };
        _units joinSilent _newGroup;
    };
    case (_units isEqualType grpNull): {
        _oldGroup = _units;
        (units _units) joinSilent _newGroup;
    };
};

// Update virtualization tracking if the old group was being tracked
if (!isNull _oldGroup && {!isNil "FLO_virtualGroups"}) then {
    private _groups = FLO_virtualGroups get "_groups";
    
    if (!isNil "_groups") then {
        {
            private _groupId = _x;
            private _groupData = _y;
            private _trackedGroup = _groupData get "realGroup";
            
            if (!isNil "_trackedGroup" && {_trackedGroup isEqualTo _oldGroup}) then {
                // Update tracking to point to new group
                [_groupData, _newGroup] call FLO_fnc_virtualizationSetRealGroup;
                _groupData set ["side", _side];
                
                ["VIRTUALIZATION", 3, format["setSide: Updated tracking for %1 from old group to new %2 group", _groupId, _side]] call FLO_fnc_log;
            };
        } forEach _groups;
    };
};

// Delete old group if empty
if (!isNull _oldGroup && {count units _oldGroup == 0}) then {
    deleteGroup _oldGroup;
};

_newGroup
