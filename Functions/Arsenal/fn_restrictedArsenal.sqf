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

["ARSENAL", 3, format ["Gear Harvested. Heavy/Restricted Items found: %1", count FLO_arsenal_heavyItems]] call FLO_fnc_log;

// Function to restrict an arsenal box
FLO_fnc_restrictArsenalBox = {
    params ["_box"];
    
    if (FLO_hasAceArsenal) then {
        [_box, true, true] call FLO_fnc_applyAceRestrictedArsenalCargo;
    } else {
        if !(_box getVariable ["FLO_VanillaRestrictedArsenalActionConfigured", false]) then {
            ["AmmoboxExit", _box] call BIS_fnc_arsenal;
            ["AmmoboxInit", [_box, false, { _this distance _target < 10 }]] call BIS_fnc_arsenal;
            _box setVariable ["FLO_VanillaRestrictedArsenalActionConfigured", true];
        };

        [_box] call FLO_fnc_applyVanillaRestrictedArsenalCargo;
    };
};

// Add event handlers based on which arsenal system is available
if (FLO_hasAceArsenal) then {
    // ACE Arsenal event handler
    ["ace_arsenal_displayOpened", {
        params ["_display"];
        private _box = ace_arsenal_currentBox;
        [{
            params ["_box"];
            [_box, false, false] call FLO_fnc_applyAceRestrictedArsenalCargo;
        }, [_box]] call CBA_fnc_execNextFrame;
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

// Apply restrictions to FOBs/OPs that already exist before this client finished init
private _existingArsenalTypes = [];
if (!isNil "F_HQ_01") then {
    _existingArsenalTypes pushBack F_HQ_01;
};
if (!isNil "F_OP_01") then {
    _existingArsenalTypes pushBack F_OP_01;
};

private _existingArsenalBoxes = [];
{
    _existingArsenalBoxes append (allMissionObjects _x);
} forEach _existingArsenalTypes;

{
    [_x] call FLO_fnc_restrictArsenalBox;
} forEach (_existingArsenalBoxes arrayIntersect _existingArsenalBoxes);

// Mark as initialized to prevent multiple executions
FLO_arsenal_initialized = true;
