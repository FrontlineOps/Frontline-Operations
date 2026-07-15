/*
 * Function: FLO_fnc_virtualizationResetCarrierInsertState
 * Description:
 *   Clears carrier-side insert state on an empty-manifest transaction
 *   candidate before that candidate is validated and published.
 */

params [
    ["_carrierData", createHashMap, [createHashMap]],
    ["_carrierGroupId", "", [""]]
];

if ((_carrierData get "attachedGroups") isNotEqualTo []) then {
    private _message = format [
        "Cannot reset carrier insert state for %1 while passengers remain",
        _carrierGroupId
    ];
    ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
    throw _message;
};

_carrierData set ["dismountAtWaypoint", -1];
_carrierData set ["transportInsertMode", ""];
_carrierData set ["transportInsertPos", []];
_carrierData set ["transportLandCommandIssued", false];
_carrierData set ["transportUnloadCommandIssued", false];
_carrierData set ["transportUnloadIssuedAt", -1];

if ((_carrierData get "executionState") == "TRANSPORT") then {
    _carrierData set ["executionState", ""];
};
if ((_carrierData get "attachedTo") == "" && {(_carrierData get "missionLock") == "TRANSPORT"}) then {
    _carrierData set ["missionLock", ""];
    _carrierData set ["missionType", ""];
};

true
