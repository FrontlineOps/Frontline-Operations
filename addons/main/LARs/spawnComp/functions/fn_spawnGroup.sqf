//Spawns a group from a composition

params[ "_cfg", "_ctx" ];

private _side = call compile getText( _cfg >> "Side" );
private _group = createGroup _side;
private _inits = _ctx get "inits";
private _crewLinks = _ctx get "crewLinks";

private _attributes = _cfg >> "Attributes";

//TODO: Set groups relative position?

//TODO: Change so as to handle BI's enum behaviour
//TEST: Is the enum correct inside the composition
{
	_x params[ "_cfg", "_command" ];

	_value = [ _cfg, "TXT", "" ] call LARs_fnc_getCfgValue;
	if (_value isNotEqualTo "") then {
		_value call compile format[ "_group %1 _this", _command ];
	};
}forEach [
	[ ( _attributes >> "combatMode" ), "setCombatMode" ],
	[ ( _attributes >> "behaviour" ), "setBehaviour" ],
	[ ( _attributes >> "speedMode" ), "setSpeedMode" ],
	[ ( _attributes >> "formation" ), "setFormation" ]
];

private _name = [ ( _attributes >> "name" ), "TXT", "" ] call LARs_fnc_getCfgValue;
if (_name isNotEqualTo "") then {
	missionNamespace setVariable [ _name, _group, true ];
};

_garbageCollect = getNumber( _attributes >> "garbageCollect" );
if ( _garbageCollect > 0 ) then {
	_group deleteGroupWhenEmpty true;
};
_dynamicSimulation = getNumber( _attributes >> "dynamicSimulation" );
if ( _dynamicSimulation > 0 ) then {
	_group enableDynamicSimulation true;
};

_init = getText( _attributes >> "init" );
if (_init isNotEqualTo "") then {
	_nul = _inits pushBack [ _group, format[ "this = _this; %1", _init ] ];
};


{
	[ _x, _group, _ctx ] call LARs_fnc_spawnCompItems;
}forEach ( "true" configClasses ( _cfg >> "Entities" ) );

//TODO: Handle group placement radius ??
//private _placementRadius = getNumber( _attributes >> "placementRadius" );

//DO we want to fix placement spawning of whole groups ????
//	{
//		_x setPosATL formationPosition _x;
//	}forEach units _group;


//Save crewLinks until everything is spawned
if ( isClass( _cfg >> "crewLinks" ) ) then {
	{

		private _nul = _crewLinks pushBack [
			getNumber( _x >> 'item0' ),
			getNumber( _x >> 'item1' ),
			getNumber( _x >> 'customData' >> 'role' ),
			getArray( _x >> 'customData' >> 'turretPath' ),
			[ ( _x >> 'customData' >> 'cargoIndex' ), 'NUM', -1 ] call LARs_fnc_getCfgValue
		];

	}forEach ( "true" configClasses ( _cfg >> "crewLinks" >> "Links" ));
};

_group
