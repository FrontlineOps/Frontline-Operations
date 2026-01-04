/*
    Function: FLO_fnc_checkCratePurchase
    
    Description: Checks if there are enough funds to purchase a crate and initiates the purchase process
    
    Parameter(s):
        _target - The object the action was attached to
        _caller - The player who initiated the action
        _crateInfo - Array containing crate information
        
    Returns:
        None
*/
params ["_target", "_caller", "_crateInfo"];
_crateInfo params ["_id", "_name", "_cost", "_boxType", "_items", "_description"];

// Check funds
private _currentFunds = [] call FLO_fnc_getFunds;

if (_currentFunds >= _cost) then {
    // Deduct funds
    private _newFunds = [0 - _cost] call FLO_fnc_updateFunds;
    
    // Create crate (hidden)
    private _crate = createVehicle [_boxType, [0,0,0], [], 0, "NONE"];
    _crate allowDamage false;
    _crate enableSimulation false;
    _crate hideObject true;
    
    // Store crate info
    _crate setVariable ["FLO_crateInfo", [_id, _name, _cost, _items, _description], true];
    
    // Tell player to start placement
    [_crate, _id, _name, _cost, _boxType, _items, _description, _newFunds] remoteExec ["FLO_fnc_placeCrate", owner _caller];
} else {
    // Not enough funds - notify player
    [format ["Not enough funds to purchase %1.\nRequired: %2$\nAvailable: %3$", _name, _cost, _currentFunds]] remoteExec ["hint", _caller];
};
