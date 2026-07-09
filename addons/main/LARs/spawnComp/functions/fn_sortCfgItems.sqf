//Sort composition items into spawnable items and those that need defering until an Object it relies upon has been spawned

private[ "_dataType" ];
params[ "_cfg", [ "_groupID", -1 ], [ "_groupCfg", configNull ], [ "_toDefer", false ], "_ctx" ];

private _objects = _ctx get "objects";
private _groupCfgs = _ctx get "groupCfgs";
private _itemCfgs = _ctx get "itemCfgs";
private _deferedIDs = _ctx get "deferedIDs";
private _deferedGrps = _ctx get "deferedGrps";

{
	_dataType = getText( _x >> "dataType" );
	
	_id = getNumber( _x >> "id" );
	if ( count _objects <= _id ) then {
		_objects resize _id;
	};

	_nul = _objects set [ _id, [ _id, _x, _dataType, _groupID, _groupCfg ] ];

	switch ( _dataType ) do {
		case "Layer" : {
			[ ( _x >> "Entities" ), -1, configNull, false, _ctx ] call LARs_fnc_sortCfgItems;
		};
		case "Group" : {
			if !( isClass( _x >> "crewLinks" ) ) then {
				_nul = _groupCfgs pushBack _x;
			}else{
				_nul = _deferedIDs pushBackUnique _id;
				_nul = _deferedGrps pushBack _x;
				[ ( _x >> "Entities" ), _id, _x, true, _ctx ] call LARs_fnc_sortCfgItems;
				//[ ( _x >> "CrewLinks" ) ] call LARs_fnc_deferLinks;
			};
		};
		default {
			if !( _toDefer ) then {
				_nul = _itemCfgs pushBack _x;
			}else{
				_nul = _deferedIDs pushBackUnique _id; 
				//_nul = _deferedItems pushBack _x;
			};
		};
	};
}forEach ( "true" configClasses _cfg );

