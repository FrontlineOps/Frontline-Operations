/* Resolves deterministic home-edge reserve, ingress, and egress positions. */
params [["_groupData", nil]];

if (isNil "_groupData") then {
    private _message = "Cannot resolve air reserve positions without group data";
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _side = _groupData get "side";
if !(_side in [east, west]) then {
    private _message = format ["Cannot resolve air reserve positions for side %1", _side];
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _homeObjective = _groupData get "homeObjective";
if (_homeObjective == "") then {
    private _message = "Cannot resolve combat-air reserve without homeObjective";
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};
if !(_homeObjective in FLO_Objectives) then {
    private _message = format ["Cannot resolve combat-air reserve: missing home objective %1", _homeObjective];
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _homePos = (FLO_Objectives get _homeObjective) get "position";
if !(
    _homePos isEqualType []
    && {count _homePos >= 2}
    && {(_homePos select 0) isEqualType 0}
    && {(_homePos select 1) isEqualType 0}
) then {
    private _message = format ["Home objective %1 has invalid air-reserve position %2", _homeObjective, _homePos];
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _mapSize = worldSize;
if (_mapSize <= 1000) then {
    private _message = format ["Engine worldSize is invalid while resolving air reserve routes: %1", _mapSize];
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _homeX = _homePos select 0;
private _homeY = _homePos select 1;
if (_homeX < 0 || {_homeX > _mapSize} || {_homeY < 0} || {_homeY > _mapSize}) then {
    private _message = format [
        "Home objective %1 position %2 is outside terrain bounds 0..%3",
        _homeObjective,
        _homePos,
        _mapSize
    ];
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _edge = ["WEST", "EAST"] select (_side isEqualTo east);
private _bestDistance = [_homeX, _mapSize - _homeX] select (_side isEqualTo east);
{
    _x params ["_candidateEdge", "_distance"];
    if (_distance < _bestDistance) then {
        _edge = _candidateEdge;
        _bestDistance = _distance;
    };
} forEach [
    ["WEST", _homeX],
    ["EAST", _mapSize - _homeX],
    ["SOUTH", _homeY],
    ["NORTH", _mapSize - _homeY]
];

private _routeX = _homeX max 500 min (_mapSize - 500);
private _routeY = _homeY max 500 min (_mapSize - 500);

switch (_edge) do {
    case "WEST": {
        [[-2000, _routeY, 500], [250, _routeY, 500], [-250, _routeY, 500]]
    };
    case "EAST": {
        [[_mapSize + 2000, _routeY, 500], [_mapSize - 250, _routeY, 500], [_mapSize + 250, _routeY, 500]]
    };
    case "SOUTH": {
        [[_routeX, -2000, 500], [_routeX, 250, 500], [_routeX, -250, 500]]
    };
    case "NORTH": {
        [[_routeX, _mapSize + 2000, 500], [_routeX, _mapSize - 250, 500], [_routeX, _mapSize + 250, 500]]
    };
}
