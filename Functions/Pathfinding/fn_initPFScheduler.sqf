XPS_typ_JobScheduler = [
	["#type","XPS_typ_JobScheduler"],
	["#create", compileFinal {
		private _makeQueue = {
			createhashmapobject [[
		        ["#type", "XPS_typ_Queue"],
		        ["#str", compileFinal {_self get "#type" select  0}],
	            ["_queueArray",[]],
	            ["_head",0],
	            ["_count",0],
	            ["Clear", compileFinal {
	                (_self get "_queueArray") resize 0;
	                _self set ["_head", 0];
	                _self set ["_count", 0];
	            }],
	            ["Count", compileFinal {
	                _self get "_count";
	            }],
	            ["IsEmpty", compileFinal {
	                (_self get "_count") isEqualTo 0;
	            }],
	            ["Peek", compileFinal {
	                if (_self call ["IsEmpty"]) exitWith { nil };
	                (_self get "_queueArray") select (_self get "_head");
	            }],
	            ["Dequeue", compileFinal {
	                if (_self call ["IsEmpty"]) exitWith { nil };
	                private _arr = _self get "_queueArray";
	                private _head = _self get "_head";
	                private _item = _arr select _head;
	                private _newCount = (_self get "_count") - 1;

	                if (_newCount <= 0) exitWith {
	                    _arr resize 0;
	                    _self set ["_head", 0];
	                    _self set ["_count", 0];
	                    _item
	                };

	                _head = _head + 1;
	                _self set ["_head", _head];
	                _self set ["_count", _newCount];

	                if (_head > 256 && {(_head * 2) > (count _arr)}) then {
	                    private _compact = _arr select [_head, (count _arr) - _head];
	                    _self set ["_queueArray", _compact];
	                    _self set ["_head", 0];
	                };

	                _item
	            }],
	            ["Enqueue", compileFinal {
	                (_self get "_queueArray") pushBack _this;
	                _self set ["_count", (_self get "_count") + 1];
	            }]
	        ]]
		};

		_self set ["_queueObject", call _makeQueue];
		_self set ["_dispatchQueue", call _makeQueue];
		_self set ["_metrics", createHashMapFromArray [
			["submitted", 0],
			["completedSuccess", 0],
			["completedFail", 0],
			["budgetExhausted", 0],
			["nodeSteps", 0],
			["processedThisFrame", 0],
			["queueDepth", 0],
			["queuePeak", 0],
			["frameCostMs", 0],
			["frameCostPeakMs", 0],
			["dispatchQueued", 0],
			["dispatchProcessed", 0],
			["dispatchQueueDepth", 0],
			["dispatchQueuePeak", 0],
			["lastFrameAt", 0]
		]];
	}],
	["_handle",nil],
	["_queueObject", nil],
	["_dispatchQueue", nil],
	["_metrics", nil],
	["CurrentItem",nil],
	["ProcessesPerFrame",80],
	["NodesPerSlice",24],
	["_currentSliceRemaining",0],
	["DispatchesPerFrame",10],
	["FrameTimeBudgetMs",2.0],
	["MaxFrameTimeBudgetMs",4.5],
	["hasSearchWork", compileFinal {
		if !(isNil {_self get "CurrentItem"}) exitWith { true };
		!((_self get "_queueObject") call ["IsEmpty"]);
	}],
	["dequeue",compileFinal {
		private _next = _self get "_queueObject" call ["Dequeue"];
		if (isNil {_next}) then {
			_self set ["CurrentItem",nil];
			_self set ["_currentSliceRemaining", 0];
		} else {
			_self set ["CurrentItem",_next];
			_self set ["_currentSliceRemaining", _self get "NodesPerSlice"];
		};
	}],
	["finalizeCurrent",compileFinal {
		private _item = _self get "CurrentItem";
		private _status = _item get "Status";
		_item call ["Callback",[_status isEqualto "SUCCESS", _item call ["SmoothPath"], _item get "CallbackArgs"]];
		private _metrics = _self get "_metrics";
		if (_status isEqualTo "SUCCESS") then {
			_metrics set ["completedSuccess", (_metrics get "completedSuccess") + 1];
		} else {
			_metrics set ["completedFail", (_metrics get "completedFail") + 1];
		};
		_self call ["dequeue"];
	}],
	["preprocessCurrent",compileFinal {
		if (isNil {_self get "CurrentItem"}) then {
			_self call ["dequeue"];
		};
		
		if !(isNil {_self get "CurrentItem"}) then {
			private _item = _self get "CurrentItem";

			if !(isNil {_item get "BudgetRemaining"}) then {
				private _budget = _item get "BudgetRemaining";
				_budget = _budget - 1;
				_item set ["BudgetRemaining", _budget];
				if (_budget <= 0) exitWith {
					private _cbArgs = _item get "CallbackArgs";
					private _key = if (_cbArgs isEqualType [] && {count _cbArgs > 0}) then { _cbArgs select 0 } else { "unknown" };
					["PATHFINDING", 2, format ["Path search budget exhausted: %1", _key]] call FLO_fnc_log;
					_item set ["Status", "FAILURE"];
					private _metrics = _self get "_metrics";
					_metrics set ["budgetExhausted", (_metrics get "budgetExhausted") + 1];
					_self call ["finalizeCurrent"];
				};
			};

			private _metrics = _self get "_metrics";
			_metrics set ["nodeSteps", (_metrics get "nodeSteps") + 1];

			private _done = _item call ["ProcessNextNode"];
			if (_done) then {
				_self call ["finalizeCurrent"];
			} else {
				private _slice = (_self get "_currentSliceRemaining") - 1;
				_self set ["_currentSliceRemaining", _slice];
				if (_slice <= 0) then {
					// Time-slice pending searches to avoid a single long route starving the queue.
					_self get "_queueObject" call ["Enqueue", _item];
					_self call ["dequeue"];
				};
			};
		};
	}],
	["AddItem", compileFinal {
        if !(_this isEqualType createhashmap) exitWith {false;};
        _self get "_queueObject" call ["Enqueue",_this];
		private _metrics = _self get "_metrics";
		_metrics set ["submitted", (_metrics get "submitted") + 1];
		private _depth = (_self get "_queueObject") call ["Count"];
		_metrics set ["queueDepth", _depth];
		if (_depth > (_metrics get "queuePeak")) then {
			_metrics set ["queuePeak", _depth];
		};
		true;
    }],
	["EnqueueDispatch", compileFinal {
		if !(params [
			["_dispatchAt",-1,[0]],
			["_pathStart",[],[[]]],
			["_pathEnd",[],[[]]],
			["_callbackCode",{},[{}]],
			["_callbackArgs",[],[[]]],
			["_allowTrails",false,[true]]
		]) exitWith { false };

		(_self get "_dispatchQueue") call ["Enqueue", [_dispatchAt, _pathStart, _pathEnd, _callbackCode, _callbackArgs, _allowTrails]];
		private _metrics = _self get "_metrics";
		_metrics set ["dispatchQueued", (_metrics get "dispatchQueued") + 1];
		private _depth = (_self get "_dispatchQueue") call ["Count"];
		_metrics set ["dispatchQueueDepth", _depth];
		if (_depth > (_metrics get "dispatchQueuePeak")) then {
			_metrics set ["dispatchQueuePeak", _depth];
		};
		true;
    }],
	["processDispatchQueue", compileFinal {
		private _processed = 0;
		private _now = diag_tickTime;
		private _queue = _self get "_dispatchQueue";
		private _limit = _self get "DispatchesPerFrame";
		while {_processed < _limit} do {
			private _next = _queue call ["Peek"];
			if (isNil "_next") exitWith {};
			_next params ["_dispatchAt", "_pathStart", "_pathEnd", "_callbackCode", "_callbackArgs", "_allowTrails"];
			if (_dispatchAt > _now) exitWith {};

			_queue call ["Dequeue"];
			[_pathStart, _pathEnd, _callbackCode, _callbackArgs, _allowTrails] call FLO_fnc_findRoadPath;
			_processed = _processed + 1;
		};

		private _metrics = _self get "_metrics";
		_metrics set ["dispatchProcessed", (_metrics get "dispatchProcessed") + _processed];
		_metrics set ["dispatchQueueDepth", _queue call ["Count"]];
		_processed;
	}],
	["GetMetrics", compileFinal {
		_self get "_metrics";
    }],
	["Start",compileFinal {
		private _handle = _self get "_handle";
		if (isNil "_handle") then {
			_handle = addMissionEventHandler ["EachFrame",compileFinal { 
				private _sched = _thisArgs#0;
				private _frameStart = diag_tickTime;
				_sched call ["processDispatchQueue"];

				private _count = 0;
				private _base = _sched get "ProcessesPerFrame";
				private _queued = (_sched get "_queueObject") call ["Count"];
				private _limit = _base;
				if (_queued > 300) then {
					_limit = _base * 3;
				} else {
					if (_queued > 100) then {
						_limit = _base * 2;
					};
				};
				if (_limit > 320) then { _limit = 320; };

				private _timeBudget = _sched get "FrameTimeBudgetMs";
				if (_queued > 1400) then {
					_timeBudget = _timeBudget + 2.0;
				} else {
					if (_queued > 900) then {
						_timeBudget = _timeBudget + 1.5;
					} else {
						if (_queued > 500) then {
							_timeBudget = _timeBudget + 0.8;
						};
					};
				};
				private _maxBudget = _sched get "MaxFrameTimeBudgetMs";
				if (_timeBudget > _maxBudget) then {
					_timeBudget = _maxBudget;
				};

				private _slice = _sched get "NodesPerSlice";
				if (_queued > 1200) then {
					_slice = 48;
				} else {
					if (_queued > 700) then {
						_slice = 36;
					};
				};
				_sched set ["NodesPerSlice", _slice];
				while {_count < _limit} do {
					if !(_sched call ["hasSearchWork"]) exitWith {};
					if (((diag_tickTime - _frameStart) * 1000) >= _timeBudget) exitWith {};
					_sched call ["preprocessCurrent"];
					_count = _count + 1;
				};

				private _metrics = _sched get "_metrics";
				private _queueDepth = (_sched get "_queueObject") call ["Count"];
				private _dispatchDepth = (_sched get "_dispatchQueue") call ["Count"];
				private _frameCost = (diag_tickTime - _frameStart) * 1000;
				_metrics set ["processedThisFrame", _count];
				_metrics set ["queueDepth", _queueDepth];
				_metrics set ["dispatchQueueDepth", _dispatchDepth];
				_metrics set ["frameCostMs", _frameCost];
				if (_queueDepth > (_metrics get "queuePeak")) then {
					_metrics set ["queuePeak", _queueDepth];
				};
				if (_dispatchDepth > (_metrics get "dispatchQueuePeak")) then {
					_metrics set ["dispatchQueuePeak", _dispatchDepth];
				};
				if (_frameCost > (_metrics get "frameCostPeakMs")) then {
					_metrics set ["frameCostPeakMs", _frameCost];
				};
				_metrics set ["lastFrameAt", diag_tickTime];
			}, [_self]];
			_self set ["_handle",_handle];
		} else {_self call ["Stop"]; _self call ["Start"];};
	}],
	["Stop",compileFinal {
		private _hndl = _self get "_handle";
		if !(isNil "_hndl") then {
			removeMissionEventHandler ["EachFrame",_hndl];
			_self set ["_handle",nil];
		};
	}]
];

