sleep 12 ;

_mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
_mrkr = _mrkrs select 0;
_REPSCORE = parseNumber (markerText _mrkr) ;  

if (_REPSCORE != 16) then {

FLO_Intel_System call ["showNotification", ["REPUTATION", "Increased + + +", "success"]];


_NewScore = _REPSCORE + 1; 
_mrkr setMarkerText str _NewScore;


};

