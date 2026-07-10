/*
 * Function: FLO_fnc_virtualizationValidateGroup
 * Description:
 *   Validates one live record against the canonical schema and core lifecycle
 *   invariants. Cross-record relationships are validated by the registry.
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_expectedId", "", [""]]
];

private _defaults = call FLO_fnc_virtualizationCreateGroupRecordDefaults;
{
    if !(_x in _groupData) then {
        throw format ["Virtual group %1 missing live field %2", _expectedId, _x];
    };

    if (_x != "groupCfg") then {
        private _value = _groupData get _x;
        private _prototype = _defaults get _x;
        if !(_value isEqualType _prototype) then {
            throw format [
                "Virtual group %1 field %2 has type %3, expected %4",
                _expectedId,
                _x,
                typeName _value,
                typeName _prototype
            ];
        };
    };
} forEach (keys _defaults);

private _groupId = _groupData get "id";
if (_groupId == "") then {
    throw "Virtual group record has an empty id";
};
if (_expectedId != "" && {_groupId != _expectedId}) then {
    throw format ["Virtual group key/id mismatch: key=%1 record=%2", _expectedId, _groupId];
};
if ((_groupData get "schemaVersion") != (_defaults get "schemaVersion")) then {
    throw format [
        "Virtual group %1 has unsupported live schema %2",
        _groupId,
        _groupData get "schemaVersion"
    ];
};

private _position = _groupData get "position";
if !([_position] call FLO_fnc_validateGroupPosition) then {
    throw format ["Virtual group %1 has invalid position %2", _groupId, _position];
};
private _spawnPosition = _groupData get "spawnPosition";
if !([_spawnPosition] call FLO_fnc_validateGroupPosition) then {
    throw format ["Virtual group %1 has invalid spawn position %2", _groupId, _spawnPosition];
};

if !((_groupData get "side") in [east, west, independent, civilian]) then {
    throw format ["Virtual group %1 has unsupported side %2", _groupId, _groupData get "side"];
};
if ((_groupData get "groupType") == "") then {
    throw format ["Virtual group %1 has an empty group type", _groupId];
};
if ((_groupData get "unitCount") < 0) then {
    throw format ["Virtual group %1 has negative unit count %2", _groupId, _groupData get "unitCount"];
};

private _isActive = _groupData get "isActive";
private _realGroup = _groupData get "realGroup";
if (_isActive != (!isNull _realGroup)) then {
    throw format [
        "Virtual group %1 lifecycle mismatch: isActive=%2 realGroupNull=%3",
        _groupId,
        _isActive,
        isNull _realGroup
    ];
};
if (!_isActive && {(_groupData get "realVehicles") isNotEqualTo []}) then {
    throw format ["Inactive virtual group %1 retains real vehicles", _groupId];
};

private _waypoints = _groupData get "waypoints";
private _waypointIndex = _groupData get "currentWaypointIndex";
if (_waypointIndex < 0 || {_waypointIndex > count _waypoints}) then {
    throw format [
        "Virtual group %1 has invalid waypoint index %2/%3",
        _groupId,
        _waypointIndex,
        count _waypoints
    ];
};
private _attachedTo = _groupData get "attachedTo";
private _attachedType = _groupData get "attachedType";
private _mountedIn = _groupData get "mountedIn";
private _attachedGroups = _groupData get "attachedGroups";
if (_attachedTo == _groupId || {_mountedIn == _groupId}) then {
    throw format ["Virtual group %1 has a self transport reference", _groupId];
};
if ((_attachedTo == "") != (_attachedType == "")) then {
    throw format [
        "Virtual group %1 has incomplete attachment state: carrier=%2 type=%3",
        _groupId,
        _attachedTo,
        _attachedType
    ];
};
if (_mountedIn != "" && {_mountedIn != _attachedTo}) then {
    throw format [
        "Virtual group %1 mountedIn=%2 differs from attachedTo=%3",
        _groupId,
        _mountedIn,
        _attachedTo
    ];
};
if ((_groupData get "isTransport") != (_attachedGroups isNotEqualTo [])) then {
    throw format ["Virtual group %1 carrier flag does not match its passenger manifest", _groupId];
};
if ((count _attachedGroups) != (count (_attachedGroups arrayIntersect _attachedGroups))) then {
    throw format ["Virtual group %1 has duplicate passenger references", _groupId];
};

true
