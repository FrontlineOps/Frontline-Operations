/*
 * Function: FLO_fnc_virtualizationLoadTransportPassengers
 */

params ["_groupId", "_groupData", "_realGroup", "_position", "_pools"];

private _attachedGroups = [_groupData] call FLO_fnc_virtualizationGetTransportPassengers;
if !(([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) && {count _attachedGroups > 0}) exitWith { true };

["VIRTUALIZATION", 3, format ["Transport %1 spawning with %2 attached groups", _groupId, count _attachedGroups]] call FLO_fnc_log;

private _transportVehicles = (units _realGroup) select { vehicle _x != _x };
_transportVehicles = _transportVehicles apply { vehicle _x };
_transportVehicles = _transportVehicles arrayIntersect _transportVehicles;

if (count _transportVehicles == 0) then {
    {
        private _veh = vehicle _x;
        if (_veh != _x && !(_veh in _transportVehicles)) then {
            _transportVehicles pushBack _veh;
        };
    } forEach units _realGroup;
};

private _groups = FLO_virtualGroups get "_groups";
private _poolUnits = _pools get "units";

{
    private _attachedId = _x;
    private _attachedData = _groups get _attachedId;
    if (isNil "_attachedData") then { continue };

    private _infGroup = createGroup [_attachedData get "side", true];
    private _infComp = _attachedData get "comp";
    private _infUnitCount = _attachedData get "unitCount";

    if (_infComp isNotEqualTo []) then {
        {
            _infGroup createUnit [_x, _position, [], 0, "NONE"];
        } forEach _infComp;
    } else {
        for "_i" from 1 to _infUnitCount do {
            _infGroup createUnit [selectRandom _poolUnits, _position, [], 0, "NONE"];
        };
    };

    if (count _transportVehicles > 0) then {
        private _vehicleIndex = 0;
        {
            private _vehicle = _transportVehicles select _vehicleIndex;
            if (_vehicle emptyPositions "cargo" > 0) then {
                _x moveInCargo _vehicle;
            } else {
                _vehicleIndex = (_vehicleIndex + 1) mod (count _transportVehicles);
                private _nextVeh = _transportVehicles select _vehicleIndex;
                if (_nextVeh emptyPositions "cargo" > 0) then {
                    _x moveInCargo _nextVeh;
                };
            };
        } forEach units _infGroup;
    };

    [_attachedData, _infGroup] call FLO_fnc_virtualizationSetRealGroup;
    _attachedData set ["isActive", true];
    _attachedData set ["lastStateChangeTime", diag_tickTime];
    [_attachedData, _groupId] call FLO_fnc_virtualizationSetMountedIn;
    _infGroup setVariable ["FLO_virtualGroupId", _attachedId];

    ["VIRTUALIZATION", 3, format ["Loaded attached group %1 (%2 units) into transport %3", _attachedId, count units _infGroup, _groupId]] call FLO_fnc_log;
} forEach _attachedGroups;

true
