//Entry function - calls function to spawn composition and handles composition references

//If Server


private[ "_objects", "_index", "_compReference" ];
params[ "_compName" ];

//Init spawned comp array if it does not already exist
if ( isNil "LARs_spawnedCompositions" ) then {
	LARs_spawnedCompositions = [];
};

//Create the composition
_objects = _this call LARs_fnc_createComp;

//Remove any nil entries from the objects array
{
	if !( isNil "_x" ) then {
		_objects set [ _forEachIndex, [ _forEachIndex, _x ] ];
	}else{
		_objects set [ _forEachIndex, objNull ];
	};
}forEach _objects;
_objects = _objects - [ objNull ];

//Find a unused entry in the compositions array
_index = {
	if ( isNil "_x" ) exitWith { _forEachIndex };
}forEach LARs_spawnedCompositions;

//If there is no unused entry
if ( isNil "_index" ) then {
	//Add it to the end
	_compReference = format[ "%1_%2", _compName, count LARs_spawnedCompositions ];
	_nul = LARs_spawnedCompositions pushBack [ _compReference, _objects ];
}else{
	//Else insert at index
	_compReference = format[ "%1_%2", _compName, _index ];
	LARs_spawnedCompositions set [ _index, [ _compReference, _objects ] ];
};

_compReference
