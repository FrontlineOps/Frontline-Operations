
private[ "_item0ID", "_item1ID", "_item0Info", "_item1Info", "_linkType" ];
params[ "_cfg", "_ctx" ];

private _objects = _ctx get "objects";
private _groupCfgs = _ctx get "groupCfgs";
private _itemCfgs = _ctx get "itemCfgs";
private _deferedIDs = _ctx get "deferedIDs";
private _deferedItems = _ctx get "deferedItems";
private _deferedGrps = _ctx get "deferedGrps";
private _deferedTrgs = _ctx get "deferedTrgs";
private _priority = _ctx get "priority";

{
	
	//Connections
	//RandomStartPos = Man and Marker
	//WaypointActivation = Waypoint and Waypoint OR Waypoint and Trigger
	//Sync
	//[ "marker", "object", "group", "waypoint", "trigger", "logic" ]
	
	_item0ID = getNumber( _x >> "item0" );
	_item1ID = getNumber( _x >> "item1" );

	//[ _id, _cfg, _dataType, _groupID, _groupCfg ]
	_item0Info = _objects select _item0ID;
	_item1Info = _objects select _item1ID;

	if ( !isNil "_item0Info" && !isNil "_item1Info" ) then {
	
		switch ( toUpper ( configName _cfg ) ) do {
			case ( "CONNECTIONS" ) : {
				_linkType = getText( _x >> "customData" >> "type" );
				switch ( _linkType ) do {
					
					case "WaypointActivation" : {
						if ( { ( _x select 2 ) isEqualTo "Trigger" }count[ _item0Info, _item1Info ] > 0 ) then {
							{
								_x params[ "_id", "_cfg", "_type" ];
								if ( _type isEqualTo "Trigger" ) exitWith {
									_itemCfgs = _itemCfgs - [ _cfg ];
									_nul = _deferedIDs pushBackUnique _id;
									_nul = _deferedItems pushBackUnique _cfg;
								};
							}forEach [ _item0Info, _item1Info ];
						}else{
							_nul = _deferedIDs pushBackUnique _item0ID;
							_nul = _deferedItems pushBackUnique ( _item0Info select 1 ); 
						};
					};
					
					case "RandomStart" : {
						{
							_x params[ "_id", "_cfg", "_type", "_groupID", "_groupCfg" ];
							if ( _type isEqualTo "Object" ) exitWith {
								if !( isNull _groupCfg ) then {
									_groupCfgs = _groupCfgs - [ _groupCfg ];
									_nul = _deferedIDs pushBackUnique _groupID;
									_nul = _deferedGrps pushBackUnique _groupCfg;
								}else{
									_itemCfgs = _itemCfgs - [ _cfg ];
									_nul = _deferedIDs pushBackUnique _id;
									_nul = _deferedItems pushBackUnique _cfg;
								};
							};
						}forEach [ _item0Info, _item1Info ];
					};
					
					case "Sync" : {
						private[ "_item" ];
						_itemPriority = [ 0, 0 ];
						{
							_x params[ "_id", "_cfg", "_type" ];
							_itemPriority set [ _forEachIndex, _priority find _type ];
						}forEach [ _item0Info, _item1Info ];
						_item = [ _item0Info, _item1Info ] select ( _itemPriority select 1 < ( _itemPriority select 0 ) );
						_item params[ "_id", "_cfg", "_type", "_groupID", "_groupCfg" ];
						if ( _groupID > -1 ) then {
							_groupCfgs = _groupCfgs - [ _groupCfg ];
							_nul = _deferedIDs pushBackUnique _groupID;
							_nul = _deferedGrps pushBackUnique _groupCfg;
						}else{
							_itemCfgs = _itemCfgs - [ _cfg ];
							_nul = _deferedIDs pushBackUnique _id;
							_nul = _deferedItems pushBackUnique _cfg;
						};
					};
					
					case "TriggerOwner" : {
						private[ "_owner" ];
						//FIXME: triggerOwner is currently broken in stable branch
						//TODO: attached trigger types activationByOwner and its variants - needs proper testing hopefully handled by connections
						{
							_x params[ "_id", "_cfg", "_type", "_groupID", "_groupCfg" ];
							if ( _type isEqualTo "Trigger" ) exitWith {
								_owner = [ _item0Info, _item1Info ] - ( [ _item0Info, _item1Info ] select _forEachIndex );
								_itemCfgs = _itemCfgs - [ _cfg ];
								_nul = _deferedIDs pushBackUnique _id;
								_nul = _deferedTrgs pushBackUnique _cfg;
							};
						}forEach [ _item0Info, _item1Info ];
					};
					
				};
			};
			
//				case ( "CREWLINKS" ) :{
//					//If a Group has crewLinks then it and its units are defered
				//so will not spawn until after vehicle is done see connections
//				};
		};
	};
	

}forEach ( "true" configClasses ( _cfg >> "Links" ));

_ctx set [ "groupCfgs", _groupCfgs ];
_ctx set [ "itemCfgs", _itemCfgs ];
_ctx set [ "deferedIDs", _deferedIDs ];
_ctx set [ "deferedItems", _deferedItems ];
_ctx set [ "deferedGrps", _deferedGrps ];
_ctx set [ "deferedTrgs", _deferedTrgs ];
