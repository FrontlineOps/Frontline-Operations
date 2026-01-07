/**
 * Function: FLO_fnc_sendNotification
 * 
 * Description:
 * Broadcasts a notification to only currently connected clients
 * Does not add to JIP queue and only supports side: WEST
 *
 * Parameters:
 * _titleType : STRING -  from string table
 * _msg : STRING -  from string table
 * _type : STRING - info, success, intel, warning
 *
 * Returns:
 * Nothing
 *
 * Example:
 * ["STR_FLO_INTEL_TITLE","STR_FLO_INTEL", "info"] call FLO_fnc_sendNotification;
 */

 params [
    ["_titleType","",[""]],
    ["_msg","",["",[]]],
    ["_type","info",[""]],
    ["_playMusic", false , [true]]
];

//IF SERVER NOTIFICATION - check intel levels
if (isServer) then {
    // Get intel level from Intel System
    private _intelLevel = if (!isNil "FLO_Intel_System") then {
        FLO_Intel_System call ["getIntelLevel", []]
    } else {
        // Fallback to public variable if system not ready
        if (!isNil "FLO_Intel_Level") then { FLO_Intel_Level } else { 0 }
    };

    // Define intel requirements for different notification types
    private _requiredIntel = switch (_type) do {
        case "warning": { 50 };   // High priority - needs good intel
        case "intel": { 25 };     // Medium priority
        case "success": { 0 };    // Always show
        case "info": { 0 };       // Always show
        default { 25 };           // Default to medium priority
    };

    // Check if we meet the requirements to show this notification and exit if not
    if (_intelLevel < _requiredIntel) exitWith {
        ["Notification", 3, format ["Notification not shown: intel %1 < required %2", _intelLevel, _requiredIntel]] call FLO_fnc_log;
        nil
    };
};


// Color code based on notification type
private _color = switch (_type) do {
    case "warning": { "#FF3619" };  // Red for warnings
    case "intel": { "#FACE00" };    // Yellow for intel
    case "success": { "#00DB07" };  // Green for success
    case "info": { "#1AA3FF" };     // Blue for info
    default { "#FFFFFF" };          // White for default
};

[_titleType, _msg, _color, _playMusic] remoteExec ["FLO_fnc_displayNotification", west, false];