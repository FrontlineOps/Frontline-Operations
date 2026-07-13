/*
 * Function: FLO_fnc_virtualizationLoadTransportPassengers
 */

params ["_groupId", "_groupData", "_realGroup", "_position", "_pools"];

private _attachedGroups = [_groupData] call FLO_fnc_virtualizationGetTransportPassengers;
if !(([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) && {_attachedGroups isNotEqualTo []}) exitWith { true };

["VIRTUALIZATION", 3, format ["Transport %1 spawning with %2 attached groups", _groupId, count _attachedGroups]] call FLO_fnc_log;

private _transportVehicles = (units _realGroup) select { !isNull objectParent _x };
_transportVehicles = _transportVehicles apply { vehicle _x };
_transportVehicles = _transportVehicles arrayIntersect _transportVehicles;

if (_transportVehicles isEqualTo []) then {
    {
        private _veh = vehicle _x;
        if (_veh != _x && !(_veh in _transportVehicles)) then {
            _transportVehicles pushBack _veh;
        };
    } forEach units _realGroup;
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _poolUnits = _pools get "units";

{
    private _attachedId = _x;
    private _attachedData = _groups get _attachedId;
    if (isNil "_attachedData") then { continue };

    private _infGroup = createGroup [_attachedData get "side", true];
    if (isNull _infGroup) then {
        ["VIRTUALIZATION", 1, format [
            "Transport %1 could not activate attached group %2 because createGroup failed",
            _groupId,
            _attachedId
        ]] call FLO_fnc_log;
        continue;
    };

    private _infComp = _attachedData get "comp";
    private _infUnitCount = _attachedData get "unitCount";
    if (_infUnitCount <= 0 && {_infComp isEqualTo []}) then {
        ["VIRTUALIZATION", 1, format [
            "Transport %1 encountered zero-strength attached group %2 - removing stale passenger record",
            _groupId,
            _attachedId
        ]] call FLO_fnc_log;
        [_attachedId] call FLO_fnc_virtualizationRemoveGroup;
        deleteGroup _infGroup;
        continue;
    };

    private _spawnFailed = false;
    if (_infComp isNotEqualTo []) then {
        {
            private _unit = [
                _infGroup,
                _x,
                _position,
                [],
                0,
                "NONE",
                format ["transport=%1 passengerGroup=%2", _groupId, _attachedId]
            ] call FLO_fnc_createGroupUnit;
            if (isNull _unit) exitWith { _spawnFailed = true; };
        } forEach _infComp;
    } else {
        for "_i" from 1 to _infUnitCount do {
            private _unit = [
                _infGroup,
                selectRandom _poolUnits,
                _position,
                [],
                0,
                "NONE",
                format ["transport=%1 passengerGroup=%2", _groupId, _attachedId]
            ] call FLO_fnc_createGroupUnit;
            if (isNull _unit) exitWith { _spawnFailed = true; };
        };
    };

    if (_spawnFailed) then {
        ["VIRTUALIZATION", 1, format [
            "Transport %1 failed to create side-correct passenger group %2",
            _groupId,
            _attachedId
        ]] call FLO_fnc_log;
        { deleteVehicle _x; } forEach units _infGroup;
        deleteGroup _infGroup;
        continue;
    };

    private _attachedSide = _attachedData get "side";
    if (!isNull _infGroup && {_attachedSide in [east, west, independent]} && {_attachedSide != civilian}) then {
        _infGroup = [_infGroup, _attachedSide] call FLO_fnc_setSide;
    };
    if (isNull _infGroup) then {
        ["VIRTUALIZATION", 1, format [
            "Transport %1 failed to activate attached group %2 - side correction returned null group",
            _groupId,
            _attachedId
        ]] call FLO_fnc_log;
        continue;
    };

    [_attachedData, _infGroup] call FLO_fnc_virtualizationSetRealGroup;
    [_attachedData] call FLO_fnc_virtualizationClearRealVehicles;
    _attachedData set ["activeInitialUnitCount", count units _infGroup];
    _attachedData set ["isActive", true];
    _attachedData set ["lastStateChangeTime", diag_tickTime];
    _infGroup setVariable ["FLO_virtualGroupId", _attachedId];

    if ([_attachedId, _attachedData, _groupId, _groupData, _transportVehicles] call FLO_fnc_transportMountActivePassengerGroup) then {
        ["VIRTUALIZATION", 3, format [
            "Loaded attached group %1 (%2 units) into transport %3",
            _attachedId,
            count units _infGroup,
            _groupId
        ]] call FLO_fnc_log;
    } else {
        ["VIRTUALIZATION", 2, format [
            "Attached group %1 failed coherent mount into transport %2 (%3/%4 mounted) - forcing detach repair",
            _attachedId,
            _groupId,
            {
                private _veh = vehicle _x;
                _veh != _x && {_veh in _transportVehicles}
            } count (units _infGroup select { alive _x }),
            count (units _infGroup select { alive _x })
        ]] call FLO_fnc_log;
        [_attachedId, random 360] call FLO_fnc_transportDetach;
        [_attachedId, "TRANSPORT_LOAD_REPAIR"] call FLO_fnc_transportApplyPostDismountWaypoint;
    };
} forEach _attachedGroups;

true
