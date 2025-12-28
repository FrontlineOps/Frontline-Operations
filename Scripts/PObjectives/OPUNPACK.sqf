/*
 * OP Unpack Script
 * Runs on the CLIENT who activates the action.
 * Creates the OP on the SERVER for proper network sync.
 */

// Find the nearest OP container
private _opContainer = nearestObjects [player, ["B_Slingload_01_Repair_F"], 200] select 0;

if (isNull _opContainer) exitWith {
    hint "No OP container found nearby!";
};

private _pos = getPos _opContainer;
private _dir = getDirVisual _opContainer;

// Get faction building types
private _opType = if (!isNil "F_OP_01") then { F_OP_01 } else { "Land_Cargo_Patrol_V3_F" };
private _screenType = if (!isNil "F_OP_C_01") then { F_OP_C_01 } else { "Land_TripodScreen_01_dual_v2_sand_F" };

// Delete the container on server
[_opContainer] remoteExec ["deleteVehicle", 2];

sleep 1;

// Create OP buildings on SERVER and sync to all clients
if (isServer) then {
    private _opBuilding = createVehicle [_opType, _pos, [], 0, "CAN_COLLIDE"];
    _opBuilding setDir _dir;

    // Get building position for screen
    private _buildingPositions = _opBuilding buildingPos -1;
    private _screenPos = if (count _buildingPositions > 0) then {
        _buildingPositions select 0
    } else {
        _opBuilding modelToWorld [0, 1, 0]
    };

    private _commEquipment = createVehicle [_screenType, _screenPos, [], 0, "CAN_COLLIDE"];
    _commEquipment setDir _dir + 45;

    // Initialize OP functionality on server
    [_opBuilding] call FLO_fnc_initializeOP;

    ["OP_UNPACK", 3, format ["OP unpacked at %1", mapGridPosition _opBuilding]] call FLO_fnc_log;
} else {
    // Client triggered the action - send to server
    [[_pos, _dir, _opType, _screenType], {
        params ["_pos", "_dir", "_opType", "_screenType"];

        private _opBuilding = createVehicle [_opType, _pos, [], 0, "CAN_COLLIDE"];
        _opBuilding setDir _dir;

        private _buildingPositions = _opBuilding buildingPos -1;
        private _screenPos = if (count _buildingPositions > 0) then {
            _buildingPositions select 0
        } else {
            _opBuilding modelToWorld [0, 1, 0]
        };

        private _commEquipment = createVehicle [_screenType, _screenPos, [], 0, "CAN_COLLIDE"];
        _commEquipment setDir _dir + 45;

        [_opBuilding] call FLO_fnc_initializeOP;

        ["OP_UNPACK", 3, format ["OP unpacked at %1 (from client request)", mapGridPosition _opBuilding]] call FLO_fnc_log;
    }] remoteExec ["call", 2];
};

hint "Observation Post Deployed!";