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

[_RWRD] call FLO_fnc_addMoney
