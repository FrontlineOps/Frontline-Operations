/*
 * Function: FLO_fnc_virtualizationBuildPatrolPlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds persistent virtual patrol waypoints and patrol config for a group.
 */

params [
    "_groupData",
    ["_centerOverride", [], [[]]]
];

private _groupType = _groupData get "groupType";
private _patrolCenter = [];

if (count _centerOverride >= 2) then {
    _patrolCenter = +_centerOverride;
} else {
    private _homeObjective = _groupData get "homeObjective";
    if (_homeObjective != "" && {!(isNil "FLO_Objectives")} && {_homeObjective in FLO_Objectives}) then {
        private _objData = FLO_Objectives get _homeObjective;
        _patrolCenter = +(_objData get "position");
    } else {
        _patrolCenter = +(_groupData get "position");
    };
};

if (count _patrolCenter > 2) then {
    _patrolCenter resize 2;
};

private _rangeConfig = switch (_groupType) do {
    case "infantry": { [100, 400] };
    case "motorized": { [300, 800] };
    case "mechanized": { [250, 600] };
    case "armor": { [200, 500] };
    default { [100, 400] };
};
_rangeConfig params ["_minDist", "_maxDist"];

private _centerOffset = _minDist + random (_maxDist - _minDist);
private _centerDir = random 360;
private _offsetCenter = _patrolCenter getPos [_centerOffset * 0.5, _centerDir];
private _wpCount = 4 + floor random 5;
private _startAngle = random 360;
private _patrolWaypoints = [];

for "_i" from 0 to (_wpCount - 1) do {
    private _baseAngle = _startAngle + (_i * (360 / _wpCount));
    private _angle = _baseAngle + (random 60 - 30);
    private _dist = _minDist + random (_maxDist - _minDist);
    private _wpPos = _offsetCenter getPos [_dist, _angle];
    if !(surfaceIsWater _wpPos) then {
        _patrolWaypoints pushBack [_wpPos, "MOVE", "AWARE", "LIMITED", "STAG COLUMN", "YELLOW", 15];
    };
};

if (_patrolWaypoints isEqualTo []) exitWith { [] };

[
    _patrolWaypoints,
    [_offsetCenter, (_minDist + _maxDist) / 2, count _patrolWaypoints, "AWARE", "LIMITED"]
]
