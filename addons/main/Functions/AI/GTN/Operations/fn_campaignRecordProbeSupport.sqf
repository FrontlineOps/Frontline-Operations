/* Records one attempted or authorized support mission against a probe front. */
params [
    "_director",
    ["_sideKey", "", [""]],
    ["_objectiveId", "", [""]],
    ["_supportType", "", [""]],
    ["_authorized", false, [true]]
];

_sideKey = toUpper _sideKey;
_supportType = toUpper _supportType;
if !(_supportType in ["ARTILLERY", "AIR"]) then {
    throw format ["Invalid probe support type %1", _supportType];
};
private _probeId = [_sideKey, _objectiveId] call FLO_fnc_campaignProbeId;
private _state = _director get "_state";
private _fronts = _state get "frontlineProbes";
if !(_probeId in _fronts) then {
    throw format ["Cannot record support against missing probe front %1", _probeId];
};
private _front = _fronts get _probeId;
_front set ["supportAttemptCount", (_front get "supportAttemptCount") + 1];
if (_authorized) then {
    _front set ["supportMissionCount", (_front get "supportMissionCount") + 1];
    private _field = ["airMissionCount", "artilleryMissionCount"] select (_supportType == "ARTILLERY");
    _front set [_field, (_front get _field) + 1];
    ["CAMPAIGN", 3, format [
        "Probe front %1 received authorized %2 support",
        _probeId,
        _supportType
    ]] call FLO_fnc_log;
};
[_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
_state set ["revision", (_state get "revision") + 1];
_authorized
