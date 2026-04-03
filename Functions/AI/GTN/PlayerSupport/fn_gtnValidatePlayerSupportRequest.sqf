/*
 * Function: FLO_fnc_gtnValidatePlayerSupportRequest
 * Author: Frontline Operations Development Group
 * Description:
 *   Validates a player support request against maintained GTN state and
 *   resolves the canonical objective / dispatch position for the request.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAPOBJECT>
 *   1: Request side <SIDE>
 *   2: Support type <STRING> - "ARTY", "CAS", "CAP"
 *   3: Target position <ARRAY>
 *
 * Return Value:
 *   HASHMAP
 */

params [
    ["_cmdr", nil],
    ["_requestSide", sideUnknown],
    ["_supportType", "", [""]],
    ["_targetPos", [0, 0, 0], [[]], [3]]
];

private _result = createHashMapFromArray [
    ["valid", false],
    ["reason", ""],
    ["type", toUpper _supportType],
    ["objectiveId", ""],
    ["targetLabel", ""],
    ["assetType", ""],
    ["assetAvailable", false],
    ["dispatchPos", +_targetPos]
];

if (isNil "_cmdr") exitWith { _result };
if !(_requestSide in [east, west]) exitWith {
    _result set ["reason", "Support command is unavailable for this side."];
    _result
};

private _type = _result get "type";
if !(_type in ["ARTY", "CAS", "CAP"]) exitWith {
    _result set ["reason", format ["Unknown support type: %1", _type]];
    _result
};

private _objectiveId = [_targetPos] call FLO_fnc_gtnResolveSupportObjective;
if (_objectiveId == "") exitWith {
    _result set ["reason", "Target a valid sector on the map."];
    _result
};

private _objective = FLO_Objectives get _objectiveId;
private _objectivePos = _objective get "position";
private _objectiveRadius = _objective get "radius";
private _snapRadius = ((_cmdr get "_config") get "playerSupportObjectiveSnapRadiusMeters");
private _insideObjective = [_targetPos, _objective] call FLO_fnc_isPositionInObjective;

if !(_insideObjective || {(_targetPos distance2D _objectivePos) <= ((_objectiveRadius max 0) + _snapRadius)}) exitWith {
    _result set ["reason", "Target a valid sector instead of empty map space."];
    _result
};

private _objectiveOwner = _objective get "owner";
if (_objectiveOwner isEqualType "") then {
    private _ownerKey = toUpper _objectiveOwner;
    if (_ownerKey isEqualTo "EAST") then { _objectiveOwner = east; };
    if (_ownerKey isEqualTo "WEST") then { _objectiveOwner = west; };
};

private _objectiveName = _objective get "name";
if (_objectiveName == "") then {
    _objectiveName = _objectiveId;
};

private _artilleryManager = _cmdr get "_artilleryManager";

switch (_type) do {
    case "ARTY": {
        private _safe = _artilleryManager call [
            "_isObservedImpactSafe",
            [
                _targetPos,
                _requestSide,
                ((_cmdr get "_config") get "playerSupportArtilleryDangerCloseMeters")
            ]
        ];
        if (!_safe) exitWith {
            _result set ["reason", "Artillery danger close. Move friendlies away from the target area."];
        };

        _result set ["assetType", "artillery"];
    };

    case "CAS": {
        if (
            _objectiveOwner isEqualTo _requestSide
            && {!(_objective get "contested")}
            && {!(_objective get "underAttack")}
        ) exitWith {
            _result set ["reason", "CAS is only available on hostile or pressured sectors."];
        };

        private _safe = _artilleryManager call [
            "_isObservedImpactSafe",
            [
                _targetPos,
                _requestSide,
                ((_cmdr get "_config") get "playerSupportCASDangerCloseMeters")
            ]
        ];
        if (!_safe) exitWith {
            _result set ["reason", "CAS target is too close to friendlies."];
        };

        _result set ["assetType", "cas"];
    };

    case "CAP": {
        if !(_objectiveOwner isEqualTo _requestSide) exitWith {
            _result set ["reason", "CAP can only cover friendly-held sectors."];
        };

        _result set ["assetType", "cap"];
        _result set ["dispatchPos", +_objectivePos];
    };
};

if ((_result get "reason") != "") exitWith { _result };

private _ws = _cmdr get "_worldState";
_result set ["assetAvailable", _ws call ["_isAssetAvailable", [_result get "assetType"]]];
_result set ["objectiveId", _objectiveId];
_result set ["targetLabel", _objectiveName];
_result set ["valid", true];

_result
