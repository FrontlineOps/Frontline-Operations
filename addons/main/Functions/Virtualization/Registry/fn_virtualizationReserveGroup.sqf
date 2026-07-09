/*
 * Function: FLO_fnc_virtualizationReserveGroup
 */

params ["_virt", "_groupId", ["_missionType", "unknown"]];

private _groupData = (_virt get "_groups") get _groupId;
if (isNil "_groupData") exitWith { false };

[_groupData, "VIRTUALIZATION", _missionType] call FLO_fnc_virtualizationSetMissionLock;
[_groupData, "reserved"] call FLO_fnc_virtualizationSetRuntimeState;

if (
    (_groupData get "side") in [east, west]
    && {([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) == ""}
    && {[(_groupData get "groupType")] call FLO_fnc_gtnCombatIsSupportProvider}
) then {
    [false] call FLO_fnc_gtnCombatMarkClassificationDirty;
};

["FLO_Virtualization_GroupReserved", [_groupId, _missionType]] call CBA_fnc_localEvent;

true
