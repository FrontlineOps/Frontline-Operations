/*
    Function: FLO_fnc_getFunds
    
    Description: Gets the current funds from the FLO_MoneyHandle HashMap
    
    Parameter(s):
        None
        
    Returns:
        Number - Current funds available
*/

if (!isServer) exitWith {0};

FLO_MoneyHandle get "value"
