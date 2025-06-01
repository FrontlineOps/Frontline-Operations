/*
    Function: FLO_fnc_getFunds
    
    Description: Gets the current funds from the FLO_MoneyHandle HashMap
    
    Parameter(s):
        None
        
    Returns:
        Number - Current funds available
*/

if (!isServer) exitWith {0};

private _Money = 0;
if (!isNil "FLO_MoneyHandle") then {
    _Money = FLO_MoneyHandle get "value";
    if (isNil "_Money") then { _Money = 0; };
};

_Money