/*
 * Function: FLO_fnc_campaignRevealTarget
 * Description:
 *   Latches the defender's exact operation target after confirmed contact.
 */

params [
    "_director",
    ["_reason", "", [""]]
];

private _state = _director get "_state";
if ((_state get "phase") != "PREPARE") exitWith { false };
if ((_state get "defenderIntelLevel") == "TARGET") exitWith { false };
if ((_state get "operationId") == "" || {(_state get "objectiveId") == ""}) then {
    throw "FLO_fnc_campaignRevealTarget: PREPARE state has no active operation target";
};

_state set ["defenderIntelLevel", "TARGET"];
_state set ["defenderIntelReason", _reason];
_state set ["revision", (_state get "revision") + 1];

["CAMPAIGN", 2, format [
    "Operation %1 target revealed to defender (%2)",
    _state get "operationId",
    _reason
]] call FLO_fnc_log;

["FLO_Campaign_OperationChanged", [_state get "revision", _state get "operationId", _state get "phase"]] call CBA_fnc_localEvent;
true
