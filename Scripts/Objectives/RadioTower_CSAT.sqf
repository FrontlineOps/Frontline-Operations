_thisRadioTrigger = _this select 0;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_RadioTower = nearestObjects [(getPos _thisRadioTrigger), ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F", "Land_Communication_F"], 150] select 0;   
_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getpos _thisRadioTrigger), [], (0 + (random 40))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getpos _thisRadioTrigger), [], (0 + (random 40))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getpos _thisRadioTrigger), [], (0 + (random 40))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getpos _thisRadioTrigger), [], (0 + (random 40))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getpos _thisRadioTrigger), [], (0 + (random 40))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getpos _thisRadioTrigger), [], (0 + (random 40))];
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_Position = nearestObjects [(getpos _thisRadioTrigger), ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F", "Land_Communication_F"], 50] select 0;  
_poss = getPos _Position ;