/* Initializes persistent client UI infrastructure from one postInit owner. */
if (!hasInterface) exitWith { true };
if (FLO_ClientUIInitialized) exitWith { true };

private _initializers = [
    ["Capture", FLO_fnc_initCaptureUIEvents],
    ["Operations", FLO_fnc_operationsInitClient],
    ["Development", FLO_fnc_developmentInitClient],
    ["Support", FLO_fnc_supportInitClient],
    ["Deployment", FLO_fnc_baseDeployInitClient]
];

{
    _x params ["_name", "_initializer"];
    if !(call _initializer) then {
        private _message = format ["Persistent client UI initializer failed: %1", _name];
        ["UI", 1, _message] call FLO_fnc_log;
        throw _message;
    };
} forEach _initializers;

FLO_ClientUIInitialized = true;
["UI", 3, "Persistent client UI initialized: Capture, Operations, Development, Support, Deployment"] call FLO_fnc_log;
true
