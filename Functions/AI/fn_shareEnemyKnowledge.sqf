/*
    Function: FLO_fnc_shareEnemyKnowledge
    
    Description:
        Shares enemy knowledge between OPFOR AI units. For infantry, shares within 500m.
        For armored/wheeled vehicles, shares within 2000m. Sets units to combat mode
        when enemies are detected.
    
    Parameters:
        None
        
    Returns:
        None
        
    Example:
        [] spawn FLO_fnc_shareEnemyKnowledge;
*/

if (!isServer) exitWith {};

private _allUnits = allUnits select {
    // Filter out helicopters and player units, keep only OPFOR
    !(vehicle _x isKindOf "Air") && 
    {!isPlayer _x} && 
    {alive _x} &&
    {side _x == east}
};

{
    private _currentUnit = _x;
    private _knownEnemies = _currentUnit targets [true, 0];
    
    if (count _knownEnemies > 0) then {
        {
            private _enemy = _x;
            // Share knowledge with nearby friendly units
            {
                private _friendlyVeh = vehicle _x;
                private _sharingRange = 500;
                
                // Extended range for armored/wheeled vehicles
                if (_friendlyVeh != _x && 
                    {_friendlyVeh isKindOf "Tank" || 
                     _friendlyVeh isKindOf "Wheeled_APC" || 
                     _friendlyVeh isKindOf "Tracked_APC" || 
                     _friendlyVeh isKindOf "Car"}
                ) then {
                    _sharingRange = 2000;
                };
                
                if (
                    (_x != _currentUnit) && 
                    {_x distance2D _enemy <= _sharingRange}
                ) then {
                    _x reveal [_enemy, 4]; // Maximum knowledge level
                    _x setBehaviourStrong "COMBAT";
                };
            } forEach _allUnits;  // No need to check side again since _allUnits is already filtered
        } forEach _knownEnemies;
    };
} forEach _allUnits; 