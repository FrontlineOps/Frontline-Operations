/*
 * Function: FLO_fnc_minefieldResolveFrontlineAnchorJobStep
 * Author: Frontline Operations Development Group
 * Description:
 *   Advances the staged anchor-resolution portion of one queued minefield job.
 *
 * Arguments:
 * 0: Build job <HASHMAP>
 *
 * Return Value:
 * STRING - "pending", "complete", or "failed"
 */

params [["_job", createHashMap]];

if !(_job isEqualType createHashMap) exitWith { "failed" };

private _seed = _job get "seed";
private _resolveState = _job get "resolveState";
private _objectiveId = _job get "objectiveId";
private _center = _seed get "objectivePos";
private _radius = _seed get "objectiveRadius";
private _baseFacingDir = _seed get "baseFacingDir";
private _frontageHalfWidth = _seed get "frontageHalfWidth";
private _fieldDepth = _seed get "fieldDepth";
private _objectiveArea = _job get "objectiveArea";
private _blockingObjectiveIds = _job get "blockingObjectiveIds";
private _outsideOffset = ((_radius * 0.2) max 18) min 40;
private _anchorDistance = _radius + _outsideOffset;
private _sampleOffsets = [
    -_frontageHalfWidth,
    -(_frontageHalfWidth * 0.5),
    0,
    (_frontageHalfWidth * 0.5),
    _frontageHalfWidth
];
private _depthSamples = [0, _fieldDepth * 0.5, _fieldDepth];
private _angles = _resolveState get "angleOffsets";
private _nextIndex = _resolveState get "nextIndex";
private _angleBatchCount = (FLO_MinefieldConfig get "buildResolveAngleBatch") max 1;
private _sampleBatchCount = (FLO_MinefieldConfig get "buildResolveSampleBatch") max 1;
private _tStart = diag_tickTime;
private _sampleOffsetCount = count _sampleOffsets;
private _totalSamplesPerAngle = _sampleOffsetCount * (count _depthSamples);
private _anglesResolved = 0;
private _pendingResolve = false;

while {!_pendingResolve && {_anglesResolved < _angleBatchCount}} do {
    private _pendingAnchorPos = _resolveState get "pendingAnchorPos";
    if ((count _pendingAnchorPos) == 0) then {
        if (_nextIndex >= count _angles) exitWith {};

        private _angleOffset = _angles select _nextIndex;
        private _candidateFacingDir = _baseFacingDir + _angleOffset;
        private _candidateAnchorPos = _center getPos [_anchorDistance, _candidateFacingDir];
        _candidateAnchorPos set [2, 0];
        _nextIndex = _nextIndex + 1;

        if (surfaceIsWater _candidateAnchorPos) then {
            _anglesResolved = _anglesResolved + 1;
            continue;
        };
        if ([_candidateAnchorPos, _objectiveArea] call FLO_fnc_minefieldIsPositionInsideObjectiveArea) then {
            _anglesResolved = _anglesResolved + 1;
            continue;
        };
        if (([_candidateAnchorPos, [_objectiveId], _blockingObjectiveIds] call FLO_fnc_minefieldGetBlockingObjectiveId) != "") then {
            _anglesResolved = _anglesResolved + 1;
            continue;
        };

        _resolveState set ["pendingAnchorPos", _candidateAnchorPos];
        _resolveState set ["pendingFacingDir", _candidateFacingDir];
        _resolveState set ["pendingSampleIndex", 0];
        _resolveState set ["pendingValidSampleCount", 0];
        _resolveState set ["pendingSampleCount", _totalSamplesPerAngle];
    };

    private _candidateFacingDir = _resolveState get "pendingFacingDir";
    private _candidateAnchorPos = _resolveState get "pendingAnchorPos";
    private _sampleIndex = _resolveState get "pendingSampleIndex";
    private _validSampleCount = _resolveState get "pendingValidSampleCount";
    private _sampleCount = _resolveState get "pendingSampleCount";
    private _samplesProcessed = 0;

    while {_sampleIndex < _sampleCount && {_samplesProcessed < _sampleBatchCount}} do {
        private _depthIndex = floor (_sampleIndex / _sampleOffsetCount);
        private _lateralIndex = _sampleIndex mod _sampleOffsetCount;
        private _depthOffset = _depthSamples select _depthIndex;
        private _lateralOffset = _sampleOffsets select _lateralIndex;

        private _forwardSamplePos = _candidateAnchorPos getPos [_depthOffset, _candidateFacingDir];
        _forwardSamplePos set [2, 0];

        private _samplePos = _forwardSamplePos getPos [
            abs _lateralOffset,
            _candidateFacingDir + (if (_lateralOffset >= 0) then { 90 } else { 270 })
        ];
        _samplePos set [2, 0];

        if !(surfaceIsWater _samplePos) then {
            if !([_samplePos, _objectiveArea] call FLO_fnc_minefieldIsPositionInsideObjectiveArea) then {
                if (([_samplePos, [_objectiveId], _blockingObjectiveIds] call FLO_fnc_minefieldGetBlockingObjectiveId) == "") then {
                    _validSampleCount = _validSampleCount + 1;
                };
            };
        };

        _sampleIndex = _sampleIndex + 1;
        _samplesProcessed = _samplesProcessed + 1;
    };

    _resolveState set ["pendingSampleIndex", _sampleIndex];
    _resolveState set ["pendingValidSampleCount", _validSampleCount];

    if (_sampleIndex < _sampleCount) then {
        _pendingResolve = true;
    } else {
        private _angleOffset = ((_candidateFacingDir - _baseFacingDir + 540) % 360) - 180;
        if (_validSampleCount >= ceil (_sampleCount * 0.65)) then {
            private _candidateScore = (_validSampleCount * 100) - (abs _angleOffset);
            if (_candidateScore > (_resolveState get "bestScore")) then {
                _resolveState set ["bestScore", _candidateScore];
                _resolveState set ["bestAnchorPos", _candidateAnchorPos];
                _resolveState set ["bestFacingDir", _candidateFacingDir];
            };
        };

        _resolveState set ["pendingAnchorPos", []];
        _resolveState set ["pendingFacingDir", 0];
        _resolveState set ["pendingSampleIndex", -1];
        _resolveState set ["pendingValidSampleCount", 0];
        _resolveState set ["pendingSampleCount", 0];
        _anglesResolved = _anglesResolved + 1;
    };
};

_resolveState set ["nextIndex", _nextIndex];
private _metrics = _job get "metrics";
_metrics set ["resolveMs", (_metrics get "resolveMs") + ((diag_tickTime - _tStart) * 1000)];

if (_pendingResolve || {_nextIndex < count _angles}) exitWith { "pending" };
if ((count (_resolveState get "bestAnchorPos")) == 0) exitWith {
    _metrics set ["reason", "NO_ANCHOR"];
    "failed"
};

private _context = +_seed;
_context set ["anchorPos", _resolveState get "bestAnchorPos"];
_context set ["facingDir", _resolveState get "bestFacingDir"];
_context set ["objectiveArea", _objectiveArea];
_context set ["blockingObjectiveIds", _blockingObjectiveIds];
_job set ["context", _context];

"complete"
