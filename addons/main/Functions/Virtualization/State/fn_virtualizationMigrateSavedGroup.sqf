/*
 * Function: FLO_fnc_virtualizationMigrateSavedGroup
 * Description:
 *   Converts legacy unversioned and schema-2 virtual-group records into the
 *   current schema. Deprecated GTN engagement overlays are released instead
 *   of restoring their route over the strategic commander order.
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
private _sourceSchema = if ("schemaVersion" in _savedData) then {
    _savedData get "schemaVersion"
} else {
    0
};

if (_sourceSchema == _currentSchema) exitWith {
    private _copy = [_savedData] call FLO_fnc_virtualizationCloneValue;
    if ((_copy get "groupType") == "static_aa" && {_copy get "alwaysActive"}) then {
        _copy set ["alwaysActive", false];
    };
    [_copy, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
    _copy
};

if !(_sourceSchema in [0, 2]) then {
    throw format ["Saved virtual group %1 uses unsupported schema %2", _groupId, _sourceSchema];
};

if (_sourceSchema == 0 && {_missionSaveVersion >= 23}) then {
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
        if (_sourceSchema != 0) then {
            throw format ["Schema %1 virtual group %2 is missing field %3", _sourceSchema, _groupId, _x];
        };
        _defaults get _x
    };
    _migrated set [_x, [_value] call FLO_fnc_virtualizationCloneValue];
} forEach (call FLO_fnc_virtualizationGetPersistentFields);

_migrated set ["schemaVersion", _currentSchema];
_migrated set ["id", _groupId];
if (_sourceSchema == 0) then {
    _migrated set ["spawnPosition", +(_savedData get "position")];
    if !("direction" in _savedData) then {
        _migrated set ["direction", 0];
    };
};

private _legacyEngagementActive = false;
if ("engagementActive" in _savedData) then {
    _legacyEngagementActive = _savedData get "engagementActive";
};
private _legacyPathSource = "";
if ("pathSource" in _savedData) then {
    _legacyPathSource = _savedData get "pathSource";
};

if (_legacyEngagementActive || {(_legacyPathSource find "GTN_ENGAGE") == 0}) then {
    _migrated set ["state", "idle"];
    _migrated set ["waypoints", []];
    _migrated set ["currentWaypointIndex", 0];
    _migrated set ["noWaypoints", false];
    _migrated set ["pathToken", -1];
    _migrated set ["pathTargetPos", []];
    _migrated set ["pathAllowTrails", false];
    _migrated set ["pathStartedAt", -1];
    _migrated set ["pathSource", ""];
    _migrated set ["pathWaypointSettings", []];
    _migrated set ["commanderOrder", ""];
    _migrated set ["executionState", ""];
    _migrated set ["orderTargetPos", []];
    _migrated set ["orderMode", ""];
    _migrated set ["attackObjective", ""];
    _migrated set ["campaignOperationId", ""];
    _migrated set ["defendObjective", ""];
    _migrated set ["defendLeaseIssuedAt", -1];
    _migrated set ["defendLeaseUntil", -1];
    _migrated set ["garrisonPosition", [0, 0, 0]];
    _migrated set ["garrisonObjective", ""];
};

if ((_migrated get "groupType") == "static_aa" && {_migrated get "alwaysActive"}) then {
    _migrated set ["alwaysActive", false];
};

[_migrated, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
_migrated
