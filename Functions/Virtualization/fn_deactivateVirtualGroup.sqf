/*
 * Function: FLO_fnc_deactivateVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Deactivates a virtual group by removing it from the game world but keeping its virtual status.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Group Data <HASHMAP> - HashMap containing group data
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", _groupData] call FLO_fnc_deactivateVirtualGroup;
 */

params ["_groupId", "_groupData"];
["VIRTUALIZATION", 3, format["Deactivating virtual group %1", _groupId]] call FLO_fnc_log;

private _realGroup = _groupData get "realGroup";
if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 2, format["Attempted to deactivate virtual group %1 but no real group exists", _groupId]] call FLO_fnc_log;
    false
};

// ==========================================================================================
// SAVE PERSISTENT DATA
// ==========================================================================================

// --- SAVE POSITION ---
private _leader = leader _realGroup;
if (!isNull _leader && {alive _leader}) then {
    private _currentPos = getPos _leader;
    if ((_currentPos select 0) > 100 || (_currentPos select 1) > 100) then {
        _groupData set ["position", _currentPos];
        ["VIRTUALIZATION", 4, format["Saved position %1 for group %2", _currentPos, _groupId]] call FLO_fnc_log;
    } else {
        ["VIRTUALIZATION", 2, format["WARNING: Invalid position %1 for group %2 - keeping original", _currentPos, _groupId]] call FLO_fnc_log;
    };
};

// --- SAVE WAYPOINTS ---
private _realWaypoints = waypoints _realGroup;
private _currentWpIndex = currentWaypoint _realGroup;
private _savedWaypoints = [];

if (count _realWaypoints > 0 && _currentWpIndex < count _realWaypoints) then {
    for "_i" from _currentWpIndex to (count _realWaypoints - 1) do {
        private _wp = _realWaypoints select _i;
        private _wpPos = waypointPosition _wp;
        
        if (_wpPos isEqualType [] && {count _wpPos >= 2} && {(_wpPos select 0) > 100 || (_wpPos select 1) > 100}) then {
            _savedWaypoints pushBack [
                _wpPos,
                waypointType _wp,
                waypointBehaviour _wp,
                waypointSpeed _wp,
                waypointFormation _wp,
                waypointCombatMode _wp
            ];
        };
    };
};

if (count _savedWaypoints > 0) then {
    _groupData set ["waypoints", _savedWaypoints];
    _groupData set ["currentWaypointIndex", 0];
    ["VIRTUALIZATION", 4, format["Saved %1 remaining waypoints from real group %2", count _savedWaypoints, _groupId]] call FLO_fnc_log;
} else {
    // If completed all real waypoints, clear virtual waypoints. 
    // If real group had no waypoints (e.g. static), keep existing virtual ones (don't overwrite with empty).
    if (count _realWaypoints > 0 && _currentWpIndex >= count _realWaypoints) then {
         _groupData set ["waypoints", []];
         _groupData set ["currentWaypointIndex", 0];
         ["VIRTUALIZATION", 4, format["Group %1 completed all waypoints - clearing virtual waypoints", _groupId]] call FLO_fnc_log;
    };
};

// --- SAVE STATE ---
private _state = "idle";
private _leaderBehavior = behaviour (leader _realGroup);
private _leaderCommand = currentCommand (leader _realGroup);

if (_leaderBehavior isEqualTo "COMBAT") then {
    _state = "attacking";
} else {
    if (_leaderCommand isEqualTo "MOVE") then {
        _state = "moving";
    };
};
_groupData set ["state", _state];

// --- SAVE COMPOSITION ---
private _comp = [];
private _processedVehicles = [];

{
    if (alive _x) then {
        private _vehicle = vehicle _x;
        
        if (_vehicle != _x) then {
            // Unit is in a vehicle
            private _vehType = typeOf _vehicle;
            if !(_vehicle in _processedVehicles) then {
                _processedVehicles pushBack _vehicle;
                _comp pushBack _vehType;
                ["VIRTUALIZATION", 3, format["Saved vehicle %1 to composition", _vehType]] call FLO_fnc_log;
            };
        } else {
            // Unit is on foot
            _comp pushBack (typeOf _x);
        };
    };
} forEach units _realGroup;

_groupData set ["comp", _comp];


// ==========================================================================================
// CLEANUP & DELETION
// ==========================================================================================

// Identify unique vehicles to delete
private _vehiclesToDelete = [];
{
    private _veh = vehicle _x;
    if (!isNull _veh && {_veh != _x}) then {
        _vehiclesToDelete pushBackUnique _veh;
    };
} forEach units _realGroup;

// Delete vehicles and their crews
{
    private _veh = _x;
    _veh hideObjectGlobal true;
    { 
        _x hideObjectGlobal true;
        _veh deleteVehicleCrew _x;
    } forEach (crew _veh); 
    deleteVehicle _veh; 
} forEach _vehiclesToDelete;

// Delete remaining units (dismounts)
{
    _x hideObjectGlobal true;
    deleteVehicle _x;
} forEach units _realGroup;

deleteGroup _realGroup;

// Update virtualization state
_groupData set ["realGroup", grpNull];
_groupData set ["isActive", false];
_groupData set ["lastStateChangeTime", diag_tickTime];

["FLO_Virtualization_GroupDeactivated", [_groupId, _groupData]] call CBA_fnc_localEvent;
["VIRTUALIZATION", 3, format["Deactivated virtual group: %1", _groupId]] call FLO_fnc_log;

true