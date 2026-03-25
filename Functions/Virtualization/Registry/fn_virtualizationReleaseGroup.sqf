/*
 * Function: FLO_fnc_virtualizationReleaseGroup
 */

params ["_virt", "_groupId"];

private _groupData = (_virt get "_groups") get _groupId;
if (isNil "_groupData") exitWith { false };

[_groupData] call FLO_fnc_virtualizationClearMissionLock;
[_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;

if (
    (_groupData get "side") in [east, west]
    && {([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) == ""}
    && {[(_groupData get "groupType")] call FLO_fnc_gtnCombatIsSupportProvider}
) then {
    [false] call FLO_fnc_gtnCombatMarkClassificationDirty;
};

["FLO_Virtualization_GroupReleased", [_groupId]] call CBA_fnc_localEvent;

true
