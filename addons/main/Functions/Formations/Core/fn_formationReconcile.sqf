/* Reconciles persistent formations against the authoritative virtual registry. */
params ["_state"];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _formations = _state get "formations";
private _changed = false;

{
    private _formation = _y;
    private _sideKey = _formation get "sideKey";
    private _branch = _formation get "branch";
    private _validMembers = (_formation get "memberIds") select {
        if !(_x in _groups) then { false } else {
            private _groupData = _groups get _x;
            private _memberSideKey = ([_groupData get "side"] call FLO_fnc_gtnSideContext) get "sideKey";
            _memberSideKey == _sideKey && {([_groupData] call FLO_fnc_formationClassifyBranch) == _branch}
        }
    };
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
            _formation set ["roleStartedAtDateNum", dateToNumber date];
            _formation set ["roleEndsAtDateNum", -1];
            _formation set ["returnObjectiveId", ""];
            _changed = true;
        };
    } else {
        if !((_formation get "leadGroupId") in _validMembers) then {
            _formation set ["leadGroupId", _validMembers select 0];
            _changed = true;
        };
        if ((_formation get "homeObjectiveId") == "") then {
            _formation set ["homeObjectiveId", (_groups get (_formation get "leadGroupId")) get "homeObjective"];
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
        if ((count _members) >= 6) then { continue };
        if (_members isNotEqualTo [] && {(_formation get "homeObjectiveId") != _homeObjectiveId}) then { continue };

        _members pushBack _groupId;
        _members sort true;
        _formation set ["memberIds", _members];
        if ((_formation get "leadGroupId") == "") then { _formation set ["leadGroupId", _groupId]; };
        if ((_formation get "homeObjectiveId") == "") then { _formation set ["homeObjectiveId", _homeObjectiveId]; };
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
private _crossHomeBuckets = createHashMap;
{
    private _parts = _x splitString "|";
    _parts params ["_sideKey", "_branch", "_homeObjectiveId"];
    private _bucket = _buckets get _x;
    _bucket sort true;
    while {(count _bucket) >= 3} do {
        private _takeCount = 6 min (count _bucket);
        private _memberIds = _bucket select [0, _takeCount];
        _bucket deleteRange [0, _takeCount];
        private _formationId = [_state, _sideKey, _branch, _homeObjectiveId, _memberIds] call FLO_fnc_formationCreate;
        _formationIds pushBack _formationId;
        _changed = true;
    };
    if (_bucket isNotEqualTo []) then {
        private _crossKey = format ["%1|%2", _sideKey, _branch];
        private _crossBucket = [];
        if (_crossKey in _crossHomeBuckets) then { _crossBucket = _crossHomeBuckets get _crossKey; };
        { _crossBucket pushBack _x; } forEach _bucket;
        _crossHomeBuckets set [_crossKey, _crossBucket];
    };
} forEach _bucketKeys;

private _crossKeys = keys _crossHomeBuckets;
_crossKeys sort true;
{
    private _parts = _x splitString "|";
    _parts params ["_sideKey", "_branch"];
    private _bucket = _crossHomeBuckets get _x;
    _bucket sort true;
    while {(count _bucket) >= 3} do {
        private _takeCount = 6 min (count _bucket);
        private _memberIds = _bucket select [0, _takeCount];
        _bucket deleteRange [0, _takeCount];
        private _homeObjectiveId = (_groups get (_memberIds select 0)) get "homeObjective";
        private _formationId = [_state, _sideKey, _branch, _homeObjectiveId, _memberIds] call FLO_fnc_formationCreate;
        _formationIds pushBack _formationId;
        _changed = true;
    };
} forEach _crossKeys;

[_state] call FLO_fnc_formationRebuildIndex;
if (_changed) then { _state set ["revision", (_state get "revision") + 1]; };
[_state] call FLO_fnc_formationValidateState;

{
    private _groupData = _y;
    if (_groupData get "isActive") then {
        [_x, _groupData get "realGroup"] call FLO_fnc_formationApplyRealGroupSkills;
    };
} forEach _groups;

_changed
