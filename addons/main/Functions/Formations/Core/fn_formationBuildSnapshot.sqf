/* Builds the friendly formation read model for Command Net. */
params [["_viewerSideKey", "", [""]]];

if !(_viewerSideKey in ["WEST", "EAST"]) then {
    throw format ["Invalid formation snapshot side %1", _viewerSideKey];
};
if (isNil "FLO_FormationState") then { throw "Formation snapshot requested before formation initialization"; };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _rows = [];
{
    private _formation = _y;
    if ((_formation get "sideKey") != _viewerSideKey) then { continue };
    private _activeCount = 0;
    private _livingCount = 0;
    {
        if (_x in _groups) then {
            private _groupData = _groups get _x;
            if ((_groupData get "unitCount") > 0) then { _livingCount = _livingCount + 1; };
            if (_groupData get "isActive") then { _activeCount = _activeCount + 1; };
        };
    } forEach (_formation get "memberIds");
    private _objectiveId = _formation get "roleObjectiveId";
    if (_objectiveId == "") then { _objectiveId = _formation get "homeObjectiveId"; };
    private _objectiveName = "Theater Reserve";
    if (_objectiveId != "" && {_objectiveId in FLO_Objectives}) then {
        _objectiveName = [_objectiveId] call FLO_fnc_campaignObjectiveName;
    };
    private _rolePriority = switch (_formation get "role") do {
        case "MAIN": { 0 };
        case "EXPLOIT": { 1 };
        case "FEINT": { 2 };
        case "WITHDRAW": { 3 };
        case "FEINT_RETURN": { 4 };
        case "RECOVERY": { 5 };
        default { 6 };
    };
    _rows pushBack [_rolePriority, _formation get "name", createHashMapFromArray [
        ["id", _x],
        ["name", _formation get "name"],
        ["branch", toUpper (_formation get "branch")],
        ["rank", [_formation get "experience"] call FLO_fnc_formationGetRank],
        ["readiness", round (_formation get "readiness")],
        ["role", _formation get "role"],
        ["leadGroupId", _formation get "leadGroupId"],
        ["memberCount", _livingCount],
        ["activeCount", _activeCount],
        ["objectiveId", _objectiveId],
        ["objectiveName", _objectiveName],
        ["battleCount", _formation get "battleCount"],
        ["victories", _formation get "victories"]
    ]];
} forEach (FLO_FormationState get "formations");
_rows sort true;
_rows apply { _x select 2 }
