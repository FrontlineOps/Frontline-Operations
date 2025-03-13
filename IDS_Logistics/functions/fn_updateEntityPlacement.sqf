/**
 * @name IDS_Logistics_fnc_updateEntityPlacement
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.2
 * @date 2025-03-10
 * 
 * @description
 * Updates the position and rotation of the currently held entity
 * based on camera position, direction, and placement settings.
 * Supports both level placement and terrain-aligned placement.
 * Camera-only mode - player-based functionality removed.
 *
 * @param {None} - Uses global variables for entity state and positioning
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_updateEntityPlacement
 */

if (!IDS_Logistics_isHolding || isNull IDS_Logistics_currentEntity) exitWith {};

if (isNil "IDS_LOGISTICS_CAM" || { isNull IDS_LOGISTICS_CAM }) exitWith {};

// Calculate base height
private _baseHeight = ((boundingBoxReal IDS_Logistics_currentEntity) select 1 select 2) - ((boundingBoxReal IDS_Logistics_currentEntity) select 0 select 2);
private _centerHeight = _baseHeight / 2; // Calculate the center height of the object

// Store the center height on the object for use during finalization
IDS_Logistics_currentEntity setVariable ["IDS_Logistics_CenterHeight", _centerHeight];

// Use camera for positioning
private _referencePos = getPosASL IDS_LOGISTICS_CAM;
private _referenceDir = 0;
private _forwardVector = [];

// Try multiple methods to get reliable camera view direction - better for freelook mode
_forwardVector = vectorDir IDS_LOGISTICS_CAM; // More reliable in all camera modes

// If vectorDir fails (returns [0,0,0]), try getCameraViewDirection
if (_forwardVector isEqualTo [0,0,0]) then {
    _forwardVector = getCameraViewDirection IDS_LOGISTICS_CAM;
};

// If that still fails, calculate from camera angle
if (_forwardVector isEqualTo [0,0,0]) then {
    private _camDirection = getDir IDS_LOGISTICS_CAM;
    _forwardVector = [sin _camDirection, cos _camDirection, 0];
};

// Get horizontal component
private _horizontalVector = [_forwardVector select 0, _forwardVector select 1, 0];
private _horizontalLength = vectorMagnitude _horizontalVector;

if (_horizontalLength > 0) then {
    // Normalize the horizontal vector
    _horizontalVector = [
        (_horizontalVector select 0) / _horizontalLength,
        (_horizontalVector select 1) / _horizontalLength,
        0
    ];
    _forwardVector = _horizontalVector;
} else {
    // Fallback for looking straight up/down
    _forwardVector = [0, 1, 0]; 
};

_referenceDir = (_forwardVector select 0) atan2 (_forwardVector select 1);
if (_referenceDir < 0) then { _referenceDir = _referenceDir + 360; };

// Calculate forward position based on the reference direction and distance
private _forwardPos = [
    (_referencePos select 0) + (_forwardVector select 0) * IDS_Logistics_entityDistance,
    (_referencePos select 1) + (_forwardVector select 1) * IDS_Logistics_entityDistance,
    (_referencePos select 2)
];

// Cast a ray down to find the ground
private _intersections = lineIntersectsSurfaces [
    [_forwardPos select 0, _forwardPos select 1, (_forwardPos select 2) + 10],
    [_forwardPos select 0, _forwardPos select 1, (_forwardPos select 2) - 10],
    IDS_Logistics_currentEntity,
    objNull,
    true,
    1,
    "GEOM",
    "NONE"
];

// Calculate final position
private _finalPos = _forwardPos;
private _surfaceNormal = [0,0,1]; // Default is straight up (level)

// If we hit the ground and have intersections
if (count _intersections > 0) then {
    private _intersection = _intersections select 0;
    private _intersectionPos = _intersection select 0;
    _surfaceNormal = _intersection select 1;
    
    // Update the position to be at ground level plus the entity height offset and its center height
    _finalPos = [
        _intersectionPos select 0,
        _intersectionPos select 1,
        (_intersectionPos select 2) + IDS_Logistics_entityHeight + _centerHeight
    ];
} else {
    // No ground intersection, use the original calculation with height offset
    _finalPos set [2, (_finalPos select 2) + IDS_Logistics_entityHeight];
};

// Calculate final direction (reference direction + rotation offset)
private _finalDir = (_referenceDir + IDS_Logistics_entityRotation) % 360;

// Update entity position and orientation
IDS_Logistics_currentEntity setPosASL _finalPos;
IDS_Logistics_currentEntity setDir _finalDir;

// Apply terrain snapping if enabled
if (!isNil "IDS_Logistics_CameraTerrainSnap" && { IDS_Logistics_CameraTerrainSnap }) then {
    // Align with terrain normal but maintain entity's forward direction
    private _entityDirVector = [sin _finalDir, cos _finalDir, 0];
    private _sideVector = _surfaceNormal vectorCrossProduct _entityDirVector;
    private _adjustedDirVector = _sideVector vectorCrossProduct _surfaceNormal;
    
    IDS_Logistics_currentEntity setVectorUp _surfaceNormal;
    IDS_Logistics_currentEntity setVectorDir _adjustedDirVector;
} else {
    // Keep entity level
    IDS_Logistics_currentEntity setVectorUp [0,0,1];
};