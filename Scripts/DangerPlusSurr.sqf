sleep 8;

["showNotification", ["AGGRESSION", "Increased + + +", "warning"]] call FLO_fnc_intelSystem;

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr);  

if (_AGGRSCORE < 34) then {
    _NewScore = _AGGRSCORE + 0.35; 
    _mrkr setMarkerText str _NewScore;
} else { 
    _NewScore = 34; 
    _mrkr setMarkerText str _NewScore;
};

