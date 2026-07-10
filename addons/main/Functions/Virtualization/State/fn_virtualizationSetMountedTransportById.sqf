/*
 * Function: FLO_fnc_virtualizationSetMountedTransportById
 * Description:
 *   Updates live mounted state without exposing the registry record.
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_carrierGroupId", "", [""]]
];

private _passengerData = [_passengerGroupId] call FLO_fnc_virtualizationRequireGroup;
private _attachedTo = _passengerData get "attachedTo";
if (_carrierGroupId != "" && {_attachedTo != _carrierGroupId}) then {
    throw format [
        "Passenger %1 cannot mount %2 while attached to %3",
        _passengerGroupId,
        _carrierGroupId,
        _attachedTo
    ];
};
if (_carrierGroupId != "") then {
    private _carrierData = [_carrierGroupId] call FLO_fnc_virtualizationRequireGroup;
    if !(_passengerGroupId in (_carrierData get "attachedGroups")) then {
        throw format ["Carrier %1 does not reference mounted passenger %2", _carrierGroupId, _passengerGroupId];
    };
};

private _candidate = [_passengerData] call FLO_fnc_virtualizationCloneValue;
_candidate set ["mountedIn", _carrierGroupId];
_candidate set ["nextProcessAt", 0];
[_candidate, _passengerGroupId] call FLO_fnc_virtualizationValidateGroup;
_passengerData set ["mountedIn", _candidate get "mountedIn"];
_passengerData set ["nextProcessAt", 0];
call FLO_fnc_virtualizationTouchRegistry;
true
