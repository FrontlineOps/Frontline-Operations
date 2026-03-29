/*
 * Function: FLO_fnc_transportBuildMissionPlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the concrete carrier insert plan for a transport request. Ground
 *   carriers use a standard standoff unload, while helicopters choose between
 *   landing inserts and paradrops using maintained objective ownership, fresh
 *   enemy contact intel, and AA analysis. Landing inserts are preferred unless
 *   multiple maintained threat signals justify a paradrop.
 *
 * Arguments:
 *   0: Passenger group ID <STRING>
 *   1: Passenger group data <HASHMAP>
 *   2: Carrier group ID <STRING>
 *   3: Carrier group data <HASHMAP>
 *   4: Destination position <ARRAY>
 *   5: Request spec <HASHMAP> - Optional
 *
 * Return Value:
 *   HASHMAP - Mission plan
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_passengerData", createHashMap, [createHashMap]],
    ["_carrierGroupId", "", [""]],
    ["_carrierData", createHashMap, [createHashMap]],
    ["_destinationPos", [0, 0, 0], [[]]],
    ["_requestSpec", createHashMap, [createHashMap]]
];

if (_passengerGroupId == "" || {_carrierGroupId == ""}) exitWith {
    throw "[TRANSPORT] Mission plan requires passenger and carrier IDs";
};
if !([_destinationPos, true, format [
    "transportBuildMissionPlan passenger=%1 carrier=%2",
    _passengerGroupId,
    _carrierGroupId
]] call FLO_fnc_validateGroupPosition) exitWith {
    createHashMap
};

private _carrierType = _carrierData get "groupType";
private _pickupPos = _passengerData get "position";
private _side = _passengerData get "side";
private _forcedMode = toUpper (_requestSpec getOrDefault ["forceMode", ""]);
private _allowAirLand = _requestSpec getOrDefault ["allowAirLand", true];
private _allowAirDrop = _requestSpec getOrDefault ["allowAirDrop", true];
private _orderTag = _requestSpec getOrDefault ["orderTag", "TRANSPORT_REQUEST"];
private _mode = "GROUND";
private _insertPos = _destinationPos getPos [
    FLO_Transport_DismountDistance,
    _destinationPos getDir _pickupPos
];
private _completionRadius = 50;

if (_carrierType != "helicopter") then {
    if (_forcedMode != "" && {_forcedMode != "GROUND"}) then {
        throw format [
            "[TRANSPORT] Carrier %1 type=%2 cannot execute forced mode %3",
            _carrierGroupId,
            _carrierType,
            _forcedMode
        ];
    };
} else {
    private _objectiveId = [_destinationPos] call FLO_fnc_getNearestObjective;
    private _objectiveData = createHashMap;
    private _objectivePos = [];
    private _objectiveRadius = 0;
    private _nearObjective = false;

    if (_objectiveId != "") then {
        _objectiveData = FLO_Objectives get _objectiveId;
        _objectivePos = _objectiveData get "position";
        _objectiveRadius = _objectiveData get "radius";
        _nearObjective = (_destinationPos distance2D _objectivePos) <= ((_objectiveRadius max 200) * 1.5);
    };

    private _objectiveOwner = sideUnknown;
    private _enemyOwned = false;
    private _underPressure = false;
    private _hasAA = false;
    private _enemyNearby = [_side, _destinationPos, FLO_Transport_ThreatDismountRadius * 2] call FLO_fnc_transportHasKnownEnemyNearby;
    private _airDropThreatSignals = 0;
    private _objectiveAnchorPos = if (_nearObjective) then { _objectivePos } else { _destinationPos };

    if (_nearObjective) then {
        _objectiveOwner = _objectiveData get "owner";
        if (_objectiveOwner isEqualType "") then {
            private _ownerKey = toUpper _objectiveOwner;
            if (_ownerKey == "EAST") then { _objectiveOwner = east; };
            if (_ownerKey == "WEST") then { _objectiveOwner = west; };
        };
        _enemyOwned = _objectiveOwner != _side;

        private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
        private _gtnCommander = FLO_GTN_CommandersBySide get _sideKey;
        private _worldState = _gtnCommander get "_worldState";
        private _objectiveState = (_worldState call ["_getObjectives", []]) get _objectiveId;
        if (!isNil "_objectiveState") then {
            _underPressure = (_objectiveState get "contested") || { _objectiveState get "underAttack" };
        };

        private _objectiveAnalysis = _worldState call ["_getObjectiveAnalysis", [_objectiveId]];
        if (!isNil "_objectiveAnalysis") then {
            _hasAA = _objectiveAnalysis get "hasAA";
        };
    };

    if (_enemyOwned) then { _airDropThreatSignals = _airDropThreatSignals + 1; };
    if (_underPressure) then { _airDropThreatSignals = _airDropThreatSignals + 1; };
    if (_enemyNearby) then { _airDropThreatSignals = _airDropThreatSignals + 1; };

    if (_forcedMode != "") then {
        if !(_forcedMode in ["AIR_LAND", "AIR_DROP"]) then {
            throw format [
                "[TRANSPORT] Invalid forced transport mode %1 for carrier %2",
                _forcedMode,
                _carrierGroupId
            ];
        };
        if (_forcedMode == "AIR_LAND" && {!_allowAirLand}) then {
            throw format [
                "[TRANSPORT] Forced AIR_LAND requested for %1 but air land is disabled",
                _passengerGroupId
            ];
        };
        if (_forcedMode == "AIR_DROP" && {!_allowAirDrop}) then {
            throw format [
                "[TRANSPORT] Forced AIR_DROP requested for %1 but paradrop is disabled",
                _passengerGroupId
            ];
        };
        _mode = _forcedMode;
    } else {
        if (
            _allowAirDrop
            && {!_hasAA}
            && {_airDropThreatSignals >= FLO_Transport_AirDropMinThreatSignals}
            && {(!FLO_Transport_AirDropRequireEnemyNearby) || {_enemyNearby}}
        ) then {
            _mode = "AIR_DROP";
        } else {
            if (!_allowAirLand) exitWith {
                throw format [
                    "[TRANSPORT] AIR_LAND disabled for helicopter transport request %1",
                    _passengerGroupId
                ];
            };
            _mode = "AIR_LAND";
        };
    };

    if (_mode == "AIR_LAND") then {
        if (_enemyOwned || {_underPressure} || {_enemyNearby} || {_hasAA}) then {
            private _standoff = if (_nearObjective) then {
                (_objectiveRadius max FLO_Transport_DismountDistance) + (if (_hasAA) then { 350 } else { 225 })
            } else {
                FLO_Transport_DismountDistance max 250
            };
            _insertPos = [_objectiveAnchorPos getPos [_standoff, _objectiveAnchorPos getDir _pickupPos], 900] call FLO_fnc_getSafeLandPos;
        } else {
            _insertPos = [_destinationPos, 900] call FLO_fnc_getSafeLandPos;
        };
        _completionRadius = 90;
    } else {
        private _dzAnchor = if (_nearObjective) then {
            _objectiveAnchorPos getPos [
                (((_objectiveRadius * 0.35) max 80) min 220),
                _objectiveAnchorPos getDir _pickupPos
            ]
        } else {
            _destinationPos
        };
        _insertPos = [_dzAnchor, 900] call FLO_fnc_getSafeLandPos;
        _completionRadius = 120;
    };
};

createHashMapFromArray [
    ["mode", _mode],
    ["insertPos", _insertPos],
    ["completionRadius", _completionRadius],
    ["orderTag", _orderTag],
    ["finalDestination", _destinationPos]
]
