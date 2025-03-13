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
	["ProcessesPerFrame",10],
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
			if (_self call ["processCurrent"]) then {
				_self call ["finalizeCurrent"];
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
				private _count = 0;
				private _limit = _thisArgs#0 get "ProcessesPerFrame";
				while {_count < _limit} do {
					_thisArgs#0 call ["preprocessCurrent"]; 
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