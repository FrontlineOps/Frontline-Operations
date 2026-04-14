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
        if (!isNil "FLO_VirtEventHandlers" && {count FLO_VirtEventHandlers > 0}) exitWith {
            ["VIRTUALIZATION_EVENTS", 3, "Event handlers already registered"] call FLO_fnc_log;
            true
        };

        FLO_VirtEventHandlers = call FLO_fnc_virtualizationCreateEventHandlerState;
        [FLO_VirtEventHandlers] call FLO_fnc_virtualizationRegisterEventHandlers;

        ["VIRTUALIZATION_EVENTS", 3, "Event handlers registered"] call FLO_fnc_log;
        true
    };

    case "cleanup": {
        if (isNil "FLO_VirtEventHandlers") exitWith { true };

        [FLO_VirtEventHandlers] call FLO_fnc_virtualizationRemoveEventHandlers;
        FLO_VirtEventHandlers = nil;
        
        ["VIRTUALIZATION_EVENTS", 3, "Event handlers removed"] call FLO_fnc_log;
        true
    };

    default { false };
};