if (isNil "FLO_PF_Scheduler") then {
	FLO_PF_Scheduler = createhashmapobject [XPS_typ_JobScheduler];
	FLO_PF_Scheduler call ["Start"];
};

if (isNil "FLO_fnc_pfProbe") then {
	FLO_fnc_pfProbe = compileFinal {
		if (isNil "FLO_PF_Scheduler") exitWith { [] };
		private _m = FLO_PF_Scheduler call ["GetMetrics"];
		private _pending = if (isNil "FLO_PF_RequestPending") then { 0 } else { count (keys FLO_PF_RequestPending) };
		private _cache = if (isNil "FLO_PF_RequestCache") then { 0 } else { count (keys FLO_PF_RequestCache) };
		private _active = if (isNil {FLO_PF_Scheduler get "CurrentItem"}) then { 0 } else { 1 };
		[
			["queueDepth", _m get "queueDepth"],
			["queuePeak", _m get "queuePeak"],
			["dispatchQueueDepth", _m get "dispatchQueueDepth"],
			["dispatchQueuePeak", _m get "dispatchQueuePeak"],
			["processedThisFrame", _m get "processedThisFrame"],
			["nodeSteps", _m get "nodeSteps"],
			["submitted", _m get "submitted"],
			["completedSuccess", _m get "completedSuccess"],
			["completedFail", _m get "completedFail"],
			["budgetExhausted", _m get "budgetExhausted"],
			["frameCostMs", _m get "frameCostMs"],
			["frameCostPeakMs", _m get "frameCostPeakMs"],
			["requestPending", _pending],
			["requestCache", _cache],
			["activeSearch", _active]
		]
	};
};

if (isNil "FLO_fnc_pathfindingProbe") then {
	FLO_fnc_pathfindingProbe = FLO_fnc_pfProbe;
};
