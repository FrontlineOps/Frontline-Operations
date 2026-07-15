/*
 * Function: FLO_fnc_virtualizationRemoveGroup
 */

params [
    ["_groupId", "", [""]],
    ["_catastrophicPassengerLoss", false, [false]],
    ["_emitCatastrophicLog", true, [true]]
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _groupData = _groups get _groupId;
if (isNil "_groupData") exitWith { false };
private _directPassengerIds = +(_groupData get "attachedGroups");
private _catastrophicManifest = [];
private _catastrophicPassengerUnits = 0;
if (_catastrophicPassengerLoss) then {
    if (_groupData get "isActive") then {
        private _message = format ["Catastrophic virtual carrier removal received active group %1", _groupId];
        ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
        throw _message;
    };

    _catastrophicManifest = [_groupId] call FLO_fnc_virtualizationCollectTransportManifest;
    {
        private _passengerData = _groups get _x;
        if (_passengerData get "isActive") then {
            private _message = format [
                "Catastrophic virtual carrier removal %1 contains active passenger %2",
                _groupId,
                _x
            ];
            ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
            throw _message;
        };
        _catastrophicPassengerUnits = _catastrophicPassengerUnits + (_passengerData get "unitCount");
    } forEach _catastrophicManifest;
};
private _availableTransports = FLO_TransportPool get "available";
private _activeTransports = FLO_TransportPool get "active";

private _detachIndex = 0;

{
    private _otherId = _x;
    private _otherData = _y;
    if (_otherId == _groupId) then { continue };

    private _attachedTo = [_otherData] call FLO_fnc_virtualizationGetTransportAttachment;
    if (_attachedTo == _groupId) then {
        if (_catastrophicPassengerLoss) then { continue };
        private _offsetDir = (_detachIndex * 45) mod 360;
        if ([_otherId, _offsetDir] call FLO_fnc_transportDetach) then {
            _detachIndex = _detachIndex + 1;
            [_otherId, "CARRIER_REMOVAL"] call FLO_fnc_transportApplyPostDismountWaypoint;
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

        if (([_otherData] call FLO_fnc_virtualizationGetTransportPassengers) isEqualTo []) then {
            if ((_otherData get "dismountAtWaypoint") >= 0 || {(_otherData get "transportInsertMode") != ""}) then {
                ["TRANSPORT", 3, format [
                    "Clearing transport task state on %1 after passenger %2 was removed",
                    _otherId,
                    _groupId
                ]] call FLO_fnc_log;
                [_otherId] call FLO_fnc_transportClearInsertState;
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
private _removedSnapshot = [_groupId] call FLO_fnc_virtualizationSnapshotGroup;

["cleanup", _groupId] call FLO_fnc_virtualizationDebugManager;
_groups deleteAt _groupId;
call FLO_fnc_virtualizationTouchRegistry;

if (_catastrophicPassengerLoss) then {
    {
        if !([_x, true, false] call FLO_fnc_virtualizationRemoveGroup) then {
            private _message = format [
                "Catastrophic carrier removal %1 could not remove passenger %2 after successful preflight",
                _groupId,
                _x
            ];
            ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
            throw _message;
        };
    } forEach _directPassengerIds;

    if (_emitCatastrophicLog && {_catastrophicManifest isNotEqualTo []}) then {
        ["TRANSPORT", 3, format [
            "Catastrophic virtual carrier loss carrier=%1 passengerGroups=%2 passengerUnits=%3",
            _groupId,
            count _catastrophicManifest,
            _catastrophicPassengerUnits
        ]] call FLO_fnc_log;
    };
};

["FLO_Virtualization_GroupRemoved", [_groupId, _removedSnapshot]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 4, format ["Removed group %1", _groupId]] call FLO_fnc_log;

true
