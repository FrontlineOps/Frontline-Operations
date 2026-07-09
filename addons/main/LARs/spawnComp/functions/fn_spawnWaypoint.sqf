
//Spawns a waypoint from a composition

params[ "_cfg", "_group", "_ctx" ];

private _position = getArray( _cfg >> "position" );
private _ATLOffset = getNumber( _cfg >> "atlOffset" );
_position = [ objNull, _position, [0,0,0], _ATLOffset, [], false, 0, _ctx ] call LARs_fnc_setPositionAndRotation;
private _placement = getNumber( _cfg >> "placement" );
private _compRadius = getNumber( _cfg >> "completitionRadius" );
private _condition = [ ( _cfg >> "expCond" ), "TXT", "true" ] call LARs_fnc_getCfgValue; //TODO: does this need defering
private _timeout = [ getNumber( _cfg >> "timeoutMin" ), getNumber( _cfg >> "timeoutMid" ), getNumber( _cfg >> "timeoutMax" ) ];
//TODO: does this need defering
private _effectCondition = [ ( _cfg >> "Effects" >> "condition" ), "TXT", "true" ] call LARs_fnc_getCfgValue;
private _type = getText( _cfg >> "type" );
private _show = getText( _cfg >> "showWP" );
private _onAct = getText( _cfg >> "expActiv" );

private _mode = getText( _cfg >> "combatMode" );
private _formation = getText( _cfg >> "formation" );
private _speed = getText( _cfg >> "speed" );
private _behaviour = getText( _cfg >> "combat" );
private _description = getText( _cfg >> "description" );
private _name = getText( _cfg >> "name" );
private _script = getText( _cfg >> "script" );
private _effectSound = [ ( _cfg >> "Effects" >> "sound" ), "TXT", "$NONE$" ] call LARs_fnc_getCfgValue;
private _effectVoice = getText( _cfg >> "Effects" >> "voice" );
private _effectSoundEnvironment = getText( _cfg >> "Effects" >> "soundEnv" );
private _effectMusic = getText( _cfg >> "Effects" >> "track" );
private _effectTitle = getText( _cfg >> "Effects" >> "title" );




private _wp = _group addWaypoint[ ASLToATL _position, _placement, count waypoints _group, _name];
_wp setWaypointType _type;
_wp setWaypointCompletionRadius _compRadius;
_wp setWaypointStatements[ _condition, _onAct ];
_wp setWaypointTimeout _timeout;
_wp showWaypoint _show;

if (_mode isNotEqualTo "") then {
	_wp setWaypointCombatMode _mode;
};
if (_formation isNotEqualTo "") then {
	_wp setWaypointFormation _formation;
};
if (_speed isNotEqualTo "") then {
	_wp setWaypointSpeed _speed;
};
if (_behaviour isNotEqualTo "") then {
	_wp setWaypointBehaviour _behaviour;
};
if (_description isNotEqualTo "") then {
	_wp setWaypointDescription _description;
};
if (_script isNotEqualTo "") then {
	_wp setWaypointScript _script;
};


//TODO: Effects need testing
_wp setEffectCondition _effectCondition;
if ( { (_x isNotEqualTo "") }count [ _effectVoice, _effectSoundEnvironment ] > 0 || _effectSound != "$NONE$" ) then {
	_wp setSoundEffect [ _effectSound, _effectVoice, _effectSoundEnvironment, "" ];
};
if (_effectMusic isNotEqualTo "") then {
	_wp setMusicEffect _effectMusic;
};

switch ( true ) do {
	case ( isClass( missionConfigFile >> "RscTitles" >> _effectTitle ) ) : {
		_wp setTitleEffect [ "RES", "", _effectTitle ];
	};
	case ( isClass( configFile >> "CfgTitles" >> _effectTitle ) ) : {
		_wp setTitleEffect [ "OBJECT", "", _effectTitle ];
	};
	default {
		if ( _effectTitle != "" ) then {
			_wp setTitleEffect [ "TEXT", "PLAIN", _effectTitle ];
		};
	};
};

_wp
