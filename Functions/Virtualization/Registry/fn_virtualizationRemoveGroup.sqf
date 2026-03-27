/*
 * Function: FLO_fnc_virtualizationRemoveGroup
 */

params ["_virt", "_groupId"];

private _groups = _virt get "_groups";
private _groupData = _groups get _groupId;
if (isNil "_groupData") exitWith { false };

private _detachIndex = 0;

{
    private _otherId = _x;
    private _otherData = _y;
    if (_otherId == _groupId) then { continue };

    private _attachedTo = [_otherData] call FLO_fnc_virtualizationGetTransportAttachment;
    if (_attachedTo == _groupId) then {
        private _offsetDir = (_detachIndex * 45) mod 360;
        if ([_otherId, _offsetDir] call FLO_fnc_transportDetach) then {
            _detachIndex = _detachIndex + 1;
        } else {
            ["VIRTUALIZATION", 2, format [
                "Clearing stale transport attachment on %1 while removing carrier %2",
                _otherId,
                _groupId
            ]] call FLO_fnc_log;
            [_otherData] call FLO_fnc_virtualizationClearTransportAttachment;
            [_otherData] call FLO_fnc_virtualizationClearMountedIn;
            if ((_otherData get "missionLock") == "ORGANIC_PACKAGE") then {
                [_otherData] call FLO_fnc_virtualizationClearMissionLock;
            };
        };
    };

    if (([_otherData] call FLO_fnc_virtualizationGetMountedTransport) == _groupId) then {
        ["VIRTUALIZATION", 2, format [
            "Clearing stale mounted transport marker on %1 while removing carrier %2",
            _otherId,
            _groupId
        ]] call FLO_fnc_log;
        [_otherData] call FLO_fnc_virtualizationClearMountedIn;
    };

    private _attachedGroups = _otherData get "attachedGroups";
    if (_groupId in _attachedGroups) then {
        [_otherData, _groupId] call FLO_fnc_virtualizationRemoveTransportPassenger;
    };

    if ((_otherData get "organicPackageParentGroupId") == _groupId) then {
        _otherData set ["organicPackageParentGroupId", ""];
    };
} forEach _groups;

[_groupId] call FLO_fnc_virtualizationSpatialRemove;

if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
};

["cleanup", _groupId] call FLO_fnc_virtualizationDebugManager;
_groups deleteAt _groupId;
["FLO_Virtualization_GroupRemoved", [_groupId]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 4, format ["Removed group %1", _groupId]] call FLO_fnc_log;

true
