/*
 * Function: FLO_fnc_gtnPickObjectiveGarrisonPosition
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Picks a dispersed hold position inside an objective for a standing
 *   garrison, preferring positions away from existing claimed garrison slots.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Objective ID <STRING>
 * 2: Claimed Positions <ARRAY>
 *
 * Return Value:
 * Position <ARRAY>
 */

params [
    ["_cmdr", nil],
    ["_objectiveId", ""],
    ["_claimedPositions", [], [[]]]
];

private _ws = _cmdr get "_worldState";
private _objective = FLO_Objectives get _objectiveId;
private _center = _objective get "position";
private _radius = _objective get "radius";

private _minRadius = ((_radius * 0.35) max 40) min _radius;
private _maxRadius = ((_radius * 0.85) max (_minRadius + 10)) min (_radius max (_minRadius + 10));
private _sampleCount = (10 + (count _claimedPositions) * 2) min 24;
private _preferredRadius = (_minRadius + _maxRadius) * 0.5;

private _bestPos = [];
private _bestScore = -1e12;

for "_i" from 1 to _sampleCount do {
    private _dir = random 360;
    private _dist = _minRadius + random ((_maxRadius - _minRadius) max 1);
    private _candidatePos = _center getPos [_dist, _dir];
    _candidatePos set [2, 0];

    if !([_candidatePos, _objective] call FLO_fnc_isPositionInObjective) then { continue };

    private _nearestClaim = _radius;
    {
        private _claimPos = _x;
        if !(_claimPos isEqualType [] && {count _claimPos >= 2}) then { continue };
        private _claimDist = _candidatePos distance2D _claimPos;
        if (_claimDist < _nearestClaim) then {
            _nearestClaim = _claimDist;
        };
    } forEach _claimedPositions;

    private _ringPenalty = abs ((_candidatePos distance2D _center) - _preferredRadius);
    private _score = (_nearestClaim * 3) - _ringPenalty;

    if (_score > _bestScore) then {
        _bestScore = _score;
        _bestPos = _candidatePos;
    };
};

if ((count _bestPos) >= 2) exitWith { _bestPos };

[_objectiveId] call FLO_fnc_getRandomObjectivePos
