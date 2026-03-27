/*
 * Function: FLO_fnc_virtualizationProcessAttachedGroup
 */

params ["_groupId", "_groupData", "_virtStats"];

private _attachedTo = [_groupData] call FLO_fnc_virtualizationGetTransportAttachment;
if (_attachedTo == "") exitWith { false };

private _transportData = (FLO_virtualGroups get "_groups") get _attachedTo;
if (isNil "_transportData") exitWith {
    ["VIRTUALIZATION", 1, format [
        "Passenger %1 had stale attachment to missing carrier %2 - clearing attachment state",
        _groupId,
        _attachedTo
    ]] call FLO_fnc_log;

    [_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
    [_groupData] call FLO_fnc_virtualizationClearMountedIn;
    if ((_groupData get "missionLock") == "ORGANIC_PACKAGE") then {
        [_groupData] call FLO_fnc_virtualizationClearMissionLock;
    };
    [true] call FLO_fnc_gtnCombatMarkClassificationDirty;

    true
};

private _mountedIn = [_groupData] call FLO_fnc_virtualizationGetMountedTransport;
private _transportIsActive = _transportData get "isActive";
private _transportRealGroup = _transportData get "realGroup";

if ((_groupData get "isActive") && {_mountedIn == _attachedTo} && {(!_transportIsActive) || {isNull _transportRealGroup}}) exitWith {
    ["VIRTUALIZATION", 2, format [
        "Mounted passenger %1 remained active while carrier %2 was virtual. Repairing passenger virtualization state.",
        _groupId,
        _attachedTo
    ]] call FLO_fnc_log;
    [_groupId, _groupData, _attachedTo] call FLO_fnc_virtualizationDeactivateMountedPassengerGroup;
    _virtStats set ["deactivationsTotal", (_virtStats get "deactivationsTotal") + 1];
    _virtStats set ["deactivationsThisBatch", (_virtStats get "deactivationsThisBatch") + 1];
    true
};

private _transportPos = _transportData get "position";
if !([_transportPos, true, format [
    "virtualizationProcessAttachedGroup passenger=%1 carrier=%2",
    _groupId,
    _attachedTo
]] call FLO_fnc_validateGroupPosition) exitWith {
    true
};
[FLO_virtualGroups, _groupId, _transportPos] call FLO_fnc_virtualizationUpdateGroupPosition;

_virtStats set ["attachedSyncsTotal", (_virtStats get "attachedSyncsTotal") + 1];
_virtStats set ["attachedSyncsThisBatch", (_virtStats get "attachedSyncsThisBatch") + 1];

true
