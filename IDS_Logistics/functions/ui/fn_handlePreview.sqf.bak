/**
 * @name IDS_Logistics_fnc_handlePreview
 * @category Logistics_UI
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Sets up interactive 3D preview functionality in the logistics interface.
 * Implements smooth rotation via mouse dragging and zooming via mouse wheel.
 * Handles gimbal lock prevention when viewing at extreme angles.
 *
 * @param {String} _mode - Mode of operation (unused but kept for consistency)
 * @param {Display} _display - The display containing the preview control
 *
 * @return {Nothing}
 *
 * @example
 * ["", findDisplay 12345] call IDS_Logistics_fnc_handlePreview
 */

params [["_display", displayNull, [displayNull]]];

_display displayCtrl 9506 ctrlEnable false;

// Store initial values
uiNamespace setVariable ["IDS_Logistics_previewRotX", 0];
uiNamespace setVariable ["IDS_Logistics_previewRotY", 0];
uiNamespace setVariable ["IDS_Logistics_previewZoom", 0.5];
uiNamespace setVariable ["IDS_Logistics_isDragging", false];
uiNamespace setVariable ["IDS_Logistics_lastMousePos", [0.5, 0.5]];

// Add mouse button handlers
_display displayAddEventHandler ["MouseButtonDown", {
    params ["_display", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    
    if (_button == 1) then { // Right mouse button
        uiNamespace setVariable ["IDS_Logistics_isDragging", true];
        uiNamespace setVariable ["IDS_Logistics_lastMousePos", [_xPos, _yPos]];
    };
}];

_display displayAddEventHandler ["MouseButtonUp", {
    params ["_display", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    
    if (_button == 1) then { // Right mouse button
        uiNamespace setVariable ["IDS_Logistics_isDragging", false];
    };
}];

// Add mouseMoving handler for rotation
_display displayAddEventHandler ["MouseMoving", {
    params ["_display", "_xPos", "_yPos", "_mouseOver"];
    
    // Only process rotation if dragging
    if (uiNamespace getVariable ["IDS_Logistics_isDragging", false]) then {
        private _preview = _display displayCtrl 9506;
        private _lastPos = uiNamespace getVariable ["IDS_Logistics_lastMousePos", [0.5, 0.5]];
        private _rotX = uiNamespace getVariable ["IDS_Logistics_previewRotX", 0];
        private _rotY = uiNamespace getVariable ["IDS_Logistics_previewRotY", 0];
        
        // Calculate rotation change based on mouse movement
        private _rotationSpeed = 100; // Adjust sensitivity as needed
        private _deltaX = (_xPos - (_lastPos select 0)) * _rotationSpeed;
        private _deltaY = (_yPos - (_lastPos select 1)) * _rotationSpeed;
        
        // Update stored rotation values
        _rotY = _rotY + _deltaX;
        _rotX = (_rotX + _deltaY) max -80 min 80; // Limit vertical rotation
        
        uiNamespace setVariable ["IDS_Logistics_previewRotX", _rotX];
        uiNamespace setVariable ["IDS_Logistics_previewRotY", _rotY];
        uiNamespace setVariable ["IDS_Logistics_lastMousePos", [_xPos, _yPos]];
        
        // Calculate direction and up vectors based on rotation values
        private _dir = [
            sin(_rotY) * cos(_rotX),
            cos(_rotY) * cos(_rotX),
            sin(_rotX)
        ];
        
        private _up = [0, 0, 1];
        if (abs(_rotX) > 85) then {
            // Adjust up vector when looking straight up/down to prevent gimbal lock
            _up = [sin(_rotY + 90), cos(_rotY + 90), 0];
        };
        
        // Apply rotation
        _preview ctrlSetModelDirAndUp [_dir, _up];
    };
}];

// Add mouseZChanged handler for zooming
_display displayAddEventHandler ["MouseZChanged", {
    params ["_display", "_scroll"];
    
    private _preview = _display displayCtrl 9506;
    private _currentZoom = uiNamespace getVariable ["IDS_Logistics_previewZoom", 0.5];
    
    // Adjust zoom level (negative scroll = zoom in)
    private _zoomChange = (_scroll * 0.05) * -1;
    private _newZoom = (_currentZoom + _zoomChange) max 0.01 min 0.02;
    uiNamespace setVariable ["IDS_Logistics_previewZoom", _newZoom];
    
    // Apply zoom by adjusting scale
    _preview ctrlSetModelScale _newZoom;
}];