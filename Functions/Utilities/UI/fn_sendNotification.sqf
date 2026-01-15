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
    ["_playMusic", false, [true]]
];

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

[_title, _type, _playMusic] remoteExec ["FLO_fnc_displayNotification", west, false];