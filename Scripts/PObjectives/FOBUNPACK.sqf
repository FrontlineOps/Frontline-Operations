/*
 * FOB Unpack Script
 * Runs on the CLIENT who activates the action.
 * Creates the FOB on the SERVER for proper network sync.
 */

// Find the nearest FOB container
private _fobContainer = nearestObjects [player, ["B_Slingload_01_Cargo_F"], 200] select 0;

if (isNull _fobContainer) exitWith {
    hint "No FOB container found nearby!";
};

private _pos = getPos _fobContainer;
private _dir = getDirVisual _fobContainer;

// Get faction building types
private _hqType = if (!isNil "F_HQ_01") then { F_HQ_01 } else { "Land_Cargo_HQ_V3_F" };
private _screenType = if (!isNil "F_HQ_C_01") then { F_HQ_C_01 } else { "Land_TripodScreen_01_large_sand_F" };

// Delete the container on server
[_fobContainer] remoteExec ["deleteVehicle", 2];

sleep 1;

// Create FOB buildings on SERVER and sync to all clients
private _fobHQ = objNull;
private _fobScreen = objNull;

// Server-side creation for proper network sync
if (isServer) then {
    _fobHQ = createVehicle [_hqType, _pos, [], 0, "CAN_COLLIDE"];
    _fobHQ setDir _dir;

    // Get building position for screen
    private _buildingPositions = _fobHQ buildingPos -1;
    private _screenPos = if (count _buildingPositions > 10) then {
        _buildingPositions select 10
    } else {
        _fobHQ modelToWorld [0, 2, 0]
    };

    _fobScreen = createVehicle [_screenType, _screenPos, [], 0, "CAN_COLLIDE"];
    _fobScreen setDir _dir + 180;

    // Initialize FOB functionality on server
    [_fobHQ] call FLO_fnc_initializeFOB;

    ["FOB_UNPACK", 3, format ["FOB unpacked at %1", mapGridPosition _fobHQ]] call FLO_fnc_log;
} else {
    // Client triggered the action - send to server
    [[_pos, _dir, _hqType, _screenType], {
        params ["_pos", "_dir", "_hqType", "_screenType"];

        private _fobHQ = createVehicle [_hqType, _pos, [], 0, "CAN_COLLIDE"];
        _fobHQ setDir _dir;

        private _buildingPositions = _fobHQ buildingPos -1;
        private _screenPos = if (count _buildingPositions > 10) then {
            _buildingPositions select 10
        } else {
            _fobHQ modelToWorld [0, 2, 0]
        };

        private _fobScreen = createVehicle [_screenType, _screenPos, [], 0, "CAN_COLLIDE"];
        _fobScreen setDir _dir + 180;

        [_fobHQ] call FLO_fnc_initializeFOB;

        ["FOB_UNPACK", 3, format ["FOB unpacked at %1 (from client request)", mapGridPosition _fobHQ]] call FLO_fnc_log;
    }] remoteExec ["call", 2];
};

hint "FOB Deployed!";