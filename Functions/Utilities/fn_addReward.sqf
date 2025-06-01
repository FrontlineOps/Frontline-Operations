/**
 * Function: FLO_fnc_addReward
 * 
 * Description:
 * Adds specified amount to the player's reward/money counter.
 * The money value is stored in FLO_MoneyHandle.
 *
 * Parameters:
 * _this select 0: NUMBER - The amount to add to the reward counter
 *
 * Returns:
 * NUMBER - The new money value after adding the reward
 *
 * Example:
 * [100] call FLO_fnc_addReward;
 */

if (!isServer) exitWith {}; // Only execute on server

// Check parameters
params [["_RWRD", 0, [0]]];

private _Money = 0;
if (!isNil "FLO_MoneyHandle") then {
    _Money = FLO_MoneyHandle get "value";
    if (isNil "_Money") then { _Money = 0; };
};

// Calculate new money value
private _NewMoney = _Money + _RWRD;
FLO_MoneyHandle set ["value", _NewMoney];
publicVariable "FLO_MoneyHandle";

// Return new balance
_NewMoney 