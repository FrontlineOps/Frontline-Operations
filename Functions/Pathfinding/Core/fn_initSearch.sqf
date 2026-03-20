XPS_typ_AstarSearch = [
	["#type","XPS_typ_AstarSearch"],
	["#create",compileFinal {
		params [["_graph",nil,[createhashmap]],["_startKey",nil,[]],["_endKey",nil,[]],["_reversePath",true,[true]]];
		_self set ["_workingGraph",_graph];
		_self set ["_workingStartKey",_startKey];
		_self set ["_workingEndKey",_endKey];
		_self set ["_reverse",_reversePath];
		_self set ["Path",[]];
		_self set ["CallbackArgs",[]];
		_self call ["Init"];
	}],
	["#str", compileFinal {_self get "#type" select  0}],
	["_workingGraph",nil],
	["_workingStartKey",nil],
	["_workingEndKey",nil],
	["_reverse",nil],
	["cameFrom",nil], //part of working graph
	["cameEdge",nil], //path segment from previous node to this node
	["closedSet",nil],
	["costSoFar",nil], //part of working graph
	["currentNode",nil],
	["frontier",nil], //part of working graph
	["frontierBest",nil],
	["lastNode",nil],
	["UseDecoratedNeighborsOnly",false],
	["getPath",compileFinal {
		private _status = "PARTIAL";
		private _start = _self get "StartNode";
		private _end = _self get "EndNode";
		private _path = [];
		private _cameFrom = _self get "cameFrom";
		private _cameEdge = _self get "cameEdge";
		private _resolvedNode = _self get "lastNode";
		private _reachedEnd = false;

		if ((_end get "Index") isEqualTo (_start get "Index")) then {
			_reachedEnd = true;
			_resolvedNode = _end;
		} else {
			if !(isNil {_cameFrom get (_end get "Index")}) then {
				_reachedEnd = true;
				_resolvedNode = _end;
			};
		};

		private _current = _resolvedNode;

		while {!(isNil "_current") && !(_current isEqualTo _start)} do {
			private _edgeSegment = _cameEdge get (_current get "Index");
			if (isNil "_edgeSegment") then {
				_path pushBack _current;
			} else {
				private _segment = +_edgeSegment;
				reverse _segment;
				{
					_path pushBack _x;
				} forEach _segment;
			};
			_current = _cameFrom get (_current get "Index");
		};

		if (_reachedEnd && {_current isEqualTo _start}) then {_status = "SUCCESS";};
		if (_self get "_reverse") then {reverse _path};
		_self set ["Path",_path];
		_self set ["Status",_status];

	}],
	["frontierAdd",compileFinal {
		params [["_priority",nil,[0]],"_item"];

		private _frontierBest = _self get "frontierBest";
		private _itemIndex = _item get "Index";
		private _knownBest = _frontierBest get _itemIndex;
		if !(isNil "_knownBest") then {
			if (_priority >= _knownBest) exitWith { false };
		};
		_frontierBest set [_itemIndex, _priority];

		private _heap = _self get "frontier";
		_heap pushBack [_priority, _item];
		private _idx = (count _heap) - 1;
		while {_idx > 0} do {
			private _parent = floor ((_idx - 1) / 2);
			private _parentPri = (_heap select _parent) select 0;
			if (_parentPri <= _priority) exitWith {};
			_heap set [_idx, _heap select _parent];
			_idx = _parent;
		};
		_heap set [_idx, [_priority, _item]];
		true;
	}],
	["frontierPullLowest",compileFinal {
		private _heap = _self get "frontier";
		private _count = count _heap;
		if (_count isEqualTo 0) exitWith { nil };

		private _root = _heap select 0;
		if (_count isEqualTo 1) exitWith {
			_heap resize 0;
			_root;
		};

		private _last = _heap deleteAt (_count - 1);
		private _lastPri = _last select 0;
		private _idx = 0;
		private _newCount = count _heap;

		while {true} do {
			private _left = (_idx * 2) + 1;
			if (_left >= _newCount) exitWith {};
			private _right = _left + 1;
			private _child = _left;
			if (_right < _newCount && {((_heap select _right) select 0) < ((_heap select _left) select 0)}) then {
				_child = _right;
			};
			if (((_heap select _child) select 0) >= _lastPri) exitWith {};
			_heap set [_idx, _heap select _child];
			_idx = _child;
		};

		_heap set [_idx, _last];
		_root;
	}],
	["Path",[]],
	["Status",nil],
	["CallbackArgs",[]],
	["Callback",{}],
	["AdjustEstimate",compileFinal {
		params ["_estimate","_fromNode","_toNode"];
		_estimate;
	}],
	["AdjustCost",compileFinal {
		params ["_cost","_fromNode","_toNode"];
		_cost;
	}],
	["FilterNeighbors",compileFinal {
		params ["_neighbors"];
		_neighbors;
	}],
	["DecorateNeighbors",compileFinal {
		params ["_currentNode","_prevNode","_neighbors"];
		_neighbors;
	}],
	["Init",compileFinal {
		private _graph = _self get "_workingGraph";
		private _startNode = _graph call ["GetNodeAt",[_self get "_workingStartKey"]];
		_self set ["StartNode",_startNode];
		_self set ["EndNode",_graph call ["GetNodeAt",[_self get "_workingEndKey"]]];
		_self set ["frontier",[[0,_startNode]]];
		_self set ["frontierBest",createhashmap];
		(_self get "frontierBest") set [_startNode get "Index", 0];
		_self set ["costSoFar",createhashmap];
		_self get "costSoFar" set [_startNode get "Index",0];
		_self set ["cameFrom",createhashmap];
		_self set ["cameEdge",createhashmap];
		_self set ["closedSet",createhashmap];
		_self set ["Path",[]];
		_self set ["Status","INITIALIZED"];
	}],
	["ProcessNextNode",compileFinal {
		//Bail if already finished
		if (_self get "Status" in ["SUCCESS","PARTIAL"]) exitWith {true;};
		
		// Set status Running if not already
		if !(_self get "Status" == "RUNNING") then {_self set ["Status","RUNNING"]};

		private _graph = _self get "_workingGraph";
		private _endNode = _self get "EndNode";
		private _frontierBest = _self get "frontierBest";
		private _closedSet = _self get "closedSet";
		private _currentNode = nil;

		while {isNil "_currentNode"} do {
			private _frontierEntry = _self call ["frontierPullLowest"];
			if (isNil "_frontierEntry") exitWith {};

			_frontierEntry params ["_entryPriority", "_entryNode"];
			private _entryIndex = _entryNode get "Index";
			if !(isNil { _closedSet get _entryIndex }) then { continue };

			private _knownBest = _frontierBest get _entryIndex;
			if (!(isNil "_knownBest") && {_entryPriority > _knownBest}) then { continue };

			_currentNode = _entryNode;
		};

		_self set ["currentNode",_currentNode];
		
		// Check if path is found or failed to be found
		if (isNil "_currentNode" || (_endNode get "Index") isEqualTo (_currentNode get "Index")) exitWith {
			_self call ["getPath"];
		};

		private _currentIndex = _currentNode get "Index";
		_closedSet set [_currentIndex, true];
		private _prevNode = _self get "cameFrom" get _currentIndex;
		private _costSoFarMap = _self get "costSoFar";
		private _cameFromMap = _self get "cameFrom";
		private _cameEdgeMap = _self get "cameEdge";
		private _currentCostSoFar = _costSoFarMap get _currentIndex;

		private _neighbors = [];
		if !(_self get "UseDecoratedNeighborsOnly") then {
			_neighbors = _graph call ["GetNeighbors",[_currentNode,_prevNode]];
			_self call ["FilterNeighbors",[_neighbors]];
		};
		_neighbors = _self call ["DecorateNeighbors",[_currentNode,_prevNode,_neighbors]];

		{
			private _neighborNode = _x;
			private _edgeCost = 0;
			private _edgePath = [];
			if (_x isEqualType []) then {
				_neighborNode = _x select 0;
				if ((count _x) > 1) then {
					_edgeCost = _x select 1;
				};
				if ((count _x) > 2) then {
					_edgePath = _x select 2;
				};
			} else {
				_edgeCost = _graph call ["GetCost",[_currentNode,_neighborNode]];
				_edgePath = [_neighborNode];
			};

			if (isNil "_neighborNode") then { continue };

			private _estimate = _self call ["AdjustEstimate",[_graph call ["GetEstimate",[_neighborNode,_endNode]],_neighborNode,_endNode]];
			private _cost = _self call ["AdjustCost",[_edgeCost,_currentNode,_neighborNode]];
			private _costSofar = _currentCostSoFar + _cost;
			private _priority = _costSofar + _estimate;
			
			private _neighborIndex = _neighborNode get "Index";
			if !(isNil { _closedSet get _neighborIndex }) then { continue };
			private _costSoFarX = _costSoFarMap get _neighborIndex;

			if (isNil {_costSoFarX} || {_costSofar < _costSoFarX}) then {
				if (_self call ["frontierAdd",[_priority,_neighborNode]]) then {
					_costSoFarMap set [_neighborIndex, _costSofar];
					_cameFromMap set [_neighborIndex, _currentNode];
					_cameEdgeMap set [_neighborIndex, _edgePath];
				};
			};

		} forEach _neighbors;

		_self set ["lastNode",_currentNode];

		false;
	}],
	["SmoothPath",compileFinal {_self get "Path";}]
]
