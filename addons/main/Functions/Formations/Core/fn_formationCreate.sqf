/* Creates one persistent formation from three to six eligible groups. */
params [
    "_state",
    ["_sideKey", "", [""]],
    ["_branch", "", [""]],
    ["_homeObjectiveId", "", [""]],
    ["_memberIds", [], [[]]]
];

if ((count _memberIds) < 3 || {(count _memberIds) > 6}) then {
    throw format ["Cannot form %1 %2 with %3 groups", _sideKey, _branch, count _memberIds];
};
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _strength = 0;
{
    if !(_x in _groups) then { throw format ["Cannot form a unit from missing group %1", _x]; };
    _strength = _strength + ((_groups get _x) get "unitCount");
} forEach _memberIds;

private _sequenceKey = format ["%1:%2", _sideKey, _branch];
private _sequence = 1;
private _sequences = _state get "sequenceByKey";
if (_sequenceKey in _sequences) then { _sequence = (_sequences get _sequenceKey) + 1; };
_sequences set [_sequenceKey, _sequence];
private _formationId = format ["FORM_%1_%2_%3", _sideKey, toUpper _branch, _sequence];
private _formations = _state get "formations";
if (_formationId in _formations) then { throw format ["Formation ID collision %1", _formationId]; };

_formations set [_formationId, createHashMapFromArray [
    ["formationId", _formationId],
    ["name", [_sideKey, _branch, _sequence] call FLO_fnc_formationBuildName],
    ["sideKey", _sideKey],
    ["branch", _branch],
    ["memberIds", _memberIds],
    ["leadGroupId", _memberIds select 0],
    ["homeObjectiveId", _homeObjectiveId],
    ["readiness", 85],
    ["experience", 20],
    ["battleCount", 0],
    ["victories", 0],
    ["defeats", 0],
    ["withdrawals", 0],
    ["formedAtDateNum", call FLO_fnc_operationalDateNumber],
    ["lastCombatAtDateNum", -1],
    ["lastStrength", _strength],
    ["lastCombatZoneId", ""],
    ["lastCombatRound", 0],
    ["role", "RESERVE"],
    ["roleMemberIds", []],
    ["roleObjectiveId", ""],
    ["roleOperationId", ""],
    ["roleStartedAtDateNum", -1],
    ["roleEndsAtDateNum", -1],
    ["returnObjectiveId", ""]
]];
["FORMATIONS", 4, format ["Formed %1 with %2 groups", (_formations get _formationId) get "name", count _memberIds]] call FLO_fnc_log;
_formationId
