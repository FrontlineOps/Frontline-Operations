/*
 * Function: FLO_fnc_civilianDetainActions
 * Description: Adds detain-related actions to a captured civilian.
 */
params ["_unit"];

// Move Action
[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Move",
    {(_this select 0) attachTo [player, [0, 0.7, 0]];},
    nil, 0, true, true, "", "true", 3, false, "", ""
]] remoteExec ["addAction", 0, true];

// Stop Action
[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Stop",
    {detach (_this select 0);},
    nil, 0, true, true, "", "true", 3, false, "", ""
]] remoteExec ["addAction", 0, true];

// Mount Action
[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Mount",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        detach _target;
        private _nearVehicles = nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15];
        
        if (count _nearVehicles > 0) then {
            private _vh = _nearVehicles select 0;
            _target moveInCargo _vh;
            
            // Unmount Action
            [_vh, [
                "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>UnMount",
                {
                    params ["_target", "_caller", "_actionId"];
                    private _pows = crew _target select {side _x == civilian && captive _x && alive _x};
                    if (count _pows > 0) then {
                        private _pow = _pows select 0;
                        detach _pow;
                        unassignVehicle _pow;
                        moveOut _pow;
                        _pow switchMove 'AmovPercMstpSsurWnonDnon';
                        _target removeAction _actionId;
                    };
                },
                nil, 0, true, true, "", "true", 5, false, "", ""
            ]] remoteExec ["addAction", 0, true];
        };
    },
    nil, 0, true, true, "", "count (nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15]) > 0", 5, false, "", ""
]] remoteExec ["addAction", 0, true];
