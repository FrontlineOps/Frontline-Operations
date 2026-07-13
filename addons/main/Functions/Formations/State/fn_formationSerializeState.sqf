/* Serializes formation domain state without derived runtime indexes. */
params ["_state"];

[_state] call FLO_fnc_formationValidateState;
private _serializedFormations = createHashMap;
{
    private _formation = _y;
    _serializedFormations set [_x, createHashMapFromArray [
        ["formationId", _formation get "formationId"],
        ["name", _formation get "name"],
        ["sideKey", _formation get "sideKey"],
        ["branch", _formation get "branch"],
        ["memberIds", +(_formation get "memberIds")],
        ["leadGroupId", _formation get "leadGroupId"],
        ["homeObjectiveId", _formation get "homeObjectiveId"],
        ["readiness", _formation get "readiness"],
        ["experience", _formation get "experience"],
        ["battleCount", _formation get "battleCount"],
        ["victories", _formation get "victories"],
        ["defeats", _formation get "defeats"],
        ["withdrawals", _formation get "withdrawals"],
        ["formedAtDateNum", _formation get "formedAtDateNum"],
        ["lastCombatAtDateNum", _formation get "lastCombatAtDateNum"],
        ["lastStrength", _formation get "lastStrength"],
        ["lastCombatZoneId", _formation get "lastCombatZoneId"],
        ["lastCombatRound", _formation get "lastCombatRound"],
        ["role", _formation get "role"],
        ["roleMemberIds", +(_formation get "roleMemberIds")],
        ["roleObjectiveId", _formation get "roleObjectiveId"],
        ["roleOperationId", _formation get "roleOperationId"],
        ["roleStartedAtDateNum", _formation get "roleStartedAtDateNum"],
        ["roleEndsAtDateNum", _formation get "roleEndsAtDateNum"],
        ["returnObjectiveId", _formation get "returnObjectiveId"]
    ]];
} forEach (_state get "formations");

createHashMapFromArray [
    ["schemaVersion", 1],
    ["revision", _state get "revision"],
    ["formations", _serializedFormations],
    ["sequenceByKey", +(_state get "sequenceByKey")],
    ["doctrineBySide", +(_state get "doctrineBySide")],
    ["lastReadinessUpdateAtDateNum", _state get "lastReadinessUpdateAtDateNum"],
    ["lastDoctrineUpdateAtDateNum", _state get "lastDoctrineUpdateAtDateNum"],
    ["lastWithdrawalAtBySide", +(_state get "lastWithdrawalAtBySide")]
]
