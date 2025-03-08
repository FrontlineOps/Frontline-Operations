sleep 2;
_POW = nearestObjects [player , ["B_Pilot_F"], 10000] ;  
_CPOW = _POW select {side _x == civilian};
_THPOW = _CPOW select 0;

_possss = (getPos _THPOW) getPos [(30 + (random 100)), (0 + (random 350))];
_markerName = "CSMark" + (str _possss);
_mrkr = createMarkerLocal [_markerName,_possss];
_mrkr setMarkerType "hd_unknown"; 
_mrkr setMarkerSize [0.7, 0.7];  
_mrkr setMarkerColor "colorCivilian";  
_mrkr setMarkerAlpha 0.7;
								sleep 1;
								FLO_Intel_System call ["showNotification", ["+ NEW INTEL", "POW Intel Received", "intel"]];
									_attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
								[[west,"HQ"], "Enemy Presence Confirmed at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];

 