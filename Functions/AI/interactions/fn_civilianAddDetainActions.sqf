/*
 * Function: FLO_fnc_civilianAddDetainActions
 * Description: Adds Move/Stop/Mount actions to a detained civilian.
 * Arguments:
 *   0: Civilian Unit <OBJECT>
 */

params ["_unit"];

// Move Action
[_unit, [
    "<img size=2 color='#7CC2FF' image='\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Move",
    {
        params ["_target", "_caller"];
        _target attachTo [_caller, [0, 0.7, 0]];
    },
    nil, 0, true, true, "", "true", 3, false, "", ""
]] remoteExec ["addAction", 0, true];

// Stop Action
[_unit, [
    "<img size=2 color='#7CC2FF' image='\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Stop",
    {
        params ["_target"];
        detach _target;
    },
    nil, 0, true, true, "", "true", 3, false, "", ""
]] remoteExec ["addAction", 0, true];

// Mount Action
[_unit, [
    "<img size=2 color='#7CC2FF' image='\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Mount",
    {
        params ["_target", "_caller"];
        detach _target;
        private _nearVehicles = nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15];
        
        if (count _nearVehicles > 0) then {
            private _vh = _nearVehicles select 0;
            _target moveInCargo _vh;
            
            private _actionId = _vh getVariable ["FLO_UnmountActionID", -1];
            if (_actionId == -1) then {
                _actionId = _vh addAction [
                    "<img size=2 color='#7CC2FF' image='\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>UnMount POWs",
                    {
                        params ["_target", "_caller", "_actionId"];
                        
                        // Find a captive civilian
                        private _pows = crew _target select {side _x == civilian && captive _x && alive _x};
                        
                        if (count _pows > 0) then {
                            private _pow = _pows select 0;
                            unassignVehicle _pow;
                            moveOut _pow;
                            _pow switchMove 'AmovPercMstpSsurWnonDnon';
                            
                            // Re-check: if no more POWs, remove action?
                            if (count (_pows - [_pow]) == 0) then {
                                _target removeAction _actionId;
                                _target setVariable ["FLO_UnmountActionID", -1, true];
                            };
                        } else {
                            // Cleanup if empty
                            _target removeAction _actionId;
                            _target setVariable ["FLO_UnmountActionID", -1, true];
                        };
                    },
                    nil, 0, true, true, "", 
                    "(count (crew _target select {side _x == civilian && captive _x && alive _x}) > 0)", // Condition
                    5, false, "", ""
                ];
            };
        };
    },
    nil, 0, true, true, "", "count (nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15]) > 0", 5, false, "", ""
]] remoteExec ["addAction", 0, true];
