// Get parameters from function call
private _center = _this select 0;
private _radius = _this select 1;

// Define intelligence items that can be added to enemies
private _intelItems = [
    "FlashDisk",
    "FilesSecret",
    "SmartPhone",
    "MobilePhone",
    "DocumentsSecret"
];

// Find all enemy units within the specified radius
private _enemyUnits = allUnits select {
    (side _x == east || side _x == independent) && 
    getPos _x distance _center < _radius
};

// Select approximately half of the enemy units randomly
private _enemyCount = count _enemyUnits;
private _targetCount = round (_enemyCount / 2);
private _shuffledEnemies = _enemyUnits call BIS_fnc_arrayShuffle;
private _selectedEnemies = _shuffledEnemies select [0, _targetCount];

// Add random intel items to selected enemies
{
    _x addItem selectRandom _intelItems;
} forEach _selectedEnemies;

// Temporarily remove non-BLUFOR units and vehicles from remains collector
private _nonBluforUnits = allUnits select { side _x != west };
private _nonBluforVehicles = vehicles select { side (driver _x) != west };

{ removeFromRemainsCollector [_x]; } forEach _nonBluforUnits;
{ removeFromRemainsCollector [_x]; } forEach _nonBluforVehicles;

sleep 3;

// Add non-BLUFOR units and vehicles back to remains collector
{ addToRemainsCollector [_x]; } forEach _nonBluforUnits;
{ addToRemainsCollector [_x]; } forEach _nonBluforVehicles;