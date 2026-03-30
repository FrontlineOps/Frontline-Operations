/*
 * Function: FLO_fnc_virtualizationRestoreTransportState
 */

params ["_groupData", "_savedData"];

private _savedTransportRole = false;
if ("transportRole" in _savedData) then {
    _savedTransportRole = _savedData get "transportRole";
};
if !(_savedTransportRole isEqualType true) then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved transportRole type for %1: %2",
        _groupData get "groupType",
        typeName _savedTransportRole
    ]] call FLO_fnc_log;
    _savedTransportRole = false;
};
_groupData set ["transportRole", _savedTransportRole];

private _savedIsTransport = false;
if ("isTransport" in _savedData) then {
    _savedIsTransport = _savedData get "isTransport";
} else {
    ["VIRTUALIZATION", 1, format [
        "Saved transport state missing isTransport for %1",
        _groupData get "groupType"
    ]] call FLO_fnc_log;
};
if !(_savedIsTransport isEqualType true) then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved transport isTransport type for %1: %2",
        _groupData get "groupType",
        typeName _savedIsTransport
    ]] call FLO_fnc_log;
    _savedIsTransport = false;
};
_groupData set ["isTransport", _savedIsTransport];

[_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
private _attachedTo = "";
if ("attachedTo" in _savedData) then {
    _attachedTo = _savedData get "attachedTo";
} else {
    ["VIRTUALIZATION", 1, format [
        "Saved transport state missing attachedTo for %1",
        _groupData get "groupType"
    ]] call FLO_fnc_log;
};
if !(_attachedTo isEqualType "") then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved attachedTo type for %1: %2",
        _groupData get "groupType",
        typeName _attachedTo
    ]] call FLO_fnc_log;
    _attachedTo = "";
};
if (_attachedTo != "") then {
    private _attachedType = "";
    if ("attachedType" in _savedData) then {
        _attachedType = _savedData get "attachedType";
    } else {
        ["VIRTUALIZATION", 1, format [
            "Saved transport state missing attachedType for %1",
            _groupData get "groupType"
        ]] call FLO_fnc_log;
    };
    if !(_attachedType isEqualType "") then {
        ["VIRTUALIZATION", 1, format [
            "Invalid saved attachedType type for %1: %2",
            _groupData get "groupType",
            typeName _attachedType
        ]] call FLO_fnc_log;
        _attachedType = "";
    };
    [_groupData, _attachedTo, _attachedType] call FLO_fnc_virtualizationSetTransportAttachment;
};

private _attachedGroups = [];
if ("attachedGroups" in _savedData) then {
    _attachedGroups = _savedData get "attachedGroups";
} else {
    ["VIRTUALIZATION", 1, format [
        "Saved transport state missing attachedGroups for %1",
        _groupData get "groupType"
    ]] call FLO_fnc_log;
};
if !(_attachedGroups isEqualType []) then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved attachedGroups type for %1: %2",
        _groupData get "groupType",
        typeName _attachedGroups
    ]] call FLO_fnc_log;
    _attachedGroups = [];
};
[_groupData, _attachedGroups] call FLO_fnc_virtualizationSetTransportPassengers;

private _dismountAtWaypoint = -1;
if ("dismountAtWaypoint" in _savedData) then {
    _dismountAtWaypoint = _savedData get "dismountAtWaypoint";
} else {
    ["VIRTUALIZATION", 1, format [
        "Saved transport state missing dismountAtWaypoint for %1",
        _groupData get "groupType"
    ]] call FLO_fnc_log;
};
if !(_dismountAtWaypoint isEqualType 0) then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved dismountAtWaypoint type for %1: %2",
        _groupData get "groupType",
        typeName _dismountAtWaypoint
    ]] call FLO_fnc_log;
    _dismountAtWaypoint = -1;
};
_groupData set ["dismountAtWaypoint", _dismountAtWaypoint];

private _transportInsertMode = "";
if ("transportInsertMode" in _savedData) then {
    _transportInsertMode = _savedData get "transportInsertMode";
};
if !(_transportInsertMode isEqualType "") then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved transportInsertMode type for %1: %2",
        _groupData get "groupType",
        typeName _transportInsertMode
    ]] call FLO_fnc_log;
    _transportInsertMode = "";
};
_groupData set ["transportInsertMode", toUpper _transportInsertMode];

private _transportInsertPos = [];
if ("transportInsertPos" in _savedData) then {
    _transportInsertPos = _savedData get "transportInsertPos";
};
if !(_transportInsertPos isEqualType []) then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved transportInsertPos type for %1: %2",
        _groupData get "groupType",
        typeName _transportInsertPos
    ]] call FLO_fnc_log;
    _transportInsertPos = [];
};
_groupData set ["transportInsertPos", _transportInsertPos];

private _transportLandCommandIssued = false;
if ("transportLandCommandIssued" in _savedData) then {
    _transportLandCommandIssued = _savedData get "transportLandCommandIssued";
};
if !(_transportLandCommandIssued isEqualType true) then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved transportLandCommandIssued type for %1: %2",
        _groupData get "groupType",
        typeName _transportLandCommandIssued
    ]] call FLO_fnc_log;
    _transportLandCommandIssued = false;
};
_groupData set ["transportLandCommandIssued", _transportLandCommandIssued];

private _postDismountWaypoint = [];
if ("postDismountWaypoint" in _savedData) then {
    _postDismountWaypoint = _savedData get "postDismountWaypoint";
} else {
    ["VIRTUALIZATION", 1, format [
        "Saved transport state missing postDismountWaypoint for %1",
        _groupData get "groupType"
    ]] call FLO_fnc_log;
};
if !(_postDismountWaypoint isEqualType []) then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved postDismountWaypoint type for %1: %2",
        _groupData get "groupType",
        typeName _postDismountWaypoint
    ]] call FLO_fnc_log;
    _postDismountWaypoint = [];
};
_groupData set ["postDismountWaypoint", _postDismountWaypoint];

[_groupData] call FLO_fnc_virtualizationClearMountedIn;
private _mountedIn = "";
if ("mountedIn" in _savedData) then {
    _mountedIn = _savedData get "mountedIn";
} else {
    ["VIRTUALIZATION", 1, format [
        "Saved transport state missing mountedIn for %1",
        _groupData get "groupType"
    ]] call FLO_fnc_log;
};
if !(_mountedIn isEqualType "") then {
    ["VIRTUALIZATION", 1, format [
        "Invalid saved mountedIn type for %1: %2",
        _groupData get "groupType",
        typeName _mountedIn
    ]] call FLO_fnc_log;
    _mountedIn = "";
};
if (_mountedIn != "") then {
    [_groupData, _mountedIn] call FLO_fnc_virtualizationSetMountedIn;
};

true
