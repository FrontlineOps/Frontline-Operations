/*
 * Function: FLO_fnc_findWaterDetour
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds a coarse land detour for a water-crossing segment by probing
 *   perpendicular pivots around the sampled water span.
 *
 * Arguments:
 *   0: Start position <ARRAY>
 *   1: End position <ARRAY>
 *   2: Water profile array from FLO_fnc_pathSegmentWaterProfile <ARRAY>
 *   3: Sample step meters <NUMBER>
 *
 * Return Value:
 *   [detourPoints, sampleCount]
 */

params [
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_endPos", [0, 0, 0], [[]], [2, 3]],
    ["_profile", [false, 0, [], [], [], []], [[]]],
    ["_sampleStep", 180, [0]]
];

_profile params [
    ["_crossesWater", false, [true]],
    ["_baseSamples", 0, [0]],
    ["_lastLandBefore", [], [[]]],
    ["_firstWater", [], [[]]],
    ["_lastWater", [], [[]]],
    ["_firstLandAfter", [], [[]]]
];

if (!_crossesWater) exitWith { [[], 0] };

private _sampleCount = 0;
private _detour = [];
private _segmentDir = _startPos getDir _endPos;
private _waterSpan = (_firstWater distance2D _lastWater) max (_sampleStep * 1.5);
private _spanMid = [
    (((_firstWater select 0) + (_lastWater select 0)) * 0.5),
    (((_firstWater select 1) + (_lastWater select 1)) * 0.5),
    0
];
private _entryAnchor = [
    (((_lastLandBefore select 0) + (_firstWater select 0)) * 0.5),
    (((_lastLandBefore select 1) + (_firstWater select 1)) * 0.5),
    0
];
private _exitAnchor = [
    (((_lastWater select 0) + (_firstLandAfter select 0)) * 0.5),
    (((_lastWater select 1) + (_firstLandAfter select 1)) * 0.5),
    0
];
private _offsetStep = FLO_PF_WaterDetourStep;
private _offsetMax = FLO_PF_WaterDetourMax;
private _offsetStart = ((_waterSpan * 0.8) max FLO_PF_WaterDetourBaseOffset) min _offsetMax;

for "_offset" from _offsetStart to _offsetMax step _offsetStep do {
    {
        private _sideDir = _segmentDir + _x;
        private _candidate = _spanMid getPos [_offset, _sideDir];
        if (surfaceIsWater _candidate) then {
            _candidate = [_candidate, ((_offset * 0.75) max 250)] call FLO_fnc_getSafeLandPos;
        };
        if (surfaceIsWater _candidate) then { continue };

        private _leftProfile = [_startPos, _candidate, _sampleStep] call FLO_fnc_pathSegmentWaterProfile;
        private _rightProfile = [_candidate, _endPos, _sampleStep] call FLO_fnc_pathSegmentWaterProfile;
        _sampleCount = _sampleCount + (_leftProfile select 1) + (_rightProfile select 1);

        if (!(_leftProfile select 0) && {!(_rightProfile select 0)}) exitWith {
            _detour = [+_candidate];
        };

        private _entryDetour = _entryAnchor getPos [_offset, _sideDir];
        if (surfaceIsWater _entryDetour) then {
            _entryDetour = [_entryDetour, ((_offset * 0.75) max 250)] call FLO_fnc_getSafeLandPos;
        };
        if (surfaceIsWater _entryDetour) then { continue };

        private _exitDetour = _exitAnchor getPos [_offset, _sideDir];
        if (surfaceIsWater _exitDetour) then {
            _exitDetour = [_exitDetour, ((_offset * 0.75) max 250)] call FLO_fnc_getSafeLandPos;
        };
        if (surfaceIsWater _exitDetour) then { continue };

        private _legA = [_startPos, _entryDetour, _sampleStep] call FLO_fnc_pathSegmentWaterProfile;
        private _legB = [_entryDetour, _exitDetour, _sampleStep] call FLO_fnc_pathSegmentWaterProfile;
        private _legC = [_exitDetour, _endPos, _sampleStep] call FLO_fnc_pathSegmentWaterProfile;
        _sampleCount = _sampleCount + (_legA select 1) + (_legB select 1) + (_legC select 1);

        if (!(_legA select 0) && {!(_legB select 0)} && {!(_legC select 0)}) exitWith {
            _detour = [+_entryDetour, +_exitDetour];
        };
    } forEach [90, -90];

    if (_detour isNotEqualTo []) exitWith {};
};

[_detour, _sampleCount]
