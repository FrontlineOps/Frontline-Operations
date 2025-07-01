/*
 * Function: FLO_fnc_aiCommanderStagingDebug
 * Author: Frontline Operations Development Group
 * Description:
 * Debug visualization for AI Commander staging operations.
 * Creates markers to show staging points, operations, and group movements.
 *
 * Arguments:
 * 0: AI Commander Object <HASHMAP>
 * 1: Enable/Disable Debug <BOOL> (optional, default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_aiCommander, true] call FLO_fnc_aiCommanderStagingDebug;
 */

params ["_aiCommander", ["_enableDebug", true]];

if (!isServer) exitWith {};

// Store debug state in commander
_aiCommander set ["_debugEnabled", _enableDebug];

if (!_enableDebug) exitWith {
    // Clean up existing markers
    {
        deleteMarker _x;
    } forEach (allMapMarkers select {_x find "FLO_STAGING_" == 0 || _x find "FLO_OPERATION_" == 0});
    
    ["AI Commander Debug", 3, "Staging debug disabled - cleaned up markers"] call FLO_fnc_log;
};

// Add debug methods to the commander
_aiCommander set ["_updateDebugMarkers", {
    if (!(_self get "_debugEnabled")) exitWith {};
    
    // Clean up old markers first
    {
        if (_x find "FLO_STAGING_" == 0 || _x find "FLO_OPERATION_" == 0) then {
            deleteMarker _x;
        };
    } forEach allMapMarkers;
    
    // Create markers for attack operations
    private _attackOps = _self get "_attackOperations";
    {
        private _opId = _x;
        private _op = _y;
        private _stagingPos = _op get "stagingPos";
        private _targetPos = _op get "targetPos";
        private _groups = _op get "groups";
        private _launched = _op get "operationLaunched";
        
        // Staging point marker
        private _stagingMarker = createMarker [format["FLO_STAGING_ATK_%1", _opId], _stagingPos];
        _stagingMarker setMarkerType "hd_flag";
        _stagingMarker setMarkerColor (if (_launched) then {"ColorRed"} else {"ColorOrange"});
        _stagingMarker setMarkerText format["ATK STAGE: %1 (%2 grp)", _opId, count _groups];
        _stagingMarker setMarkerSize [0.8, 0.8];
        
        // Target marker
        private _targetMarker = createMarker [format["FLO_OPERATION_ATK_%1", _opId], _targetPos];
        _targetMarker setMarkerType "hd_destroy";
        _targetMarker setMarkerColor "ColorRed";
        _targetMarker setMarkerText format["ATK TGT: %1", _opId];
        _targetMarker setMarkerSize [1.0, 1.0];
        
        // Line from staging to target
        private _lineMarker = createMarker [format["FLO_STAGING_LINE_ATK_%1", _opId], _stagingPos];
        _lineMarker setMarkerShape "RECTANGLE";
        _lineMarker setMarkerColor "ColorRed";
        _lineMarker setMarkerBrush "Border";
        _lineMarker setMarkerSize [2, _stagingPos distance2D _targetPos / 2];
        _lineMarker setMarkerDir (_stagingPos getDir _targetPos);
        _lineMarker setMarkerPos (_stagingPos vectorAdd (_targetPos vectorDiff _stagingPos) vectorMultiply 0.5);
        
    } forEach _attackOps;
    
    // Create markers for defense operations
    private _defenseOps = _self get "_defenseOperations";
    {
        private _opId = _x;
        private _op = _y;
        private _stagingPos = _op get "stagingPos";
        private _targetPos = _op get "targetPos";
        private _groups = _op get "groups";
        private _launched = _op get "operationLaunched";
        
        // Staging point marker
        private _stagingMarker = createMarker [format["FLO_STAGING_DEF_%1", _opId], _stagingPos];
        _stagingMarker setMarkerType "hd_flag";
        _stagingMarker setMarkerColor (if (_launched) then {"ColorBlue"} else {"ColorYellow"});
        _stagingMarker setMarkerText format["DEF STAGE: %1 (%2 grp)", _opId, count _groups];
        _stagingMarker setMarkerSize [0.8, 0.8];
        
        // Target marker
        private _targetMarker = createMarker [format["FLO_OPERATION_DEF_%1", _opId], _targetPos];
        _targetMarker setMarkerType "hd_unknown";
        _targetMarker setMarkerColor "ColorBlue";
        _targetMarker setMarkerText format["DEF TGT: %1", _opId];
        _targetMarker setMarkerSize [1.0, 1.0];
        
        // Line from staging to target
        private _lineMarker = createMarker [format["FLO_STAGING_LINE_DEF_%1", _opId], _stagingPos];
        _lineMarker setMarkerShape "RECTANGLE";
        _lineMarker setMarkerColor "ColorBlue";
        _lineMarker setMarkerBrush "Border";
        _lineMarker setMarkerSize [2, _stagingPos distance2D _targetPos / 2];
        _lineMarker setMarkerDir (_stagingPos getDir _targetPos);
        _lineMarker setMarkerPos (_stagingPos vectorAdd (_targetPos vectorDiff _stagingPos) vectorMultiply 0.5);
        
    } forEach _defenseOps;
    
    // Create info marker showing commander status
    private _infoMarker = createMarker ["FLO_COMMANDER_INFO", [0, 0, 0]];
    _infoMarker setMarkerType "hd_dot";
    _infoMarker setMarkerColor "ColorWhite";
    _infoMarker setMarkerText format[
        "AI CDR: ATK:%1/%2 DEF:%3/%4 GAR:%5", 
        count (_self get "_activeAttackGroups"),
        _self get "_maxAttackingGroups",
        count (_self get "_activeDefenseGroups"),
        _self get "_maxDefendingGroups",
        count (_self get "_garrisonedGroups")
    ];
    _infoMarker setMarkerSize [0.5, 0.5];
}];

