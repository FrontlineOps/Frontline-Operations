/*
 * Function: FLO_fnc_sideMissionTemplatesInit
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes and registers all side mission templates.
 *   Should be called during mission initialization before the manager starts.
 *
 * Arguments: None
 *
 * Returns:
 *   BOOL - True if all templates registered successfully
 *
 * Example:
 *   [] call FLO_fnc_sideMissionTemplatesInit;
 */

diag_log "[FLO_SM] Initializing side mission templates...";

private _success = true;

// Register all templates
private _templates = [
    // Rescue Missions
    ["pilotRescue", call FLO_fnc_templatePilotRescue],
    ["squadRescue", call FLO_fnc_templateSquadRescue],
    ["powRescue", call FLO_fnc_templatePOWRescue],
    
    // Convoy Missions
    ["convoyInterdiction", call FLO_fnc_templateConvoyInterdiction],
    ["hvtConvoy", call FLO_fnc_templateHVTConvoy],
    
    // Combat Missions
    ["patrolSweep", call FLO_fnc_templatePatrolSweep],
    ["intelGathering", call FLO_fnc_templateIntelGathering]
];

{
    _x params ["_typeName", "_template"];
    
    if (isNil "_template") then {
        diag_log format ["[FLO_SM] ERROR: Template %1 returned nil!", _typeName];
        _success = false;
    } else {
        private _registered = ["register", [_typeName, _template]] call FLO_fnc_sideMissionTemplate;
        if (_registered) then {
            diag_log format ["[FLO_SM] Registered template: %1", _typeName];
        } else {
            diag_log format ["[FLO_SM] WARNING: Failed to register template: %1", _typeName];
            _success = false;
        };
    };
} forEach _templates;

// Log summary
private _registeredCount = count (keys FLO_SM_Templates);
diag_log format ["[FLO_SM] Template initialization complete. %1 templates registered.", _registeredCount];

_success

