/*
 * Function: FLO_fnc_virtualizationRollbackOrganicPackageCreation
 */

params [
    ["_carrierData", createHashMap, [createHashMap]],
    ["_createdGroupIds", [], [[]]],
    ["_previousRole", "", [""]],
    ["_previousParentGroupId", "", [""]]
];

{
    [FLO_virtualGroups, _x] call FLO_fnc_virtualizationRemoveGroup;
} forEach _createdGroupIds;

_carrierData set ["organicPackageRole", _previousRole];
_carrierData set ["organicPackageParentGroupId", _previousParentGroupId];

true
