/*
 * Function: FLO_fnc_virtualizationEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers CBA event handlers for virtualization system events.
 *   Allows other systems (GTN, AI Commander) to react to group changes.
 *
 * Events fired by the virtualization system:
 *   FLO_Virtualization_GroupAdded    - [groupId, groupData]
 *   FLO_Virtualization_GroupRemoved  - [groupId]
 *   FLO_Virtualization_GroupReserved - [groupId, missionType]
 *   FLO_Virtualization_GroupReleased - [groupId]
 *   FLO_Virtualization_GroupActivated   - [groupId, groupData, realGroup]
 *   FLO_Virtualization_GroupDeactivated - [groupId, groupData]
 *
 * Arguments:
 * 0: Mode <STRING> - "init" to register handlers, "cleanup" to remove them
 *
 * Return Value:
 * Boolean - Success
 *
 * Example:
 * ["init"] call FLO_fnc_virtualizationEvents;
 */

params [["_mode", "init", [""]]];

if (!isServer) exitWith { false };

switch (toLower _mode) do {

    case "init": {
        // Initialize event handler storage if needed
        if (isNil "FLO_VirtEventHandlers") then {
            FLO_VirtEventHandlers = createHashMap;
        };

        // ====================================================================
        // GROUP ADDED EVENT
        // Called when a new virtual group is created
        // ====================================================================
        private _addedHandler = ["FLO_Virtualization_GroupAdded", {
            params ["_groupId", "_groupData"];
            
            // Log for debugging
            ["VIRTUALIZATION_EVENTS", 4, format["Group added: %1", _groupId]] call FLO_fnc_log;
            
            // GTN can hook into this to track available groups
        }] call CBA_fnc_addEventHandler;
        FLO_VirtEventHandlers set ["groupAdded", _addedHandler];

        // ====================================================================
        // GROUP REMOVED EVENT
        // Called when a virtual group is eliminated or removed
        // ====================================================================
        private _removedHandler = ["FLO_Virtualization_GroupRemoved", {
            params ["_groupId"];
            
            ["VIRTUALIZATION_EVENTS", 4, format["Group removed: %1", _groupId]] call FLO_fnc_log;
            
            // GTN should release any tasks associated with this group
        }] call CBA_fnc_addEventHandler;
        FLO_VirtEventHandlers set ["groupRemoved", _removedHandler];

        // ====================================================================
        // GROUP RESERVED EVENT
        // Called when a group is reserved for a mission
        // ====================================================================
        private _reservedHandler = ["FLO_Virtualization_GroupReserved", {
            params ["_groupId", "_missionType"];
            
            ["VIRTUALIZATION_EVENTS", 4, format["Group reserved: %1 for %2", _groupId, _missionType]] call FLO_fnc_log;
        }] call CBA_fnc_addEventHandler;
        FLO_VirtEventHandlers set ["groupReserved", _reservedHandler];

        // ====================================================================
        // GROUP RELEASED EVENT
        // Called when a group is released from a mission
        // ====================================================================
        private _releasedHandler = ["FLO_Virtualization_GroupReleased", {
            params ["_groupId"];
            
            ["VIRTUALIZATION_EVENTS", 4, format["Group released: %1", _groupId]] call FLO_fnc_log;
        }] call CBA_fnc_addEventHandler;
        FLO_VirtEventHandlers set ["groupReleased", _releasedHandler];

        // ====================================================================
        // GROUP ACTIVATED EVENT
        // Called when a virtual group becomes real (spawned in world)
        // ====================================================================
        private _activatedHandler = ["FLO_Virtualization_GroupActivated", {
            params ["_groupId", "_groupData", "_realGroup"];
            
            ["VIRTUALIZATION_EVENTS", 4, format["Group activated: %1 (%2 units)", 
                _groupId, count units _realGroup]] call FLO_fnc_log;
            
            // GTN can assign tactical behaviors to newly spawned groups
        }] call CBA_fnc_addEventHandler;
        FLO_VirtEventHandlers set ["groupActivated", _activatedHandler];

        // ====================================================================
        // GROUP DEACTIVATED EVENT
        // Called when a real group becomes virtual again
        // ====================================================================
        private _deactivatedHandler = ["FLO_Virtualization_GroupDeactivated", {
            params ["_groupId", "_groupData"];
            
            ["VIRTUALIZATION_EVENTS", 4, format["Group deactivated: %1", _groupId]] call FLO_fnc_log;
        }] call CBA_fnc_addEventHandler;
        FLO_VirtEventHandlers set ["groupDeactivated", _deactivatedHandler];

        ["VIRTUALIZATION_EVENTS", 3, "Event handlers registered"] call FLO_fnc_log;
        true
    };

    case "cleanup": {
        if (!isNil "FLO_VirtEventHandlers") then {
            {
                [_x, _y] call CBA_fnc_removeEventHandler;
            } forEach FLO_VirtEventHandlers;
            
            FLO_VirtEventHandlers = nil;
        };
        
        ["VIRTUALIZATION_EVENTS", 3, "Event handlers removed"] call FLO_fnc_log;
        true
    };

    default { false };
};

