private _mineTypesAP = ["APERSMine", "APERSBoundingMine"];
private _mineTypesAT = ["ATMine"];

private _createMines = {
    params ["_mineTypes", "_markers"];
    {
        for "_i" from 1 to 28 do {
            private _mineType = selectRandom _mineTypes;
            createMine [_mineType, getMarkerPos _x, [], 200];
        };
    } forEach _markers;
};

// Create AP mines
private _allAPMineMarks = allMapMarkers select {
    markerType _x == "mil_triangle" && markerColor _x == "colorBLUFOR" && markerText _x == "AP MineField"
};
[_mineTypesAP, _allAPMineMarks] call _createMines;

// Create AT mines
private _allATMineMarks = allMapMarkers select {
    markerType _x == "mil_triangle" && markerColor _x == "colorBLUFOR" && markerText _x == "AT MineField"
};
[_mineTypesAT, _allATMineMarks] call _createMines;
