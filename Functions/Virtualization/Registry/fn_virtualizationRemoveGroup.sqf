/*
 * Function: FLO_fnc_virtualizationRemoveGroup
 */

params ["_virt", "_groupId"];

private _groups = _virt get "_groups";
private _groupData = _groups get _groupId;
if (isNil "_groupData") exitWith { false };

[_groupId] call FLO_fnc_virtualizationSpatialRemove;

if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
};

["cleanup", _groupId] call FLO_fnc_virtualizationDebugManager;
_groups deleteAt _groupId;
["FLO_Virtualization_GroupRemoved", [_groupId]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 4, format ["Removed group %1", _groupId]] call FLO_fnc_log;

true
