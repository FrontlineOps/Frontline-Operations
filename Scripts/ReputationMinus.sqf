sleep 12 ;

_mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
_mrkr = _mrkrs select 0;
_REPSCORE = parseNumber (markerText _mrkr) ;  

if (_REPSCORE != 0) then {


FLO_Intel_System call ["showNotification", ["REPUTATION", "Decreased - - -", "success"]];


_NewScore = _REPSCORE - 1; 
_mrkr setMarkerText str _NewScore;


};






















