/**
 * Function: FLO_fnc_sendNotification
 * 
 * Description:
 * Broadcasts a notification to only currently connected clients.
 * Title is the message shown in the task bar.
 *
 * Parameters:
 * _title : STRING or ARRAY - Message to display (array for format with STR_ keys)
 * _type : STRING - info, success, intel, warning
 * _playMusic : BOOL - play music for rewards
 * _targetFilter : SIDE/OWNER/OBJECT/ARRAY - Optional remoteExec target filter
 *
 * Returns:
 * Nothing
 *
 * Example:
 * ["Enemy patrol spotted at grid 045123", "warning"] call FLO_fnc_sendNotification;
 * [["STR_FLO_INTEL_MIL", _gridPos], "info"] call FLO_fnc_sendNotification;
 */

params [
    ["_title", "", ["", []]],
    ["_type", "info", [""]],
    ["_playMusic", false, [true]],
    ["_targetFilter", objNull]
];

if (!isServer) exitWith {
    [_title, _type, _playMusic, _targetFilter] remoteExec ["FLO_fnc_sendNotification", 2, false];
};

if (isNil "FLO_NotificationDedup") then {
    FLO_NotificationDedup = createHashMap;
};

private _dedupeKey = format ["%1|%2|%3|%4", str _title, _type, _playMusic, str _targetFilter];
private _nowTick = diag_tickTime;
private _lastTick = FLO_NotificationDedup getOrDefault [_dedupeKey, -999];
if ((_nowTick - _lastTick) < 0.5) exitWith {};
FLO_NotificationDedup set [_dedupeKey, _nowTick];

// IF SERVER - check intel levels
if (isServer) then {
    private _intelLevel = if (!isNil "FLO_Intel_System") then {
        FLO_Intel_System call ["getIntelLevel", []]
    } else {
        if (!isNil "FLO_Intel_Level") then { FLO_Intel_Level } else { 0 }
    };

    private _requiredIntel = switch (_type) do {
        case "warning": { 50 };
        case "intel": { 25 };
        case "success": { 0 };
        case "info": { 0 };
        default { 25 };
    };

    if (_intelLevel < _requiredIntel) exitWith {
        ["Notification", 3, format ["Notification not shown: intel %1 < required %2", _intelLevel, _requiredIntel]] call FLO_fnc_log;
        nil
    };
};

private _target = _targetFilter;
if (_target isEqualTo objNull) then {
    _target = FLO_ActivePlayerSide;
    if (!(_target in [east, west])) then { _target = 0 };
};

if (isServer) then {
    [_title, _type, _playMusic, _target] call FLO_fnc_displayNotification;
} else {
    [_title, _type, _playMusic, _target] remoteExec ["FLO_fnc_displayNotification", 2, false];
};
