
XPS_PF_typ_RoadNode = [
	["#str", compileFinal {"XPS_PF_typ_RoadNode"}],
	["#type","XPS_PF_typ_RoadNode"],
	["BeginPos",[]],
	["ConnectedTo",createhashmap],
	["EndPos",[]],
	["IsBridge",false],
	["PosASL",[]],
	["Index",nil],
	["RoadObject",nil],
	["Type",""],
	["Width",0],
	["Intersection",false],
	["#create",compileFinal {
		params [["_index",nil,[""]],["_object",objNull,[objNull]]];
		_self set ["Index",_index];
		_self set ["RoadObject",_object];
		_self set ["ConnectedTo",createhashmap];
		//_self set ["ConnectedToPath",createHashMapFromArray [["RHDrive",createhashmap],["RHWalk",createhashmap],["LHDrive",createhashmap],["LHWalk",createhashmap]]];
		private _roadInfo = getRoadInfo _object;
		_self set ["Type",_roadInfo#0]; 
		_self set ["Width",_roadInfo#1]; 
		_self set ["BeginPos",_roadInfo#6]; 
		_self set ["EndPos",_roadInfo#7]; 
		_self set ["IsBridge",_roadInfo#8]; 
		private _aslPos = getposASL _object;
		_aslPos set [2,((_roadInfo#7#2) + (_roadInfo#6#2))/2];
		_self set ["PosASL",_aslPos]; 
	}]
];

XPS_PF_typ_RoadGraph = [
	["#str", compileFinal {"XPS_PF_typ_RoadGraph"}],
	["#type","XPS_PF_typ_RoadGraph"],
	["addRoadToGraph",compileFinal {
		params [["_object",objNull,[objNull]],["_typeDef",XPS_PF_typ_RoadNode,[[]]]];
		if !(_object isEqualto objNull) then {
			private _hmo = createHashmapObject [_typeDef,[str _object,_object]];
			_self get "Roads" set [str _object,_hmo];
		};
	}],
	["getAllConnected",compileFinal {
		params [["_node",nil,[createhashmap]]];
		private _object = _node get "RoadObject";
		private _ct = _node get "ConnectedTo";
		private _roadArray = [];
		{
			if !(_x isEqualto objNull || (str _x) isEqualTo (str _object) || (str _x) in _ct) then {
				_roadArray pushBackunique _x;
			};
		} forEach roadsconnectedto _object;

		private _pos = _node get "PosASL";
		private _bPos = _node get "BeginPos";
		private _ePos = _node get "EndPos";
		private _width = (_node get "Width")/2;
		if (_width isEqualTo 0) then {_width = 5.5};
		private _bPosC = _pos getpos [(_pos distance _bPos)+0.02,(_pos getDir _bPos)];
		private _bPosL = _bPosC getpos [_width,(_pos getDir _bPosC)-90];
		private _bPosR = _bPosC getpos [_width,(_pos getDir _bPosC)+90];
		private _ePosC = _pos getpos [(_pos distance _ePos)+0.02,(_pos getDir _ePos)];
		private _ePosL = _ePosC getpos [_width,(_pos getDir _ePosC)-90];
		private _ePosR = _ePosC getpos [_width,(_pos getDir _ePosC)+90];
		{
			_x resize 2;
			private _r = roadAt _x;
			if !(_r isEqualto objNull || (str _r) isEqualTo (str _object) || (str _r) in _ct || abs((getposASL _r)#2)-(_pos#2)>2) then {
				_roadArray pushBackunique _r;
			};
		} forEach [_bposC,_bPosL,_bPosR,_eposC,_ePosL,_ePosR];

		// _m = createmarker [str _bPosC,_bPosC]; 
		// _m setmarkershape "rectangle"; 
		// _m setmarkercolor "ColorBlue"; 
		// _m setmarkersize [_width,0.1]; 
		// _m setmarkerdir (_pos getdir _bPosC); 
		// _m = createmarker [str _ePosC,_ePosC]; 
		// _m setmarkershape "rectangle"; 
		// _m setmarkercolor "ColorBlack"; 
		// _m setmarkersize [_width,0.1]; 
		// _m setmarkerdir (_pos getdir _ePosC);  

		{
			_ct set [str _x, _x];
			private _rct = _self get "Roads" get (str _x);
			// Only update connected road if it exists in our graph
			if (!isNil "_rct") then {
				_rct get "ConnectedTo" set [str _object, _object];
			};
		} forEach _roadArray;
		_node set ["Intersection", count (_node get "ConnectedTo") > 2];
	}],
	["buildGraph",compileFinal {
		private _roads = nearestterrainobjects [[worldsize/2,worldsize/2],["MAIN ROAD","ROAD","TRACK","TRAIL"],worldSize,false,false];
		_self set ["Roads",createhashmap];
		{_self call ["addRoadToGraph",[_x]];} forEach _roads;
		{_self call ["getAllConnected",[_x]];} forEach values (_self get "Roads");
		
	}],
	["#create",compileFinal {
		_self set ["_graphMarkersEnabled",false];
		_self set ["_graphMarkers",[]];
		_self set ["_nodeLookupCache", createHashMap];
		_self set ["_searchEdgeCache", createHashMap];
		_self set ["_componentCacheByMode", createHashMap];
		_self set ["_componentCountByMode", createHashMap];
		_self call ["buildGraph"];
	}],
	["Roads",createhashmap],
	["GetEstimate",compileFinal {
		params ["_current","_end"];
		(_current get "RoadObject") distance2D (_end get "RoadObject");
	}],
	["GetNeighbors",compileFinal {
		if !(params [["_current",nil,[createhashmap]],"_prev"]) exitWith {nil};
		
		private _result = [];
		private _neighbors = [];
		private _road = _current get "RoadObject";
		_neighbors append (values (_current get "ConnectedTo"));
		private _prevRoadObject = if (isNil "_prev") then {objNull} else {_prev get "RoadObject"};
		
		{
			if !(_x isEqualTo _prevRoadObject || _x isEqualTo (_current get "RoadObject")) then {
				_result pushBack (_self get "Roads" get str _x);
			};
		} forEach _neighbors;
		_result;
	}],
	["BuildSearchEdge",compileFinal {
		params [["_current",nil,[createhashmap]],["_next",nil,[createhashmap]],["_allowedTypes",[],[[]]]];

		if (isNil "_next") exitWith { nil };
		if !((_next get "Type") in _allowedTypes) exitWith { nil };

		private _pathNodes = [];
		private _edgeCost = 0;
		private _prevNode = _current;
		private _cursor = _next;
		private _visited = createHashMap;
		_visited set [_current get "Index", true];

		while {true} do {
			private _cursorIndex = _cursor get "Index";
			if (_visited getOrDefault [_cursorIndex, false]) exitWith {};
			_visited set [_cursorIndex, true];

			_pathNodes pushBack _cursor;
			_edgeCost = _edgeCost + ((_prevNode get "PosASL") distance (_cursor get "PosASL"));

			private _connected = values (_cursor get "ConnectedTo");
			if ((count _connected) != 2) exitWith {};
			if (_cursor get "Intersection") exitWith {};

			private _prevRoad = _prevNode get "RoadObject";
			private _forwardRoad = objNull;
			{
				if !(_x isEqualTo _prevRoad) exitWith {
					_forwardRoad = _x;
				};
			} forEach _connected;

			if (_forwardRoad isEqualTo objNull) exitWith {};

			private _forwardNode = (_self get "Roads") get (str _forwardRoad);
			if (isNil "_forwardNode") exitWith {};
			if !((_forwardNode get "Type") in _allowedTypes) exitWith {};

			_prevNode = _cursor;
			_cursor = _forwardNode;
		};

		[_cursor, _edgeCost, _pathNodes];
	}],
	["GetSearchEdges",compileFinal {
		params [["_current",nil,[createhashmap]],["_allowedTypes",[],[[]]]];

		private _cache = _self get "_searchEdgeCache";
		private _modeKey = _allowedTypes joinString "|";
		private _cacheKey = format ["%1|%2", _current get "Index", _modeKey];
		if (_cacheKey in _cache) exitWith {
			_cache get _cacheKey;
		};

		private _edges = [];
		{
			private _nextNode = (_self get "Roads") get (str _x);
			if (isNil "_nextNode") then { continue };
			private _edge = _self call ["BuildSearchEdge", [_current, _nextNode, _allowedTypes]];
			if (isNil "_edge") then { continue };
			_edges pushBack _edge;
		} forEach (values (_current get "ConnectedTo"));

		_cache set [_cacheKey, _edges];
		_edges;
	}],
	["BuildComponentCache",compileFinal {
		params [["_allowedTypes",["MAIN ROAD","ROAD","TRACK","TRAIL"],[[]]]];

		private _modeKey = _allowedTypes joinString "|";
		private _componentCacheByMode = _self get "_componentCacheByMode";
		if (_modeKey in _componentCacheByMode) exitWith {
			_componentCacheByMode get _modeKey;
		};

		private _componentMap = createHashMap;
		private _componentCount = 0;
		private _roads = _self get "Roads";

		{
			private _node = _x;
			if !((_node get "Type") in _allowedTypes) then { continue };

			private _nodeIndex = _node get "Index";
			if (_nodeIndex in _componentMap) then { continue };

			private _queue = [_node];
			_componentMap set [_nodeIndex, _componentCount];

			while {count _queue > 0} do {
				private _current = _queue deleteAt ((count _queue) - 1);
				{
					private _neighborNode = _roads get (str _x);
					if (isNil "_neighborNode") then { continue };
					if !((_neighborNode get "Type") in _allowedTypes) then { continue };

					private _neighborIndex = _neighborNode get "Index";
					if (_neighborIndex in _componentMap) then { continue };

					_componentMap set [_neighborIndex, _componentCount];
					_queue pushBack _neighborNode;
				} forEach (values (_current get "ConnectedTo"));
			};

			_componentCount = _componentCount + 1;
		} forEach (values _roads);

		_componentCacheByMode set [_modeKey, _componentMap];
		(_self get "_componentCountByMode") set [_modeKey, _componentCount];
		_componentMap;
	}],
	["GetNodeComponentId",compileFinal {
		params [["_node",nil,[createhashmap]],["_allowedTypes",["MAIN ROAD","ROAD","TRACK","TRAIL"],[[]]]];
		if (isNil "_node") exitWith { -1 };

		private _componentMap = _self call ["BuildComponentCache", [_allowedTypes]];
		_componentMap getOrDefault [_node get "Index", -1];
	}],
	["GetCost",compileFinal {
		params [["_current",nil,[createhashmap]],["_next",nil,[createhashmap]]];
		
		(_current get "PosASL") distance (_next get "PosASL");
	}],
	["GetNodeAt",compileFinal {
		if !(params [["_pos",nil,[[]],[2,3]],["_allowedTypes",["MAIN ROAD","ROAD","TRACK","TRAIL"],[[]]]]) exitWith {nil};
		private _cache = _self get "_nodeLookupCache";
		private _typeKey = _allowedTypes joinString "|";
		private _cacheKey = format ["%1_%2|%3", floor ((_pos select 0) / 50), floor ((_pos select 1) / 50), _typeKey];
		if (_cacheKey in _cache) exitWith {
			_cache get _cacheKey;
		};

		private _node = nil;

		private _road = roadAt _pos;
		if (!isNull _road) then {
			private _directNode = (_self get "Roads") get (str _road);
			if (!isNil "_directNode" && {(_directNode get "Type") in _allowedTypes}) then {
				_node = _directNode;
			};
		};

		if (isNil "_node") then {
			{
				private _roads = _pos nearRoads _x;
				private _roadIndex = _roads findIf {
					private _roadNode = (_self get "Roads") get (str _x);
					!isNil "_roadNode" && {(_roadNode get "Type") in _allowedTypes}
				};
				if (_roadIndex >= 0) exitWith {
					_node = (_self get "Roads") get (str (_roads select _roadIndex));
				};
			} forEach [30, 100, 250, 500, 900, 1500, 3000];
		};

		if (isNil "_node") then {
			{
				private _roads = nearestTerrainObjects [_pos,_allowedTypes,_x,false];
				if (count _roads > 0) exitWith {
					_node = (_self get "Roads") get (str (_roads select 0));
				};
			} forEach [100, 300, 700, 1500, 3000, 6000];
		};

		if (isNil "_node") exitwith {
			private _roads = nearestTerrainObjects [_pos, _allowedTypes, worldSize, false];
			private _road = _roads select 0;
			_node = (_self get "Roads") get (str _road);
			_cache set [_cacheKey, _node];
			_node;
		};
		_cache set [_cacheKey, _node];
		_node;
	}]
];

XPS_PF_typ_RoadDoctrine = [
	["#str", compileFinal {"XPS_PF_typ_RoadGraphDoctrine"}],
	["#type","XPS_PF_typ_RoadGraphDoctrine"],
	["#create",compileFinal {
		params [
			["_heuristics",[0.9, 1, 1.2],[[]],[3]],
			["_roadTypes",["MAIN ROAD","ROAD","TRACK"],[[]],[1,2,3,4]],
			["_spacingCap",350,[0]],
			["_turnThreshold",50,[0]],
			["_estimateBias",1,[0]],
			["_minEmitDistance",75,[0]],
			["_junctionTurnThreshold",-1,[0]]
		];
		_self set ["Weights",_heuristics];
		_self set ["RoadTypes",_roadTypes];
		_self set ["SpacingCap", _spacingCap];
		_self set ["TurnThreshold", _turnThreshold];
		_self set ["EstimateBias", _estimateBias];
		_self set ["MinEmitDistance", _minEmitDistance];
		if (_junctionTurnThreshold < 0) then {
			_junctionTurnThreshold = _turnThreshold;
		};
		_self set ["JunctionTurnThreshold", _junctionTurnThreshold];
	}],
	["Weights",[0.9, 1, 1.2]],
	["RoadTypes",["MAIN ROAD","ROAD","TRACK"]],
	["SpacingCap",350],
	["TurnThreshold",50],
	["EstimateBias",1],
	["MinEmitDistance",75],
	["JunctionTurnThreshold",50]
];

XPS_PF_typ_RoadGraphSearch = [
	["#str", compileFinal {"XPS_PF_typ_RoadGraphSearch"}],
	["#type","XPS_PF_typ_RoadGraphSearch"],
	["#base",XPS_typ_AstarSearch],
	["#create",compileFinal {
		params [
			["_graph",nil,[createhashmap]],
			["_startKey",nil,[]],
			["_endKey",nil,[]],
			["_reversePath",true,[true]],
			["_doctrine",nil,[createhashmap]]
		];
		_self set ["_workingGraph",_graph];
		_self set ["_workingStartKey",_startKey];
		_self set ["_workingEndKey",_endKey];
		_self set ["_reverse",_reversePath];
		if (isNil "_doctrine") then {
			_doctrine = FLO_PF_RoadDoctrine_V;
		};
		_self set ["Doctrine",_doctrine];
		_self set ["Path",[]];
		_self set ["CallbackArgs",[]];
		_self call ["Init"];
	}],
	["UseDecoratedNeighborsOnly",true],
	["AdjustEstimate",compileFinal {
		params ["_estimate","_fromNode","_toNode"];
		_estimate * ((_self get "Doctrine") get "EstimateBias");
	}],
	["AdjustCost",compileFinal {
		params ["_cost","_fromNode","_toNode"];

		private _weights = _self get "Doctrine" get "Weights";
		private _roadType = _toNode get "Type";
		private _modifier = _weights#2;
		switch (_roadType) do {
			case "MAIN ROAD" : {_modifier = _weights#0};
			case "ROAD" : {_modifier = _weights#1};
		};
		_cost * _modifier;
	}],
	["FilterNeighbors",compileFinal {
		params ["_neighbors"];
		private _types = _self get "Doctrine" get "RoadTypes";
		private _i = 0;
		while {_i < (count _neighbors)} do {
			if !(((_neighbors#_i) get "Type") in _types) then {
				_neighbors deleteat _i;
			} else {_i = _i + 1;};
		};
	}],
	["DecorateNeighbors",compileFinal {
		params ["_currentNode","_prevNode","_neighbors"];

		private _graph = _self get "_workingGraph";
		private _allowedTypes = _self get "Doctrine" get "RoadTypes";
		private _endNode = _self get "EndNode";
		private _endIndex = _endNode get "Index";
		private _prevIndex = if (isNil "_prevNode") then { "" } else { _prevNode get "Index" };
		private _edges = _graph call ["GetSearchEdges", [_currentNode, _allowedTypes]];
		private _decorated = [];

		{
			_x params ["_nextNode", "_edgeCost", "_edgePath"];
			private _resolvedNode = _nextNode;
			private _resolvedCost = _edgeCost;
			private _resolvedPath = _edgePath;

			if !((_resolvedNode get "Index") isEqualTo _endIndex) then {
				private _endPathIndex = _edgePath findIf { (_x get "Index") isEqualTo _endIndex };
				if (_endPathIndex >= 0) then {
					_resolvedPath = _edgePath select [0, _endPathIndex + 1];
					_resolvedNode = _resolvedPath select _endPathIndex;
					_resolvedCost = 0;
					private _prevHop = _currentNode;
					{
						_resolvedCost = _resolvedCost + ((_prevHop get "PosASL") distance (_x get "PosASL"));
						_prevHop = _x;
					} forEach _resolvedPath;
				};
			};

			if (_prevIndex != "" && {(_resolvedNode get "Index") isEqualTo _prevIndex}) then { continue };
			_decorated pushBack [_resolvedNode, _resolvedCost, _resolvedPath];
		} forEach _edges;

		_decorated;
	}],
	["Doctrine",nil],
	["SmoothPath", compileFinal {
		private _resolvedNodes = _self get "Path";
		private _doctrine = _self get "Doctrine";
		private _spacingCap = _doctrine get "SpacingCap";
		private _turnThreshold = _doctrine get "TurnThreshold";
		private _minEmitDistance = _doctrine get "MinEmitDistance";
		private _junctionTurnThreshold = _doctrine get "JunctionTurnThreshold";
		private _route = [];
		private _endPos = +(_self get "_workingEndKey");

		if (count _endPos > 2) then {
			_endPos set [2, 0];
		} else {
			_endPos pushBack 0;
		};

		if (count _resolvedNodes isEqualTo 0) exitWith { [_endPos] };

		private _lastEmitted = [];
		{
			private _node = _x;
			private _pos = +(_node get "PosASL");
			_pos set [2, 0];

			private _shouldEmit = false;
			if (count _route isEqualTo 0) then {
				_shouldEmit = true;
			} else {
				if ((_lastEmitted distance2D _pos) >= _spacingCap) then {
					_shouldEmit = true;
				};
				if (!_shouldEmit && { _forEachIndex > 0 }) then {
					private _prevPos = +((_resolvedNodes select (_forEachIndex - 1)) get "PosASL");
					_prevPos set [2, 0];
					private _turnRefPos = if (count _route > 0) then {
						+_lastEmitted
					} else {
						+_prevPos
					};

					private _nextPos = if ((_forEachIndex + 1) < (count _resolvedNodes)) then {
						+((_resolvedNodes select (_forEachIndex + 1)) get "PosASL")
					} else {
						+_endPos
					};
					_nextPos set [2, 0];

					private _dirIn = _turnRefPos getDir _pos;
					private _dirOut = _pos getDir _nextPos;
					private _turnDelta = abs (((_dirOut - _dirIn + 540) mod 360) - 180);
					private _turnSampleDist = _turnRefPos distance2D _pos;
					if (_turnDelta >= _turnThreshold && {_turnSampleDist >= (_minEmitDistance * 0.8)}) then {
						_shouldEmit = true;
					} else {
						if ((_node get "Intersection") && {_turnDelta >= _junctionTurnThreshold} && {(_lastEmitted distance2D _pos) >= (_spacingCap * 0.85)}) then {
							_shouldEmit = true;
						};
					};
				};
			};

			if (_shouldEmit && { (count _route isEqualTo 0) || { _lastEmitted distance2D _pos >= _minEmitDistance } }) then {
				_route pushBack _pos;
				_lastEmitted = _pos;
			};
		} forEach _resolvedNodes;

		if (count _route isEqualTo 0) exitWith { [_endPos] };

		private _lastIndex = (count _route) - 1;
		if ((_route select _lastIndex) distance2D _endPos < _minEmitDistance) then {
			_route set [_lastIndex, _endPos];
		} else {
			_route pushBack _endPos;
		};

		_route;
	}]
];

if (isNil "FLO_PF_RoadGraph") then {
	private _t0 = diag_tickTime;
	FLO_PF_RoadGraph = createhashmapobject [XPS_PF_typ_RoadGraph];
	private _buildMs = (diag_tickTime - _t0) * 1000;
	private _roadCount = count (keys (FLO_PF_RoadGraph get "Roads"));
	FLO_PF_Perf set ["graphBuildMs", _buildMs];
	FLO_PF_Perf set ["roadCount", _roadCount];
	diag_log format [
		"[FLO][PERF] Pathfinding road graph built %1 road nodes in %2 ms",
		_roadCount,
		_buildMs
	];
};

// Vehicle doctrine (no trails, main road always better - descending preference)
FLO_PF_RoadDoctrine_V = createhashmapobject [XPS_PF_typ_RoadDoctrine,[[0.85, 1, 1.3],["MAIN ROAD","ROAD","TRACK"],550,70,1.3,140,80]];

// Logistics reinforcement doctrine favors throughput and coarse route output over lane-precise steering.
FLO_PF_RoadDoctrine_V_Logi = createhashmapobject [XPS_PF_typ_RoadDoctrine,[[0.8, 1, 1.35],["MAIN ROAD","ROAD"],700,85,1.4,220,95]];

// Man doctrine (with trails, all roads equal)
FLO_PF_RoadDoctrine_M = createhashmapobject [XPS_PF_typ_RoadDoctrine,[[1, 1, 1],["MAIN ROAD","ROAD","TRACK","TRAIL"],260,40,1.15,110,50]];

// To initiate a search :
// _search = createhashmapobject [XPS_PF_typ_RoadGraphSearch,[FLO_Pathfinding_RoadGraph, <start road object> , <end road object>, <reverse path?: true/false>]];
