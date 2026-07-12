params [["_sideKey", "", [""]]];

if !(_sideKey in ["WEST", "EAST"]) then {
    throw format ["Cannot resolve Development projects for side %1", _sideKey];
};

private _activeObjectiveIds = [];
{
    private _project = _y get "developmentProject";
    if ((keys _project) isNotEqualTo [] && {(_project get "sideKey") == _sideKey}) then {
        _activeObjectiveIds pushBack _x;
    };
} forEach FLO_Objectives;

_activeObjectiveIds sort true;
_activeObjectiveIds
