/*
    Function: FLO_fnc_updateFunds
    
    Description: Updates the current funds by adding or subtracting the specified amount
    
    Parameter(s):
        _amount - Amount to add (positive) or subtract (negative) from current funds
        
    Returns:
        Number - New funds balance after update
*/

if (!isServer) exitWith {0};

params ["_amount"];

private _Money = 0;
if (!isNil "FLO_MoneyHandle") then {
    _Money = FLO_MoneyHandle get "value";
    if (isNil "_Money") then { _Money = 0; };
};

// Calculate new money value
private _NewMoney = _Money + _amount;
FLO_MoneyHandle set ["value", _NewMoney];
publicVariable "FLO_MoneyHandle";

// Return new balance
_NewMoney
