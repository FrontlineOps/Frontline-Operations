/*
 * Function: FLO_fnc_virtualizationPruneTransportPassenger
 * Description:
 *   Removes a stale passenger ID from a carrier manifest when no reciprocal
 *   passenger record can be used for a normal unlink.
 */

params [
    ["_carrierGroupId", "", [""]],
    ["_passengerGroupId", "", [""]]
];

private _carrierData = [_carrierGroupId] call FLO_fnc_virtualizationRequireGroup;
private _passengerIds = _carrierData get "attachedGroups";
if !(_passengerGroupId in _passengerIds) exitWith { false };

private _passengerData = [_passengerGroupId] call FLO_fnc_virtualizationFindGroup;
if !(isNil "_passengerData") then {
    if ((_passengerData get "attachedTo") == _carrierGroupId) then {
        throw format [
            "Cannot prune reciprocal passenger %1 from carrier %2; unlink it instead",
            _passengerGroupId,
            _carrierGroupId
        ];
    };
};

_passengerIds = _passengerIds - [_passengerGroupId];
private _candidate = [_carrierData] call FLO_fnc_virtualizationCloneValue;
_candidate set ["attachedGroups", _passengerIds];
_candidate set ["isTransport", _passengerIds isNotEqualTo []];
_candidate set ["nextProcessAt", 0];
if (_passengerIds isEqualTo []) then {
    [_candidate, _carrierGroupId] call FLO_fnc_virtualizationResetCarrierInsertState;
};
[_candidate, _carrierGroupId] call FLO_fnc_virtualizationValidateGroup;
{
    _carrierData set [_x, _candidate get _x];
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
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_TransportRelationshipChanged",
    [_passengerGroupId, _carrierGroupId, "PRUNE"]
] call CBA_fnc_localEvent;

true
