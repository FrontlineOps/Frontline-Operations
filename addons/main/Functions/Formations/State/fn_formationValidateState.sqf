/* Validates formation persistence independently of the live group registry. */
params ["_state"];

private _requiredStateFields = [
    "revision",
    "formations",
    "sequenceByKey",
    "doctrineBySide",
    "lastReadinessUpdateAtDateNum",
    "lastDoctrineUpdateAtDateNum",
    "lastWithdrawalAtBySide",
    "groupToFormation"
];
private _unexpectedStateFields = (keys _state) select {
    !(_x in _requiredStateFields)
};
if (_unexpectedStateFields isNotEqualTo []) then {
    throw format [
        "Formation state has unexpected fields %1",
        _unexpectedStateFields
    ];
};
{
    if !(_x in _state) then {
        throw format ["Formation state is missing required field %1", _x];
    };
} forEach _requiredStateFields;
private _validDoctrines = ["BREAKTHROUGH", "DECEPTION", "ELASTIC_DEFENSE", "COUNTERATTACK", "ECONOMY_OF_FORCE"];
private _doctrines = _state get "doctrineBySide";
private _withdrawals = _state get "lastWithdrawalAtBySide";
private _sideKeys = ["WEST", "EAST"];
private _unexpectedDoctrineKeys = (keys _doctrines) select { !(_x in _sideKeys) };
private _unexpectedWithdrawalKeys = (keys _withdrawals) select { !(_x in _sideKeys) };
if (_unexpectedDoctrineKeys isNotEqualTo [] || {_unexpectedWithdrawalKeys isNotEqualTo []}) then {
    throw format [
        "Formation side state has unexpected doctrine keys %1 or withdrawal keys %2",
        _unexpectedDoctrineKeys,
        _unexpectedWithdrawalKeys
    ];
};
{
    if !(_x in _doctrines) then { throw format ["Formation state has no %1 doctrine", _x]; };
    if !((_doctrines get _x) in _validDoctrines) then {
        throw format ["Invalid %1 doctrine %2", _x, _doctrines get _x];
    };
    if !(_x in _withdrawals) then { throw format ["Formation state has no %1 withdrawal timestamp", _x]; };
} forEach _sideKeys;

private _validBranches = ["infantry", "motorized", "mechanized", "armor", "artillery", "air_defense", "helicopter", "fixed_wing"];
private _validRoles = ["RESERVE", "MAIN", "FEINT", "FEINT_RETURN", "EXPLOIT", "WITHDRAW", "RECOVERY"];
private _seenMembers = createHashMap;
{
    private _formationId = _x;
    private _formation = _y;
    private _requiredFormationFields = [
        "formationId", "name", "sideKey", "branch", "memberIds", "leadGroupId", "homeObjectiveId",
        "readiness", "experience", "battleCount", "victories", "defeats", "withdrawals",
        "formedAtDateNum", "lastCombatAtDateNum", "lastStrength", "lastCombatZoneId", "lastCombatRound",
        "role", "roleMemberIds", "roleObjectiveId", "roleOperationId", "roleStartedAtDateNum",
        "roleEndsAtDateNum", "returnObjectiveId"
    ];
    private _unexpectedFormationFields = (keys _formation) select {
        !(_x in _requiredFormationFields)
    };
    if (_unexpectedFormationFields isNotEqualTo []) then {
        throw format [
            "Formation %1 has unexpected fields %2",
            _formationId,
            _unexpectedFormationFields
        ];
    };
    {
        if !(_x in _formation) then {
            throw format ["Formation %1 is missing required field %2", _formationId, _x];
        };
    } forEach _requiredFormationFields;
    if ((_formation get "formationId") != _formationId) then {
        throw format ["Formation key/id mismatch: %1/%2", _formationId, _formation get "formationId"];
    };
    if !((_formation get "sideKey") in ["WEST", "EAST"]) then {
        throw format ["Formation %1 has invalid side %2", _formationId, _formation get "sideKey"];
    };
    if !((_formation get "branch") in _validBranches) then {
        throw format ["Formation %1 has invalid branch %2", _formationId, _formation get "branch"];
    };
    if !((_formation get "role") in _validRoles) then {
        throw format ["Formation %1 has invalid role %2", _formationId, _formation get "role"];
    };
    if ((_formation get "readiness") < 0 || {(_formation get "readiness") > 100}) then {
        throw format ["Formation %1 has invalid readiness %2", _formationId, _formation get "readiness"];
    };
    if ((_formation get "experience") < 0 || {(_formation get "experience") > 100}) then {
        throw format ["Formation %1 has invalid experience %2", _formationId, _formation get "experience"];
    };
    private _memberIds = _formation get "memberIds";
    if ((count _memberIds) > 6) then {
        throw format ["Formation %1 exceeds six groups", _formationId];
    };
    private _leadGroupId = _formation get "leadGroupId";
    if (_memberIds isEqualTo []) then {
        if (_leadGroupId != "") then { throw format ["Empty formation %1 retained lead %2", _formationId, _leadGroupId]; };
    } else {
        if !(_leadGroupId in _memberIds) then { throw format ["Formation %1 lead is not a member", _formationId]; };
    };
    {
        if (_x in _seenMembers) then {
            throw format ["Group %1 belongs to formations %2 and %3", _x, _seenMembers get _x, _formationId];
        };
        _seenMembers set [_x, _formationId];
    } forEach _memberIds;
    {
        if !(_x in _memberIds) then {
            throw format ["Formation %1 role references non-member group %2", _formationId, _x];
        };
    } forEach (_formation get "roleMemberIds");
} forEach (_state get "formations");

true
