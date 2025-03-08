params ["_trigger"];

// Get aggression score from marker
private _aggrScore = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color6_FD_F"}) select 0));

// Hide nearby terrain objects
{
    _x hideObjectGlobal true;
} forEach (nearestTerrainObjects [getPos _trigger, ["House", "TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS"], 15]);

// Get building positions
private _buildings = nearestObjects [getPos _trigger, ["House", "Land_BagBunker_Large_F", "Land_BagBunker_Small_F", "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F"], 50];
private _positions = [];
{
    _positions append (_x buildingPos -1);
} forEach _buildings;

if (count _positions > 0) then {
    // Spawn crates
    private _crateTypes = [
        "Box_IND_WpsSpecial_F", "Box_East_WpsSpecial_F", "Box_IND_Support_F",
        "Box_East_Support_F", "Box_CSAT_Equip_F", "Box_AAF_Equip_F",
        "Box_East_WpsLaunch_F", "Box_IND_WpsLaunch_F", "Box_East_AmmoOrd_F",
        "Box_East_Ammo_F", "Box_IND_Ammo_F", "Box_IND_AmmoOrd_F",
        "Box_East_Wps_F", "Box_IND_Wps_F"
    ];

    for "_i" from 1 to 4 do {
        if (count _positions == 0) exitWith {};
        private _cratePos = selectRandom _positions;
        _positions deleteAt (_positions find _cratePos);
        createVehicle [selectRandom _crateTypes, _cratePos, [], 0, "NONE"];
    };

    // Spawn intel
    if (count _positions > 0) then {
        private _intelPos = selectRandom _positions;
        _positions deleteAt (_positions find _intelPos);
        ["Intel_01", _intelPos, [0,0,0], random 360, false, false, true] call LARs_fnc_spawnComp;
    };
};

// Create surrender trigger
private _surrenderTrigger = createTrigger ["EmptyDetector", getPos _trigger, false];
_surrenderTrigger setTriggerArea [120, 120, 0, false, 200];
_surrenderTrigger setTriggerInterval 6;
_surrenderTrigger setTriggerActivation ["WEST SEIZED", "PRESENT", false];
_surrenderTrigger setTriggerStatements [
    "this && {(alive _x) && ((side _x) == EAST) && (position _x inArea thisTrigger)} count allUnits < 3",
    "
    {
        if (((side _x) == east) && (position _x inArea thisTrigger)) then {
            _x disableAI 'PATH';
            _x disableAI 'ANIM';
            removeAllWeapons _x;
            removeBackpack _x;
            _x setCaptive true;
            _x switchMove 'AmovPercMstpSsurWnonDnon';

            _x addEventHandler ['Killed', {
                [] execVM 'Scripts\DangerPlusSurr.sqf';
                removeAllActions (_this select 0);
            }];

            [
                _x,
                'Arrest',
                'Screens\FOBA\holdAction_secure_ca.paa',
                'Screens\FOBA\holdAction_secure_ca.paa',
                '_this distance _target < 3',
                '_caller distance _target < 3',
                {},
                {},
                {
                    (_this select 0) enableAI 'ANIM';
                    (_this select 0) enableAI 'PATH';
                    (_this select 0) switchMove '';
                    (_this select 0) setBehaviour 'AWARE';
                    [(_this select 0)] joinSilent player;
                    (_this select 0) setCaptive true;
                    removeAllActions (_this select 0);
                },
                {},
                [],
                3,
                0,
                true,
                false
            ] remoteExec ['BIS_fnc_holdActionAdd', 0, _x];

            [
                _x,
                'Release',
                '\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa',
                '\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa',
                '_this distance _target < 3',
                '_caller distance _target < 3',
                {(_this select 0) setDir (position (_this select 0) getDir position player);},
                {},
                {
                    (_this select 0) enableAI 'ANIM';
                    (_this select 0) enableAI 'PATH';
                    (_this select 0) switchMove '';
                    (_this select 0) setBehaviour 'AWARE';
                    removeAllActions (_this select 0);
                    _x removeAllEventHandlers 'Killed';
                    (group (_this select 0)) addWaypoint [player getPos [3000 + random 1000, random 360], 0];
                    [] execVM 'Scripts\DangerMinusSurr.sqf';
                    [(_this select 0), (_this select 2)] remoteExec ['bis_fnc_holdActionRemove', [0,-2] select isDedicated, true];
                },
                {},
                [],
                3,
                0,
                true,
                false
            ] remoteExec ['BIS_fnc_holdActionAdd', 0, _x];
        };
    } forEach allUnits;

    private _markers = allMapMarkers select {markerType _x == 'o_service'};
    private _nearestMarker = [_markers, thisTrigger] call BIS_fnc_nearestPosition;
    deleteMarker _nearestMarker;

    [30] call FLO_fnc_addReward;
    [thisTrigger, 1000] call FLO_fnc_requestQRF;
    [] execVM 'Scripts\DangerPlusSurr.sqf';
    [30, 'ROADBLOCK'] call FLO_fnc_notification;
    ",
    ""
];

// Spawn intel items
[_trigger, 100] execVM "Scripts\INTLitems.sqf";

// Set up weapon emplacements
sleep 5;
private _weapons = nearestObjects [getPos _trigger, ["O_G_HMG_02_high_F", "O_G_Mortar_01_F"], 100];
{
    [_x, 3, position _x, "ATL"] call BIS_fnc_setHeight;
    _x setVectorUp [0,0,1];
} forEach _weapons;

if (count _weapons > 0) then {
    createVehicleCrew (_weapons select 0);
};
