//Return composition referece for the passed object

private[ "_compName", "_objects" ];
params[ "_item" ];

//[ "Marker", "Object", "Group", "Waypoint", "Trigger", "Logic" ];
{
	if !( isNil "_x" ) then {
		_objects = ( _x select 0 ) call LARs_fnc_getCompObjects;
		if ( _item in _objects ) exitWith { _compName = _x select 0 };
	};
}forEach LARs_spawnedCompositions;

if ( isNil "_compName" ) then {
	""
}else{
	_compName
};