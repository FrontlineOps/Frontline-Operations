/*
    Function: FLO_fnc_log
    
    Description:
    Logs a message to the RPT file based on the current debug level.
    
    Parameters:
    _component - The component name for the log message (String)
    _level - The log level (Number)
             0 = Off, 1 = Errors, 2 = Warnings, 3 = Info, 4 = Debug, 5 = All
    _message - The message to log (String)
    
    Returns:
    Nothing
*/

params [
    ["_component", "", [""]],
    ["_level", 3, [0]],
    ["_message", "", [""]]
];

// Debug Level Control: 0 = Off, 1 = Errors, 2 = Warnings, 3 = Info, 4 = Debug, 5 = All
if (isNil "FLO_Debug_Level") then {
    FLO_Debug_Level = 0;  // Default to Info level
};

// Only log if the current level is high enough
if (_level <= FLO_Debug_Level) then {
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