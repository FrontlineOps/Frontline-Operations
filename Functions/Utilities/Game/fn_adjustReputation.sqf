/*
 * Function: FLO_fnc_adjustReputation
 * Adjusts the reputation score using FLO_ReputationHandle.
 * Parameters:
 *   0: Amount to adjust (NUMBER, positive or negative)
 *   1: Type (STRING, 'increase' or 'decrease')
 * Example:
 *   [1, 'increase'] call FLO_fnc_adjustReputation;
 *   [-1, 'decrease'] call FLO_fnc_adjustReputation;
 */
params [
    ["_amount", 0, [0]],
    ["_type", "increase", [""]]
];

private _REPSCORE = FLO_ReputationHandle get "value";
private _newScore = _REPSCORE + _amount;
_newScore = _newScore max 0 min 16;
FLO_ReputationHandle set ["value", _newScore];
publicVariable "FLO_ReputationHandle";

// Notification
private _msg = if (_type isEqualTo "increase") then {"STR_FLO_REP_INC"} else {"STR_FLO_REP_DEC"};
[_msg, "success"] call FLO_fnc_sendNotification; 