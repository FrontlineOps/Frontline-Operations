params [
    "_network",
    ["_position", [], [[]]],
    ["_currentObjectiveId", "", [""]]
];

private _managedSide = _network get "_managedSide";
private _maxDistance = _network get "NODE_OBJECTIVE_LINK_RADIUS";

if (_currentObjectiveId != "" && {_currentObjectiveId in FLO_Objectives}) then {
    private _current = FLO_Objectives get _currentObjectiveId;
    if (
        (_current get "owner") isEqualTo _managedSide
        && {[_currentObjectiveId] call FLO_fnc_campaignIsObjectiveIntegrated}
        && {(_position distance2D (_current get "position")) <= _maxDistance}
    ) exitWith { _currentObjectiveId };
};

private _bestObjectiveId = "";
private _bestDistance = _maxDistance;
{
    private _objective = FLO_Objectives get _x;
    private _distance = _position distance2D (_objective get "position");
    if (_distance <= _bestDistance) then {
        _bestDistance = _distance;
        _bestObjectiveId = _x;
    };
} forEach (_network get "_managedObjectiveIds");

_bestObjectiveId
