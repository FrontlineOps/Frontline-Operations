sleep 2;
_chance23 = selectRandom [0, 1, 2, 3, 4, 5];
if (_chance23 > 1) then {		
	
	if (count (nearestObjects [player, ["Land_Garbage_square3_F","Land_Garbage_square3_F","Land_Garbage_line_F","Land_Garbage_line_F", "Land_Garbage_line_F"], 1000]) > 0) then {
		_chance = selectRandom [0, 1, 2, 3, 4];
		if (_Chance > 2) then {		
			
			_IED = selectRandom nearestObjects [player, ["Land_Garbage_square3_F","Land_Garbage_square3_F","Land_Garbage_line_F","Land_Garbage_line_F", "Land_Garbage_line_F"], 1000];
			_pos = _IED getPos [(5 + (random 5)),(0 + (random 350))]; 
			_mrkr = createMarker [str _pos, _pos]; 
			_mrkr setMarkerType "hd_unknown";
			_mrkr setMarkerColor "colorCivilian";
			_mrkr setMarkerSize [0.8, 0.8];
			_mrkr setMarkerAlpha 0.6;
			
			sleep 1;
			private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
			["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_CIV", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
		} else {
			
			_INTL = allMapMarkers select { (markerAlpha _x == 0.001 or markerAlpha _x == 0) && markerColor _x == "colorOPFOR" && markerType _x == "o_unknown" && markerType _x != "o_inf" && markerType _x != "o_Ordnance" && markerType _x != "o_maint" && markerShape _x != "RECTANGLE" && markerShape _x != "ELLIPSE"};
			_x = selectRandom _INTL;
			
			_pos = (getMarkerpos _x) getPos [(5 + (random 15)),(0 + (random 350))]; 
			_mrkr = createMarker [str _pos, _pos]; 
			_mrkr setMarkerType "hd_unknown";
			_mrkr setMarkerColor "colorCivilian";
			_mrkr setMarkerSize [0.8, 0.8];
			_mrkr setMarkerAlpha 0.6;
			
			sleep 1;
			private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
			["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_CIV", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
		};
		
	} else {
		
		_INTL = allMapMarkers select { (markerAlpha _x == 0.001 or markerAlpha _x == 0) && markerColor _x == "colorOPFOR" && markerType _x == "o_unknown" && markerType _x != "o_inf" && markerType _x != "o_Ordnance" && markerType _x != "o_maint" && markerShape _x != "RECTANGLE" && markerShape _x != "ELLIPSE"};
		
		if (count _INTL > 0) then {
			private _intlMrkr = selectRandom _INTL;
			
			_pos = (getMarkerpos _intlMrkr) getPos [(5 + (random 15)),(0 + (random 350))]; 
			_mrkr = createMarker [str _pos, _pos]; 
			_mrkr setMarkerType "hd_unknown";
			_mrkr setMarkerColor "colorCivilian";
			_mrkr setMarkerSize [0.8, 0.8];
			_mrkr setMarkerAlpha 0.6;
			
			sleep 1;
			private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
			["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_CIV", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
		};
	};
	
} else {
	
	execVM "Scripts\INTL.sqf";
};