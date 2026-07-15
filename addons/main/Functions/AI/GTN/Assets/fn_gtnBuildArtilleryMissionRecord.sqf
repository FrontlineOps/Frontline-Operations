/*
 * Function: FLO_fnc_gtnBuildArtilleryMissionRecord
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the canonical artillery mission record used by the commander COP
 *   support layer and mission lifecycle tracking.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group data <HASHMAP>
 *   2: Target position <ARRAY>
 *   3: Number of rounds <NUMBER>
 *   4: Accuracy / dispersion meters <NUMBER>
 *   5: Deterministic fire plan <HASHMAP>
 *   6: Request kind <STRING>
 *   7: Target context <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - Artillery mission record
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", nil],
    ["_targetPos", [0, 0, 0], [[]], [3]],
    ["_rounds", 0, [0]],
    ["_accuracy", 100, [0]],
    ["_firePlan", createHashMap],
    ["_requestKind", "GENERAL", [""]],
    ["_targetContext", createHashMap, [createHashMap]]
];

private _targetGroupIds = [];
private _engagementZoneId = "";
private _contactState = "AREA";
private _contactConfidence = 1;
private _contactAgeSeconds = 0;
private _uncertaintyRadius = 0;
if ("targetGroupIds" in _targetContext) then { _targetGroupIds = +(_targetContext get "targetGroupIds"); };
if ("engagementZoneId" in _targetContext) then { _engagementZoneId = _targetContext get "engagementZoneId"; };
if ("contactState" in _targetContext) then { _contactState = _targetContext get "contactState"; };
if ("contactConfidence" in _targetContext) then { _contactConfidence = _targetContext get "contactConfidence"; };
if ("contactAgeSeconds" in _targetContext) then { _contactAgeSeconds = _targetContext get "contactAgeSeconds"; };
if ("uncertaintyRadius" in _targetContext) then { _uncertaintyRadius = _targetContext get "uncertaintyRadius"; };

private _impactPoints = [];
private _etaMin = -1;
private _etaMax = -1;
private _radius = ((_accuracy max 60) * 1.2) min 450;
private _plannedRounds = ceil _rounds;

if ((keys _firePlan) isNotEqualTo []) then {
    _plannedRounds = _firePlan get "plannedRounds";
    _impactPoints = _firePlan get "impactPoints";
    _etaMin = _firePlan get "etaMin";
    _etaMax = _firePlan get "etaMax";

    if (_impactPoints isNotEqualTo []) then {
        private _maxOffset = 0;
        {
            private _offset = _x distance2D _targetPos;
            if (_offset > _maxOffset) then {
                _maxOffset = _offset;
            };
        } forEach _impactPoints;

        private _plannedRadius = _maxOffset + 40;
        if (_plannedRadius > _radius) then {
            _radius = _plannedRadius;
        };
        if (_radius > 500) then {
            _radius = 500;
        };
    };
} else {
    private _distance = (_groupData get "position") distance2D _targetPos;
    private _gunCount = (_groupData get "unitCount") max 1;
    private _setupDelay = 10;
    private _cadenceSeconds = 4;
    private _flightSeconds = ((_distance / 240) * 1.35) max 4;
    private _roundsPerGun = ceil (_rounds / _gunCount);
    if (_roundsPerGun < 1 && {_rounds > 0}) then {
        _roundsPerGun = 1;
    };

    _etaMin = ceil (_setupDelay + _flightSeconds);
    _etaMax = ceil (_etaMin + (((_roundsPerGun max 1) - 1) * _cadenceSeconds));
};

private _issuedAt = diag_tickTime;
private _missionId = [] call FLO_fnc_createUUID;
private _etaEnd = _etaMax;
if (_etaEnd < _etaMin) then {
    _etaEnd = _etaMin;
};
if (_etaEnd < 0) then {
    _etaEnd = 15;
};

createHashMapFromArray [
    ["missionId", _missionId],
    ["groupId", _groupId],
    ["side", _groupData get "side"],
    ["targetPos", _targetPos],
    ["rounds", _rounds],
    ["plannedRounds", _plannedRounds],
    ["accuracy", _accuracy],
    ["requestKind", _requestKind],
    ["targetGroupIds", _targetGroupIds],
    ["engagementZoneId", _engagementZoneId],
    ["contactState", _contactState],
    ["contactConfidence", _contactConfidence],
    ["contactAgeSeconds", _contactAgeSeconds],
    ["uncertaintyRadius", _uncertaintyRadius],
    ["radius", _radius],
    ["impactPoints", _impactPoints],
    ["etaMin", _etaMin],
    ["etaMax", _etaMax],
    ["issuedAt", _issuedAt],
    ["expiresAt", _issuedAt + _etaEnd + 30],
    ["isLivePlan", (keys _firePlan) isNotEqualTo []],
    ["treasuryCost", 0],
    ["localSupplyCost", 0],
    ["supplyNodeId", ""],
    ["supplyObjectiveId", ""],
    ["sideReadyAt", -1],
    ["batteryReadyAt", -1],
    ["virtualLosses", 0],
    ["virtualGroupsHit", 0],
    ["virtualGroupsDestroyed", 0]
]
