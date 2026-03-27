/*
 * Function: FLO_fnc_virtualizationAddGroup
 */

params ["_virt", "_groupId", "_groupData"];

private _pos = _groupData get "position";
if !([_pos, true, format ["virtualizationAddGroup %1", _groupId]] call FLO_fnc_validateGroupPosition) exitWith {
    false
};

(_virt get "_groups") set [_groupId, _groupData];
[_groupId, _pos, _groupData get "side"] call FLO_fnc_virtualizationSpatialAdd;

if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
};

["FLO_Virtualization_GroupAdded", [_groupId, _groupData]] call CBA_fnc_localEvent;

true
