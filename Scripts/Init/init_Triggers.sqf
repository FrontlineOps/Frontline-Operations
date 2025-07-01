// Init Minefields
[] execVM 'Scripts\Objectives\Minefield_B.sqf';


// Init Removal of Intel Creation Items (After Usage)
[] spawn {
    while {true} do {
        sleep 2; // Check every 2 seconds

        private _items = vestItems player + uniformItems player + backpackItems player;
        private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];

        //diag_log format ["Checking player inventory for intel items: %1", _items];

        if (_intelItems findIf { _x in _items } != -1) then {
            {
                if (_x in _items) then {
                    player removeItem _x;
                    [mapGridPosition player] remoteExec ["FLO_fnc_addIntelServer", 2];
                };
            } forEach _intelItems;

            if (random 1 < 0.5) then {
                [] remoteExec ["FLO_fnc_militaryIntel", 0];
            } else {
                [] remoteExec ["FLO_fnc_revealRandomEnemyGroup", 0];
            };
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