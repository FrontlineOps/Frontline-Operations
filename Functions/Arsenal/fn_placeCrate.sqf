/*
    Function: FLO_fnc_placeCrate
    
    Description: Allows the player to place a purchased crate in the world
    
    Parameter(s):
        _crate - The actual crate object (hidden)
        _id - Crate ID
        _name - Crate name
        _cost - Crate cost
        _boxType - Type of box/crate
        _items - Array of items to be added to the crate
        _description - Crate description
        _newFunds - New funds balance after purchase
        
    Returns:
        None
*/

params ["_crate", "_id", "_name", "_cost", "_boxType", "_items", "_description", "_newFunds"];

// Create preview object
private _preview = _boxType createVehicleLocal (position player);
_preview allowDamage false;
_preview enableSimulation false;
_preview setObjectTextureGlobal [0, "#(argb,8,8,3)color(1,1,1,0.7)"];

// Setup placement mode
missionNamespace setVariable ["FLO_PlacementActive", true];
missionNamespace setVariable ["FLO_Crate", _crate];
missionNamespace setVariable ["FLO_Preview", _preview];

// Add movement handler
private _pfhID = [{
    params ["_args", "_pfhID"];
    _args params ["_preview"];
    
    if !(missionNamespace getVariable ["FLO_PlacementActive", false]) exitWith {
        [_pfhID] call CBA_fnc_removePerFrameHandler;
        if (!isNull _preview) then {
            deleteVehicle _preview;
        };
    };
    
    // Update position
    private _pos = screenToWorld [0.5, 0.5];
    _pos set [2, getTerrainHeightASL _pos];
    _preview setPosASL _pos;
    _preview setDir (getDir player);
    
}, 0, [_preview]] call CBA_fnc_addPerFrameHandler;

// Add place action
private _placeActionId = player addAction [
    "<t color='#00FF00'>Place Crate</t>",
    {
        params ["_target", "_caller", "_actionId", "_args"];
        _args params ["_preview", "_crate", "_items", "_pfhID"];
        
        // End placement
        missionNamespace setVariable ["FLO_PlacementActive", false];
        
        // Get position
        private _pos = getPosASL _preview;
        private _dir = getDir _preview;
        
        // Tell server where to place crate
        [_crate, _pos, _dir, _items] remoteExec ["FLO_fnc_finalizeCrate", 2];
        
        // Cleanup
        player removeAction _actionId;
        deleteVehicle _preview;
        
        // Remove cancel action
        private _cancelActionId = player getVariable ["FLO_CancelActionId", -1];
        if (_cancelActionId != -1) then {
            player removeAction _cancelActionId;
            player setVariable ["FLO_CancelActionId", -1];
        };
        
        // Remove key handler
        private _keyHandler = player getVariable ["FLO_KeyHandler", -1];
        if (_keyHandler != -1) then {
            (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyHandler];
        };
    },
    [_preview, _crate, _items, _pfhID],
    1.5,
    true,
    true,
    "",
    "missionNamespace getVariable ['FLO_PlacementActive', false]"
];
player setVariable ["FLO_PlaceActionId", _placeActionId];

// Add cancel action
private _cancelActionId = player addAction [
    "<t color='#FF0000'>Cancel Placement</t>",
    {
        params ["_target", "_caller", "_actionId", "_args"];
        _args params ["_preview", "_crate", "_cost"];
        
        // End placement
        missionNamespace setVariable ["FLO_PlacementActive", false];
        
        // Tell server to refund
        [_crate, _cost] remoteExec ["FLO_fnc_cancelCrate", 2];
        
        // Cleanup
        player removeAction _actionId;
        deleteVehicle _preview;
        
        // Remove place action
        private _placeActionId = player getVariable ["FLO_PlaceActionId", -1];
        if (_placeActionId != -1) then {
            player removeAction _placeActionId;
            player setVariable ["FLO_PlaceActionId", -1];
        };
        
        // Remove key handler
        private _keyHandler = player getVariable ["FLO_KeyHandler", -1];
        if (_keyHandler != -1) then {
            (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyHandler];
        };
        
        hint format ["Purchase cancelled. %1$ refunded.", _cost];
    },
    [_preview, _crate, _cost],
    1.5,
    true,
    true,
    "",
    "missionNamespace getVariable ['FLO_PlacementActive', false]"
];
player setVariable ["FLO_CancelActionId", _cancelActionId];

// Add ESC key handler
private _keyHandler = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];
    
    if (_key == 1 && {missionNamespace getVariable ["FLO_PlacementActive", false]}) then {
        private _preview = missionNamespace getVariable ["FLO_Preview", objNull];
        private _crate = missionNamespace getVariable ["FLO_Crate", objNull];
        
        // End placement
        missionNamespace setVariable ["FLO_PlacementActive", false];
        
        // Cleanup
        if (!isNull _preview) then {
            deleteVehicle _preview;
        };
        
        // Get cost for refund
        private _cost = 0;
        if (!isNull _crate) then {
            _cost = (_crate getVariable ["FLO_crateInfo", ["", "", 0, [], ""]]) select 2;
        };
        
        // Tell server to refund
        [_crate, _cost] remoteExec ["FLO_fnc_cancelCrate", 2];
        
        // Remove actions
        private _placeActionId = player getVariable ["FLO_PlaceActionId", -1];
        if (_placeActionId != -1) then {
            player removeAction _placeActionId;
            player setVariable ["FLO_PlaceActionId", -1];
        };

        private _cancelActionId = player getVariable ["FLO_CancelActionId", -1];
        if (_cancelActionId != -1) then {
            player removeAction _cancelActionId;
            player setVariable ["FLO_CancelActionId", -1];
        };
        
        hint format ["Purchase cancelled. %1$ refunded.", _cost];
        true
    } else {
        false
    };
}];

player setVariable ["FLO_KeyHandler", _keyHandler];

hint format ["Positioning %1...\nUse PLACE when satisfied or CANCEL to get a refund.", _name];
