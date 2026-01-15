/*
 * Function: FLO_fnc_adjustAggression
 * Adjusts the aggression score (difficulty) using FLO_DifficultyHandle.
 * Parameters:
 *   0: Amount to adjust (NUMBER, positive or negative)
 *   1: Type (STRING, 'increase' or 'decrease')
 * Example:
 *   [0.75, 'increase'] call FLO_fnc_adjustAggression;
 */
params [
    ["_amount", 0, [0]],
    ["_type", "increase", [""]]
];

private _AGGRSCORE = FLO_DifficultyHandle get "value";
private _newScore = _AGGRSCORE + _amount;
_newScore = _newScore max 0 min 34;
FLO_DifficultyHandle set ["value", _newScore];
publicVariable "FLO_DifficultyHandle";

// Notification - just pass the message
private _msg = if (_type isEqualTo "increase") then {"STR_FLO_REP_AGG_INC"} else {"STR_FLO_REP_AGG_DEC"};
[_msg, "warning"] call FLO_fnc_sendNotification; 