/* Advances formation roles through bounded, non-blocking state transitions. */
params [
    "_state",
    "_director"
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _formations = _state get "formations";
private _campaignState = _director call ["_getState", []];
private _operations = _campaignState get "operations";
private _fronts = _campaignState get "frontlineProbes";
private _frontByFormation = createHashMap;
{
    private _probeId = _x;
    {
        if !(_x in _formations) then {
            private _message = format ["Probe front %1 references missing formation %2", _probeId, _x];
            ["FORMATIONS", 1, _message] call FLO_fnc_log;
            throw _message;
        };
        if (_x in _frontByFormation) then {
            private _message = format [
                "Probe fronts %1 and %2 both own formation %3",
                _frontByFormation get _x,
                _probeId,
                _x
            ];
            ["FORMATIONS", 1, _message] call FLO_fnc_log;
            throw _message;
        };
        _frontByFormation set [_x, _probeId];
    } forEach (_y get "formationIds");
} forEach _fronts;
private _now = call FLO_fnc_operationalDateNumber;
private _changed = false;
private _campaignChanged = false;

{
    private _formationId = _x;
    private _formation = _y;
    private _sideKey = _formation get "sideKey";
    private _cmdr = FLO_GTN_CommandersBySide get _sideKey;
    private _side = [_sideKey] call FLO_fnc_campaignSideFromKey;
    private _livingMembers = (_formation get "memberIds") select { _x in _groups && {((_groups get _x) get "unitCount") > 0} };
    private _role = _formation get "role";

    if (_role == "RESERVE") then {
        if ((_formation get "roleMemberIds") isEqualTo [] && {(_formation get "roleOperationId") != ""}) then {
            _formation set ["roleOperationId", ""];
            _formation set ["returnObjectiveId", ""];
            _changed = true;
        };
        private _attackMembers = _livingMembers select { ((_groups get _x) get "commanderOrder") == "ATTACK" };
        if (_attackMembers isNotEqualTo []) then {
            private _operationId = (_groups get (_attackMembers select 0)) get "campaignOperationId";
            if (_operationId != "" && {_operationId in _operations}) then {
                _formation set ["role", "MAIN"];
                _formation set ["roleMemberIds", _attackMembers];
                _formation set ["roleObjectiveId", (_operations get _operationId) get "objectiveId"];
                _formation set ["roleOperationId", _operationId];
                _formation set ["roleStartedAtDateNum", _now];
                _formation set ["roleEndsAtDateNum", -1];
                _formation set ["returnObjectiveId", ""];
                _role = "MAIN";
                _changed = true;
            };
        };
    };

    if (_role == "MAIN") then {
        private _assignmentId = _formation get "roleOperationId";
        private _roleObjectiveId = _formation get "roleObjectiveId";
        private _activeAttackMembers = (_formation get "roleMemberIds") select {
            _x in _groups
            && {((_groups get _x) get "unitCount") > 0}
            && {((_groups get _x) get "commanderOrder") == "ATTACK"}
            && {((_groups get _x) get "campaignOperationId") == _assignmentId}
            && {((_groups get _x) get "attackObjective") == _roleObjectiveId}
        };
        if (_activeAttackMembers isNotEqualTo (_formation get "roleMemberIds")) then {
            _formation set ["roleMemberIds", _activeAttackMembers];
            _changed = true;
        };
        if (_formationId in _frontByFormation) then {
            private _front = _fronts get (_frontByFormation get _formationId);
            private _memberIds = _formation get "memberIds";
            private _currentCommittedIds = _front get "committedGroupIds";
            private _nextCommittedIds = _currentCommittedIds select { !(_x in _memberIds) };
            {
                _nextCommittedIds pushBackUnique _x;
            } forEach _activeAttackMembers;
            if (_nextCommittedIds isNotEqualTo _currentCommittedIds) then {
                _front set ["committedGroupIds", _nextCommittedIds];
                _campaignChanged = true;
            };
        };
        if (_activeAttackMembers isEqualTo []) then {
            _formation set ["role", "RECOVERY"];
            _formation set ["roleObjectiveId", _formation get "homeObjectiveId"];
            _formation set ["roleStartedAtDateNum", _now];
            _formation set ["roleEndsAtDateNum", [_now, 180] call FLO_fnc_dateNumberAddSeconds];
            _changed = true;
        };
        continue;
    };

    if (_role == "RECOVERY") then {
        if (_livingMembers isEqualTo [] && {_formationId in _frontByFormation}) then {
            private _probeId = _frontByFormation get _formationId;
            private _front = _fronts get _probeId;
            private _memberIds = _formation get "memberIds";
            _front set [
                "committedGroupIds",
                (_front get "committedGroupIds") select { !(_x in _memberIds) }
            ];
            _front set [
                "formationIds",
                (_front get "formationIds") select { _x != _formationId }
            ];
            [_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
            _formation set ["roleOperationId", ""];
            _campaignChanged = true;
            _changed = true;
        };
        private _endsAt = _formation get "roleEndsAtDateNum";
        if (_livingMembers isNotEqualTo [] && {_endsAt >= 0} && {([_now, _endsAt] call FLO_fnc_dateNumberDeltaSeconds) <= 0}) then {
            if (_formationId in _frontByFormation) then {
                private _probeId = _frontByFormation get _formationId;
                private _front = _fronts get _probeId;
                private _memberIds = _formation get "memberIds";
                _front set [
                    "committedGroupIds",
                    (_front get "committedGroupIds") select { !(_x in _memberIds) }
                ];
                _front set [
                    "formationIds",
                    (_front get "formationIds") select { _x != _formationId }
                ];
                [_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
                _campaignChanged = true;
            };
            _formation set ["role", "RESERVE"];
            _formation set ["roleMemberIds", []];
            _formation set ["roleObjectiveId", ""];
            _formation set ["roleOperationId", ""];
            _formation set ["roleStartedAtDateNum", -1];
            _formation set ["roleEndsAtDateNum", -1];
            _formation set ["returnObjectiveId", ""];
            _changed = true;
        };
        continue;
    };

    private _roleMemberIds = (_formation get "roleMemberIds") select { _x in _groups };
    _formation set ["roleMemberIds", _roleMemberIds];
    if (_roleMemberIds isEqualTo []) then {
        _formation set ["role", "RECOVERY"];
        _formation set ["roleObjectiveId", _formation get "homeObjectiveId"];
        _formation set ["roleOperationId", ""];
        _formation set ["roleEndsAtDateNum", -1];
        _changed = true;
        continue;
    };

    if (_role == "FEINT") then {
        private _targetId = _formation get "roleObjectiveId";
        private _returnId = _formation get "returnObjectiveId";
        private _feintEnded = ([_now, _formation get "roleEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0;
        if !(_targetId in FLO_Objectives) then { _feintEnded = true; } else {
            if (((FLO_Objectives get _targetId) get "owner") isEqualTo _side) then { _feintEnded = true; };
        };
        if (_feintEnded) then {
            if !(_returnId in FLO_Objectives) then {
                _cmdr call ["_releaseGroups", [_roleMemberIds, ""]];
                _formation set ["role", "RECOVERY"];
                _formation set ["roleMemberIds", []];
                _formation set ["roleEndsAtDateNum", [_now, 180] call FLO_fnc_dateNumberAddSeconds];
            } else {
                private _returnPosition = (FLO_Objectives get _returnId) get "position";
                _cmdr call ["_releaseGroups", [_roleMemberIds, ""]];
                { _cmdr call ["_orderGroupMove", [_x, _returnPosition getPos [(_forEachIndex mod 3) * 40, _forEachIndex * 120], "AWARE"]]; } forEach _roleMemberIds;
                _formation set ["role", "FEINT_RETURN"];
                _formation set ["roleObjectiveId", _returnId];
                _formation set ["roleEndsAtDateNum", [_now, 180] call FLO_fnc_dateNumberAddSeconds];
            };
            _changed = true;
        };
        continue;
    };

    if (_role in ["FEINT_RETURN", "WITHDRAW"]) then {
        private _targetId = _formation get "roleObjectiveId";
        private _complete = !(_targetId in FLO_Objectives);
        if (!_complete) then {
            private _target = FLO_Objectives get _targetId;
            private _leadId = _roleMemberIds select 0;
            _complete = ((_groups get _leadId) get "position") distance2D (_target get "position") <= ((_target get "radius") max 200);
        };
        if (([_now, _formation get "roleEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0) then { _complete = true; };
        if (_complete) then {
            _cmdr call ["_releaseGroups", [_roleMemberIds, ""]];
            private _operationId = _formation get "roleOperationId";
            if (_role == "FEINT_RETURN" && {_operationId in _operations}) then {
                private _operation = _operations get _operationId;
                _operation set ["shapingStatus", "FEINT_COMPLETE"];
                [_operation] call FLO_fnc_campaignValidateOperationalState;
                _campaignChanged = true;
            };
            _formation set ["role", "RECOVERY"];
            _formation set ["roleMemberIds", []];
            _formation set ["roleObjectiveId", _formation get "homeObjectiveId"];
            _formation set ["roleOperationId", ""];
            _formation set ["roleStartedAtDateNum", _now];
            _formation set ["roleEndsAtDateNum", [_now, 180] call FLO_fnc_dateNumberAddSeconds];
            _formation set ["returnObjectiveId", ""];
            _changed = true;
        };
        continue;
    };

    if (_role == "EXPLOIT") then {
        private _targetId = _formation get "roleObjectiveId";
        private _operationId = _formation get "roleOperationId";
        private _status = "";
        if !(_targetId in FLO_Objectives) then {
            _status = "ABORTED";
        } else {
            private _target = FLO_Objectives get _targetId;
            if ((_target get "owner") isEqualTo _side) then {
                _status = "COMPLETE";
            } else {
                private _worldObjective = ((_cmdr get "_worldState") call ["_getObjectives", []]) get _targetId;
                if ((_worldObjective get "enemyCount") > 12 || {(_worldObjective get "enemyCount") > ((_worldObjective get "friendlyCount") + 8)}) then {
                    _status = "ABORTED";
                };
            };
        };
        if ((_formation get "readiness") < 35 || {([_now, _formation get "roleEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0}) then {
            _status = "ABORTED";
        };
        private _sourceId = _formation get "returnObjectiveId";
        if !(_sourceId in FLO_Objectives) then { _status = "ABORTED"; } else {
            if (((FLO_Objectives get _sourceId) get "owner") isNotEqualTo _side) then { _status = "ABORTED"; };
        };
        if (_status != "") then {
            _cmdr call ["_releaseGroups", [_roleMemberIds, ""]];
            if (_status == "COMPLETE") then {
                _formation set ["experience", ((_formation get "experience") + 5) min 100];
            };
            if (_operationId in _operations) then {
                private _operation = _operations get _operationId;
                _operation set ["exploitationStatus", _status];
                [_operation] call FLO_fnc_campaignValidateOperationalState;
                _campaignChanged = true;
            };
            _formation set ["role", "RECOVERY"];
            _formation set ["roleMemberIds", []];
            _formation set ["roleObjectiveId", _formation get "homeObjectiveId"];
            _formation set ["roleOperationId", ""];
            _formation set ["roleStartedAtDateNum", _now];
            _formation set ["roleEndsAtDateNum", [_now, 240] call FLO_fnc_dateNumberAddSeconds];
            _formation set ["returnObjectiveId", ""];
            _changed = true;
        };
    };
} forEach _formations;

{
    private _front = _y;
    if (
        (_front get "formalOperationId") == ""
        && {(_front get "committedGroupIds") isEqualTo []}
        && {!((_front get "stage") in ["PROBE", "REGROUP"])}
    ) then {
        private _cmdr = FLO_GTN_CommandersBySide get (_front get "sideKey");
        [_director, _cmdr, _front, "PROBE_FORCE_RELEASED"] call FLO_fnc_campaignReleaseProbeFront;
        _campaignChanged = true;
    };
} forEach _fronts;

if (_changed) then {
    _state set ["revision", (_state get "revision") + 1];
};
if (_campaignChanged) then {
    _campaignState set ["revision", (_campaignState get "revision") + 1];
    [_campaignState] call FLO_fnc_campaignSyncPrimaryProjection;
};
_changed
