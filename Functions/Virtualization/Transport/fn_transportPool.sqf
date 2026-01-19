/*
 * Function: FLO_fnc_transportPool
 * Author: Frontline Operations Development Group
 * Description:
 *   Singleton pool manager for tracking available and active transports.
 *   Provides methods to find, claim, and release transport vehicles.
 *
 * Return Value:
 *   FLO_TransportPool <HASHMAP>
 */

if (!isServer) exitWith {};

if (!isNil "FLO_TransportPool") exitWith { FLO_TransportPool };

["TRANSPORT", 3, "Initializing Transport Pool Manager"] call FLO_fnc_log;

FLO_TransportPool = createHashMapFromArray [
    // Available transports: groupId -> [capacity, position]
    ["available", createHashMap],
    
    // Active transports: groupId -> [capacity, infantryGroupId]
    ["active", createHashMap]
];

// ============================================================================
// FIND AVAILABLE TRANSPORT FROM POOL
// ============================================================================
// Returns: groupId or ""
FLO_fnc_transportPoolFind = {
    params [
        ["_requiredCapacity", 1, [0]],
        ["_nearPos", [0,0,0], [[]]],
        ["_maxDistance", 3000, [0]]
    ];
    
    private _available = FLO_TransportPool get "available";
    private _bestGroup = "";
    private _bestDist = _maxDistance + 1;
    
    {
        private _groupId = _x;
        _y params ["_capacity", "_position"];
        
        if (_capacity < _requiredCapacity) then { continue };
        
        private _dist = _position distance2D _nearPos;
        if (_dist < _bestDist) then {
            _bestDist = _dist;
            _bestGroup = _groupId;
        };
    } forEach _available;
    
    if (_bestGroup != "") then {
        ["TRANSPORT", 3, format["Pool: Found available transport %1 (dist: %2m)", 
            _bestGroup, round _bestDist]] call FLO_fnc_log;
    };
    
    _bestGroup
};

// ============================================================================
// FIND EXISTING VEHICLE GROUP FROM VIRTUALIZATION
// ============================================================================
// Returns: groupId or ""
FLO_fnc_transportPoolFindExisting = {
    params [
        ["_requiredCapacity", 1, [0]],
        ["_nearPos", [0,0,0], [[]]],
        ["_side", east, [east]],
        ["_maxDistance", 5000, [0]]
    ];
    
    if (isNil "FLO_virtualGroups") exitWith { "" };
    
    private _groups = FLO_virtualGroups get "_groups";
    private _available = FLO_TransportPool get "available";
    private _active = FLO_TransportPool get "active";
    
    private _bestGroup = "";
    private _bestDist = _maxDistance + 1;
    private _bestCapacity = 0;
    
    {
        private _groupId = _x;
        private _gData = _y;
        
        // Skip if already in pool
        if (_groupId in _available || _groupId in _active) then { continue };
        
        // Must be same side
        if ((_gData get "side") != _side) then { continue };
        
        // Must be vehicle type that can transport
        private _groupType = _gData get "groupType";
        if (!(_groupType in ["motorized", "mechanized"])) then { continue };
        
        // Skip if already carrying passengers
        private _attachedGroups = _gData getOrDefault ["attachedGroups", []];
        if (count _attachedGroups > 0) then { continue };
        
        // Skip if on critical mission
        private _currentOrder = _gData getOrDefault ["currentOrder", ""];
        if (_currentOrder != "" && {!(_currentOrder in ["PATROL", "GARRISON", "DEFEND", ""])}) then { continue };
        
        // Get capacity from config or estimate
        private _vehicleType = _gData getOrDefault ["vehicleType", ""];
        private _capacity = if (_vehicleType != "") then {
            [_vehicleType] call FLO_fnc_transportGetCapacity
        } else {
            [_groupType] call FLO_fnc_transportGetCapacity
        };
        
        if (_capacity < _requiredCapacity) then { continue };
        
        // Check distance
        private _position = _gData get "position";
        private _dist = _position distance2D _nearPos;
        if (_dist < _bestDist) then {
            _bestDist = _dist;
            _bestGroup = _groupId;
            _bestCapacity = _capacity;
        };
    } forEach _groups;
    
    if (_bestGroup != "") then {
        ["TRANSPORT", 3, format["Pool: Found existing vehicle group %1 (capacity: %2, dist: %3m)", 
            _bestGroup, _bestCapacity, round _bestDist]] call FLO_fnc_log;
    };
    
    _bestGroup
};

// ============================================================================
// CLAIM TRANSPORT (move from available to active)
// ============================================================================
FLO_fnc_transportPoolClaim = {
    params [["_groupId", "", [""]], ["_infantryId", "", [""]]];
    
    if (_groupId == "") exitWith { false };
    
    private _available = FLO_TransportPool get "available";
    private _active = FLO_TransportPool get "active";
    
    // If in available pool, move to active
    private _data = _available getOrDefault [_groupId, nil];
    if (!isNil "_data") then {
        _available deleteAt _groupId;
        _active set [_groupId, [_data select 0, _infantryId]];
    } else {
        // Not in pool yet - get capacity and add to active
        if (isNil "FLO_virtualGroups") exitWith { false };
        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith { false };
        
        private _vehicleType = _gData getOrDefault ["vehicleType", ""];
        private _groupType = _gData get "groupType";
        private _capacity = if (_vehicleType != "") then {
            [_vehicleType] call FLO_fnc_transportGetCapacity
        } else {
            [_groupType] call FLO_fnc_transportGetCapacity
        };
        
        _active set [_groupId, [_capacity, _infantryId]];
    };
    
    ["TRANSPORT", 3, format["Pool: Claimed transport %1 for %2", _groupId, _infantryId]] call FLO_fnc_log;
    true
};

// ============================================================================
// RELEASE TRANSPORT (move from active to available)
// ============================================================================
FLO_fnc_transportPoolRelease = {
    params [["_groupId", "", [""]]];
    
    if (_groupId == "") exitWith { false };
    
    private _available = FLO_TransportPool get "available";
    private _active = FLO_TransportPool get "active";
    
    private _data = _active getOrDefault [_groupId, nil];
    if (isNil "_data") exitWith { false };
    
    _active deleteAt _groupId;
    
    // Update position before returning to pool
    private _position = [0,0,0];
    if (!isNil "FLO_virtualGroups") then {
        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (!isNil "_gData") then {
            _position = _gData get "position";
        };
    };
    
    _available set [_groupId, [_data select 0, _position]];
    
    ["TRANSPORT", 3, format["Pool: Released transport %1 back to available", _groupId]] call FLO_fnc_log;
    true
};

["TRANSPORT", 3, "Transport Pool Manager initialized"] call FLO_fnc_log;

FLO_TransportPool
