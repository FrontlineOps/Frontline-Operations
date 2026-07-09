
//Spawns a marker from a composition

params[ "_cfg", "_ctx" ];

private _position = getArray( _cfg >> "position" );
_position = [ objNull, _position, [0,0,0], 0, [], false, 0, _ctx ] call LARs_fnc_setPositionAndRotation;
private _name = getText( _cfg >> "name" );
private _text = getText( _cfg >> "text" );
private _markerType = getText( _cfg >> "markerType" );
private _type = getText( _cfg >> "type" );
private _colorName = getText( _cfg >> "colorName" );
private _alpha = [ ( _cfg >> "alpha" ), "NUM", 1 ] call LARs_fnc_getCfgValue;

private _fill = getText( _cfg >> "fillName" );
private _sizeA = getNumber( _cfg >> "a" );
private _sizeB = getNumber( _cfg >> "b" );
private _angle = getNumber( _cfg >> "angle" );
private _id = getNumber( _cfg >> "id" );


private _mrk = createMarker[ _name, _position ];

_mrk setMarkerDirLocal _angle;
_mrk setMarkerTextLocal _text;
_mrk setMarkerSizeLocal [ _sizeA, _sizeB ];
if (_markerType isNotEqualTo "") then {
	_mrk setMarkerShapeLocal _markerType;
	if (_fill isNotEqualTo "") then {
		_mrk setMarkerBrushLocal _fill;
	};
}else{
	_mrk setMarkerShapeLocal "ICON";
	_mrk setMarkerType _type;
};
if (_colorName isNotEqualTo "") then {
	_mrk setMarkerColorLocal _colorName;
};
_mrk setMarkerAlpha _alpha;

_mrk
