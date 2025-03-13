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
	["costSoFar",nil], //part of working graph
	["currentNode",nil],
	["frontier",nil], //part of working graph
	["lastNode",nil],
	["getPath",compileFinal {
		private _status = "FAILURE";
		private _start = _self get "StartNode";
		private _end = _self get "EndNode";
		private _current = _end;
		private _path = [];
		private _cameFrom = _self get "cameFrom";

		if (isNil {_cameFrom get (_current get "Index")}) then {_current = _self get "lastNode";};

		while {!(isNil "_current") && !(_current isEqualTo _start)} do {
			_path pushBack _current;
			_current = _cameFrom get (_current get "Index");
		};

		if (_current isEqualTo _start) then {_status = "SUCCESS";};
		if (_self get "_reverse") then {reverse _path};
		_self set ["Path",_path];
		_self set ["Status",_status];

	}],
	["frontierAdd",compileFinal {
		params [["_priority",nil,[0]],"_item"];

		private _frontier = _self get "frontier";
		private _frontierSize = count _frontier;
		private _i = 0;

		while {_i <= _frontierSize - 1 && { _priority > ((_frontier select _i) select 0) }} do {
			_i = _i + 1;
		};

		_frontier insert [_i, [[_priority, _item]] ];
	}],
	["frontierPullLowest",compileFinal {
		private _frontier = _self get "frontier";
		if (count _frontier > 0) exitWith {
			(_frontier deleteat 0) # 1;
		};
		nil;
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
	["Init",compileFinal {
		private _graph = _self get "_workingGraph";
		_self set ["StartNode",_graph call ["GetNodeAt",[_self get "_workingStartKey"]]];
		_self set ["EndNode",_graph call ["GetNodeAt",[_self get "_workingEndKey"]]];
		_self set ["frontier",[[0,_self get "StartNode"]]];
		_self set ["costSoFar",createhashmap];
		_self get "costSoFar" set [_self get "StartNode" get "Index",0];
		_self set ["cameFrom",createhashmap];
		_self set ["Path",[]];
		_self set ["Status","INITIALIZED"];
	}],
	["ProcessNextNode",compileFinal {
		//Bail if already finished
		if (_self get "Status" in ["SUCCESS","FAILURE"]) exitWith {true;};
		
		// Set status Running if not already
		if !(_self get "Status" == "RUNNING") then {_self set ["Status","RUNNING"]};

		private _graph = _self get "_workingGraph";
		private _endNode = _self get "EndNode";
		private _currentNode = _self call ["frontierPullLowest"];
		_self set ["currentNode",_currentNode];
		
		// Check if path is found or failed to be found
		if (isNil "_currentNode" || (_endNode get "Index") isEqualTo (_currentNode get "Index")) exitWith {
			_self call ["getPath"];
		};
		private _prevNode = _self get "cameFrom" get (_currentNode get "Index");

		private _neighbors = _graph call ["GetNeighbors",[_currentNode,_prevNode]];
		_self call ["FilterNeighbors",[_neighbors]];

		{
			private _costSoFarMap = _self get "costSoFar";
			private _estimate = _self call ["AdjustEstimate",[_graph call ["GetEstimate",[_x,_endNode]],_x,_endNode]];
			private _cost = _self call ["AdjustCost",[_graph call ["GetCost",[_currentNode,_x]],_currentNode,_x]];
			private _costSofar = (_costSoFarMap get (_currentNode get "Index")) + _cost;
			private _priority = _costSoFar + _estimate;
			
			private _costSoFarX = _costSoFarMap get (_x get "Index");

			if (isNil {_costSoFarX} || {_costSoFar < _costSoFarX}) then {
				_costSoFarMap set [_x get "Index", _costSoFar];
				_self call ["frontierAdd",[_priority,_x]];
				_self get "cameFrom" set [_x get "Index", _currentNode];
			};

		} forEach _neighbors;

		_self set ["lastNode",_currentNode];

		false;
	}],
	["SmoothPath",compileFinal {_self get "Path";}]
]