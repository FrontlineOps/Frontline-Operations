/* Releases surviving probe groups and immediately resets the canonical front. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_reason", "", [""]],
    ["_logRelease", true, [true]]
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _releaseIds = (_front get "committedGroupIds") select { _x in _groups };
{
    [_x, [], true, "PROBE_RELEASE"] call FLO_fnc_updateVirtualGroupWaypoints;
} forEach _releaseIds;
if (_releaseIds isNotEqualTo []) then {
    _cmdr call ["_releaseGroups", [_releaseIds, ""]];
};

private _now = call FLO_fnc_operationalDateNumber;
_front set ["committedGroupIds", []];
_front set ["committedUnitBaseline", 0];
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
_front set ["nextActionAtDateNum", _now];
[_front, "PROBE", _reason] call FLO_fnc_campaignSetProbeStage;

if (_logRelease) then {
    ["CAMPAIGN", 3, format [
        "Probe front %1 released %2 groups and reset (%3)",
        _front get "probeId",
        count _releaseIds,
        _reason
    ]] call FLO_fnc_log;
};
true
