/*
    Function: FLO_fnc_purchaseCrate
    
    Description: Creates a system for purchasing limited equipment crates at FOBs and OPs
                 These crates contain special equipment not available in the arsenal
    
    Parameter(s):
        _object - The FOB or OP object to attach the purchase action to
        
    Returns:
        None
*/

if (isNil "FLO_crates_initialized") then {
    FLO_crates_initialized = false;
};

if (FLO_crates_initialized) exitWith {};

// Define available crate types with their contents and costs
FLO_availableCrates = [
    // Format: [ID, Name, Cost, Type of Box, Items Array, Description]
    ["heavyweapons", "Heavy Weapons Crate", 50, "Box_NATO_WpsSpecial_F", [
        ["launch_B_Titan_short_F", 2],  // 2x Javelin launchers
        ["Titan_AT", 10]                // 10x Javelin missiles
    ], "Contains 2 Javelin launchers and 10 missiles"],
    
    ["explosives", "Explosives Crate", 40, "Box_NATO_AmmoOrd_F", [
        ["SatchelCharge_Remote_Mag", 4],
        ["DemoCharge_Remote_Mag", 8],
        ["ClaymoreDirectionalMine_Remote_Mag", 6],
        ["ACE_Clacker", 2]
    ], "Contains various explosives and detonators"],
    
    ["specialammo", "Special Ammunition Crate", 30, "Box_NATO_Ammo_F", [
        ["150Rnd_762x54_Box", 5],
        ["130Rnd_338_Mag", 5],
        ["7Rnd_408_Mag", 10]
    ], "Contains special ammunition for machine guns and sniper rifles"]
];

// Use the existing map marker money system instead of a separate variable
FLO_fnc_getFunds = {
    // Find money marker
    private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
    if (count _mrkrs == 0) exitWith {
        diag_log "[FLO] ERROR: No money marker (Color2_FD_F) found on map";
        0
    };
    
    // Get marker and current money value
    private _mrkr = _mrkrs select 0;
    private _Money = 0;
    private _markerText = markerText _mrkr;
    
    // Try to parse current money value
    if (_markerText != "") then {
        _Money = parseNumber _markerText;
    };
    
    // Return current balance
    _Money
};

FLO_fnc_updateFunds = {
    params ["_amount"];
    
    // Find money marker
    private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
    if (count _mrkrs == 0) exitWith {
        diag_log "[FLO] ERROR: No money marker (Color2_FD_F) found on map";
        0
    };
    
    // Get marker and current money value
    private _mrkr = _mrkrs select 0;
    private _Money = 0;
    private _markerText = markerText _mrkr;
    
    // Try to parse current money value
    if (_markerText != "") then {
        _Money = parseNumber _markerText;
    };
    
    // Calculate new money value
    private _NewMoney = _Money + _amount;
    
    // Update marker text
    _mrkr setMarkerText str _NewMoney;
    
    // Return new balance
    _NewMoney
};

// Function to add purchase action to a FOB or OP
FLO_fnc_addCratePurchaseActions = {
    params ["_object"];
    
    // Remove any existing actions first
    {
        _object removeAction _x;
    } forEach (_object getVariable ["FLO_crateActions", []]);
    
    // Store actions to allow removal later
    private _actions = [];
    
    // Add main action
    private _mainAction = [_object, [
        "<img size=2 color='#FFE258' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\box_ca.paa' /><t font='PuristaBold' color='#FFA500'>Equipment Crates",
        {},
        [],
        1.5,
        true,
        true,
        "",
        "true",
        10
    ]] remoteExecCall ["addAction", 0, true];
    
    _actions pushBack _mainAction;
    
    // Add individual crate options as nested actions
    {
        _x params ["_id", "_name", "_cost", "_boxType", "_items", "_description"];
        
        private _crateAction =  [_object, [
            format [" - %1 (%2$)", _name, _cost],
            {
                params ["_target", "_caller", "_actionId", "_crateInfo"];
                
                // Execute purchase on server to ensure synchronization
                [_target, _caller, _crateInfo] remoteExec ["FLO_fnc_processCratePurchase", 2];
            },
            _x,
            1.4,
            false,
            true,
            "",
            "true",
            10
        ]] remoteExecCall ["addAction", 0, true];
        
        _actions pushBack _crateAction;
    } forEach FLO_availableCrates;
    
    // Store actions on the object
    _object setVariable ["FLO_crateActions", _actions, true];
};

