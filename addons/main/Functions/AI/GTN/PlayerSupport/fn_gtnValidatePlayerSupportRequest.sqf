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
    ["cooldownKey", ""],
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

private _config = _cmdr get "_config";
private _objectiveId = [_targetPos, _config get "playerSupportObjectiveSnapRadiusMeters"] call FLO_fnc_gtnResolveSupportObjective;
private _objectiveName = "";

if (_objectiveId != "") then {
    private _objective = FLO_Objectives get _objectiveId;

    _objectiveName = _objective get "name";
    if (_objectiveName == "") then {
        _objectiveName = _objectiveId;
    };
};

private _gridLabel = mapGridPosition _targetPos;
private _targetLabel = if (_objectiveName != "") then {
    format ["%1 (%2)", _objectiveName, _gridLabel]
} else {
    format ["grid %1", _gridLabel]
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
        _result set ["assetType", "cap"];
    };
};

if ((_result get "reason") != "") exitWith { _result };

private _ws = _cmdr get "_worldState";
_result set ["assetAvailable", _ws call ["_isAssetAvailable", [_result get "assetType"]]];
_result set ["objectiveId", _objectiveId];
_result set ["cooldownKey", [_type, _objectiveId, _targetPos, _config get "playerSupportMapCooldownBucketMeters"] call FLO_fnc_gtnBuildSupportCooldownKey];
_result set ["targetLabel", _targetLabel];
_result set ["valid", true];

_result
