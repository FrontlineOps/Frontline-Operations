/* Builds one protected static-building or cyclic-patrol garrison route. */
params [
    ["_cmdr", nil],
    ["_objectiveId", "", [""]],
    ["_claimedPositions", [], [[]]],
    ["_slotIndex", 0, [0]],
    ["_groupType", "", [""]]
];

if (isNil "_cmdr") then {
    throw "FLO_fnc_gtnBuildObjectiveGarrisonRoute: missing commander";
};
if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) then {
    throw format ["FLO_fnc_gtnBuildObjectiveGarrisonRoute: invalid objective %1", _objectiveId];
};
if (_slotIndex < 0 || {_slotIndex != floor _slotIndex}) then {
    throw format ["FLO_fnc_gtnBuildObjectiveGarrisonRoute: invalid slot %1", _slotIndex];
};
if (_groupType == "") then {
    throw "FLO_fnc_gtnBuildObjectiveGarrisonRoute: empty group type";
};

private _objective = FLO_Objectives get _objectiveId;
private _center = _objective get "position";
private _radius = _objective get "radius";
private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND", "LINE", "COLUMN"];
private _buildingSlot = _groupType == "infantry" && {(_slotIndex mod 2) == 0};

if (_buildingSlot) exitWith {
    private _rankedPositions = [];
    {
        private _building = _x;
        {
            private _position = _x;
            if (_position isEqualTo [0, 0, 0]) then { continue };
            if (surfaceIsWater _position) then { continue };
            if !([_position, _objective] call FLO_fnc_isPositionInObjective) then { continue };

            private _nearestClaim = _radius;
            {
                private _claim = _x;
                if (!(_claim isEqualType []) || {count _claim < 2}) then { continue };
                _nearestClaim = _nearestClaim min (_position distance2D _claim);
            } forEach _claimedPositions;
            _rankedPositions pushBack [-_nearestClaim, _position distance2D _center, _position];
        } forEach (_building buildingPos -1);
    } forEach (nearestObjects [_center, ["House"], _radius, true]);
    _rankedPositions sort true;

    private _usedBuilding = _rankedPositions isNotEqualTo [];
    private _targetPos = if (_usedBuilding) then {
        +((_rankedPositions select 0) select 2)
    } else {
        [_cmdr, _objectiveId, _claimedPositions] call FLO_fnc_gtnPickObjectiveGarrisonPosition
    };
    createHashMapFromArray [
        ["orderMode", "GARRISON_BUILDING"],
        ["targetPos", _targetPos],
        ["waypoints", [
            [_targetPos, "MOVE", "SAFE", "LIMITED", _formation, "GREEN", 12],
            [_targetPos, "HOLD", "AWARE", "LIMITED", _formation, "YELLOW", 8]
        ]],
        ["usedBuilding", _usedBuilding]
    ]
};

private _routePositions = [];
private _routeClaims = +_claimedPositions;
for "_routeIndex" from 0 to 2 do {
    private _patrolPos = [_cmdr, _objectiveId, _routeClaims] call FLO_fnc_gtnPickObjectiveGarrisonPosition;
    _routePositions pushBack _patrolPos;
    _routeClaims pushBack _patrolPos;
};
private _targetPos = _routePositions select 0;
private _waypoints = _routePositions apply {
    [_x, "MOVE", "SAFE", "LIMITED", _formation, "GREEN", 35]
};
_waypoints pushBack [_targetPos, "CYCLE", "SAFE", "LIMITED", _formation, "GREEN", 35];

createHashMapFromArray [
    ["orderMode", "GARRISON_PATROL"],
    ["targetPos", _targetPos],
    ["waypoints", _waypoints],
    ["usedBuilding", false]
]
