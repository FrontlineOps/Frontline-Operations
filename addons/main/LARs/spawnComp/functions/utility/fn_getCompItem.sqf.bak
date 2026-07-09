//Find an item via its composition reference
//Passing the object itself will return its composition ID
//Passing a composition ID will return the object

private[ "_found" ];
params[ "_compReference", "_item" ];

//[ "Marker", "Object", "Group", "Waypoint", "Trigger", "Logic" ];
{
	if ( !isNil "_x" && { _x select 0 == _compReference } ) exitWith {
		{
			_x params[ "_id", "_obj" ];
			switch ( typeName _item ) do {
				case "STRING";
				case "WAYPOINT";
				case "ARRAY";
				case "GROUP";
				case "OBJECT" : {
					if ( _obj isEqualTo _item ) exitWith { _found = _id };
				};
				case "SCALAR" : {
					if ( _id isEqualTo _item ) exitWith { _found = _obj };
				};
			};
			if !( isNil "_found" ) exitWith {};
		}forEach ( _x select 1 );
	};
	if !( isNil "_found" ) exitWith {};
}forEach LARs_spawnedCompositions;

if ( isNil "_found" ) then {
	[ -1, objNull ] select ( _item isEqualType 0 ) 
}else{
	_found
};