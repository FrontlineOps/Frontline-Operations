//Apply composition Object rotation and position
//TODO: Fixme, this is not always corrrect

#include "macros.inc"

private[ "_pos", "_newPosX", "_newPosY", "_newPosASL", "_newPosZ", "_rotation", "_mkrPos" ];
params[
	[ "_obj", objNull ],
	[ "_cfgOffset", [0,0,0] ],
	[ "_cfgRot", [0,0,0] ],
	[ "_ATLOffset", 0 ],
	[ "_randomStartPos", [] ],
	[ "_needsSurfaceUp", false ],
	[ "_placementRadius", 0 ],
	"_ctx"
];

private _compIgnoreATLOffset = _ctx get "compIgnoreATLOffset";
private _compRot = _ctx get "compRot";
private _compOffset = _ctx get "compOffset";
private _compAlign = _ctx get "compAlign";
private _asPlaced = _ctx get "asPlaced";
private _compPos = _ctx get "compPos";
private _compWater = _ctx get "compWater";

if ( _compIgnoreATLOffset ) then {
	_ATLOffset = 0;
};

//TESTING
//	if ( DEBUG_DEV ) then {
//		if !( canSuspend ) exitWith {
//			_this spawn LARs_fnc_setPositionAndRotation;
//		};
//	};

//ReOrientated Objects composition offset from [ x, z, y ] to [ x, y, z ]
_cfgOffset = [ _cfgOffset select 0, _cfgOffset select 2 , _cfgOffset select 1 ];

//Rotate composition offset by rotation passed to spawnComp
_cfgOffset = [ _cfgOffset, 360 - _compRot ] call BIS_fnc_rotateVector2D;

//Add offset passed to spawnComp ( rotated by rotation passed to spawnComp )
_cfgOffset = _cfgOffset vectorAdd ( [ _compOffset, 360 - _compRot ] call BIS_fnc_rotateVector2D ) ;

if ( _compAlign && !_asPlaced ) then {
	_newPosX = ( _compPos select 0 ) + ( _cfgOffset select 0 );
	_newPosY = ( _compPos select 1 ) + ( _cfgOffset select 1 );
	_newPosASL = getTerrainHeightASL [ _newPosX, _newPosY ];
	_newPosZ = _newPosASL + ( _cfgOffset select 2 );
//		if ( _asPlaced ) then {
//			_pos = [ _newPosX, _newPosY, _newPosZ + _ATLOffset ];
//		}else{
		_pos = [ _newPosX, _newPosY, _newPosZ ];
//		};
}else{
	_pos = ( _compPos vectorAdd _cfgOffset ) vectorAdd [ 0, 0, _ATLOffset ];
};

if ( _randomStartPos isNotEqualTo [] ) then {
	_randomStartPos = _randomStartPos  apply {
		_mkrPos = ATLToASL getMarkerPos _x;
		_mkrPos = _mkrPos vectorAdd [ 0, 0, abs( boundingBoxReal _obj select 0 select 2 ) ];
		_mkrPos
	};
	_pos = selectRandom ( [ _pos ] + _randomStartPos );
};

if ( _placementRadius > 0 ) then {
	_pos = AGLToASL ( _pos getPos [ random _placementRadius, random 360 ] );
	_pos = _pos vectorAdd [ 0, 0, abs( boundingBoxReal _obj select 0 select 2 ) ];
};

if ( surfaceIsWater _pos && _compWater && !_asPlaced ) then {
	_pos = [ _pos select 0, _pos select 1, 0 + ( _cfgOffset select 2 ) + ( _compOffset select 2 ) ];
};

if ( DEBUG_DEV ) then {
	//OBJECT composition pos + offset + atl offset
	createVehicle [ "Sign_Arrow_Yellow_F", ASLToATL ( ( _compPos vectorAdd _cfgOffset ) vectorAdd [ 0, 0, _ATLOffset ] ), [], 0, "CAN_COLLIDE" ];
	//OBJECT calculated final position
	createVehicle [ "Sign_Arrow_Green_F", ASLToATL _pos, [], 0, "CAN_COLLIDE" ];
};


if !( isNull _obj ) then {

	//Move object to its world position
	_obj setPosWorld _pos;

	//Turn composition angles to degrees
	_cfgRot params[ "_pitch", "_yaw", "_roll" ];

	_yaw = ( deg _yaw ) + _compRot;
	_pitch = deg _pitch;
	_roll = 360 - deg _roll;

	//If Aliging composition or its a vehicle that needs surface up
	private _surfacePitchBank = if ( ( _compAlign || _needsSurfaceUp ) && !( surfaceIsWater _pos && _compWater ) && !_asPlaced ) then {
		//Face it in the right direction
		_obj setDir _yaw;
		//Get positions surface up
		private _surfaceUp = surfaceNormal _pos;

		//Get bound corner surface ups
		private _bounds = boundingBoxReal _obj;
		_bounds params[ "_mins", "_maxs" ];
		_mins params[ "_minX", "_minY", "_minZ" ];
		_maxs params[ "_maxX", "_maxY" ];

		//Calculate up based on corner surface normals
		private _newUp = _surfaceUp;
		{
			private _cornerPos = _obj modelToWorldVisual _x;
			private _cornerUp = surfaceNormal _cornerPos;
			private _weight = _pos distance _cornerPos;
			private _diff = ( _surfaceUp vectorDiff _cornerUp ) vectorMultiply _weight;
			_newUp = _newUp vectorAdd _diff;
		}forEach [
			[ _minX, _minY, _minZ ],
			[ _minX, _maxY, _minZ ],
			[ _maxX, _maxY, _minZ ],
			[ _maxX, _minY, _minZ ]
		];

		_obj setVectorUp vectorNormalized _surfaceUp;

		_obj call BIS_fnc_getPitchBank
	}else{
		[ 0, 0 ]
	};

	//Add any surface offset to composition rotations
	_surfacePitchBank params[ "_surfacePitch", "_surfaceRoll" ];

	_pitch = _pitch + _surfacePitch;
	_roll = _roll + _surfaceRoll;

	//Make sure rotations are in 0 - 360 range
	private _normalizeDegrees = {
		params [ "_degrees" ];
		private _normal = _degrees mod 360;
		if (_normal < 0) then {
			_normal + 360
		} else {
			_normal
		}
	};

	_pitch = [_pitch] call _normalizeDegrees;
	_roll = [_roll] call _normalizeDegrees;
	_yaw = [_yaw] call _normalizeDegrees;

	//Calculate Dir and Up
	private _dir = [ sin _yaw * cos _pitch, cos _yaw * cos _pitch, sin _pitch];
	private _up = [ [ sin _roll, -sin _pitch, cos _roll * cos _pitch ], -_yaw ] call BIS_fnc_rotateVector2D;

	//Set Object orientation
	_obj setVectorDirAndUp [ _dir, _up ];

};

_pos

//private LARs_fnc_getRotation = {
//	params[ "_CfgRot", "_obj" ];
//
//
//	_CfgRot params[ "_P", "_Y", "_R" ];
//	_Y = ( ( deg _Y ) + _compRot );
//	_P = ( deg _P );
//	_R = ( deg _R );
//
//	_cfgDir = [ sin _Y * cos _P, cos _Y * cos _P, sin _P];
//	_cfgUp = [ [ sin _R, -sin _P, cos _R * cos _P ], -_Y ] call BIS_fnc_rotateVector2D;
//
//	_obj setVectorDirAndUp [ _cfgDir, _cfgUp ];
//
//};
