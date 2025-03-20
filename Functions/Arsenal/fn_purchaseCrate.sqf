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
        
        // Create the crate high above the player for placement
        private _playerPos = getPosATL _caller;
        private _pos = [_playerPos select 0, _playerPos select 1, (_playerPos select 2) + 1000];
        private _crate = createVehicle [_boxType, _pos, [], 0, "NONE"];
        _crate allowDamage false;
        
        // Setup placement mode
        [_crate, _caller, _id, _name, _cost, _boxType, _items, _description, _newFunds] remoteExec ["FLO_fnc_initCratePlacement", owner _caller];
        
    } else {
        // Only notify the buyer about insufficient funds
        [format ["Not enough funds to purchase %1.\nRequired: %2$\nAvailable: %3$", _name, _cost, _currentFunds]] remoteExec ["hint", _caller];
    };
};

// Function to handle crate placement (runs on player's machine)
FLO_fnc_initCratePlacement = {
    params ["_crate", "_player", "_id", "_name", "_cost", "_boxType", "_items", "_description", "_newFunds"];
    
    // Setup placement mode
    missionNamespace setVariable ["FLO_CratePlacementActive", true];
    _crate enableSimulation false;
    
    // Use CBA perFrameHandler for smoother updates
    private _pfhID = [{
        params ["_args", "_pfhID"];
        _args params ["_crate"];
        
        // Check if placement mode is still active
        if !(missionNamespace getVariable ["FLO_CratePlacementActive", false]) exitWith {
            [_pfhID] call CBA_fnc_removePerFrameHandler;
        };
        
        // Update position every frame for smooth movement
        _crate setVehiclePosition [screenToWorld [0.5, 0.5], [], 0, "CAN_COLLIDE"];
        _crate setDir ((getDirVisual player) + 180);
        
    }, 0, [_crate]] call CBA_fnc_addPerFrameHandler;
    
    // Add cancel action
    private _cancelAction = [_crate,
        "<t color='#FF0000'>CANCEL</t>",
        '\A3\ui_f\data\IGUI\Cfg\Actions\reammo_ca.paa',
        '\A3\ui_f\data\IGUI\Cfg\Actions\reammo_ca.paa',
        'true',
        'true',
        {},
        {},
        {
            params ["_target", "_caller", "_actionId", "_args"];
            _args params ["_crate", "_player", "_id", "_name", "_cost", "_boxType", "_items", "_description", "_newFunds", "_pfhID"];
            
            // End placement mode
            missionNamespace setVariable ["FLO_CratePlacementActive", false];
            
            // Remove keyboard event handler if it exists
            private _keyHandlerId = _crate getVariable ["FLO_keyHandler", -1];
            if (_keyHandlerId != -1) then {
                (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyHandlerId];
            };
            
            // Refund cost
            [_cost] remoteExec ["FLO_fnc_updateFunds", 2];
            
            // Remove the holdActions (to be safe, though the crate will be deleted)
            private _cancelActionId = _crate getVariable ["FLO_cancelActionId", -1];
            private _placeActionId = _crate getVariable ["FLO_placeActionId", -1];
            
            if (_cancelActionId != -1) then {
                [_crate, _cancelActionId] call BIS_fnc_holdActionRemove;
            };
            
            if (_placeActionId != -1) then {
                [_crate, _placeActionId] call BIS_fnc_holdActionRemove;
            };
            
            // Delete the crate
            deleteVehicle _crate;
            
            // Notify the player
            hint format ["Cancelled purchase of %1.\nRefunded %2$.", _name, _cost];
        },
        {},
        [_crate, _player, _id, _name, _cost, _boxType, _items, _description, _newFunds, _pfhID],
        3,
        0,
        false,
        false
    ] call BIS_fnc_holdActionAdd;
    
    // Store the action ID for later removal
    _crate setVariable ["FLO_cancelActionId", _cancelAction, false];
    
    // Add place action
    private _placeAction = [_crate,
        "<t color='#00FF00'>PLACE</t>",
        '\A3\ui_f\data\IGUI\Cfg\Actions\reammo_ca.paa',
        '\A3\ui_f\data\IGUI\Cfg\Actions\reammo_ca.paa',
        'true',
        'true',
        {},
        {},
        {
            params ["_target", "_caller", "_actionId", "_args"];
            _args params ["_crate", "_player", "_id", "_name", "_cost", "_boxType", "_items", "_description", "_newFunds", "_pfhID"];
            
            // End placement mode
            missionNamespace setVariable ["FLO_CratePlacementActive", false];
            
            // Remove keyboard event handler if it exists
            private _keyHandlerId = _crate getVariable ["FLO_keyHandler", -1];
            if (_keyHandlerId != -1) then {
                (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyHandlerId];
            };
            
            // Enable simulation and physics
            _crate enableSimulation true;
            _crate allowDamage true;
            
            // Fill the crate with items (server-side)
            [_crate, _items] remoteExec ["FLO_fnc_fillCrate", 2];
            
            // Make it draggable
            [_crate, true, [0, 2, 0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, true];
            
            // Remove the holdActions
            private _cancelActionId = _crate getVariable ["FLO_cancelActionId", -1];
            private _placeActionId = _crate getVariable ["FLO_placeActionId", -1];
            
            if (_cancelActionId != -1) then {
                [_crate, _cancelActionId] call BIS_fnc_holdActionRemove;
            };
            
            if (_placeActionId != -1) then {
                [_crate, _placeActionId] call BIS_fnc_holdActionRemove;
            };
            
            // Notify the player
            hint format ["Purchased %1 for %2$\nFunds remaining: %3$", _name, _cost, _newFunds];
        },
        {},
        [_crate, _player, _id, _name, _cost, _boxType, _items, _description, _newFunds, _pfhID],
        3,
        0,
        false,
        false
    ] call BIS_fnc_holdActionAdd;
    
    // Store the action ID for later removal
    _crate setVariable ["FLO_placeActionId", _placeAction, false];
    
    // Add keyboard event handler for quick actions
    private _keyHandler = (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_display", "_key", "_shift", "_ctrl", "_alt"];
        
        // Check if placement mode is active
        if !(missionNamespace getVariable ["FLO_CratePlacementActive", false]) exitWith {false};
        
        // Handle ESC key to cancel placement
        if (_key == 1) then {
            private _crate = missionNamespace getVariable ["FLO_ActivePlacementCrate", objNull];
            if (!isNull _crate) then {
                // End placement mode
                missionNamespace setVariable ["FLO_CratePlacementActive", false];
                
                // Remove the holdActions
                private _cancelActionId = _crate getVariable ["FLO_cancelActionId", -1];
                private _placeActionId = _crate getVariable ["FLO_placeActionId", -1];
                
                if (_cancelActionId != -1) then {
                    [_crate, _cancelActionId] call BIS_fnc_holdActionRemove;
                };
                
                if (_placeActionId != -1) then {
                    [_crate, _placeActionId] call BIS_fnc_holdActionRemove;
                };
                
                // Remove keyboard event handler
                private _keyHandlerId = _crate getVariable ["FLO_keyHandler", -1];
                if (_keyHandlerId != -1) then {
                    (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyHandlerId];
                };
                
                // Refund the cost
                [_crate getVariable ["FLO_cost", 0]] remoteExec ["FLO_fnc_updateFunds", 2];
                
                // Delete the crate
                deleteVehicle _crate;
                hint "Purchase cancelled. Funds refunded.";
            };
            true
        } else {
            false
        };
    }];
    
    // Store values for later cleanup
    _crate setVariable ["FLO_keyHandler", _keyHandler, false];
    _crate setVariable ["FLO_cost", _cost, false];
    missionNamespace setVariable ["FLO_ActivePlacementCrate", _crate];
    
    // Notify player about placement mode
    hint format ["Positioning %1...\nUse the PLACE action when satisfied with the position.\nUse CANCEL or ESC to cancel and get a refund.", _name];
};

// Function to fill a crate with items (server-side)
FLO_fnc_fillCrate = {
    if (!isServer) exitWith {};
    
    params ["_crate", "_items"];
    
    // Clear the crate
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