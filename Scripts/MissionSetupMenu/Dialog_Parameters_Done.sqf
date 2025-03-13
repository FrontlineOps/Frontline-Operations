/*
    File: Dialog_Parameters_Done.sqf
    Author: [Your Name]
    Description:
    Handles the saving of mission parameters when the APPLY PARAMETERS button is clicked
*/

// Get values from the dialog
private _autoSaveSwitchIndex = lbCurSel 1970;
private _autoSaveIntervalIndex = lbCurSel 1971;
private _missionSaveIndex = lbCurSel 1972;
private _restrictedArsenalIndex = lbCurSel 1973;

// Map dropdowns to parameter values
private _autoSaveSwitchValues = [1, 0]; // Activate, DeActivate
private _autoSaveIntervalValues = [300, 600, 1200]; // 5 min, 10 min, 20 min
private _missionSaveValues = [0, 1]; // Load, Reset
private _restrictedArsenalValues = [0, 1]; // Enable, Disable

// Get the actual parameter values based on selected indices
private _autoSaveSwitch = _autoSaveSwitchValues select _autoSaveSwitchIndex;
private _autoSaveInterval = _autoSaveIntervalValues select _autoSaveIntervalIndex;
private _missionSave = _missionSaveValues select _missionSaveIndex;
private _restrictedArsenal = _restrictedArsenalValues select _restrictedArsenalIndex;

// Store values in mission namespace (can be accessed globally)
missionNamespace setVariable ["FLO_AutoSaveSwitch", _autoSaveSwitch, true];
missionNamespace setVariable ["FLO_AutoSaveInterval", _autoSaveInterval, true];
missionNamespace setVariable ["FLO_FreshStart", _missionSave, true];
missionNamespace setVariable ["FLO_RestrictedArsenal", _restrictedArsenal, true];

// Apply parameters immediately
if (isServer) then {
    // Apply parameters on server
    // These would need to be implemented based on how your mission uses these parameters
    
    // Example: Start or stop autosave based on selection
    if (_autoSaveSwitch == 1) then {
        // Enable autosave functionality
        if (!isNil "FLO_AutoSaveHandle") then {
            // If autosave is already running, stop it to update the interval
            [FLO_AutoSaveHandle] call CBA_fnc_removePerFrameHandler;
        };
        
        // Start autosave with new interval
        FLO_AutoSaveHandle = [{ 
            // Autosave code here
            systemChat "Game Autosaved";
            // Add actual save code here 
        }, _autoSaveInterval] call CBA_fnc_addPerFrameHandler;
    } else {
        // Disable autosave functionality
        if (!isNil "FLO_AutoSaveHandle") then {
            [FLO_AutoSaveHandle] call CBA_fnc_removePerFrameHandler;
            FLO_AutoSaveHandle = nil;
        };
    };
    
    // Apply restricted arsenal setting
    // This would need to be implemented based on how your arsenal restriction works
    
    // Apply mission save management
    if (_missionSave == 1) then {
        // Reset mission progress code
        // This would need to be implemented based on your save system
    };
};

// Inform player of changes
hint "Mission parameters applied successfully!";

// Close the dialog
closeDialog 0; 