private _thisReconTrigger = _this select 0;
private _AGGRSCORE = FLO_DifficultyHandle get "value";  

sleep 5;

private _allWatchposts = [
    "Watchpost_2",
    "Watchpost_3", 
    "Watchpost_4",
    "Watchpost_5",
    "Watchpost_6",
    "Watchpost_7",
    "Watchpost_8",
    "Watchpost_9",
    "Watchpost_10"
];

private _poss = [_thisReconTrigger, 10, 200, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;

// Spawn watchpost based on difficulty
if (_AGGRSCORE < 6) then {
    [selectRandom _allWatchposts, _poss, [0,0,0], 0, true] call LARs_fnc_spawnComp;
} else {
    if (_AGGRSCORE < 11) then {
        [selectRandom _allWatchposts, _poss, [0,0,0], 0, true] call LARs_fnc_spawnComp;
    } else {
        [selectRandom _allWatchposts, _poss, [0,0,0], 0, true] call LARs_fnc_spawnComp;
    };
};

[_thisReconTrigger, 210] execVM "Scripts\INTLitems.sqf";