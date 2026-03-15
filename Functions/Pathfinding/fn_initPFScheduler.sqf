XPS_typ_JobScheduler = [
	["#type","XPS_typ_JobScheduler"],
	["#create", compileFinal {
		_self set ["_queueObject", createhashmapobject [[
	        ["#type", "XPS_typ_Queue"],
	        ["#str", compileFinal {_self get "#type" select  0}],
            ["_queueArray",[]],
            ["Clear", compileFinal {
                _self get "_queueArray" resize 0;
            }],
            ["Count", compileFinal {
                count (_self get "_queueArray");
            }],
            ["IsEmpty", compileFinal {
                count (_self get "_queueArray") isEqualTo 0;
            }],
            ["Peek", compileFinal {
                if !(_self call ["IsEmpty"]) then {
                    _self get "_queueArray" select 0;
                } else {nil};
            }],
            ["Dequeue", compileFinal {
                if !(_self call ["IsEmpty"]) then {
                    _self get "_queueArray" deleteat 0;
                } else {nil};
            }],
            ["Enqueue", compileFinal {
                _self get "_queueArray" pushBack _this;
            }]
        ]] ];
	}],
	["_handle",nil],
	["_queueObject", nil],
	["CurrentItem",nil],
	["ProcessesPerFrame",60],
	["dequeue",compileFinal {
		private _next = _self get "_queueObject" call ["Dequeue"];
		if (isNil {_next}) then {
			_self set ["CurrentItem",nil];
		} else {
			_self set ["CurrentItem",_next];
		};
	}],
	["finalizeCurrent",compileFinal {
		private _item = _self get "CurrentItem";
		_item call ["Callback",[_item get "Status" isEqualto "SUCCESS", _item call ["SmoothPath"], _item get "CallbackArgs"]];
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
					_self call ["finalizeCurrent"];
				};
			};

			private _done = _item call ["ProcessNextNode"];
			if (_done) then {
				_self call ["finalizeCurrent"];
			} else {
				// Time-slice pending searches to avoid a single long route starving the queue.
				_self get "_queueObject" call ["Enqueue", _item];
				_self call ["dequeue"];
			};
		};
	}],
	["processCurrent",compileFinal {
		_self get "CurrentItem" call ["ProcessNextNode"];
	}],
	["AddItem", compileFinal {
        if !(_this isEqualType createhashmap) exitWith {false;};
        _self get "_queueObject" call ["Enqueue",_this];
    }],
	["Start",compileFinal {
		private _handle = _self get "_handle";
		if (isNil "_handle") then {
			_handle = addMissionEventHandler ["EachFrame",compileFinal { 
				private _sched = _thisArgs#0;
				private _count = 0;
				private _base = _sched get "ProcessesPerFrame";
				private _queued = (_sched get "_queueObject") call ["Count"];
				private _limit = _base;
				if (_queued > 300) then {
					_limit = _base * 4;
				} else {
					if (_queued > 100) then {
						_limit = _base * 2;
					};
				};
				if (_limit > 400) then { _limit = 400; };
				while {_count < _limit} do {
					_sched call ["preprocessCurrent"];
					_count = _count + 1;
				};
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

FLO_PF_Scheduler = createhashmapobject [XPS_typ_JobScheduler];
FLO_PF_Scheduler call ["Start"];
