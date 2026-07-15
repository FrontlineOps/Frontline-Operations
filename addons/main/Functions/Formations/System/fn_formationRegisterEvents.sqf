/* Registers formation lifecycle integration once on the server. */
if (!isServer) exitWith { false };
if (!isNil "FLO_FormationEventHandlers" && {(keys FLO_FormationEventHandlers) isNotEqualTo []}) exitWith { true };

FLO_FormationEventHandlers = createHashMap;
FLO_FormationEventHandlers set ["added", ["FLO_Virtualization_GroupAdded", {
    FLO_FormationReconcileDirty = true;
}] call CBA_fnc_addEventHandler];
FLO_FormationEventHandlers set ["removed", ["FLO_Virtualization_GroupRemoved", {
    FLO_FormationReconcileDirty = true;
}] call CBA_fnc_addEventHandler];
FLO_FormationEventHandlers set ["patched", ["FLO_Virtualization_GroupPatched", {
    FLO_FormationReconcileDirty = true;
}] call CBA_fnc_addEventHandler];
FLO_FormationEventHandlers set ["activated", ["FLO_Virtualization_GroupActivated", {
    params ["_groupId", "_snapshot", "_realGroup"];
    [_groupId, _realGroup] call FLO_fnc_formationApplyRealGroupSkills;
}] call CBA_fnc_addEventHandler];
FLO_FormationEventHandlers set ["combat", ["FLO_GTN_VirtualCombatResolved", {
    params ["_event", "_eastGroupIds", "_westGroupIds"];
    [_event, _eastGroupIds, _westGroupIds] call FLO_fnc_formationRecordCombat;
}] call CBA_fnc_addEventHandler];
FLO_FormationEventHandlers set ["operation", ["FLO_Campaign_OperationChanged", {
    params ["_revision", "_operationId", "_phase"];
    if (_phase == "ASSAULT" && {_operationId != ""}) then {
        [FLO_FormationDirector, _operationId] call FLO_fnc_formationStartFeint;
    };
    if (_phase == "SECURE" && {_operationId != ""}) then {
        [FLO_FormationState, FLO_FormationDirector] call FLO_fnc_formationProcessRoles;
        [FLO_FormationDirector, _operationId] call FLO_fnc_formationStartExploitation;
    };
    if (_phase == "PROBING" && {_operationId == ""}) then {
        [FLO_FormationState, "WEST"] call FLO_fnc_formationSelectDoctrine;
        [FLO_FormationState, "EAST"] call FLO_fnc_formationSelectDoctrine;
    };
}] call CBA_fnc_addEventHandler];
true
