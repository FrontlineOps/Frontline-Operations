/*
 * Function: FLO_fnc_initializeObjectiveGroups
 * Author: Frontline Operations Development Group
 * Description:
 * Creates virtual groups for all objectives based on their type.
 * Spawns appropriate units for each objective according to CUSTOM_ENEMY_FACTION.sqf settings.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * [] call FLO_fnc_initializeObjectiveGroups;
 */

// Ensure we're running on the server
if (!isServer) exitWith {false};

// Ensure virtualization system is initialized
if (isNil "FLO_virtualGroups") then {
    [2000] call FLO_fnc_initVirtualization;
};

// Ensure initializationOG is set to false
// for Dialog_Faction_Done.sqf to use
InitializationOG = false;
publicVariable "InitializationOG";

["VIRTUALIZATION", 3, "Initializing objective groups"] call FLO_fnc_log;

// Define mapping of objective types to group configurations
private _objectiveGroupConfig = createHashMapFromArray [
    // Support objectives - mix of infantry and light vehicles
    ["o_support", [
        ["infantry", 3], 
        ["motorized", 2]
    ]],
    
    ["n_support", [
        ["infantry", 2], 
        ["motorized", 1]
    ]],
    
    // Installation objectives - mix of infantry and heavy vehicles
    ["o_installation", [
        ["infantry", 4], 
        ["mechanized", 2],
        ["armor", 1]
    ]],
    
    ["n_installation", [
        ["infantry", 3], 
        ["mechanized", 1]
    ]],
    
    // Anti-air objectives - AA vehicles and infantry
    ["o_antiair", [
        ["infantry", 2],
        ["motorized", 1],
        ["air", 1]
    ]],
    
    // Service objectives - light vehicles and infantry
    ["o_service", [
        ["infantry", 2],
        ["motorized", 2]
    ]],
    
    // Power plant objectives - infantry defense
    ["loc_Power", [
        ["infantry", 3],
        ["motorized", 1]
    ]],
    
    // Ruins objectives - light infantry presence
    ["loc_Ruin", [
        ["infantry", 1]
    ]],
    
    // Recon objectives - small infantry and light vehicles
    ["o_recon", [
        ["infantry", 2],
        ["motorized", 1],
        ["helicopter", 1]
    ]],
    
    // Infantry objectives - heavier infantry presence
    ["o_inf", [
        ["infantry", 4],
        ["motorized", 1]
    ]]
];

// Track all created groups
private _allCreatedGroups = [];

// Get all markers
private _allMarkers = allMapMarkers;

// Process each marker that could be an objective
{
    private _marker = _x;
    private _markerType = getMarkerType _marker;
    private _position = getMarkerPos _marker;
    
    // Check if this marker type is defined in our configuration
    if (_objectiveGroupConfig getOrDefault [_markerType, []] isNotEqualTo []) then {
        ["VIRTUALIZATION", 3, format["Processing objective: %1 (Type: %2)", _marker, _markerType]] call FLO_fnc_log;
        
        // Get group configuration for this objective type
        private _groupsToCreate = _objectiveGroupConfig get _markerType;
        private _objectiveGroups = [];
        
        // Create virtual groups for this objective using distribution
        {
            _x params ["_groupType", "_count"];
            
            // Distribute the groups around the objective
            private _createdGroups = [_marker, _groupType, _count] call FLO_fnc_distributeVirtualGroups;
            _objectiveGroups append _createdGroups;
        } forEach _groupsToCreate;
        
        // Add all created groups to tracking array
        _allCreatedGroups append _objectiveGroups;
        
        ["VIRTUALIZATION", 3, format["Created %1 virtual groups at objective %2", count _objectiveGroups, _marker]] call FLO_fnc_log;
    };
} forEach _allMarkers;

["VIRTUALIZATION", 3, format["Finished initializing objective groups - %1 total groups created", count _allCreatedGroups]] call FLO_fnc_log;

InitializationOG = true;
publicVariable "InitializationOG";