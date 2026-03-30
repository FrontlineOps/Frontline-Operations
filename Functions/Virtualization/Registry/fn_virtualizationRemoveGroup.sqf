/*
 * Function: FLO_fnc_virtualizationRemoveGroup
 */

params ["_virt", "_groupId"];

private _groups = _virt get "_groups";
private _groupData = _groups get _groupId;
if (isNil "_groupData") exitWith { false };
private _availableTransports = FLO_TransportPool get "available";
private _activeTransports = FLO_TransportPool get "active";

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
            if ((_otherData get "missionLock") in ["ORGANIC_PACKAGE", "TRANSPORT"]) then {
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

        if (count ([_otherData] call FLO_fnc_virtualizationGetTransportPassengers) == 0) then {
            if ((_otherData get "dismountAtWaypoint") >= 0 || {(_otherData get "transportInsertMode") != ""}) then {
                ["TRANSPORT", 3, format [
                    "Clearing transport task state on %1 after passenger %2 was removed",
                    _otherId,
                    _groupId
                ]] call FLO_fnc_log;
                [_otherData] call FLO_fnc_transportClearInsertState;
            };

            if (_otherId in _activeTransports) then {
                [_otherId] call FLO_fnc_transportPoolRelease;
            };
        };
    };

    if ((_otherData get "organicPackageParentGroupId") == _groupId) then {
        _otherData set ["organicPackageParentGroupId", ""];
    };
} forEach _groups;

private _removedFromTransportPool = false;
if (_groupId in _availableTransports) then {
    _availableTransports deleteAt _groupId;
    _removedFromTransportPool = true;
};
if (_groupId in _activeTransports) then {
    _activeTransports deleteAt _groupId;
    _removedFromTransportPool = true;
};
if (_removedFromTransportPool) then {
    ["TRANSPORT", 3, format [
        "Pool: Removed deleted transport %1 from pool state",
        _groupId
    ]] call FLO_fnc_log;
};

[_groupId] call FLO_fnc_virtualizationSpatialRemove;

if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
};

["cleanup", _groupId] call FLO_fnc_virtualizationDebugManager;
_groups deleteAt _groupId;
["FLO_Virtualization_GroupRemoved", [_groupId]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 4, format ["Removed group %1", _groupId]] call FLO_fnc_log;

true
