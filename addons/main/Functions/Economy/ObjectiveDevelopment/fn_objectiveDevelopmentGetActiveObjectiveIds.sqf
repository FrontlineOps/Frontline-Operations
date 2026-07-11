params [["_sideKey", "", [""]]];

if !(_sideKey in ["WEST", "EAST"]) then {
    throw format ["Cannot resolve development projects for side %1", _sideKey];
};

private _activeObjectiveIds = [];
{
    private _project = _y get "developmentProject";
    if ((keys _project) isNotEqualTo [] && {(_project get "sideKey") == _sideKey}) then {
        _activeObjectiveIds pushBack _x;
    };
} forEach FLO_Objectives;

_activeObjectiveIds sort true;
private _maximum = FLO_ObjectiveDevelopmentConfig get "maximumConcurrentProjects";
if ((count _activeObjectiveIds) > _maximum) then {
    throw format [
        "Side %1 owns %2 development projects, above the configured maximum of %3: %4",
        _sideKey,
        count _activeObjectiveIds,
        _maximum,
        _activeObjectiveIds
    ];
};

_activeObjectiveIds
