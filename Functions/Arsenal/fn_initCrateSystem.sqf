/*
    Function: FLO_fnc_initCrateSystem
    
    Description: Initializes the crate purchase system
    
    Parameter(s):
        None
        
    Returns:
        None
*/

// Only run on server
if (isServer) then {
    // Process existing FOBs/OPs
    {
        if ((typeOf _x) in [F_HQ_01, F_OP_01]) then {
            [_x] call FLO_fnc_addCratePurchaseActions;
        };
    } forEach (entities "All");
    
    // Monitor for new FOBs/OPs with JIP compatibility
    addMissionEventHandler ["EntityCreated", {
        params ["_entity"];
        
        if ((typeOf _entity) in [F_HQ_01, F_OP_01]) then {
            // Wait a frame to let the object initialize
            [{
                params ["_object"];
                [_object] call FLO_fnc_addCratePurchaseActions;
            }, [_entity], 0.1] call CBA_fnc_waitAndExecute;
        };
    }];
};

FLO_crates_initialized = true;
