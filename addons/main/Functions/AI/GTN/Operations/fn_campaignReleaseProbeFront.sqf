/* Releases surviving probe groups and places their formations into recovery. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_reason", "", [""]],
    ["_recoverySeconds", 0, [0]]
];

if (_recoverySeconds < 0) then {
    throw format ["Probe recovery delay cannot be negative: %1", _recoverySeconds];
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _releaseIds = (_front get "committedGroupIds") select { _x in _groups };
{
    [_x, [], true, "PROBE_REGROUP"] call FLO_fnc_updateVirtualGroupWaypoints;
} forEach _releaseIds;
if (_releaseIds isNotEqualTo []) then {
    _cmdr call ["_releaseGroups", [_releaseIds, ""]];
};

private _now = call FLO_fnc_operationalDateNumber;
private _formationState = (_director get "_state") get "formationState";
private _formations = _formationState get "formations";
{
    if !(_x in _formations) then { continue };
    private _formation = _formations get _x;
    _formation set ["role", "RECOVERY"];
    _formation set ["roleMemberIds", []];
    _formation set ["roleObjectiveId", _formation get "homeObjectiveId"];
    _formation set ["roleOperationId", _front get "probeId"];
    _formation set ["roleStartedAtDateNum", _now];
    _formation set ["roleEndsAtDateNum", [_now, 180] call FLO_fnc_dateNumberAddSeconds];
    _formation set ["returnObjectiveId", ""];
} forEach (_front get "formationIds");
if ((_front get "formationIds") isNotEqualTo []) then {
    _formationState set ["revision", (_formationState get "revision") + 1];
};

_front set ["committedGroupIds", []];
_front set ["committedUnitBaseline", 0];
_front set ["reinforcementCount", 0];
_front set ["contactSamples", 0];
_front set ["progressSamples", 0];
_front set ["stalledSamples", 0];
_front set ["bestDistance", 1e12];
_front set ["lastEnemyCount", -1];
_front set ["lastActiveGroupCount", 0];
_front set ["lastUnitCount", 0];
_front set ["lastArrivedCount", 0];
_front set ["lastContested", false];
_front set ["lastContactCount", 0];
_front set ["lastContactAt", -1];
_front set ["reinforcementProgressCheckpoint", 0];
_front set ["supportProgressCheckpoint", 0];
_front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
_front set ["nextActionAtDateNum", [_now, _recoverySeconds] call FLO_fnc_dateNumberAddSeconds];
[_front, "REGROUP", _reason] call FLO_fnc_campaignSetProbeStage;

["CAMPAIGN", 3, format [
    "Probe front %1 released %2 groups to regroup (%3)",
    _front get "probeId",
    count _releaseIds,
    _reason
]] call FLO_fnc_log;
true
