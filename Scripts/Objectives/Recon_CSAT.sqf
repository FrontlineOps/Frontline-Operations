_thisReconTrigger = _this select 0;
_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

sleep 5; 

_allWatchposts = [ 
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

_poss = [_thisReconTrigger, 10, 200, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;

if (_AGGRSCORE < 6) then {
	[ selectRandom _allWatchposts, _poss, [0,0,0], 0, true ] call LARs_fnc_spawnComp;
};

if ((_AGGRSCORE > 5) && (_AGGRSCORE < 11)) then {
	[selectRandom _allWatchposts, _poss, [0,0,0], 0, true ] call LARs_fnc_spawnComp;
};

if (_AGGRSCORE > 10) then {
	[ selectRandom _allWatchposts, _poss, [0,0,0], 0, true ] call LARs_fnc_spawnComp;
};
		
[_thisReconTrigger, 210] execVM "Scripts\INTLitems.sqf";

{ if !((side _x) == west) then {
            ZEUS removeCuratorEditableObjects [[_x],true];
}; } foreach allUnits;





