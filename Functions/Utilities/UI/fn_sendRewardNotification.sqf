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
    ["_objectiveStr", "STR_FLO_OBJECTIVE", [""]]
];

// Display notification to all players
[["STR_FLO_REWARD_SECURED", _objectiveStr, _reward], "success", true] call FLO_fnc_sendNotification;
