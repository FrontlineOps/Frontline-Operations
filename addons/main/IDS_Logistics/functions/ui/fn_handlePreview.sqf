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
 * Implements rotation via WASD keys and zooming via +/- keys.
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

// Add keyDown handler for WASD rotation and +/- zooming
_display displayAddEventHandler ["KeyDown", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];
    
    private _preview = _display displayCtrl 9506;
    private _rotX = uiNamespace getVariable ["IDS_Logistics_previewRotX", 0];
    private _rotY = uiNamespace getVariable ["IDS_Logistics_previewRotY", 0];
    private _currentZoom = uiNamespace getVariable ["IDS_Logistics_previewZoom", 0.5];
    
    // Rotation speed (degrees per frame)
    private _rotationSpeed = 2;
    // Zoom speed
    private _zoomSpeed = 0.05;
    
    // Handle WASD keys and +/- for zooming
    switch (_key) do {
        case 17: { // W key
            _rotX = (_rotX + _rotationSpeed) max -80 min 80;
        };
        case 31: { // S key
            _rotX = (_rotX - _rotationSpeed) max -80 min 80;
        };
        case 30: { // A key
            _rotY = _rotY + _rotationSpeed;
        };
        case 32: { // D key
            _rotY = _rotY - _rotationSpeed;
        };
        case 13: { // + key
            private _newZoom = (_currentZoom + _zoomSpeed) max 0.01 min 0.02;
            uiNamespace setVariable ["IDS_Logistics_previewZoom", _newZoom];
            _preview ctrlSetModelScale _newZoom;
        };
        case 12: { // - key
            private _newZoom = (_currentZoom - _zoomSpeed) max 0.01 min 0.02;
            uiNamespace setVariable ["IDS_Logistics_previewZoom", _newZoom];
            _preview ctrlSetModelScale _newZoom;
        };
        default {
            // Not a handled key, don't consume the event
            false
        };
    };
    
    // Update stored rotation values
    uiNamespace setVariable ["IDS_Logistics_previewRotX", _rotX];
    uiNamespace setVariable ["IDS_Logistics_previewRotY", _rotY];
    
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
    
    // Consume the event if it was a handled key
    _key in [17, 31, 30, 32, 13, 12]
}];
