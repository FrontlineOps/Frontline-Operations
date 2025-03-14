/*
    Function: FLO_fnc_fireObserver
    
    Description:
    Handles the AI Fire Observer system for artillery control
    Only works with units defined as Fire Observers in FLO_configCache
    
    Parameters:
    _unit - The Fire Observer unit [Object]
    _side - Side of the Fire Observer [Side]
    
    Returns:
    Boolean - Success of initialization
*/

params ["_unit", "_side"];

// Exit if not a Fire Observer unit
// Check if unit type is in the fireObservers array from FLO_configCache
if !(typeOf _unit in (FLO_configCache get "fireObservers")) exitWith { false };

// Initialize global Fire Observer settings if not exists
if (isNil "FLO_fireObservers") then {
    FLO_fireObservers = createHashMapFromArray [
        ["observationTime", 15],    // Time needed to maintain vision
        ["cooldownTime", 300],      // 5 minutes between fire missions
        ["airSupportCooldown", 900],// 15 minutes between air support
        ["minRange", 100],          // Minimum range for artillery
        ["maxRange", 4000],         // Maximum range for artillery
        ["scanRadius", 1000],       // How far the observer looks for targets
        ["observers", createHashMap],  // Store individual observer data
        ["lastAirSupport", -900]    // Initialize air support cooldown
    ];
};

// Setup the Fire Observer
private _observerId = str _unit;
private _observerData = createHashMapFromArray [
    ["unit", _unit],
    ["side", _side],
    ["lastMission", -300],  // Start ready to fire
    ["observingTarget", objNull],
    ["observationStartTime", 0],
    ["isObserving", false]
];

(FLO_fireObservers get "observers") set [_observerId, _observerData];

// Add PFH to check for targets and manage observation
[{
    params ["_args", "_handle"];
    _args params ["_observerId"];
    
    private _observers = FLO_fireObservers get "observers";
    private _observer = _observers get _observerId;
    private _unit = _observer get "unit";
    
    // Remove handler if unit is dead or null
    if (isNull _unit || !alive _unit) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        _observers deleteAt _observerId;
    };
    
    private _currentTime = time;
    
    // Early cooldown check
    if (_currentTime - (_observer get "lastMission") < (FLO_fireObservers get "cooldownTime")) exitWith {};
    
    // If not observing, look for new targets
    if !(_observer get "isObserving") then {
        private _targets = _unit targets [true, FLO_fireObservers get "scanRadius"];
        private _validTargets = _targets select {
            private _targetPos = getPosASL _x;
            0 == count ((units side _unit) select {alive _x && _x distance _targetPos < 100})
        };
        
        if (count _validTargets > 0) then {
            private _target = selectRandom _validTargets;
            _observer set ["observingTarget", _target];
            _observer set ["isObserving", true];
            _observer set ["observationStartTime", _currentTime];
        };
    } else {
        private _target = _observer get "observingTarget";
        
        if (_currentTime - (_observer get "observationStartTime") >= (FLO_fireObservers get "observationTime")) then {
            // Double check no friendlies moved into area during observation
            private _targetPos = getPosASL _target;
            if (0 == count ((units side _unit) select {alive _x && _x distance _targetPos < 100})) then {
                private _lastAirSupport = FLO_fireObservers get "lastAirSupport";
                private _airSupportAvailable = (_currentTime - _lastAirSupport) > (FLO_fireObservers get "airSupportCooldown");

                private _supportType = floor random 10; // 0 to 10
                if (_supportType <= 3 && _airSupportAvailable) then {
                    // Call air support
                    private _airSupport = [getPosASL _target, "CAS", "", 150] call FLO_fnc_airSupport;
                    if (!isNil "_airSupport") then {
                        FLO_fireObservers set ["lastAirSupport", _currentTime];
                        [side _unit, "HQ"] commandChat "CAS birds inbound to marked position";
                    };
                } else {
                    // Call artillery
                    [getPosASL _target, 3] call FLO_fnc_artilleryPrep;
                    [side _unit, "HQ"] commandChat "Artillery barrage inbound to marked position";
                };

                // Update both cooldowns
                _observer set ["lastMission", _currentTime];
            } else {
                [side _unit, "HQ"] commandChat "Fire mission aborted - friendlies in target area.";
            };
            _observer set ["isObserving", false];
            _observer set ["observingTarget", objNull];
        };
    };
}, 2, [_observerId]] call CBA_fnc_addPerFrameHandler;

true