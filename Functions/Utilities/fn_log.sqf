/*
    Function: FLO_fnc_log
    
    Description:
    Logs a message to the RPT file based on the current debug level.
    
    Parameters:
    _component - The component name for the log message (String)
    _level - The log level (Number)
             0 = Off, 1 = Errors only, 2 = Warnings only, 3 = Info only, 4 = Debug only, 5 = All levels
    _message - The message to log (String)
    
    Returns:
    Nothing
*/

params [
    ["_component", "", [""]],
    ["_level", 3, [0]],
    ["_message", "", [""]]
];

// Debug Level Control: 0 = Off, 1 = Errors only, 2 = Warnings only, 3 = Info only, 4 = Debug only, 5 = All levels
if (isNil "FLO_Debug_Level") then {
    FLO_Debug_Level = 1;  // Default to show all levels
};

// Only log if the level matches exactly (or if level 5 is selected to show all)
if (_level == FLO_Debug_Level || FLO_Debug_Level == 5) then {
    private _prefix = switch (_level) do {
        case 0: {"OFF"};
        case 1: {"ERROR"};
        case 2: {"WARN"};
        case 3: {"INFO"};
        case 4: {"DEBUG"};
        case 5: {"ALL"};
        default {"TRACE"};
    };
    
    diag_log format ["[FLO][%1][%2] %3", _component, _prefix, _message];
};