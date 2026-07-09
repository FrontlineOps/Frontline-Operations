//inital composition position as asked for by users

params[ "_compCfg", "_compPos", "_compRot" ];
private _asPlaced = false;

switch ( true ) do {

	//Get original composition position
	case ( _compPos isEqualType [] && { _compPos isEqualTo [] } ) : {
		_compPos = getArray( _compCfg >> "center" );
		_compPos = [ _compPos select 0, _compPos select 2, _compPos select 1 ];
		_asPlaced = true;
	};

	//Get position of a specified OBJECT
	case ( _compPos isEqualType objNull ) : {
		if ( _compRot isEqualType true ) then {
			_compRot = getDirVisual _compPos;
		};
		_compPos = getPosASLVisual _compPos;
	};

	//Get position of a MARKER
	case ( _compPos isEqualType "" && { getMarkerPos _compPos != [0,0,0] } ) : {
		if ( _compRot isEqualType true ) then {
			_compRot = markerDir _compPos;
		};
		if (count _compPos == 2) then {_compPos set [2,0];};
		_compPos = ATLToASL getMarkerPos _compPos;
	};

	//Get position of a LOCATION
	case ( _compPos isEqualType locationNull ) : {
		if ( _compRot isEqualType true ) then {
			_compRot = direction _compPos;
		};
		_compPos = ATLToASL locationPosition _compPos;
	};

	default {
		if (count _compPos == 2) then {_compPos set [2,0];};
		_compPos = ATLToASL _compPos;
	};
};

[ _compPos, _compRot, _asPlaced ]
