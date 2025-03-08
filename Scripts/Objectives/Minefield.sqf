params ["_pos"]; 

private _mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
private _mrkr = _mrkrs select 0;
private _AGGRSCORE = parseNumber (markerText _mrkr) ;  

private _mines = [];
private _mineCount = 10; // Default mine count

if (_AGGRSCORE < 6) then {
    _mineCount = 10;
} else {
    _mineCount = 20;
};

if (_AGGRSCORE > 10) then {
    _mineCount = 40;
};

private _minesToCreate = [];
if (_AGGRSCORE > 5) then {
    _minesToCreate = ["APERSMine", "APERSBoundingMine", "ATMine"];
} else {
    _minesToCreate = ["APERSMine", "APERSBoundingMine"];
};

for "_i" from 1 to _mineCount do {
    private _mineType = selectRandom _minesToCreate;
    private _distance = 0 + (random (if (_AGGRSCORE < 6) then {100} else {if (_AGGRSCORE < 11) then {250} else {450}}));
    _mine = createMine [_mineType, _pos, [], _distance];
    _mines pushBack _mine;
};

[_mines] spawn {
    params ["_mines"];
    _mines = +_mines; // Create a copy so we can mutate
    scopeName "MinefieldLoop";
    while {count _mines > 0} do {
        sleep 10; // Check every 10 seconds

        // Recount active mines
        private _i = 0;
        while {_i < count _mines} do {
            private _mine = _mines select _i;
            if (_mine isEqualTo objNull || {!mineActive _mine}) then {
                _mines deleteAt _i;
            } else {
                _i = _i + 1;
            };
        };

        // Reward if cleared or exploded
        if (count _mines == 0) then {
            private _MMarks = allMapMarkers select {markerType _x == "loc_mine"};
            private _M = [_MMarks, _pos] call BIS_fnc_nearestPosition;

            if (!isNil "_M") then {
                deleteMarker _M;
            };

            [100, "MINEFIELD"] call FLO_fnc_notification;
            [100] call FLO_fnc_addReward;
            [] execVM "Scripts\ReputationPlus.sqf";
            execVM "Scripts\Civ_Relations.sqf";

            breakOut "MinefieldLoop"; // Kill the Do Loop
        };
    };
};