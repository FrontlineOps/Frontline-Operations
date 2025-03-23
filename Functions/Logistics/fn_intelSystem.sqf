/*
    Function: FLO_fnc_intelSystem
    
    Description:
    Manages BLUFOR's intelligence level based on collected intel and radio tower control.
    Intel decays over time but can be increased through intel collection and radio tower control.
    
    Parameter(s):
    _mode - The function mode to execute ["init", "get", "add", "notify", "showNotification"] (String)
    _params - Parameters based on mode (Array)
        init: [] - No parameters needed
        get: [] - No parameters needed
        add: [_amount, _source] - Amount to add and source of intel
        notify: [_message, _importance] - Message to broadcast and its importance (1-3)
        showNotification: [_title, _message, _type] - Title, message and type ("warning", "intel", "success", "info")
    
    Returns:
    Based on mode:
        init: Nothing
        get: Number - Current intel level
        add: Number - New intel level
        notify: Boolean - True if message was broadcast
        showNotification: Boolean - True if notification was shown
*/

params [
    ["_mode", "init", [""]],
    ["_params", [], [[]]]
];

// Only execute on server to prevent multiple intel systems running
if (!isServer) exitWith {};

// System configuration constants
private _INTEL_DECAY_RATE = 0.01;        // Intel points lost per minute
private _RADIO_TOWER_BONUS = 0.3;       // Multiplier for intel gain per radio tower
private _MAX_INTEL_LEVEL = 100;         // Maximum intel level
private _MIN_INTEL_LEVEL = 0;           // Minimum intel level
private _DECAY_INTERVAL = 300;           // Seconds between decay checks

// Initialize intel system if it doesn't exist (server only)
if (isNil "FLO_Intel_System") then {
    private _intelClass = [
        // Class identifier
        ["#type", "IntelSystem"],
        
        // Constructor - Called when object is created
        ["#create", {
            params [
                "_decayRate",
                "_radioTowerBonus",
                "_maxIntelLevel",
                "_minIntelLevel",
                "_decayInterval"
            ];

            _self set ["decayRate", _decayRate];
            _self set ["radioTowerBonus", _radioTowerBonus];
            _self set ["maxIntelLevel", _maxIntelLevel];
            _self set ["minIntelLevel", _minIntelLevel];
            _self set ["decayInterval", _decayInterval];
            _self call ["initDecayLoop", []];
        }],
        
        // Initial state properties
        ["intelLevel", 0],
        ["lastUpdate", time],
        ["radioTowers", 0],
        
        // Update and return the count of BLUFOR-controlled radio towers
        ["updateRadioTowers", {
            private _towers = count (allMapMarkers select { 
                markerType _x == "loc_Transmitter" && 
                markerColor _x == "colorBLUFOR" 
            });
            _self set ["radioTowers", _towers];
            _towers
        }],
        
        // Add intel from various sources with radio tower bonus
        ["addIntel", {
            params ["_amount", "_source"];
            
            // Get radio tower bonus multiplier
            private _radioTowers = _self call ["updateRadioTowers", []];
            private _bonus = 1 + (_radioTowers * (_self get "radioTowerBonus"));
            
            // Special case for intel items
            if (_source == "intel_item") then {
                _amount = 0.005;
                _bonus = 1;
            };
            
            // Calculate and apply new intel level with bounds
            private _adjustedAmount = _amount * _bonus;
            private _current = _self get "intelLevel";
            private _new = ((_current + _adjustedAmount) min (_self get "maxIntelLevel")) max (_self get "minIntelLevel");
            
            _self set ["intelLevel", _new];
            _self set ["lastUpdate", time];
            
            // TODO convert to FLO_fnc_sendNotification and add to string table
            // // Notify of significant intel gains
            // if (_adjustedAmount >= 10) then {
            //     private _msg = format ["Significant intelligence gained from %1", _source];
            //     _self call ["notify", [_msg, 2]];
            // };
            
            _new
        }],
        
        // Initialize the intel decay loop with optimized broadcasting
        ["initDecayLoop", {
             [] spawn {

                private _lastBroadcast = time;
                
                while {true} do {
                    // Get current intel state
                    private _currentLevel = FLO_Intel_System get "intelLevel";
                    private _lastUpdate = FLO_Intel_System get "lastUpdate";
                    private _timePassed = (time - _lastUpdate) / 60;
                    
                    // Update radio tower count
                    FLO_Intel_System call ["updateRadioTowers", []];
                    
                    // Calculate and apply intel decay
                    private _decay = (FLO_Intel_System get "decayRate") * _timePassed;
                    private _newLevel = (_currentLevel - _decay) max (FLO_Intel_System get "minIntelLevel");
                    
                    FLO_Intel_System set ["intelLevel", _newLevel];
                    FLO_Intel_System set ["lastUpdate", time];
                    
                    // Update players with current intel coverage level
                    private _intelText = switch (true) do {
                        case (_newLevel >= 75): {"High Intelligence Coverage"};
                        case (_newLevel >= 50): {"Moderate Intelligence Coverage"};
                        case (_newLevel >= 25): {"Limited Intelligence Coverage"};
                        default {"Minimal Intelligence Coverage"};
                    };
                    
                    [_intelText, _newLevel] remoteExec ["hint", 0];
                    
                    sleep (FLO_Intel_System get "decayInterval");
                };
            };
        }]        
    ];
    
    // Create the intel management object and make it public
    FLO_Intel_System = createHashMapObject [_intelClass, [_INTEL_DECAY_RATE, _RADIO_TOWER_BONUS, _MAX_INTEL_LEVEL, _MIN_INTEL_LEVEL, _DECAY_INTERVAL]];
};