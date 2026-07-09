//Return an array of all objects spawned for the passed composition referece

private[ "_objects", "_nul" ];
params[ "_compReference" ];

_objects = [];

{
	if ( !isNil "_x" && { _x select 0 == _compReference } ) exitWith {
		{
			_nul = _objects pushBack ( _x select 1 ); 
		}forEach ( _x select 1 );
	};
}forEach LARs_spawnedCompositions;

_objects