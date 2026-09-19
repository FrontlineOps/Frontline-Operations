/* Run through gtnRunCycleStep so force selection and reservation cannot yield. */
params ["_commander", "_entry", "_supportAdmitted"];
_entry params ["_negativeScore", "_objectiveId", "_kind"];
if (_kind in _supportAdmitted) exitWith { [0, 0] };
private _world = _commander get "_worldState";
private _objectives = _world get "_objectives";
private _picture = _world get "_strategicPicture";
private _objective = _objectives get _objectiveId;
private _stageId = _objectiveId;
private _targetPos = +(_objective get "position");
private _stageReady = true;
if (_kind == "CAPTURE") then {
    _targetPos = [_objectiveId, _objective] call FLO_fnc_gtnResolveAttackLandAnchor;
    if (_targetPos isEqualTo []) exitWith { _stageReady = false };
    private _sources = [];
    {
        private _source = _picture get _x;
        _sources pushBack [(_source get "threat") + (_source get "supplyExposure") * 15, -(_source get "friendlyLinks"), ((_objectives get _x) get "position") distance2D _targetPos, _x];
    } forEach ((_picture get _objectiveId) get "sources");
    _sources sort true;
    if (_sources isEqualTo []) exitWith { _stageReady = false };
    _stageId = (_sources select 0) select 3;
};
if (!_stageReady) exitWith { [0, 1] };
private _groupIds = [];
private _needsForces = _kind in ["GARRISON", "DEFEND", "CAPTURE"];
if (_needsForces) then {
    _groupIds = [_commander, _kind, _objectiveId, _stageId] call FLO_fnc_gtnSelectIntentForces;
};
if (_needsForces && {_groupIds isEqualTo []}) exitWith { [0, 1] };
if (!_needsForces) then { _supportAdmitted set [_kind, true] };
[_commander, _kind, _objectiveId, _groupIds, _stageId, (_objectives get _stageId) get "position", _targetPos, -_negativeScore] call FLO_fnc_gtnCreateIntent;
[1, 1]
