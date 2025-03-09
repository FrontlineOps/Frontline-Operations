// This Function is for when players capture radio towers to display enemy positions (small to large based on Marker Size)

// Function to create markers for enemy units
private _createMarkers = {
    params ["_units", "_markerColor", "_markerPrefix"];
    private _transmitterMarkers = allMapMarkers select { markerType _x == "loc_Transmitter" && markerColor _x == "colorBLUFOR" };

    {
        private _unit = _x;
        private _nearestTransmitter = [_transmitterMarkers, position _unit] call BIS_fnc_nearestPosition;
        if ((getMarkerPos _nearestTransmitter) distance (position _unit) < 3500) then {
            private _radius = 50 + (random 250);
            private _markerName = _markerPrefix + (str (position _unit getPos [(5 + (random 15)), (0 + (random 360))]));
            private _marker = createMarkerLocal [_markerName, position _unit];
            _marker setMarkerColorLocal _markerColor;
            _marker setMarkerBrushLocal "FDiagonal";
            _marker setMarkerShapeLocal "RECTANGLE";
            _marker setMarkerSizeLocal [_radius, _radius];
            _marker setMarkerAlpha (0 + (random 0.4));
        };
    } forEach _units;
};

// Function to create markers for enemy ordnance markers
private _createOrdnanceMarkers = {
    params ["_markers", "_markerColor", "_markerPrefix"];
    private _transmitterMarkers = allMapMarkers select { markerType _x == "loc_Transmitter" && markerColor _x == "colorBLUFOR" };

    {
        private _marker = _x;
        private _nearestTransmitter = [_transmitterMarkers, getMarkerPos _marker] call BIS_fnc_nearestPosition;
        if ((getMarkerPos _nearestTransmitter) distance (getMarkerPos _marker) < 3500) then {
            private _radius = 50 + (random 250);
            private _newMarkerName = _markerPrefix + (str ((getMarkerPos _marker) getPos [(5 + (random 15)), (0 + (random 360))]));
            private _newMarker = createMarkerLocal [_newMarkerName, getMarkerPos _marker];
            _newMarker setMarkerColorLocal _markerColor;
            _newMarker setMarkerBrushLocal "FDiagonal";
            _newMarker setMarkerShapeLocal "RECTANGLE";
            _newMarker setMarkerSizeLocal [_radius, _radius];
            _newMarker setMarkerAlpha (0 + (random 0.4));
        };
    } forEach _markers;
};

// Create markers for OPFOR units
private _opforUnits = allUnits select { side _x == east && alive _x && leader _x == _x };
[_opforUnits, "colorOPFOR", "Enm_East"] call _createMarkers;
sleep 1;

// Create markers for Independent units
private _independentUnits = allUnits select { side _x == independent && alive _x && leader _x == _x };
[_independentUnits, "colorIndependent", "Enm_Guer"] call _createMarkers;
sleep 1;

// Create markers for OPFOR ordnance markers
private _opforOrdnanceMarkers = allMapMarkers select { markerType _x == "o_Ordnance" && markerColor _x == "colorOPFOR" };
[_opforOrdnanceMarkers, "colorOPFOR", "Enm_East"] call _createOrdnanceMarkers;
sleep 1;

// Create markers for Independent ordnance markers
private _independentOrdnanceMarkers = allMapMarkers select { markerType _x == "o_Ordnance" && markerColor _x == "colorIndependent" };
[_independentOrdnanceMarkers, "colorIndependent", "Enm_Guer"] call _createOrdnanceMarkers;