// Add debug info method
_aiCommander set ["_logOperationStatus", {
    private _attackOps = _self get "_attackOperations";
    private _defenseOps = _self get "_defenseOperations";
    
    ["AI Commander Debug", 3, format[
        "Operations Status - Attack: %1 active, Defense: %2 active, Total Groups: ATK:%3 DEF:%4 GAR:%5",
        count _attackOps,
        count _defenseOps,
        count (_self get "_activeAttackGroups"),
        count (_self get "_activeDefenseGroups"),
        count (_self get "_garrisonedGroups")
    ]] call FLO_fnc_log;
    
    // Detailed operation info
    {
        private _op = _y;
        private _launched = _op get "operationLaunched";
        private _groups = _op get "groups";
        private _ready = 0;
        
        if (!_launched) then {
            private _stagingPos = _op get "stagingPos";
            {
                private _gData = (FLO_virtualGroups get "_groups") get _x;
                if (!isNil "_gData") then {
                    private _pos = _gData get "position";
                    if (_pos distance2D _stagingPos < 75) then { _ready = _ready + 1; };
                };
            } forEach _groups;
        };
        
        ["AI Commander Debug", 4, format[
            "Attack Op %1: %2 groups, %3 ready, launched: %4",
            _x, count _groups, _ready, _launched
        ]] call FLO_fnc_log;
    } forEach _attackOps;
    
    {
        private _op = _y;
        private _launched = _op get "operationLaunched";
        private _groups = _op get "groups";
        private _ready = 0;
        
        if (!_launched) then {
            private _stagingPos = _op get "stagingPos";
            {
                private _gData = (FLO_virtualGroups get "_groups") get _x;
                if (!isNil "_gData") then {
                    private _pos = _gData get "position";
                    if (_pos distance2D _stagingPos < 50) then { _ready = _ready + 1; };
                };
            } forEach _groups;
        };
        
        ["AI Commander Debug", 4, format[
            "Defense Op %1: %2 groups, %3 ready, launched: %4",
            _x, count _groups, _ready, _launched
        ]] call FLO_fnc_log;
    } forEach _defenseOps;
}];

// Start debug update loop
[_aiCommander] spawn {
    params ["_commander"];
    
    while {_commander get "_debugEnabled"} do {
        _commander call ["_updateDebugMarkers", []];
        _commander call ["_logOperationStatus", []];
        sleep 30; // Update every 30 seconds
    };
    
    // Clean up markers when disabled
    {
        if (_x find "FLO_STAGING_" == 0 || _x find "FLO_OPERATION_" == 0 || _x == "FLO_COMMANDER_INFO") then {
            deleteMarker _x;
        };
    } forEach allMapMarkers;
};

["AI Commander Debug", 3, "Staging debug enabled - markers will update every 30 seconds"] call FLO_fnc_log;