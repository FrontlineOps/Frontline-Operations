/*
 * Function: FLO_fnc_civilianPlanRoutine
 * Author: Frontline Operations Development Group
 * Description:
 *   Plans the next civilian routine state and route using objective context
 *   and cached civilian POIs.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Objective context <HASHMAP>
 * 2: Objective POI cache <HASHMAP>
 * 3: Current time tick <NUMBER>
 *
 * Return Value:
 * HASHMAP - Empty when no retask is needed
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_context", createHashMap, [createHashMap]],
    ["_poiCache", createHashMap, [createHashMap]],
    ["_nowTick", diag_tickTime, [0]]
];

private _plan = createHashMap;
private _groupType = _groupData get "groupType";
private _role = _groupData get "civilianRole";
private _currentState = _groupData get "civilianRoutineState";
private _routineUntil = _groupData get "civilianRoutineUntil";
private _currentAnchor = _groupData get "civilianRoutineAnchorPos";
private _homeAnchor = _groupData get "civilianHomeAnchorPos";
private _fallbackAnchor = _groupData get "civilianAnchorPos";

if (!(_currentState isEqualType "")) then {
    _currentState = "";
};
if (!(_routineUntil isEqualType 0)) then {
    _routineUntil = -1;
};
if (!(_fallbackAnchor isEqualType [])) then {
    _fallbackAnchor = [0, 0, 0];
};
if (!(_homeAnchor isEqualType [])) then {
    _homeAnchor = +_fallbackAnchor;
};
if (!(_currentAnchor isEqualType [])) then {
    _currentAnchor = +_fallbackAnchor;
};
if (_homeAnchor isEqualTo []) then {
    _homeAnchor = +_fallbackAnchor;
};
if (_currentAnchor isEqualTo []) then {
    _currentAnchor = +_fallbackAnchor;
};

private _disposition = _context get "disposition";
private _contested = _context get "contested";
private _pressure = _contested || {_disposition in ["HOSTILE", "WARY"]};
private _isBuildingGroup = _groupType == "civ_building";
private _isVehicleGroup = _groupType in ["civilianVehicle", "civ_car"];

private _targetState = _currentState;
private _mustRetask = false;

if (_pressure) then {
    _targetState = "shelter";
    _mustRetask = _currentState != "shelter";
} else {
    if (_isBuildingGroup) then {
        _targetState = ["home", "observe"] select (_role == "watcher");
        _mustRetask = _currentState != _targetState || {_nowTick >= _routineUntil};
    } else {
        if (_currentState == "" || {_currentState == "shelter"} || {_nowTick >= _routineUntil}) then {
            _mustRetask = true;

            _targetState = switch (_role) do {
                case "worker": {
                    switch (_currentState) do {
                        case "work": { "return" };
                        case "return": { "home" };
                        case "home": { "work" };
                        default { "work" };
                    };
                };
                case "vendor": {
                    switch (_currentState) do {
                        case "market": { "return" };
                        case "return": { "home" };
                        case "home": { "market" };
                        default { "market" };
                    };
                };
                case "watcher": {
                    switch (_currentState) do {
                        case "observe": { "return" };
                        case "return": { "home" };
                        case "home": { "observe" };
                        default { "observe" };
                    };
                };
                case "wanderer": {
                    switch (_currentState) do {
                        case "market": { "observe" };
                        case "observe": { "return" };
                        case "return": { "home" };
                        case "home": { selectRandom ["market", "observe"] };
                        default { selectRandom ["market", "observe"] };
                    };
                };
                case "driver": {
                    switch (_currentState) do {
                        case "work": { "return" };
                        case "return": { "home" };
                        case "home": { "work" };
                        default { "work" };
                    };
                };
                default {
                    switch (_currentState) do {
                        case "market": { "return" };
                        case "observe": { "return" };
                        case "return": { "home" };
                        case "home": { selectRandom ["market", "observe"] };
                        default { selectRandom ["home", "market", "observe"] };
                    };
                };
            };
        };
    };
};

if (!_mustRetask) exitWith { _plan };

private _homePois = _poiCache get "home";
private _marketPois = _poiCache get "market";
private _workPois = _poiCache get "work";
private _observePois = _poiCache get "observe";
private _shelterPois = _poiCache get "shelter";
private _parkingPois = _poiCache get "parking";

if (_homeAnchor isEqualTo [0, 0, 0] && {_homePois isNotEqualTo []}) then {
    _homeAnchor = +(selectRandom _homePois);
};

private _targetAnchor = +_homeAnchor;
private _anchorPool = switch (_targetState) do {
    case "market": { _marketPois };
    case "work": { [_workPois, _parkingPois] select (_isVehicleGroup) };
    case "observe": { _observePois };
    case "shelter": { _shelterPois };
    case "return": { _homePois };
    default { _homePois };
};

if (_anchorPool isNotEqualTo []) then {
    _targetAnchor = +(selectRandom _anchorPool);
};

private _secondaryAnchor = [];
if (_targetState in ["market", "work", "observe"]) then {
    private _secondaryPool = _anchorPool select { (_x distance2D _targetAnchor) > 20 };
    if (_secondaryPool isNotEqualTo []) then {
        _secondaryAnchor = +(selectRandom _secondaryPool);
    };
};

private _wpBehavior = "SAFE";
private _wpSpeed = "LIMITED";
private _wpFormation = ["FILE", "COLUMN"] select (_isVehicleGroup);
private _wpCombatMode = "WHITE";
private _wpRadius = [6, 20] select (_isVehicleGroup);

if (_targetState == "shelter") then {
    _wpBehavior = "CARELESS";
    _wpSpeed = ["FULL", "NORMAL"] select (_isVehicleGroup);
    _wpRadius = [4, 16] select (_isVehicleGroup);
};

private _routeAnchors = [_targetAnchor];
private _waypoints = [];

if (_isBuildingGroup) then {
    _routeAnchors = [_targetAnchor];
} else {
    switch (_targetState) do {
        case "home";
        case "return";
        case "shelter": {
            _routeAnchors = [_targetAnchor];
            if ((_currentAnchor distance2D _targetAnchor) > 8) then {
                _waypoints pushBack [_targetAnchor, "MOVE", _wpBehavior, _wpSpeed, _wpFormation, _wpCombatMode, _wpRadius];
            };
        };

        default {
            _routeAnchors = [_homeAnchor, _targetAnchor];
            _waypoints pushBack [_targetAnchor, "MOVE", _wpBehavior, _wpSpeed, _wpFormation, _wpCombatMode, _wpRadius];

            if (_secondaryAnchor isNotEqualTo []) then {
                _routeAnchors pushBack _secondaryAnchor;
                _waypoints pushBack [_secondaryAnchor, "MOVE", _wpBehavior, _wpSpeed, _wpFormation, _wpCombatMode, _wpRadius];
            };

            if ((_homeAnchor distance2D _targetAnchor) > 25) then {
                _waypoints pushBack [_homeAnchor, "MOVE", "SAFE", "LIMITED", _wpFormation, "WHITE", _wpRadius];
            };

            private _cyclePos = [_targetAnchor, _secondaryAnchor] select (_secondaryAnchor isNotEqualTo []);
            _waypoints pushBack [_cyclePos, "CYCLE", _wpBehavior, _wpSpeed, _wpFormation, _wpCombatMode, _wpRadius];
        };
    };
};

private _duration = switch (_targetState) do {
    case "work": { 180 + random 120 };
    case "market": { 140 + random 100 };
    case "observe": { 110 + random 90 };
    case "shelter": { 90 + random 90 };
    default { 90 + random 75 };
};

_plan set ["state", _targetState];
_plan set ["homeAnchorPos", _homeAnchor];
_plan set ["anchorPos", _targetAnchor];
_plan set ["routeAnchors", _routeAnchors];
_plan set ["waypoints", _waypoints];
_plan set ["until", _nowTick + _duration];
_plan set ["mood", _disposition];
_plan set ["source", format ["CIV_ROUTINE_%1", toUpper _targetState]];

_plan
