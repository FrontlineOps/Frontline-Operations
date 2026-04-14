/*
 * Function: FLO_fnc_virtualizationReconcileTransportState
 * Author: Frontline Operations Development Group
 * Description:
 *   Rebuilds canonical transport linkage after restore or initial seeding so
 *   the update loop never sees half-constructed passenger/carrier state.
 *
 * Arguments:
 *   0: Virtualization registry <HASHMAP> - Optional, defaults to FLO_virtualGroups
 *
 * Return Value:
 *   BOOL - True when reconciliation completed
 */

params [["_virt", FLO_virtualGroups, [createHashMap]]];

private _groups = _virt get "_groups";
private _passengersByCarrier = createHashMap;
private _repairCount = 0;

{
    private _groupId = _x;
    private _groupData = _y;
    private _attachedTo = [_groupData] call FLO_fnc_virtualizationGetTransportAttachment;
    private _mountedIn = [_groupData] call FLO_fnc_virtualizationGetMountedTransport;
    private _organicRole = _groupData get "organicPackageRole";
    private _organicParentGroupId = _groupData get "organicPackageParentGroupId";

    if (_organicRole == "dismount" && {_organicParentGroupId != ""}) then {
        private _organicParentData = _groups get _organicParentGroupId;
        if (isNil "_organicParentData") then {
            ["VIRTUALIZATION", 1, format [
                "Clearing stale organic package parent on %1 -> %2",
                _groupId,
                _organicParentGroupId
            ]] call FLO_fnc_log;
            _groupData set ["organicPackageRole", ""];
            _groupData set ["organicPackageParentGroupId", ""];
            if ((_groupData get "missionLock") == "ORGANIC_PACKAGE") then {
                [_groupData] call FLO_fnc_virtualizationClearMissionLock;
            };
            _repairCount = _repairCount + 1;
        };
    };

    if (_attachedTo == "") then {
        if (_mountedIn != "") then {
            ["VIRTUALIZATION", 1, format [
                "Clearing mountedIn on unattached passenger %1 -> %2",
                _groupId,
                _mountedIn
            ]] call FLO_fnc_log;
            [_groupData] call FLO_fnc_virtualizationClearMountedIn;
            _repairCount = _repairCount + 1;
        };
        if ((_groupData get "missionLock") == "TRANSPORT") then {
            ["VIRTUALIZATION", 1, format [
                "Clearing stale transport mission lock on unattached passenger %1",
                _groupId
            ]] call FLO_fnc_log;
            [_groupData] call FLO_fnc_virtualizationClearMissionLock;
            _repairCount = _repairCount + 1;
        };
        continue;
    };

    if (_attachedTo == _groupId) then {
        ["VIRTUALIZATION", 1, format [
            "Clearing self-attachment on %1",
            _groupId
        ]] call FLO_fnc_log;
        [_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
        if ((_groupData get "missionLock") in ["ORGANIC_PACKAGE", "TRANSPORT"]) then {
            [_groupData] call FLO_fnc_virtualizationClearMissionLock;
        };
        if (_organicRole == "dismount") then {
            _groupData set ["organicPackageRole", ""];
            _groupData set ["organicPackageParentGroupId", ""];
        };
        _repairCount = _repairCount + 1;
        continue;
    };

    private _carrierData = _groups get _attachedTo;
    if (isNil "_carrierData") then {
        ["VIRTUALIZATION", 1, format [
            "Clearing stale saved attachment on %1 -> %2",
            _groupId,
            _attachedTo
        ]] call FLO_fnc_log;
        [_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
        if ((_groupData get "missionLock") in ["ORGANIC_PACKAGE", "TRANSPORT"]) then {
            [_groupData] call FLO_fnc_virtualizationClearMissionLock;
        };
        if (_organicRole == "dismount") then {
            _groupData set ["organicPackageRole", ""];
            _groupData set ["organicPackageParentGroupId", ""];
        };
        _repairCount = _repairCount + 1;
        continue;
    };

    private _carrierPos = _carrierData get "position";
    if !([_carrierPos, true, format [
        "virtualizationReconcileTransportState passenger=%1 carrier=%2",
        _groupId,
        _attachedTo
    ]] call FLO_fnc_validateGroupPosition) then {
        ["VIRTUALIZATION", 1, format [
            "Clearing attachment on %1 because carrier %2 has invalid position",
            _groupId,
            _attachedTo
        ]] call FLO_fnc_log;
        [_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
        if ((_groupData get "missionLock") in ["ORGANIC_PACKAGE", "TRANSPORT"]) then {
            [_groupData] call FLO_fnc_virtualizationClearMissionLock;
        };
        if (_organicRole == "dismount") then {
            _groupData set ["organicPackageRole", ""];
            _groupData set ["organicPackageParentGroupId", ""];
        };
        _repairCount = _repairCount + 1;
        continue;
    };

    if (_mountedIn != "" && {_mountedIn != _attachedTo}) then {
        ["VIRTUALIZATION", 1, format [
            "Clearing mismatched mountedIn on %1 -> %2 (attached to %3)",
            _groupId,
            _mountedIn,
            _attachedTo
        ]] call FLO_fnc_log;
        [_groupData] call FLO_fnc_virtualizationClearMountedIn;
        _repairCount = _repairCount + 1;
    };

    [_virt, _groupId, _carrierPos] call FLO_fnc_virtualizationUpdateGroupPosition;

    private _passengerIds = _passengersByCarrier get _attachedTo;
    if (isNil "_passengerIds") then {
        _passengerIds = [];
    };
    _passengerIds pushBack _groupId;
    _passengersByCarrier set [_attachedTo, _passengerIds];
} forEach _groups;

{
    private _carrierId = _x;
    private _carrierData = _y;
    private _passengerIds = _passengersByCarrier get _carrierId;
    if (isNil "_passengerIds") then {
        _passengerIds = [];
    };

    private _existingPassengers = [_carrierData] call FLO_fnc_virtualizationGetTransportPassengers;
    if !(_existingPassengers isEqualTo _passengerIds) then {
        [_carrierData, _passengerIds] call FLO_fnc_virtualizationSetTransportPassengers;
        _repairCount = _repairCount + 1;
    };

    if (count _passengerIds == 0 && {(_carrierData get "dismountAtWaypoint") >= 0 || {(_carrierData get "transportInsertMode") != ""}}) then {
        ["VIRTUALIZATION", 1, format [
            "Clearing stale transport insert state on carrier %1 with no passengers",
            _carrierId
        ]] call FLO_fnc_log;
        [_carrierData] call FLO_fnc_transportClearInsertState;
        _repairCount = _repairCount + 1;
    };
} forEach _groups;

if (_repairCount > 0) then {
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
    ["VIRTUALIZATION", 2, format [
        "Reconciled transport state: %1 repairs",
        _repairCount
    ]] call FLO_fnc_log;
};

true