// Add a new function to process crate purchase on the server
FLO_fnc_processCratePurchase = {
    if (!isServer) exitWith {};
    
    params ["_target", "_caller", "_crateInfo"];
    _crateInfo params ["_id", "_name", "_cost", "_boxType", "_items", "_description"];
    
    // Check if we have enough funds
    private _currentFunds = [] call FLO_fnc_getFunds;
    if (_currentFunds >= _cost) then {
        // Deduct cost
        private _newFunds = [0 - _cost] call FLO_fnc_updateFunds;
        
        // Create the crate near the player instead of the FOB
        private _playerPos = position _caller;
        // Find a safe position 2-4 meters in front of the player
        private _dir = getDir _caller;
        private _spawnPos = _playerPos vectorAdd [sin _dir * 3, cos _dir * 3, 0];
        private _safePos = _spawnPos findEmptyPosition [0, 5, _boxType];
        if (count _safePos == 0) then {
            _safePos = _spawnPos;
        };
        
        // Create the crate globally
        private _crate = createVehicle [_boxType, _safePos, [], 0, "NONE"];
        // Ensure crate is on the ground but not underground
        _crate setPos [_safePos select 0, _safePos select 1, 0.1];
        clearItemCargoGlobal _crate;
        clearWeaponCargoGlobal _crate;
        clearMagazineCargoGlobal _crate;
        clearBackpackCargoGlobal _crate;
        
        // Add items to the crate
        {
            _x params ["_item", "_count"];
            
            // Determine type of item and add accordingly
            if (isClass (configFile >> "CfgWeapons" >> _item)) then {
                _crate addWeaponCargoGlobal [_item, _count];
            } else {
                if (isClass (configFile >> "CfgMagazines" >> _item)) then {
                    _crate addMagazineCargoGlobal [_item, _count];
                } else {
                    if (isClass (configFile >> "CfgVehicles" >> _item)) then {
                        _crate addBackpackCargoGlobal [_item, _count];
                    } else {
                        _crate addItemCargoGlobal [_item, _count];
                    };
                };
            };
        } forEach _items;
        
        // Make the crate draggable for all players
        [_crate, true, [0, 2, 0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, true];
        
        // Personal notification to the buyer
        [format ["Purchased %1 for %2$\nFunds remaining: %3$", _name, _cost, _newFunds]] remoteExec ["hint", _caller];
    } else {
        // Only notify the buyer about insufficient funds
        [format ["Not enough funds to purchase %1.\nRequired: %2$\nAvailable: %3$", _name, _cost, _currentFunds]] remoteExec ["hint", _caller];
    };
};

// Function to initialize the crate system
FLO_fnc_initCrateSystem = {
    // Initialize on existing FOBs/OPs with JIP compatibility
    if (isServer) then {
        // Process all existing FOBs/OPs
        {
            if ((typeOf _x) in [F_HQ_01, F_OP_01]) then {
                // Add actions locally on server
                [_x] call FLO_fnc_addCratePurchaseActions;
                
                // Add actions on all clients with JIP flag (true)
                // [_x] remoteExec ["FLO_fnc_addCratePurchaseActions", 0, true];
            };
        } forEach (entities "All");
        
        // Add event handler for new FOBs/OPs
        addMissionEventHandler ["EntityCreated", {
            params ["_entity"];
            
            if ((typeOf _entity) in [F_HQ_01, F_OP_01]) then {
                // Wait a frame to let the object initialize
                [{
                    params ["_object"];
                    // Add purchase actions locally
                    [_object] call FLO_fnc_addCratePurchaseActions;
                    // Add purchase actions on all clients with JIP flag
                    // [_object] remoteExec ["FLO_fnc_addCratePurchaseActions", 0, true];
                }, [_entity], 0.1] call CBA_fnc_waitAndExecute;
            };
        }];
    };
    
    FLO_crates_initialized = true;
};

// Call initialization
[] call FLO_fnc_initCrateSystem;