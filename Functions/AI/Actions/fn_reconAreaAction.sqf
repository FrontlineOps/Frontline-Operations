/* ----------------------------------------------------------------------------
Function: FLO_fnc_reconAreaAction

Description:
    A function to be executed when a unit reaches a reconnaissance waypoint.
    Reports information about enemy presence in the area to the AI commander.

Parameters:
    - Unit (Object) - The unit that triggered the waypoint

Returns:
    None

Example:
    (begin example)
    [this] call FLO_fnc_reconAreaAction
    (end)

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params ["_unit"];

// Get the group and position
private _group = group _unit;
private _position = getPos _unit;
private _radius = 300; // Scan range

// Detect enemies in the area
private _enemies = _position nearEntities [["Man", "LandVehicle", "Air"], _radius];
_enemies = _enemies select {side _x == west || side _x == civilian};

// If enemies detected, report to the AI Commander
if (count _enemies > 0) then {
    private _enemyTypes = [];
    private _enemyCount = count _enemies;
    private _infantry = 0;
    private _vehicles = 0;
    private _armor = 0;
    private _air = 0;
    
    // Categorize enemies
    {
        private _enemyType = "";
        
        if (_x isKindOf "Man") then {
            _infantry = _infantry + 1;
            _enemyType = "INFANTRY";
        } else {
            if (_x isKindOf "Air") then {
                _air = _air + 1;
                _enemyType = "AIR";
            } else {
                if (_x isKindOf "Tank" || _x isKindOf "Wheeled_APC") then {
                    _armor = _armor + 1;
                    _enemyType = "ARMOR";
                } else {
                    if (_x isKindOf "Car") then {
                        _vehicles = _vehicles + 1;
                        _enemyType = "VEHICLE";
                    };
                };
            };
        };
        
        if (_enemyType != "") then {
            _enemyTypes pushBackUnique _enemyType;
        };
    } forEach _enemies;
    
    // Log the recon information
    ["AI Commander", 2, format ["RECON REPORT: Unit %1 detected %2 enemies at %3: %4 infantry, %5 vehicles, %6 armor, %7 air assets", 
        _unit, _enemyCount, _position, _infantry, _vehicles, _armor, _air]] call FLO_fnc_log;
    
    // Notify the AI Commander of the enemy presence for potential response
    if (!isNil "FLO_AI_Commander") then {
        private _reportData = [
            _position,
            _enemyCount,
            _infantry,
            _vehicles,
            _armor,
            _air,
            _enemyTypes
        ];
        
        FLO_AI_Commander call ["_processReconReport", [_reportData, _group]];
    };
} else {
    // No enemies found
    ["AI Commander", 3, format ["RECON REPORT: Unit %1 reports no enemy contacts at %2", _unit, _position]] call FLO_fnc_log;
}; 