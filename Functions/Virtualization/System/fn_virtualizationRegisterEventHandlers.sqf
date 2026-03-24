/*
 * Function: FLO_fnc_virtualizationRegisterEventHandlers
 */

params ["_handlers"];

_handlers set ["FLO_Virtualization_GroupAdded", ["FLO_Virtualization_GroupAdded", {
    params ["_groupId", "_groupData"];
    ["VIRTUALIZATION_EVENTS", 4, format ["Group added: %1", _groupId]] call FLO_fnc_log;
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupRemoved", ["FLO_Virtualization_GroupRemoved", {
    params ["_groupId"];
    ["VIRTUALIZATION_EVENTS", 4, format ["Group removed: %1", _groupId]] call FLO_fnc_log;
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupReserved", ["FLO_Virtualization_GroupReserved", {
    params ["_groupId", "_missionType"];
    ["VIRTUALIZATION_EVENTS", 4, format ["Group reserved: %1 for %2", _groupId, _missionType]] call FLO_fnc_log;
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupReleased", ["FLO_Virtualization_GroupReleased", {
    params ["_groupId"];
    ["VIRTUALIZATION_EVENTS", 4, format ["Group released: %1", _groupId]] call FLO_fnc_log;
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupActivated", ["FLO_Virtualization_GroupActivated", {
    params ["_groupId", "_groupData", "_realGroup"];
    ["VIRTUALIZATION_EVENTS", 4, format ["Group activated: %1 (%2 units)", _groupId, count units _realGroup]] call FLO_fnc_log;
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupDeactivated", ["FLO_Virtualization_GroupDeactivated", {
    params ["_groupId", "_groupData"];
    ["VIRTUALIZATION_EVENTS", 4, format ["Group deactivated: %1", _groupId]] call FLO_fnc_log;
}] call CBA_fnc_addEventHandler];

_handlers
