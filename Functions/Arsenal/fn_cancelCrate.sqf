/*
    Function: FLO_fnc_cancelCrate
    
    Description: Cancels crate purchase and refunds the cost
    
    Parameter(s):
        _crate - The crate object to delete
        _cost - The cost to refund
        
    Returns:
        None
*/

if (!isServer) exitWith {};

params ["_crate", "_cost"];

// Refund cost
[_cost] call FLO_fnc_updateFunds;

// Delete crate
deleteVehicle _crate;
