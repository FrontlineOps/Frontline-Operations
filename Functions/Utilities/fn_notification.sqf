/**
 * Function: FLO_fnc_notification
 * 
 * Description:
 * Displays a notification to all players and plays a success sound.
 * Used for reward announcements after completing objectives.
 *
 * Parameters:
 * _this select 0: NUMBER - The reward points amount
 * _this select 1: STRING - The objective name/description
 *
 * Returns:
 * NOTHING
 *
 * Example:
 * [100, "ENEMY OUTPOST"] call FLO_fnc_notification;
 */

// Check parameters
params [
    ["_reward", 0, [0]],
    ["_objectiveStr", "OBJECTIVE", [""]]
];

// Play music for all players
{playMusic "EventTrack01_F_Curator";} remoteExec ["call", 0];

// Display notification to all players
["showNotification", ["REWARD", format["%1 SECURED - %2 Points", _objectiveStr, _reward], "success"]] call FLO_fnc_intelSystem; 