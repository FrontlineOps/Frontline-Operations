/*
 * Function: FLO_fnc_virtualizationPatchGroup
 * Description:
 *   Atomically applies validated non-identity state changes to one registry
 *   record. Structural lifecycle and relationship fields have dedicated APIs.
 */

params [
    ["_groupId", "", [""]],
    ["_changes", createHashMap, [createHashMap]]
];

if ((keys _changes) isEqualTo []) exitWith { true };

private _protectedFields = [
    "id",
    "position",
    "spawnPosition",
    "side",
    "groupType",
    "groupCfg",
    "isActive",
    "realGroup",
    "realVehicles",
    "nextProcessAt",
    "lastProcessedAt",
    "attachedTo",
    "attachedGroups",
    "attachedType",
    "mountedIn",
    "landRouteStartBlocked",
    "landRouteRetryAt"
];
_protectedFields append (call FLO_fnc_virtualizationGetRouteOwnedFields);
private _defaults = call FLO_fnc_virtualizationCreateGroupRecordDefaults;
private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
private _candidate = [_groupData] call FLO_fnc_virtualizationCloneValue;

{
    private _field = _x;
    if (_field in _protectedFields) then {
        throw format ["Virtual group %1 field %2 requires a structural command", _groupId, _field];
    };
    if !(_field in _defaults) then {
        throw format ["Virtual group %1 patch contains unknown field %2", _groupId, _field];
    };

    private _value = _y;
    private _prototype = _defaults get _field;
    if !(_value isEqualType _prototype) then {
        throw format [
            "Virtual group %1 patch field %2 has type %3, expected %4",
            _groupId,
            _field,
            typeName _value,
            typeName _prototype
        ];
    };

    _candidate set [_field, [_value] call FLO_fnc_virtualizationCloneValue];
} forEach _changes;

_candidate set ["nextProcessAt", 0];
[_candidate, _groupId] call FLO_fnc_virtualizationValidateGroup;
{
    _groupData set [_x, _candidate get _x];
} forEach (keys _changes);
_groupData set ["nextProcessAt", 0];
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_GroupPatched",
    [_groupId, keys _changes]
] call CBA_fnc_localEvent;
true
