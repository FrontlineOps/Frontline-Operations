
//Spawns a trigger from a composition

params[ "_cfg", [ "_defered", false ], "_ctx" ];

private _attributes = _cfg >> "Attributes";

//FIX for default grpNull passed from spawnItems
if ( _defered isEqualType grpNull ) then { _defered = false };

private _type = getText( _cfg >> "type" );
private _position = getArray( _cfg >> "position" );
private _rotation = getNumber( _cfg >> "angle" );
private _ATLOffset = getNumber( _cfg >> "atlOffset" );
private _varName = getText( _attributes >> "name" );
private _description = getText( _attributes >> "text" );
private _condition = if !( _defered ) then {
	[ ( _attributes >> "condition" ), "TXT", "this" ] call LARs_fnc_getCfgValue
}else{
	//If trigger is defered due to connections TriggerOwner
	//set its condition to false until after connections are made
	"false"
};

private _onActivation = getText( _attributes >> "onActivation" );
private _onDeactivation = getText( _attributes >> "onDeactivation" );
private _sizeA = getNumber( _attributes >> "sizeA" );
private _sizeB = getNumber( _attributes >> "sizeB" );
private _sizeC = getNumber( _attributes >> "sizeC" );
private _timeout = [ ( _attributes >> "timeout" ), "ARRAY", [0,0,0] ] call LARs_fnc_getCfgValue;
private _interuptable = [ ( _attributes >> "interuptable" ), "BOOL", false ] call LARs_fnc_getCfgValue;
private _repeatable = [ ( _attributes >> "repeatable" ), "BOOL", false ] call LARs_fnc_getCfgValue;

//TODO: Hopefully done see connections TriggerOwner
//Default to NONE if not defined it could possibly be waiting on a connection TriggerOwner
private _activationBy = [ ( _attributes >> "activationBy" ), "TXT", "NONE" ] call LARs_fnc_getCfgValue;

private _trig_type = [ ( _attributes >> "type" ), "TXT", "PRESENT" ] call LARs_fnc_getCfgValue;
private _isRectangle = [false, true] select getNumber( _attributes >> "isRectangle" );

private _effectCondition = [ ( _attributes >> "effectCondition" ), "TXT", "true" ] call LARs_fnc_getCfgValue;
private _effectSound = [ ( _attributes >> "effectSound" ), "TXT", "$NONE$" ] call LARs_fnc_getCfgValue;
private _effectVoice = getText( _attributes >> "effectVoice" );
private _effectSoundEnvironment = getText( _attributes >> "effectSoundEnvironment" );
private _effectSoundTrigger = getText( _attributes >> "effectSoundTrigger" );
private _effectMusic = getText( _attributes >> "effectMusic" );
private _effectTitle = getText( _attributes >> "effectTitle" );

private _isServerOnly = [ ( _attributes >> "isServerOnly" ), "BOOL", false ] call LARs_fnc_getCfgValue;


private _trg = createTrigger[ _type, [0,0,0], !_isServerOnly ];
_position = [ _trg, _position, [0,0,0], _ATLOffset, [], false, 0, _ctx ] call LARs_fnc_setPositionAndRotation;
_trg setTriggerArea [ _sizeA, _sizeB, _rotation, _isRectangle, _sizeC ];
if (_varName isNotEqualTo "") then {
	_trg setVehicleVarName _varName;
	missionNamespace setVariable [ _varName, _trg, true ];
};
_trg setTriggerText _description;
_trg setTriggerStatements [ _condition, _onActivation, _onDeactivation ];
_trg setTriggerActivation [ _activationBy, _trig_type, _repeatable ];
_trg setTriggerTimeout ( _timeout + [ _interuptable ] );

//TODO: Needs testing
_trg setEffectCondition _effectCondition;
if ( { (_x isNotEqualTo "") }count [ _effectVoice, _effectSoundEnvironment, _effectSoundTrigger ] > 0 || _effectSound != "$NONE$" ) then {
	_trg setSoundEffect [ _effectSound, _effectVoice, _effectSoundEnvironment, _effectSoundTrigger ];
};
if (_effectMusic isNotEqualTo "") then {
	_trg setMusicEffect _effectMusic;
};

switch ( true ) do {
	case ( isClass( missionConfigFile >> "RscTitles" >> _effectTitle ) ) : {
		_trg setTitleEffect [ "RES", "", _effectTitle ];
	};
	case ( isClass( configFile >> "CfgTitles" >> _effectTitle ) ) : {
		_trg setTitleEffect [ "OBJECT", "", _effectTitle ];
	};
	default {
		if (_effectTitle isNotEqualTo "") then {
			_trg setTitleEffect [ "TEXT", "PLAIN", _effectTitle ];
		};
	};
};

_trg
