params ["_player", ["_baseType", "FOB", [""]]];

if (!isServer) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Base deployment must run on the server."]
    ]
};

if (isNull _player) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Invalid deployment player."]
    ]
};

if (!alive _player) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Cannot deploy a base while dead."]
    ]
};

private _type = toUpper _baseType;
if !(_type in ["FOB", "COP"]) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", format ["Unknown base type: %1", _baseType]]
    ]
};

private _side = side group _player;
if !(_side in [west, east]) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Base deployment is only available to BLUFOR and OPFOR."]
    ]
};

private _pos = getPosATL _player;
if (surfaceIsWater _pos) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Base deployment requires dry land."]
    ]
};

private _isCOP = _type isEqualTo "COP";
private _label = ["FOB", "COP"] select _isCOP;
private _minDistance = [500, 250] select _isCOP;
private _baseClass = [[FLO_FactionFobType, "Land_Cargo_HQ_V3_F"] select (_side isEqualTo east), [FLO_FactionCopType, "Land_Cargo_House_V3_F"] select (_side isEqualTo east)] select (_isCOP);
private _screenClass = [[FLO_FactionFobTerminalType, "Land_TripodScreen_01_large_sand_F"] select (_side isEqualTo east), [FLO_FactionCopTerminalType, "Land_TripodScreen_01_dual_v2_sand_F"] select (_side isEqualTo east)] select (_isCOP);
private _existingClasses = [
    FLO_FactionFobType,
    FLO_FactionCopType,
    "Land_Cargo_HQ_V1_F",
    "Land_Cargo_HQ_V3_F",
    "Land_Cargo_House_V1_F",
    "Land_Cargo_House_V3_F"
];
private _tooClose = false;

{
    if ((_x distance2D _pos) < _minDistance) exitWith {
        _tooClose = true;
    };
} forEach (nearestObjects [_pos, _existingClasses, _minDistance]);

if (_tooClose) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", format ["Deploy farther away from existing bases. Minimum distance: %1m.", _minDistance]]
    ]
};

private _base = createVehicle [_baseClass, _pos, [], 0, "CAN_COLLIDE"];
_base setDir (getDir _player);
_base setVariable ["FLO_BaseSide", _side, true];
_base setVariable ["FLO_BaseType", _label, true];

private _buildingPositions = _base buildingPos -1;
private _screenPos = if (_isCOP && {_buildingPositions isNotEqualTo []}) then {
    _buildingPositions select 0
} else {
    if ((!_isCOP) && {(count _buildingPositions) > 10}) then {
        _buildingPositions select 10
    } else {
        _base modelToWorld (if (_isCOP) then { [0, 1, 0] } else { [0, 2, 0] })
    }
};
private _screen = createVehicle [_screenClass, _screenPos, [], 0, "CAN_COLLIDE"];
_screen setDir ((getDir _base) + ([180, 45] select _isCOP));
_screen setVariable ["FLO_BaseSide", _side, true];
_screen setVariable ["FLO_BaseType", _label, true];

if (_isCOP) then {
    [_base] call FLO_fnc_initializeOP;
} else {
    [_base] call FLO_fnc_initializeFOB;
};

createHashMapFromArray [
    ["success", true],
    ["message", format ["%1 deployed at %2.", _label, mapGridPosition _base]],
    ["object", _base]
]
