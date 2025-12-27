/*
 * Client Post-Initialization Triggers
 * Author: Frontline Operations
 *
 * Description:
 * Final client-side initialization after faction setup is complete.
 * Handles minefield initialization, intel item processing, and player activation.
 *
 * This script runs on each client after all other initialization is complete.
 */

// ============================================================================
// MINEFIELD INITIALIZATION
// ============================================================================

["INIT_TRIGGERS", 3, "Initializing minefields..."] call FLO_fnc_log;
[] execVM "Scripts\Objectives\Minefield_B.sqf";

// ============================================================================
// INTEL ITEM PROCESSING
// ============================================================================

// Background loop to process intel items picked up by the player
[] spawn {
    private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];

    while {true} do {
        sleep 2;

        private _playerItems = vestItems player + uniformItems player + backpackItems player;

        // Check if player has any intel items
        if (_intelItems findIf {_x in _playerItems} != -1) then {
            // Process each intel item
            {
                if (_x in _playerItems) then {
                    player removeItem _x;
                    [mapGridPosition player] remoteExec ["FLO_fnc_addIntelServer", 2];
                };
            } forEach _intelItems;

            // 50% chance for each intel type reveal
            if (random 1 < 0.5) then {
                [] remoteExec ["FLO_fnc_militaryIntel", 0];
            } else {
                [] remoteExec ["FLO_fnc_revealRandomEnemyGroup", 0];
            };
        };
    };
};

// ============================================================================
// PLAYER ACTIVATION
// ============================================================================

sleep 1;

// Notify all clients that loading is complete
["LOADING 100 %"] remoteExec ["hint", 0];

// Welcome message with fade-in
titleText [
    "<t color='#674ea7' size='2' font='PuristaBold'>FLO  |  FRONTLINE OPERATIONS</t>",
    "BLACK IN",
    7,
    true,
    true
];

// Enable the player entity
player hideObjectGlobal false;
player enableSimulationGlobal true;
player allowDamage true;

// Give player UAV terminal for drone control
player linkItem "B_UavTerminal";

// Force respawn in multiplayer to complete initialization
if (isMultiplayer) then {
    RESPAWN_IS_FORCED = true;
    forceRespawn player;
};

["INIT_TRIGGERS", 3, "Post-initialization complete"] call FLO_fnc_log;