/*
 * Function: FLO_fnc_virtualizationUnlinkTransportGroups
 * Description:
 *   Atomically clears a passenger relationship and its carrier manifest entry.
 */

params [["_passengerGroupId", "", [""]]];

private _passengerData = [_passengerGroupId] call FLO_fnc_virtualizationRequireGroup;
private _carrierGroupId = _passengerData get "attachedTo";
if (_carrierGroupId == "") exitWith { false };

private _carrierData = [_carrierGroupId] call FLO_fnc_virtualizationFindGroup;
private _carrierCandidate = nil;
if !(isNil "_carrierData") then {
    private _passengerIds = (_carrierData get "attachedGroups") - [_passengerGroupId];
    _carrierCandidate = [_carrierData] call FLO_fnc_virtualizationCloneValue;
    _carrierCandidate set ["attachedGroups", _passengerIds];
    _carrierCandidate set ["isTransport", _passengerIds isNotEqualTo []];
    _carrierCandidate set ["nextProcessAt", 0];
    if (_passengerIds isEqualTo []) then {
        [_carrierCandidate, _carrierGroupId] call FLO_fnc_virtualizationResetCarrierInsertState;
    };
    [_carrierCandidate, _carrierGroupId] call FLO_fnc_virtualizationValidateGroup;
};

private _passengerCandidate = [_passengerData] call FLO_fnc_virtualizationCloneValue;
_passengerCandidate set ["attachedTo", ""];
_passengerCandidate set ["attachedType", ""];
_passengerCandidate set ["mountedIn", ""];
_passengerCandidate set ["nextProcessAt", 0];
[_passengerCandidate, _passengerGroupId] call FLO_fnc_virtualizationValidateGroup;

if !(isNil "_carrierCandidate") then {
    {
        _carrierData set [_x, _carrierCandidate get _x];
    } forEach [
        "attachedGroups",
        "isTransport",
        "dismountAtWaypoint",
        "transportInsertMode",
        "transportInsertPos",
        "transportLandCommandIssued",
        "transportUnloadCommandIssued",
        "transportUnloadIssuedAt",
        "executionState",
        "missionLock",
        "missionType",
        "nextProcessAt"
    ];
};
{
    _passengerData set [_x, _passengerCandidate get _x];
} forEach ["attachedTo", "attachedType", "mountedIn", "nextProcessAt"];
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_TransportRelationshipChanged",
    [_passengerGroupId, _carrierGroupId, "UNLINK"]
] call CBA_fnc_localEvent;

true
