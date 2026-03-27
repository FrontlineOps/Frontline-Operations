/*
 * Function: FLO_fnc_gtnRecordCounterBatteryExposure
 * Author: Frontline Operations Development Group
 * Description:
 *   Records artillery-source exposure for the opposite side so repeated enemy
 *   fire missions can mature into a counter-battery opportunity.
 *
 * Arguments:
 *   0: Artillery Manager <HASHMAP>
 *   1: Source group ID <STRING>
 *   2: Source group data <HASHMAP>
 *   3: Counter-battery side <SIDE>
 *   4: Mission record <HASHMAP>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_manager", nil],
    ["_sourceGroupId", "", [""]],
    ["_sourceGroupData", nil],
    ["_counterBatterySide", sideUnknown],
    ["_missionRecord", createHashMap]
];

if (isNil "_manager" || {_sourceGroupId isEqualTo ""}) exitWith { false };
if !(_counterBatterySide in [east, west]) exitWith { false };

private _reports = _manager get "counterBatteryReports";
private _windowSeconds = _manager get "counterBatteryWindowSeconds";
private _rounds = (_missionRecord get "rounds") max 1;
private _exposureGain = ((_rounds max 4) * 0.5) min 5;
private _sideKey = ([_counterBatterySide] call FLO_fnc_gtnSideContext) get "sideKey";
private _reportKey = format ["%1:%2", _sideKey, _sourceGroupId];
private _now = diag_tickTime;

private _report = if (_reportKey in _reports) then {
    _reports get _reportKey
} else {
    createHashMapFromArray [
        ["reportKey", _reportKey],
        ["requestSide", _counterBatterySide],
        ["enemyGroupId", _sourceGroupId],
        ["enemySide", _sourceGroupData get "side"],
        ["sourcePos", _sourceGroupData get "position"],
        ["firstSeen", _now],
        ["lastSeen", _now],
        ["missionCount", 0],
        ["exposure", 0]
    ]
};

if ((_now - (_report get "lastSeen")) > _windowSeconds) then {
    _report set ["firstSeen", _now];
    _report set ["missionCount", 0];
    _report set ["exposure", 0];
};

_report set ["enemySide", _sourceGroupData get "side"];
_report set ["sourcePos", _sourceGroupData get "position"];
_report set ["lastSeen", _now];
_report set ["missionCount", (_report get "missionCount") + 1];
_report set ["exposure", (_report get "exposure") + _exposureGain];

_reports set [_reportKey, _report];
true
