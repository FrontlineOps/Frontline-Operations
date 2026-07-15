/*
 * Function: FLO_fnc_gtnCombatRegisterVirtualizationEvents
 * Description:
 *   Adapts virtualization registry events into GTN combat cache invalidation.
 *   This keeps the registry independent from GTN implementation state.
 */

if (!isServer) exitWith { false };
if (!isNil "FLO_GTN_CombatVirtualizationHandlers") exitWith { true };

private _handlers = createHashMap;
_handlers set ["FLO_Virtualization_GroupAdded", ["FLO_Virtualization_GroupAdded", {
    params ["_groupId", "_groupData"];
    if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
        [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
    };
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupRemoved", ["FLO_Virtualization_GroupRemoved", {
    params ["_groupId", "_groupData"];
    if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
        [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
    };
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupPositionChanged", ["FLO_Virtualization_GroupPositionChanged", {
    params ["_groupId"];
    private _groupData = [_groupId] call FLO_fnc_virtualizationFindGroupSnapshot;
    if !(isNil "_groupData") then {
        if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
            [false] call FLO_fnc_gtnCombatMarkClassificationDirty;
        };
    };
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupPatched", ["FLO_Virtualization_GroupPatched", {
    params ["_groupId", "_fields"];
    private _classificationFields = [
        "unitCount",
        "groupType",
        "side",
        "isActive",
        "missionLock",
        "transportRole",
        "replacementState",
        "comp",
        "vehicleType"
    ];
    if ((_fields arrayIntersect _classificationFields) isNotEqualTo []) then {
        private _groupData = [_groupId] call FLO_fnc_virtualizationFindGroupSnapshot;
        if !(isNil "_groupData") then {
            private _groupType = _groupData get "groupType";
            if (
                (_groupData get "side") in [east, west]
                && {
                    [_groupType] call FLO_fnc_gtnCombatIsDirectCombatGroup
                    || {[_groupType] call FLO_fnc_gtnCombatIsSupportProvider}
                }
            ) then {
                [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
            };
        };
    };
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupActivated", ["FLO_Virtualization_GroupActivated", {
    params ["_groupId", "_groupData", "_realGroup"];
    if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
        [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
    };
    [_groupId, _realGroup] call FLO_fnc_gtnCombatApplyGroupSkills;
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_GroupDeactivated", ["FLO_Virtualization_GroupDeactivated", {
    params ["_groupId", "_groupData"];
    if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
        [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
    };
}] call CBA_fnc_addEventHandler];

_handlers set ["FLO_Virtualization_TransportRelationshipChanged", ["FLO_Virtualization_TransportRelationshipChanged", {
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
}] call CBA_fnc_addEventHandler];

FLO_GTN_CombatVirtualizationHandlers = _handlers;
true
