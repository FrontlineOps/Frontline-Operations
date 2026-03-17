
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
	["_getConnectedToPath",compileFinal {
		if !(params [["_fromPoint",nil,[[]],[3]],["_direction",nil,[0]],["_toObject",nil,[createhashmap]],["_toWidth",nil,[0]],["_nextObject",nil,[createhashmap]],["_nextWidth",nil,[0]],["_dirOffset",nil,[0]]]) exitWith {diag_log ["_getConnectedToPath:",_fromPoint,_toObject,_toWidth,_nextObject,_dirOffset]};
		if (_fromPoint isEqualTo [0,0,0]) then {diag_log ["_getConnectedToPath:",_fromPoint,_toObject,_toWidth,_nextObject,_dirOffset]};

		private _posA = _toObject get "PosASL";
		private _bPosA = _toObject get "BeginPos";
		private _ePosA = _toObject get "EndPos";

		private _posB = _nextObject get "PosASL";
		private _bPosB = _nextObject get "BeginPos";
		private _ePosB = _nextObject get "EndPos";

		private _int = [_bPosA,_ePosA,_bPosB,_ePosB] call XPS_fnc_lineIntersect2d;
		private _dirA = 0;
		private _dirB = 0;

		if (isNil "_int" || count _int isEqualTo 0) then {
			_dirA = _posA getdir _posB;
			_dirB = _posA getdir _posB;
		} else {
			_dirA = _posA getdir _int;
			_dirB = _int getdir _posB;
		}; 

		private _headA = _bposA getdir _eposA;
		private _headB = _bposB getdir _eposB;
		private _posS = _posA;
		private _posE = _eposB ;

		if (abs (_headA - _dirA) > 90) then {_headA = _eposA getdir _bposA;}; 
		if (abs (_headB - _dirB) > 90) then {_headB = _eposB getdir _bposB;_posE = _bPosB;}; 

		private _posS = _posS getpos [_toWidth,_headA + _dirOffset]; _posS set [2,_posA#2];
		private _posE = _posE getpos [_nextWidth,_headB + _dirOffset]; _posE set [2,_posB#2];

		private _points = [];
		if ((_posS distance2d _posE)*1.15 < (_fromPoint distance2d _posE)) then {_points pushBack _posS;_fromPoint = _posS;};
		private _p1 = _frompoint;
		private _p2 = _frompoint getpos [5,_direction];
		private _p3 = _bPosB getpos [_nextWidth,_headB + _dirOffset];
		private _p4 = _ePosB getpos [_nextWidth,_headB + _dirOffset];
		
		// _m = createmarker ["db"+ str _fromPoint,_fromPoint]; 
		// _m setmarkertype "mil_circle"; 
		// _m setmarkercolor "ColorOrange"; 
		// _m setmarkersize [0.25,0.25]; 
		// _m = createmarker ["db"+ str str _posE,_posE]; 
		// _m setmarkertype "mil_circle"; 
		// _m setmarkercolor "ColorBlack"; 
		// _m setmarkersize [0.25,0.25]; 


		private _intersect = [_p1,_p2,_p3,_p4] call XPS_fnc_lineIntersect2D;
		private _intPoints = [];
		if !(isNil "_intersect" || count _intersect isEqualTo 0) then {
			if ((_intersect distance2d _posE < _fromPoint distance2d _posE) && (_intersect distance2d _fromPoint < _fromPoint distance2d _posE)) then {
				private _iB = _intersect getpos [(_intersect distance _frompoint)/2,_intersect getdir _frompoint]; 
				private _iE = _intersect getpos [(_intersect distance _posE)/2,_intersect getdir _posE]; 
				_intPoints pushBack _iB;
				_intPoints pushBack _intersect;
				_intPoints pushBack _iE;
				for "_p" from 0.1 to 0.5 step 0.1 do {
					private _nPos = _p bezierInterpolation _intPoints;
					//if !(roadAt _nPos isEqualTo (_toObject get "RoadObject")) then {
						_points pushBack _nPos;
					//};
				};
				// _m = createmarker ["db"+ str _intersect,_intersect]; 
				// _m setmarkertype "mil_circle"; 
				// _m setmarkercolor "ColorYellow"; 
				// _m setmarkersize [0.25,0.25]; 
			};
		};
		_points;
	}],
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
	["GetCost",compileFinal {
		params [["_current",nil,[createhashmap]],["_next",nil,[createhashmap]]];
		
		(_current get "PosASL") distance (_next get "PosASL");
	}],
	["GetNodeAt",compileFinal {
		if !(params [["_pos",nil,[[]],[2,3]]]) exitWith {nil};
		private _node = nil;
		// search for roads in increasingly large distances
		{
			private _roads = nearestTerrainObjects [_pos,["MAIN ROAD","ROAD","TRACK","TRAIL"],_x,true];
			if (count _roads > 0) exitWith {
				_node = _self get "Roads" get (str (_roads#0));
			};
		} foreach [50, 100, 500, 1000];
		if (isNil "_node") exitwith {
			diag_log format["[FLO][Pathfinding] RoadGraphSearch: failed to find suitable road within 1km of position %1",_pos];
			false;
		};
		_node;
	}],
	["SmoothPath", compileFinal {
		params [["_path",[],[[]]]];

		if (count _path > 3) then {
			private _i = 1;
			while {_i < (count _path)-1} do {

				private _first = _path#(_i-1);
				private _second = _path#(_i);
				private _third = _path#(_i+1);

				private _posA = _first get "PosASL";
				private _posB = _second get "PosASL";
				private _posC = _third get "PosASL";
				private _checkPositions = [_third get "BeginPos",_third get "EndPos"];
				
				// Check if C is actually closer than B and delete if so
				if ((_posA distance2D (_checkPositions#0)) < (_posA distance2D _posB) || (_posA distance2D (_checkPositions#1)) < (_posA distance2D _posB)) then {
					_path deleteAt _i;
				} else {
					_i = _i + 1;
				};
			};		
		};
	}]
];

XPS_PF_typ_RoadDoctrine = [
	["#str", compileFinal {"XPS_PF_typ_RoadGraphDoctrine"}],
	["#type","XPS_PF_typ_RoadGraphDoctrine"],
	["#create",compileFinal {
		params [["_heuristics",[0.9, 1, 1.2],[[]],[3]],["_roadTypes",["MAIN ROAD","ROAD","TRACK"],[[]],[1,2,3,4]]];
		_self set ["Weights",_heuristics];
		_self set ["RoadTypes",_roadTypes];
	}],
	["Weights",[0.9, 1, 1.2]],
	["RoadTypes",["MAIN ROAD","ROAD","TRACK"]]
];

XPS_PF_typ_RoadGraphSearch = [
	["#str", compileFinal {"XPS_PF_typ_RoadGraphSearch"}],
	["#type","XPS_PF_typ_RoadGraphSearch"],
	["#base",XPS_typ_AstarSearch],
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
	["Doctrine",nil],
	["SmoothPath", compileFinal {
		private _path = [];
		private _posA = [-1000,-1000,0];
		{
			private _pos = _x get "PosASL";
			if ((_x get "Intersection" && {_posA distance2D _pos > 1000}) || {_posA distance2D _pos > 1000}) then {
				// Convert to ATL (ground level)
				_path pushBack [_pos select 0, _pos select 1, 0];
				_posA = _pos;
			};
		} foreach (_self get "Path");
		// Also normalize the end position
		private _endPos = _self get "_workingEndKey";
		_path pushBack [_endPos select 0, _endPos select 1, 0];
		_path;
	}]
];

if (isNil "FLO_PF_RoadGraph") then {
	diag_Log "[FLO][Pathfinding]Building Road Graph";
	FLO_PF_RoadGraph = createhashmapobject [XPS_PF_typ_RoadGraph];
	diag_Log "[FLO][Pathfinding]Finished building Road Graph";
};

// Vehicle doctrine (no trails, main road always better - descending preference)
FLO_PF_RoadDoctrine_V = createhashmapobject [XPS_PF_typ_RoadDoctrine,[[0.9, 1, 1.2],["MAIN ROAD","ROAD","TRACK"]]];

// Man doctrine (with trails, all roads equal)
FLO_PF_RoadDoctrine_M = createhashmapobject [XPS_PF_typ_RoadDoctrine,[[1, 1, 1],["MAIN ROAD","ROAD","TRACK","TRAIL"]]];

// To initiate a search :
// _search = createhashmapobject [XPS_PF_typ_RoadGraphSearch,[FLO_Pathfinding_RoadGraph, <start road object> , <end road object>, <reverse path?: true/false>]];
