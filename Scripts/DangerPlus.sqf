sleep 8 ;

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

if (_AGGRSCORE < 34) then {

["showNotification", ["AGGRESSION", "Increased + + +", "warning"]] call FLO_fnc_intelSystem;

_NewScore = _AGGRSCORE + 0.75; 
_mrkr setMarkerText str _NewScore;

} else { 

_NewScore = 15 ; 
_mrkr setMarkerText str _NewScore;

};