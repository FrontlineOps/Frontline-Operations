/*
 * Function: FLO_fnc_virtualizationValidateSavedGroup
 */

params [
    ["_savedData", createHashMap, [createHashMap]],
    ["_expectedId", "", [""]]
];

private _defaults = call FLO_fnc_virtualizationCreateGroupRecordDefaults;
{
    if !(_x in _savedData) then {
        throw format ["Saved virtual group %1 missing field %2", _expectedId, _x];
    };

    private _value = _savedData get _x;
    private _prototype = _defaults get _x;
    if !(_value isEqualType _prototype) then {
        throw format [
            "Saved virtual group %1 field %2 has type %3, expected %4",
            _expectedId,
            _x,
            typeName _value,
            typeName _prototype
        ];
    };
} forEach (call FLO_fnc_virtualizationGetPersistentFields);

private _groupId = _savedData get "id";
if (_expectedId == "" || {_groupId != _expectedId}) then {
    throw format ["Saved virtual group key/id mismatch: key=%1 record=%2", _expectedId, _groupId];
};
if ((_savedData get "schemaVersion") != (_defaults get "schemaVersion")) then {
    throw format [
        "Saved virtual group %1 has unsupported schema %2",
        _groupId,
        _savedData get "schemaVersion"
    ];
};
if !([_savedData get "position"] call FLO_fnc_validateGroupPosition) then {
    throw format ["Saved virtual group %1 has invalid position", _groupId];
};
if !([_savedData get "spawnPosition"] call FLO_fnc_validateGroupPosition) then {
    throw format ["Saved virtual group %1 has invalid spawn position", _groupId];
};
if ((_savedData get "unitCount") < 0) then {
    throw format ["Saved virtual group %1 has negative unit count", _groupId];
};

true
