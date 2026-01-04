/*
    Function: FLO_fnc_restrictedArsenal
    
    Description: Sets up global arsenal restrictions that apply to any arsenal opened in the mission
                Handles both ACE and vanilla arsenals, including FOBs and OPs
    
    Parameter(s):
        None
        
    Returns:
        None
*/
FLO_arsenal_initialized = false;

// Check if ACE Arsenal is available
FLO_hasAceArsenal = isClass (configFile >> "ace_arsenal_loadoutsDisplay");

// Weapons and attachments
private _rifles = [];

private _launchers = [];

private _attachments = [];

// Uniforms, vests, and headgear
private _uniforms = [];

private _vests = [];

private _headgear = [];

// Equipment and items
private _medicalItems = [];

private _toolItems = [];

private _navigationItems = [];

private _backpacks = [];

// Magazines and throwables
private _magazines = [];

private _grenades = [];

// Create global arrays for each category
FLO_arsenal_allowedItems = [];
FLO_arsenal_allowedItems append _rifles;
FLO_arsenal_allowedItems append _launchers;
FLO_arsenal_allowedItems append _attachments;
FLO_arsenal_allowedItems append _uniforms;
FLO_arsenal_allowedItems append _vests;
FLO_arsenal_allowedItems append _headgear;
FLO_arsenal_allowedItems append _navigationItems;
FLO_arsenal_allowedItems append _backpacks;
FLO_arsenal_allowedItems append _magazines;
FLO_arsenal_allowedItems append _grenades;
FLO_arsenal_allowedItems append _medicalItems;
FLO_arsenal_allowedItems append _toolItems;

// Dynamically harvest gear from player faction units
private _harvestedItems = [] call FLO_fnc_harvestFactionGear;

// Separate Heavy Weapons for the Crate System
FLO_arsenal_heavyItems = [];
private _regularItems = [];

{
    if ([_x] call FLO_fnc_isHeavyWeapon) then {
        FLO_arsenal_heavyItems pushBackUnique _x;
    } else {
        _regularItems pushBackUnique _x;
    };
} forEach _harvestedItems;

// Add only regular items to the personal arsenal
FLO_arsenal_allowedItems append _regularItems;

// Deduplicate list
FLO_arsenal_allowedItems = FLO_arsenal_allowedItems arrayIntersect FLO_arsenal_allowedItems;

// Function to restrict an arsenal box
FLO_fnc_restrictArsenalBox = {
    params ["_box"];
    
    if (FLO_hasAceArsenal) then {
        // Initialize ACE Arsenal first (this is key for FOBs/OPs)
        [_box, true] remoteExec ["ace_arsenal_fnc_initBox", 0];
        
        // Wait a frame to ensure initialization is complete
        [{
            params ["_box"];
            // Clear everything first
            [_box, true] call ace_arsenal_fnc_removeVirtualItems;
            // Add only our allowed items
            [_box, FLO_arsenal_allowedItems] call ace_arsenal_fnc_addVirtualItems;
        }, [_box], 0.1] call CBA_fnc_waitAndExecute;
    } else {
        // Clear and set up vanilla arsenal
        ["AmmoboxInit", [_box, false]] call BIS_fnc_arsenal;
        
        // Split items by type for vanilla arsenal
        private _weapons = FLO_arsenal_allowedItems select {_x isKindOf ["Rifle", configFile >> "CfgWeapons"] || 
                                                         _x isKindOf ["Launcher", configFile >> "CfgWeapons"] ||
                                                         _x isKindOf ["Pistol", configFile >> "CfgWeapons"]};
        private _items = FLO_arsenal_allowedItems select {_x isKindOf ["ItemCore", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["Equipment", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["Uniform_Base", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["VestItem", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["HeadgearItem", configFile >> "CfgWeapons"]};
        private _magazines = FLO_arsenal_allowedItems select {_x isKindOf ["CA_Magazine", configFile >> "CfgMagazines"]};
        private _backpacks = FLO_arsenal_allowedItems select {_x isKindOf ["Bag_Base", configFile >> "CfgVehicles"]};
        
        [_box, _weapons] call BIS_fnc_addVirtualWeaponCargo;
        [_box, _items] call BIS_fnc_addVirtualItemCargo;
        [_box, _magazines] call BIS_fnc_addVirtualMagazineCargo;
        [_box, _backpacks] call BIS_fnc_addVirtualBackpackCargo;
    };
};

// Add event handlers based on which arsenal system is available
if (FLO_hasAceArsenal) then {
    // ACE Arsenal event handler
    ["ace_arsenal_displayOpened", {
        params ["_display"];
        private _box = ace_arsenal_currentBox;
        [_box] call FLO_fnc_restrictArsenalBox;
    }] call CBA_fnc_addEventHandler;
} else {
    // Vanilla Arsenal event handler
    ["arsenalOpened", {
        params ["_display", "_box"];
        [_box] call FLO_fnc_restrictArsenalBox;
    }] call CBA_fnc_addEventHandler;
};

// Add event handler for object initialization to catch FOBs and OPs
addMissionEventHandler ["EntityCreated", {
    params ["_entity"];
    
    // Check if it's a FOB or OP
    if ((typeOf _entity) in [F_HQ_01, F_OP_01]) then {
        // Wait a frame to let the object initialize
        [{
            params ["_box"];
            [_box] call FLO_fnc_restrictArsenalBox;
        }, [_entity], 0.1] call CBA_fnc_waitAndExecute;
    };
}];

// Mark as initialized to prevent multiple executions
FLO_arsenal_initialized = true;