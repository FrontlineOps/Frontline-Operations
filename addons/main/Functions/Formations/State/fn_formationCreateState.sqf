/* Creates or restores the current formation registry. */
params ["_savedState", "_restoreSavedState"];

if !(_savedState isEqualType createHashMap) then {
    throw format ["Formation state input has invalid type %1", typeName _savedState];
};
if !(_restoreSavedState isEqualType false) then {
    throw format ["Formation restore intent has invalid type %1", typeName _restoreSavedState];
};

if (!_restoreSavedState && {(keys _savedState) isNotEqualTo []}) then {
    throw format [
        "Fresh formation construction received persisted fields %1",
        keys _savedState
    ];
};

private _state = if (!_restoreSavedState) then {
    createHashMapFromArray [
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
    private _requiredFields = [
        "revision",
        "formations",
        "sequenceByKey",
        "doctrineBySide",
        "lastReadinessUpdateAtDateNum",
        "lastDoctrineUpdateAtDateNum",
        "lastWithdrawalAtBySide"
    ];
    private _missingFields = _requiredFields select { !(_x in _savedState) };
    private _unexpectedFields = (keys _savedState) select { !(_x in _requiredFields) };
    if (_missingFields isNotEqualTo [] || {_unexpectedFields isNotEqualTo []}) then {
        ["FORMATIONS", 1, format [
            "Current formation save is missing fields %1 and was not loaded; unexpected fields %2",
            _missingFields,
            _unexpectedFields
        ]] call FLO_fnc_log;
        throw format ["Current formation save is missing fields %1 or has unexpected fields %2", _missingFields, _unexpectedFields];
    };

    private _restored = createHashMapFromArray [
        ["revision", _savedState get "revision"],
        ["formations", +(_savedState get "formations")],
        ["sequenceByKey", +(_savedState get "sequenceByKey")],
        ["doctrineBySide", +(_savedState get "doctrineBySide")],
        ["lastReadinessUpdateAtDateNum", _savedState get "lastReadinessUpdateAtDateNum"],
        ["lastDoctrineUpdateAtDateNum", _savedState get "lastDoctrineUpdateAtDateNum"],
        ["lastWithdrawalAtBySide", +(_savedState get "lastWithdrawalAtBySide")],
        ["groupToFormation", createHashMap]
    ];
    _restored
};

[_state] call FLO_fnc_formationValidateState;
[_state] call FLO_fnc_formationRebuildIndex;
_state
