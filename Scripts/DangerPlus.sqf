sleep 8 ;

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

if (_AGGRSCORE < 16) then {

FLO_Intel_System call ["showNotification", ["AGGRESSION", "Increased + + +", "warning"]];

_NewScore = _AGGRSCORE + 0.75; 
_mrkr setMarkerText str _NewScore;

} else { 

_NewScore = 15 ; 
_mrkr setMarkerText str _NewScore;

};