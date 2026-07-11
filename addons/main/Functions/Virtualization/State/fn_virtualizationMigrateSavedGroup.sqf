/*
 * Function: FLO_fnc_virtualizationMigrateSavedGroup
 * Description:
 *   Converts legacy unversioned virtual-group records into schema 2. Current
 *   records are validated without fallback repair.
 */

params [
    ["_groupId", "", [""]],
    ["_savedData", createHashMap, [createHashMap]],
    ["_missionSaveVersion", 0, [0]]
];

if (_groupId == "") then {
    throw "Cannot migrate a virtual group with an empty map key";
};

private _defaults = call FLO_fnc_virtualizationCreateGroupRecordDefaults;
private _currentSchema = _defaults get "schemaVersion";

if ("schemaVersion" in _savedData) exitWith {
    if ((_savedData get "schemaVersion") != _currentSchema) then {
        throw format [
            "Saved virtual group %1 uses unsupported schema %2",
            _groupId,
            _savedData get "schemaVersion"
        ];
    };

    private _copy = [_savedData] call FLO_fnc_virtualizationCloneValue;
    [_copy, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
    _copy
};

if (_missionSaveVersion >= 23) then {
    throw format ["Version %1 save contains unversioned virtual group %2", _missionSaveVersion, _groupId];
};

{
    if !(_x in _savedData) then {
        throw format ["Legacy virtual group %1 missing identity field %2", _groupId, _x];
    };
} forEach ["position", "groupType", "homeObjective", "unitCount", "side"];

private _migrated = createHashMap;
{
    private _value = if (_x in _savedData) then {
        _savedData get _x
    } else {
        _defaults get _x
    };
    _migrated set [_x, [_value] call FLO_fnc_virtualizationCloneValue];
} forEach (call FLO_fnc_virtualizationGetPersistentFields);

_migrated set ["schemaVersion", _currentSchema];
_migrated set ["id", _groupId];
_migrated set ["spawnPosition", +(_savedData get "position")];
if !("direction" in _savedData) then {
    _migrated set ["direction", 0];
};

[_migrated, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
_migrated
