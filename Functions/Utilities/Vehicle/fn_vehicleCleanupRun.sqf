/*
 * Function: FLO_fnc_vehicleCleanupRun
 * Author: Frontline Operations Development Group
 * Description:
 *   Periodic server scan for abandoned derelict vehicles that should be
 *   removed even though they never became engine-managed wrecks.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - True when the scan completed
 */

if (!isServer) exitWith { false };
if (isNil "FLO_VehicleCleanup") exitWith { false };

private _state = FLO_VehicleCleanup;
if !(_state get "enabled") exitWith { false };

private _trackedVehicleKeys = createHashMap;
if (!isNil "FLO_virtualGroups" && {FLO_virtualGroups isEqualType createHashMap}) then {
    {
        private _groupData = _y;
        {
            if (!isNull _x) then {
                _trackedVehicleKeys set [str _x, true];
            };
        } forEach (_groupData get "realVehicles");

        private _realGroup = _groupData get "realGroup";
        if (!isNull _realGroup) then {
            {
                private _veh = vehicle _x;
                if (_veh == _x) then {
                    _veh = assignedVehicle _x;
                };

                if (!isNull _veh) then {
                    _trackedVehicleKeys set [str _veh, true];
                };
            } forEach units _realGroup;
        };
    } forEach (FLO_virtualGroups get "_groups");
};

private _playerPositions = (allPlayers select { alive _x }) apply { getPosATL _x };
private _installationPositions = (allMapMarkers select { markerType _x == "b_installation" }) apply { getMarkerPos _x };

private _playerSafeRadius = _state get "playerSafeRadius";
private _installationSafeRadius = _state get "installationSafeRadius";
private _graceTime = _state get "graceTime";
private _candidateSince = _state get "candidateSince";
private _now = diag_tickTime;
private _seenThisScan = createHashMap;
private _deletedCount = 0;

{
    private _vehicle = _x;
    if !([
        _vehicle,
        _trackedVehicleKeys,
        _playerPositions,
        _installationPositions,
        _playerSafeRadius,
        _installationSafeRadius
    ] call FLO_fnc_vehicleShouldCleanup) then {
        _candidateSince deleteAt str _vehicle;
        continue;
    };

    private _vehicleKey = str _vehicle;
    _seenThisScan set [_vehicleKey, true];

    if (isNil { _candidateSince get _vehicleKey }) then {
        _candidateSince set [_vehicleKey, _now];
        continue;
    };

    private _firstSeen = _candidateSince get _vehicleKey;
    if (_now - _firstSeen < _graceTime) then { continue };

    ["VEHICLE_CLEANUP", 3, format [
        "Removing abandoned derelict %1 at %2 after %3s empty",
        typeOf _vehicle,
        getPosATL _vehicle,
        round (_now - _firstSeen)
    ]] call FLO_fnc_log;

    _vehicle hideObjectGlobal true;
    deleteVehicle _vehicle;
    _candidateSince deleteAt _vehicleKey;
    _deletedCount = _deletedCount + 1;
} forEach vehicles;

{
    if (isNil { _seenThisScan get _x }) then {
        _candidateSince deleteAt _x;
    };
} forEach (keys _candidateSince);

if (_deletedCount > 0) then {
    ["VEHICLE_CLEANUP", 2, format ["Deleted %1 abandoned derelict vehicles", _deletedCount]] call FLO_fnc_log;
};

true
