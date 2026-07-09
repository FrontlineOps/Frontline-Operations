/*
    Function: FLO_fnc_log
    
    Description:
    Logs a message to the RPT file based on the current debug level.
    Debug levels are cumulative severity thresholds.
    
    Parameters:
    _component - The component name for the log message (String)
    _level - The log level (Number)
             1 = Error
             2 = Warning
             3 = Info (requires FLO_Debug_Level >= 3)
             4 = Debug (requires FLO_Debug_Level >= 4)
             5 = Trace (requires FLO_Debug_Level >= 5)
    _message - The message to log (String)
    
    Returns:
    Nothing
    
    Debug Level Control:
    1 = Errors only
    2 = Errors/Warnings only (1-2)
    3 = Info and below (1-3)
    4 = Debug and below (1-4)
    5 = All levels (1-5)
*/

params [
    ["_component", "", [""]],
    ["_level", 3, [0]],
    ["_message", "", [""]]
];

if (isNil "FLO_Debug_Level") then {
    FLO_Debug_Level = 2;
};

private _shouldLog = _level <= FLO_Debug_Level;

if (_shouldLog) then {
    private _prefix = switch (_level) do {
        case 1: {"ERROR"};
        case 2: {"WARN"};
        case 3: {"INFO"};
        case 4: {"DEBUG"};
        case 5: {"TRACE"};
        default {"LOG"};
    };
    
    diag_log format ["[FLO][%1][%2] %3", _component, _prefix, _message];
};
