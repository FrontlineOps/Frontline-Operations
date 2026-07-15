/* Starts one bounded ASSAULT-only deception movement. */
params [
    "_director",
    ["_operationId", "", [""]]
];

if (isNil "FLO_FormationState") then { throw "Feint requested before formation initialization"; };
private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
if ((_operation get "phase") != "ASSAULT" || {(_operation get "priorityRole") != "MAIN_EFFORT"}) exitWith { false };
if ((_operation get "doctrine") != "DECEPTION" || {(_operation get "shapingStatus") != "NONE"}) exitWith { false };

private _sideKey = _operation get "attackerSideKey";
private _side = [_sideKey] call FLO_fnc_campaignSideFromKey;
private _enemySide = [_operation get "defenderSideKey"] call FLO_fnc_campaignSideFromKey;
private _cmdr = FLO_GTN_CommandersBySide get _sideKey;
private _worldObjectives = (_cmdr get "_worldState") call ["_getObjectives", []];
private _campaignState = _director call ["_getState", []];
private _mainObjectiveId = _operation get "objectiveId";
private _mainPosition = (FLO_Objectives get _mainObjectiveId) get "position";
private _activeTargets = [];
{
    _activeTargets pushBack ((_y) get "objectiveId");
} forEach (_campaignState get "operations");

private _targetRows = [];
{
    private _objectiveId = _x;
    private _objective = _y;
    if (_objectiveId == _mainObjectiveId || {_objectiveId in _activeTargets}) then { continue };
    if ((_objective get "owner") isNotEqualTo _enemySide) then { continue };
    if ((_objective get "position") distance2D _mainPosition > 5000) then { continue };
    private _reachable = false;
    {
        private _linked = FLO_Objectives get _x;
        if ((_linked get "owner") isEqualTo _side && {(_linked get "campaignIntegrationState") == "INTEGRATED"}) exitWith {
            _reachable = true;
        };
    } forEach (_objective get "linkedObjectives");
    if (!_reachable) then { continue };
    private _worldObjective = _worldObjectives get _objectiveId;
    private _score = -((_objective get "priority") * 10) + ((_worldObjective get "enemyCount") * 20) + round ((_objective get "position") distance2D _mainPosition);
    _targetRows pushBack [_score, _objectiveId];
} forEach FLO_Objectives;
_targetRows sort true;

private _formationRows = [];
private _groups = call FLO_fnc_virtualizationGetGroupMap;
{
    private _formation = _y;
    if ((_formation get "sideKey") != _sideKey || {(_formation get "role") != "RESERVE"}) then { continue };
    if ((_formation get "roleOperationId") != "") then { continue };
    if !((_formation get "branch") in ["infantry", "motorized", "mechanized", "armor"]) then { continue };
    private _livingMembers = (_formation get "memberIds") select { _x in _groups && {((_groups get _x) get "unitCount") > 0} };
    if ((count _livingMembers) < 3 || {(_formation get "readiness") < 55}) then { continue };
    private _leadId = _formation get "leadGroupId";
    _formationRows pushBack [((_groups get _leadId) get "position") distance2D _mainPosition, _x, _livingMembers];
} forEach (FLO_FormationState get "formations");
_formationRows sort true;

private _now = call FLO_fnc_operationalDateNumber;
if (_targetRows isEqualTo [] || {_formationRows isEqualTo []}) exitWith {
    _operation set ["shapingStatus", "FEINT_ABORTED"];
    _operation set ["assaultOpeningEligibleAtDateNum", _now];
    _campaignState set ["revision", (_campaignState get "revision") + 1];
    [_campaignState] call FLO_fnc_campaignSyncPrimaryProjection;
    [_operation] call FLO_fnc_campaignValidateOperationalState;
    false
};

private _targetId = (_targetRows select 0) select 1;
private _target = FLO_Objectives get _targetId;
private _formationId = (_formationRows select 0) select 1;
private _memberIds = (_formationRows select 0) select 2;
private _formation = (FLO_FormationState get "formations") get _formationId;
private _sourceIds = _operation get "sourceObjectiveIds";
if (_sourceIds isEqualTo []) then { throw format ["Operation %1 has no feint return source", _operationId]; };
private _returnObjectiveId = _sourceIds select 0;
private _returnPosition = (FLO_Objectives get _returnObjectiveId) get "position";
private _targetPosition = _target get "position";
private _approachDirection = _targetPosition getDir _returnPosition;
private _anchor = _targetPosition getPos [((_target get "radius") * 0.70) max 150, _approachDirection];

_cmdr call ["_releaseGroups", [_memberIds, ""]];
{
    private _offset = (_forEachIndex - (((count _memberIds) - 1) / 2)) * 45;
    private _destination = _anchor;
    if (_offset != 0) then {
        _destination = _anchor getPos [abs _offset, _approachDirection + ([90, -90] select (_offset < 0))];
    };
    _cmdr call ["_orderGroupMove", [_x, _destination, "AWARE"]];
} forEach _memberIds;

private _endsAt = [_now, 90] call FLO_fnc_dateNumberAddSeconds;
_formation set ["role", "FEINT"];
_formation set ["roleMemberIds", _memberIds];
_formation set ["roleObjectiveId", _targetId];
_formation set ["roleOperationId", _operationId];
_formation set ["roleStartedAtDateNum", _now];
_formation set ["roleEndsAtDateNum", _endsAt];
_formation set ["returnObjectiveId", _returnObjectiveId];
_operation set ["shapingStatus", "FEINT_ACTIVE"];
_operation set ["shapingFormationId", _formationId];
_operation set ["shapingObjectiveId", _targetId];
_operation set ["assaultOpeningEligibleAtDateNum", _endsAt];
FLO_FormationState set ["revision", (FLO_FormationState get "revision") + 1];
_campaignState set ["revision", (_campaignState get "revision") + 1];
[_campaignState] call FLO_fnc_campaignSyncPrimaryProjection;
[_operation] call FLO_fnc_campaignValidateOperationalState;
["FORMATIONS", 3, format ["%1 began a feint toward %2 for operation %3", _formation get "name", [_targetId] call FLO_fnc_campaignObjectiveName, _operationId]] call FLO_fnc_log;
true
