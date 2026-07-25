/*
 * Function: FLO_fnc_virtualizationValidateSavedGroup
 */

params [
    ["_savedData", createHashMap, [createHashMap]],
    ["_expectedId", "", [""]]
];

private _defaults = call FLO_fnc_virtualizationCreateGroupRecordDefaults;
private _persistentFields = call FLO_fnc_virtualizationGetPersistentFields;
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
} forEach _persistentFields;

private _unexpectedFields = (keys _savedData) select { !(_x in _persistentFields) };
if (_unexpectedFields isNotEqualTo []) then {
    throw format [
        "Saved virtual group %1 contains fields outside the current record contract: %2",
        _expectedId,
        _unexpectedFields
    ];
};

private _groupId = _savedData get "id";
if (_expectedId == "" || {_groupId != _expectedId}) then {
    throw format ["Saved virtual group key/id mismatch: key=%1 record=%2", _expectedId, _groupId];
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
private _combatExperience = _savedData get "combatExperience";
if (_combatExperience < 0 || {_combatExperience > 100}) then {
    throw format ["Saved virtual group %1 has invalid combat experience %2", _groupId, _combatExperience];
};

[
    _groupId,
    _savedData get "waypoints",
    _savedData get "currentWaypointIndex",
    _savedData get "dismountAtWaypoint",
    _savedData get "pathToken",
    _savedData get "pathTargetPos",
    _savedData get "pathWaypointSettings"
] call FLO_fnc_virtualizationValidateWaypointState;
[_savedData, _groupId] call FLO_fnc_virtualizationValidateCommanderOrderState;

true
