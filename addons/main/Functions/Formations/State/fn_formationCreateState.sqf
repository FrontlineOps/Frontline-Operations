/* Creates or restores the versioned formation registry. */
params [["_savedState", createHashMap, [createHashMap]]];

private _state = if ((keys _savedState) isEqualTo []) then {
    createHashMapFromArray [
        ["schemaVersion", 1],
        ["revision", 1],
        ["formations", createHashMap],
        ["sequenceByKey", createHashMap],
        ["doctrineBySide", createHashMapFromArray [
            ["WEST", "ECONOMY_OF_FORCE"],
            ["EAST", "ECONOMY_OF_FORCE"]
        ]],
        ["lastReadinessUpdateAtDateNum", -1],
        ["lastDoctrineUpdateAtDateNum", -1],
        ["lastWithdrawalAtBySide", createHashMapFromArray [
            ["WEST", -1],
            ["EAST", -1]
        ]],
        ["groupToFormation", createHashMap]
    ]
} else {
    if !("schemaVersion" in _savedState) then {
        throw "Saved formation state has no schemaVersion";
    };
    private _schemaVersion = _savedState get "schemaVersion";
    if (_schemaVersion != 1) then {
        throw format ["Unsupported formation schema version: %1", _schemaVersion];
    };

    createHashMapFromArray [
        ["schemaVersion", 1],
        ["revision", _savedState get "revision"],
        ["formations", +(_savedState get "formations")],
        ["sequenceByKey", +(_savedState get "sequenceByKey")],
        ["doctrineBySide", +(_savedState get "doctrineBySide")],
        ["lastReadinessUpdateAtDateNum", _savedState get "lastReadinessUpdateAtDateNum"],
        ["lastDoctrineUpdateAtDateNum", _savedState get "lastDoctrineUpdateAtDateNum"],
        ["lastWithdrawalAtBySide", +(_savedState get "lastWithdrawalAtBySide")],
        ["groupToFormation", createHashMap]
    ]
};

[_state] call FLO_fnc_formationValidateState;
[_state] call FLO_fnc_formationRebuildIndex;
_state
