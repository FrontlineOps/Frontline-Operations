// Init Minefields
[] execVM 'Scripts\Objectives\Minefield_B.sqf';

// Init Intel Creation Items
[] spawn {
    while {true} do {
        sleep 10; // Check every 10 seconds

        if (isNil "FLO_virtualGroups") then { continue; };

        private _cursorPos = getPos cursorObject;
        private _groups = [];

        {
            private _gPos = _y get "position";
            private _side = _y getOrDefault ["side", east];
            if (_side == east && { _gPos distance _cursorPos <= 500 }) then {
                _groups pushBack [_x, _y];
            };
        } forEach (FLO_virtualGroups get "_groups");

        if (count _groups > 0) then {
            _groups = [_groups, [], {(_x select 1 get "position") distance _cursorPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _sel = _groups select 0;
            _sel params ["_gid", "_gdata"];
            private _gpos = _gdata get "position";

            private _base = format ["scoutIntel_%1_%2", _gid, floor diag_tickTime];
            private _mrk = createMarkerLocal [_base, _gpos];
            _mrk setMarkerTypeLocal "o_unknown";
            _mrk setMarkerColorLocal "colorOPFOR";
            _mrk setMarkerSizeLocal [0.8,0.8];
            _mrk setMarkerAlpha 1;

            private _marks = [_mrk];
            private _wpts = _gdata getOrDefault ["waypoints", []];
            {
                private _wpName = format ["%1_wp_%2", _base, _forEachIndex];
                private _wpPos = _x select 0;
                private _wpMark = createMarkerLocal [_wpName, _wpPos];
                _wpMark setMarkerTypeLocal "hd_dot";
                _wpMark setMarkerColorLocal "colorOPFOR";
                _wpMark setMarkerSizeLocal [0.5,0.5];
                _wpMark setMarkerAlpha 1;
                _marks pushBack _wpMark;
            } forEach _wpts;

            [_marks] spawn {
                params ["_ms"];
                private _steps = 10;
                for "_i" from 1 to _steps do {
                    private _a = 1 - (_i / _steps);
                    { _x setMarkerAlpha _a; } forEach _ms;
                    sleep 6;
                };
                { deleteMarker _x; } forEach _ms;
            };

            private _grid = mapGridPosition _gpos;
            ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_SCOUT", _grid], "info"] call FLO_fnc_sendNotification;
        };
    };
};

// Init Removal of Intel Creation Items (After Usage)
[] spawn {
    while {true} do {
        sleep 2; // Check every 2 seconds

        private _items = vestItems player + uniformItems player + backpackItems player;
        private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];

        //diag_log format ["Checking player inventory for intel items: %1", _items];

        if (_intelItems findIf { _x in _items } != -1) then {
            //diag_log "Intel item found in player inventory.";

            {
                if (_x in _items) then {
                    player removeItem _x;
                    //diag_log format ["Removed intel item: %1", _x];
                    [mapGridPosition player] remoteExec ["FLO_fnc_addIntelServer",2];
                };
            } forEach _intelItems;

            [] call FLO_fnc_militaryIntel;
            //diag_log "Executed INTL.sqf script.";
        };
    };
};
		
sleep 1;

["LOADING 100 % "] remoteExec ["hint", 0];
// Welcome to FrontlineOps
titleText ["<t color='#674ea7' size='2' font='PuristaBold'>FLO  |  FRONTLINE OPERATIONS</t>", "BLACK IN",7, true, true];

//Initialize the player
player hideObjectGlobal false;
player enableSimulationGlobal true;
player allowDamage true;

if (isMultiplayer) then {
	RESPAWN_IS_FORCED = true;
	forceRespawn player;
};

player linkItem "B_UavTerminal";