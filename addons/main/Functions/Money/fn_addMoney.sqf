/*
 * Function: FLO_fnc_addMoney
 * Author: Frontline Operations Development Group
 * Description:
 *   Adds money to the authoritative server balance and republishes the
 *   synchronized money state.
 *
 * Arguments:
 *   0: Amount to add <NUMBER>
 *
 * Return Value:
 *   New server balance <NUMBER>
 *
 * Example:
 *   [5000] remoteExecCall ["FLO_fnc_addMoney", 2];
 */

if (!isServer) exitWith {
    _this remoteExecCall ["FLO_fnc_addMoney", 2];
};

params [["_amount", 0, [0]]];

private _currentMoney = FLO_MoneyHandle get "value";
private _newMoney = _currentMoney + _amount;

FLO_MoneyHandle set ["value", _newMoney];
[_newMoney] call FLO_fnc_publishMoneyState;

diag_log format ["[FLO][MONEY] Added %1 money. New balance: %2", _amount, _newMoney];

_newMoney
