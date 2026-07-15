/* Returns the exact active ATTACK mass that makes one canonical probe promotable. */
params [
    "_director",
    ["_sideKey", "", [""]],
    ["_objectiveId", "", [""]]
];

if !(_sideKey in ["WEST", "EAST"]) then {
    throw format ["Promotable probe lookup received invalid side %1", _sideKey];
};
if (_objectiveId == "") then {
    throw "Promotable probe lookup requires an objective ID";
};

private _state = _director get "_state";
private _fronts = _state get "frontlineProbes";
private _probeId = [_sideKey, _objectiveId] call FLO_fnc_campaignProbeId;
if !(_probeId in _fronts) exitWith { [] };

private _front = _fronts get _probeId;
if ((_front get "sideKey") != _sideKey || {(_front get "objectiveId") != _objectiveId}) then {
    throw format ["Probe %1 ownership does not match %2/%3", _probeId, _sideKey, _objectiveId];
};
if (
    (_front get "stage") != "ASSAULT"
    || {!(_front get "promotionReady")}
    || {(_front get "formalOperationId") != ""}
) exitWith { [] };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _activeGroupIds = (_front get "committedGroupIds") select {
    _x in _groups
    && {((_groups get _x) get "unitCount") > 0}
    && {((_groups get _x) get "commanderOrder") == "ATTACK"}
    && {((_groups get _x) get "campaignOperationId") == _probeId}
    && {((_groups get _x) get "attackObjective") == _objectiveId}
};
if ((count _activeGroupIds) < ((_director get "_config") get "probeAssaultMinimumGroups")) exitWith { [] };
_activeGroupIds
