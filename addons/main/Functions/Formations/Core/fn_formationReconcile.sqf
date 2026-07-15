/* Reconciles persistent formations against the authoritative virtual registry. */
params ["_state"];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _formations = _state get "formations";
private _changed = false;
private _deploymentMismatchCount = 0;

{
    private _formation = _y;
    private _sideKey = _formation get "sideKey";
    private _branch = _formation get "branch";
    private _eligibleMembers = (_formation get "memberIds") select {
        if !(_x in _groups) then { false } else {
            private _groupData = _groups get _x;
            private _memberSideKey = ([_groupData get "side"] call FLO_fnc_gtnSideContext) get "sideKey";
            _memberSideKey == _sideKey && {([_groupData] call FLO_fnc_formationClassifyBranch) == _branch}
        }
    };
    private _homeObjectiveId = _formation get "homeObjectiveId";
    if (_homeObjectiveId == "" && {_eligibleMembers isNotEqualTo []}) then {
        _homeObjectiveId = (_groups get (_eligibleMembers select 0)) get "homeObjective";
        _formation set ["homeObjectiveId", _homeObjectiveId];
        _changed = true;
    };
    private _validMembers = _eligibleMembers select {
        ((_groups get _x) get "homeObjective") == _homeObjectiveId
    };
    _deploymentMismatchCount = _deploymentMismatchCount + ((count _eligibleMembers) - count _validMembers);
    _validMembers sort true;
    if (_validMembers isNotEqualTo (_formation get "memberIds")) then {
        _formation set ["memberIds", _validMembers];
        _formation set ["roleMemberIds", (_formation get "roleMemberIds") select { _x in _validMembers }];
        _changed = true;
    };
    if (_validMembers isEqualTo []) then {
        if ((_formation get "leadGroupId") != "") then {
            _formation set ["leadGroupId", ""];
            _changed = true;
        };
        if ((_formation get "role") != "RECOVERY") then {
            _formation set ["role", "RECOVERY"];
            _formation set ["roleMemberIds", []];
            _formation set ["roleObjectiveId", ""];
            _formation set ["roleOperationId", ""];
            _formation set ["roleStartedAtDateNum", call FLO_fnc_operationalDateNumber];
            _formation set ["roleEndsAtDateNum", -1];
            _formation set ["returnObjectiveId", ""];
            _changed = true;
        };
    } else {
        if !((_formation get "leadGroupId") in _validMembers) then {
            _formation set ["leadGroupId", _validMembers select 0];
            _changed = true;
        };
    };
} forEach _formations;

private _index = [_state] call FLO_fnc_formationRebuildIndex;
private _candidateRows = [];
{
    private _groupId = _x;
    private _groupData = _y;
    if (_groupId in _index) then { continue };
    private _side = _groupData get "side";
    if !(_side in [west, east]) then { continue };
    private _branch = [_groupData] call FLO_fnc_formationClassifyBranch;
    if (_branch == "") then { continue };
    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    _candidateRows pushBack [_sideKey, _branch, _groupData get "homeObjective", _groupId];
} forEach _groups;
_candidateRows sort true;

private _remainingRows = [];
private _formationIds = keys _formations;
_formationIds sort true;
{
    _x params ["_sideKey", "_branch", "_homeObjectiveId", "_groupId"];
    private _assigned = false;
    scopeName "formationCandidate";
    {
        private _formation = _formations get _x;
        private _members = _formation get "memberIds";
        if ((_formation get "sideKey") != _sideKey || {(_formation get "branch") != _branch}) then { continue };
        if ((count _members) >= 3) then { continue };
        private _formationHomeObjectiveId = _formation get "homeObjectiveId";
        if (_formationHomeObjectiveId != "" && {_formationHomeObjectiveId != _homeObjectiveId}) then { continue };

        _members pushBack _groupId;
        _members sort true;
        _formation set ["memberIds", _members];
        if ((_formation get "leadGroupId") == "") then { _formation set ["leadGroupId", _groupId]; };
        if (_formationHomeObjectiveId == "") then { _formation set ["homeObjectiveId", _homeObjectiveId]; };
        if ((_formation get "role") == "RECOVERY" && {_formation get "roleEndsAtDateNum" < 0}) then {
            _formation set ["role", "RESERVE"];
            _formation set ["roleStartedAtDateNum", -1];
        };
        _assigned = true;
        _changed = true;
        breakOut "formationCandidate";
    } forEach _formationIds;
    if (!_assigned) then { _remainingRows pushBack _x; };
} forEach _candidateRows;

private _buckets = createHashMap;
{
    _x params ["_sideKey", "_branch", "_homeObjectiveId", "_groupId"];
    private _bucketKey = format ["%1|%2|%3", _sideKey, _branch, _homeObjectiveId];
    private _bucket = [];
    if (_bucketKey in _buckets) then { _bucket = _buckets get _bucketKey; };
    _bucket pushBack _groupId;
    _buckets set [_bucketKey, _bucket];
} forEach _remainingRows;

private _bucketKeys = keys _buckets;
_bucketKeys sort true;
{
    private _parts = _x splitString "|";
    _parts params ["_sideKey", "_branch", "_homeObjectiveId"];
    private _bucket = _buckets get _x;
    _bucket sort true;
    while {(count _bucket) >= 3} do {
        private _memberIds = _bucket select [0, 3];
        _bucket deleteRange [0, 3];
        private _formationId = [_state, _sideKey, _branch, _homeObjectiveId, _memberIds] call FLO_fnc_formationCreate;
        _formationIds pushBack _formationId;
        _changed = true;
    };
} forEach _bucketKeys;

[_state] call FLO_fnc_formationRebuildIndex;
if (_changed) then { _state set ["revision", (_state get "revision") + 1]; };
[_state] call FLO_fnc_formationValidateState;
if (_deploymentMismatchCount > 0) then {
    ["FORMATIONS", 3, format [
        "Reconciled %1 cross-objective formation members into deployment-coherent pools",
        _deploymentMismatchCount
    ]] call FLO_fnc_log;
};

{
    private _groupData = _y;
    if (_groupData get "isActive") then {
        [_x, _groupData get "realGroup"] call FLO_fnc_formationApplyRealGroupSkills;
    };
} forEach _groups;

_changed
