/*
 * Function: FLO_fnc_virtualizationRollbackOrganicPackageCreation
 */

params [
    ["_carrierGroupId", "", [""]],
    ["_createdGroupIds", [], [[]]],
    ["_previousRole", "", [""]],
    ["_previousParentGroupId", "", [""]]
];

{
    [_x] call FLO_fnc_virtualizationRemoveGroup;
} forEach _createdGroupIds;

[_carrierGroupId, createHashMapFromArray [
    ["organicPackageRole", _previousRole],
    ["organicPackageParentGroupId", _previousParentGroupId]
]] call FLO_fnc_virtualizationPatchGroup;

true
