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
InitializationOG = false;
publicVariable "InitializationOG";

["VIRTUALIZATION", 3, "Initializing objective groups"] call FLO_fnc_log;

// Load objective group configuration directly from the faction settings
private _objectiveGroupConfig = createHashMapFromArray OPFOR_Objective_Groups;

// Track all created groups
private _allCreatedGroups = [];
private _allObjectives = keys FLO_Objectives;

// Process each indexed objective
{
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;
    private _subtype = _objData get "subtype";

    // Check if this subtype is defined in our configuration
    if (_subtype in _objectiveGroupConfig) then {
        ["VIRTUALIZATION", 3, format["Processing objective: %1 (Subtype: %2)", _objId, _subtype]] call FLO_fnc_log;

        // Get group configuration for this objective subtype
        private _groupsToCreate = _objectiveGroupConfig get _subtype;
        private _objectiveGroups = [];

        // Create virtual groups for this objective using distribution
        {
            _x params ["_groupType", "_count"];

            // Distribute the groups around the objective
            private _createdGroups = [_objId, _groupType, _count] call FLO_fnc_distributeVirtualGroups;
            _objectiveGroups append _createdGroups;
        } forEach _groupsToCreate;

        // Add all created groups to tracking array
        _allCreatedGroups append _objectiveGroups;

        // === STATIC AA: Always spawn immediately (bypass virtualization distance) ===
        {
            private _groupId = _x;
            private _groupData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, nil];
            if (!isNil "_groupData" && {(_groupData get "groupType") == "static_aa"}) then {
                [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
                _groupData set ["alwaysActive", true]; // Prevent deactivation
                ["VIRTUALIZATION", 3, format["Static AA %1 activated immediately (always-on)", _groupId]] call FLO_fnc_log;
            };
        } forEach _objectiveGroups;

        ["VIRTUALIZATION", 3, format["Created %1 virtual groups at objective %2", count _objectiveGroups, _objId]] call FLO_fnc_log;
    };
} forEach _allObjectives;

// After processing objectives, add civilian population to locations
[] call FLO_fnc_createVirtualCivilianPopulation;

["VIRTUALIZATION", 3, format["Finished initializing objective groups - %1 total groups created", count _allCreatedGroups]] call FLO_fnc_log;

InitializationOG = true;
publicVariable "InitializationOG";