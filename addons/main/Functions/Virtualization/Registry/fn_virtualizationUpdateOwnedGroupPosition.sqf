/* Updates one canonical group record whose reference is already owned by virtualization. */
params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_newPosition", [], [[]]]
];

_newPosition = [_newPosition] call FLO_fnc_virtualizationNormalizePosition;
if !([_newPosition, true, format ["virtualizationUpdateGroupPosition %1 new", _groupId]] call FLO_fnc_validateGroupPosition) exitWith {
    false
};

private _oldPosition = _groupData get "position";
private _side = _groupData get "side";
private _eventCellSize = ["positionEventCellSize"] call FLO_fnc_virtualizationGetConfigValue;

_groupData set ["position", _newPosition];
[_groupId, _newPosition, _side] call FLO_fnc_virtualizationSpatialUpdate;
call FLO_fnc_virtualizationTouchRegistry;

private _oldEventCellKey = "";
if ([_oldPosition] call FLO_fnc_validateGroupPosition) then {
    _oldEventCellKey = format [
        "%1_%2",
        floor ((_oldPosition select 0) / _eventCellSize),
        floor ((_oldPosition select 1) / _eventCellSize)
    ];
} else {
    ["VIRTUALIZATION", 1, format [
        "Group %1 had invalid previous position during update: %2",
        _groupId,
        _oldPosition
    ]] call FLO_fnc_log;
};

private _newEventCellKey = format [
    "%1_%2",
    floor ((_newPosition select 0) / _eventCellSize),
    floor ((_newPosition select 1) / _eventCellSize)
];
if (_oldEventCellKey != _newEventCellKey) then {
    [
        "FLO_Virtualization_GroupPositionChanged",
        [_groupId, _oldPosition, _newPosition]
    ] call CBA_fnc_localEvent;
};

true
