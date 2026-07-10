/*
 * Function: FLO_fnc_virtualizationLinkTransportGroups
 * Description:
 *   Atomically creates the reciprocal passenger/carrier relationship.
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_carrierGroupId", "", [""]],
    ["_attachmentType", "GROUND", [""]],
    ["_mounted", false, [true]]
];

if (_passengerGroupId == _carrierGroupId) then {
    throw format ["Virtual group %1 cannot transport itself", _passengerGroupId];
};
if (_attachmentType == "") then {
    throw format ["Passenger %1 requires a non-empty attachment type", _passengerGroupId];
};

private _passengerData = [_passengerGroupId] call FLO_fnc_virtualizationRequireGroup;
private _carrierData = [_carrierGroupId] call FLO_fnc_virtualizationRequireGroup;
if ((_passengerData get "side") != (_carrierData get "side")) then {
    throw format ["Passenger %1 and carrier %2 have different sides", _passengerGroupId, _carrierGroupId];
};
if ([_carrierGroupId, _passengerGroupId] call FLO_fnc_virtualizationTransportChainContains) then {
    throw format [
        "Linking passenger %1 to carrier %2 would create a transport cycle",
        _passengerGroupId,
        _carrierGroupId
    ];
};

private _existingCarrier = _passengerData get "attachedTo";
if (_existingCarrier != "") then {
    throw format ["Passenger %1 is already attached to %2", _passengerGroupId, _existingCarrier];
};

private _passengerIds = +(_carrierData get "attachedGroups");
if (_passengerGroupId in _passengerIds) then {
    throw format ["Carrier %1 already references passenger %2", _carrierGroupId, _passengerGroupId];
};

_passengerIds pushBack _passengerGroupId;
private _passengerCandidate = [_passengerData] call FLO_fnc_virtualizationCloneValue;
private _carrierCandidate = [_carrierData] call FLO_fnc_virtualizationCloneValue;
_passengerCandidate set ["attachedTo", _carrierGroupId];
_passengerCandidate set ["attachedType", _attachmentType];
_passengerCandidate set ["mountedIn", ["", _carrierGroupId] select _mounted];
_passengerCandidate set ["nextProcessAt", 0];
_carrierCandidate set ["attachedGroups", _passengerIds];
_carrierCandidate set ["isTransport", true];
_carrierCandidate set ["nextProcessAt", 0];

[_passengerCandidate, _passengerGroupId] call FLO_fnc_virtualizationValidateGroup;
[_carrierCandidate, _carrierGroupId] call FLO_fnc_virtualizationValidateGroup;
{
    _passengerData set [_x, _passengerCandidate get _x];
} forEach ["attachedTo", "attachedType", "mountedIn", "nextProcessAt"];
{
    _carrierData set [_x, _carrierCandidate get _x];
} forEach ["attachedGroups", "isTransport", "nextProcessAt"];
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_TransportRelationshipChanged",
    [_passengerGroupId, _carrierGroupId, "LINK"]
] call CBA_fnc_localEvent;

true
