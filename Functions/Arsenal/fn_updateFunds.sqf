/*
    Function: FLO_fnc_updateFunds
    
    Description: Updates the current funds by adding or subtracting the specified amount
    
    Parameter(s):
        _amount - Amount to add (positive) or subtract (negative) from current funds
        
    Returns:
        Number - New funds balance after update
*/
params ["_amount"];

private _Money = FLO_MoneyHandle get "value";

// Calculate new money value
private _NewMoney = _Money + _amount;
FLO_MoneyHandle set ["value", _NewMoney];
[_NewMoney] call FLO_fnc_publishMoneyState;

// Return new balance
_NewMoney
