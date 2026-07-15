/*
 * Function: FLO_fnc_virtualizationRestoreTransportState
 * Description:
 *   Applies exact transport state after current-save validation.
 */

params ["_groupData", "_savedData"];

_groupData set ["transportRole", _savedData get "transportRole"];
_groupData set ["isTransport", _savedData get "isTransport"];

[_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
private _attachedTo = _savedData get "attachedTo";
if (_attachedTo != "") then {
    [
        _groupData,
        _attachedTo,
        _savedData get "attachedType"
    ] call FLO_fnc_virtualizationSetTransportAttachment;
};

[
    _groupData,
    +(_savedData get "attachedGroups")
] call FLO_fnc_virtualizationSetTransportPassengers;

_groupData set ["dismountAtWaypoint", _savedData get "dismountAtWaypoint"];
_groupData set ["transportInsertMode", toUpper (_savedData get "transportInsertMode")];
_groupData set ["transportInsertPos", +(_savedData get "transportInsertPos")];
_groupData set ["transportLandCommandIssued", _savedData get "transportLandCommandIssued"];
_groupData set ["transportUnloadCommandIssued", _savedData get "transportUnloadCommandIssued"];
_groupData set ["transportUnloadIssuedAt", _savedData get "transportUnloadIssuedAt"];
_groupData set ["postDismountWaypoint", +(_savedData get "postDismountWaypoint")];

[_groupData] call FLO_fnc_virtualizationClearMountedIn;
private _mountedIn = _savedData get "mountedIn";
if (_mountedIn != "") then {
    [_groupData, _mountedIn] call FLO_fnc_virtualizationSetMountedIn;
};

true
