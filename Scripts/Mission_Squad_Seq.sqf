params [["_thisIntelItem", objNull]];
private _AGGRSCORE = FLO_DifficultyHandle get "value";

[50, 'STR_FLO_INTEL'] call FLO_fnc_sendRewardNotification;
[50] call FLO_fnc_addReward;

if ((typeOf _thisIntelItem == "Land_File2_F") && (_AGGRSCORE > 5)) then {
    // Delete nearest warning marker
    private _MMarks = allMapMarkers select {markerType _x == "mil_warning"};
    private _M = [_MMarks, _thisIntelItem] call BIS_fnc_nearestPosition;
    deleteMarker _M;

    // Get all installation markers
    private _markerTypes = ["b_installation", "o_installation", "n_installation", "o_support", "n_support", "loc_Power", "loc_Ruin"];
    private _allMarks = allMapMarkers select {markerType _x in _markerTypes};
    
    // Get all houses near markers
    private _NOSHs = [];
    {
        _NOSHs append (nearestObjects [getMarkerPos _x, ["HOUSE"], 400]);
    } forEach _allMarks;

    // Find suitable HQ building
    private _ALLSHs = nearestObjects [_thisIntelItem, ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
    private _NearSHs = nearestObjects [_thisIntelItem, ["HOUSE"], 200] select {count (_x buildingPos -1) > 2};
    private _SHs = _ALLSHs - _NearSHs;
    private _SH = _SHs - _NOSHs;
    private _HQB = _SH select 0;
    private _dir = getDirVisual _HQB;

    // Spawn intel composition
    ["Intel_MIS_02", selectRandom (_HQB buildingPos -1), [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;

    // Spawn garrison units
    private _buildingPositions = _HQB buildingPos -1;
    for "_i" from 0 to 3 do {
        private _pos = selectRandom _buildingPositions;
        private _group = [_pos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
        if (_i < 2) then {
            (units _group select 0) disableAI "PATH";
        };
    };

    // Spawn patrol group
    private _patrolPos = _HQB getPos [50 + random 50, random 360];
    private _patrolGroup = [_patrolPos, East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
    [_patrolGroup, getPos _HQB, 200] call BIS_fnc_taskPatrol;

    // Create marker
    private _markerName = "InvesMark" + str getPos _HQB;
    private _mrkr = createMarker [_markerName, getPos _HQB];
    _mrkr setMarkerType "mil_warning";
    _mrkr setMarkerColor "colorOPFOR";
    _mrkr setMarkerSize [0.8, 0.8];

    // Send notification
    ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", mapGridPosition getMarkerPos _mrkr], "intel"] call FLO_fnc_sendNotification;

    // Spawn additional groups based on difficulty
    private _groupCount = 2 + (_AGGRSCORE > 5) + (_AGGRSCORE > 10);
    for "_i" from 0 to (_groupCount - 1) do {
        private _pos = _HQB getPos [50 + random 250, random 360];
        [_pos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
    };

    // Spawn patrol groups
    private _patrolCount = 1 + (_AGGRSCORE > 10);
    for "_i" from 0 to (_patrolCount - 1) do {
        private _pos = _HQB getPos [50 + random 200, random 360];
        private _group = [_pos, East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
        [_group, getPos _HQB, 500 + (_i * 500)] call BIS_fnc_taskPatrol;
    };

    // Create QRF trigger
    private _trgA = createTrigger ["EmptyDetector", getPos _HQB];
    _trgA setTriggerArea [300, 300, 0, false, 60];
    _trgA setTriggerInterval 3;
    _trgA setTriggerTimeout [1, 1, 1, true];
    _trgA setTriggerActivation ["WEST", "PRESENT", false];
    _trgA setTriggerStatements [
        "this",
        format ["[thisTrigger] execVM selectRandom ['Scripts\HeliInsert_CSAT.sqf', 'Scripts\VehiInsert_CSAT.sqf']"],
        ""
    ];
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if ((typeOf _thisIntelItem == "Land_Document_01_F") && (_AGGRSCORE > 10)) then {
    // Find and delete nearest warning marker
    private _MMarks = allMapMarkers select {markerType _x == "mil_warning"};
    private _M = [_MMarks, _thisIntelItem] call BIS_fnc_nearestPosition;
    deleteMarker _M;

    // Get all relevant markers and their nearby houses
    private _markerTypes = ["b_installation", "o_installation", "n_installation", "o_support", "n_support", "loc_Power", "loc_Ruin"];
    private _allMarks = allMapMarkers select {markerType _x in _markerTypes};
    private _NOSHs = [];
    {
        _NOSHs append (nearestObjects [getMarkerPos _x, ["HOUSE"], 400]);
    } forEach _allMarks;

    // Find suitable HQ building
    private _ALLSHs = nearestObjects [_thisIntelItem, ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
    private _NearSHs = nearestObjects [_thisIntelItem, ["HOUSE"], 200] select {count (_x buildingPos -1) > 2};
    private _SHs = _ALLSHs - _NearSHs;
    private _SH = _SHs - _NOSHs;
    private _HQB = _SH select 0;
    private _dir = getDirVisual _HQB;

    // Spawn composition and initial garrison
    ["Intel_MIS_03", selectRandom (_HQB buildingPos -1), [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;
    
    // Spawn garrison units
    for "_i" from 0 to 3 do {
        private _pos = selectRandom (_HQB buildingPos -1);
        private _group = [_pos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
        if (_i < 2) then {
            (units _group select 0) disableAI "PATH";
        };
    };

    // Spawn patrol group
    private _patrolPos = _HQB getPos [50 + random 50, random 360];
    private _patrolGroup = [_patrolPos, East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
    [_patrolGroup, getPos _HQB, 200] call BIS_fnc_taskPatrol;

    // Create marker
    private _markerName = "InvesMark" + str getPos _HQB;
    private _mrkr = createMarker [_markerName, getPos _HQB];
    _mrkr setMarkerType "mil_warning";
    _mrkr setMarkerColor "colorOPFOR";
    _mrkr setMarkerSize [0.8, 0.8];

    // Send notification
    ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", mapGridPosition getMarkerPos _mrkr], "intel"] call FLO_fnc_sendNotification;

    // Spawn additional groups based on difficulty
    private _groupCount = 2 + (_AGGRSCORE > 5) + (_AGGRSCORE > 10);
    for "_i" from 0 to (_groupCount - 1) do {
        private _pos = _HQB getPos [50 + random 250, random 360];
        [_pos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
    };

    // Spawn patrol groups
    private _patrolCount = 1 + (_AGGRSCORE > 10);
    for "_i" from 0 to (_patrolCount - 1) do {
        private _pos = _HQB getPos [50 + random 200, random 360];
        private _group = [_pos, East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
        [_group, getPos _HQB, 500 + (_i * 500)] call BIS_fnc_taskPatrol;
    };

    // Create QRF trigger
    private _trgA = createTrigger ["EmptyDetector", getPos _HQB];
    _trgA setTriggerArea [300, 300, 0, false, 60];
    _trgA setTriggerInterval 3;
    _trgA setTriggerTimeout [1, 1, 1, true];
    _trgA setTriggerActivation ["WEST", "PRESENT", false];
    _trgA setTriggerStatements [
        "this",
        format ["[thisTrigger] execVM selectRandom ['Scripts\HeliInsert_CSAT.sqf', 'Scripts\VehiInsert_CSAT.sqf']"],
        ""
    ];
};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if ((typeOf _thisIntelItem == "Land_Map_Malden_F") || ((typeOf _thisIntelItem == "Land_Document_01_F") && (_AGGRSCORE < 11)) || ((typeOf _thisIntelItem == "Land_File2_F") && (_AGGRSCORE < 6))) then {
    // Find and delete nearest warning marker
    private _MMarks = allMapMarkers select {markerType _x == "mil_warning"};
    private _M = [_MMarks, _thisIntelItem] call BIS_fnc_nearestPosition;
    deleteMarker _M;

    // Get all installation markers
    private _allMarks = allMapMarkers select {
        markerType _x in ["b_installation", "o_installation", "n_installation", "o_support", "n_support", "loc_Power", "loc_Ruin"]
    };

    // Build exclusion list of houses near installations
    private _NOSHs = [];
    {
        _NOSHs append (nearestObjects [getMarkerPos _x, ["HOUSE"], 400]);
    } forEach _allMarks;

    // Find suitable HQ building
    private _ALLSHs = nearestObjects [_thisIntelItem, ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
    private _NearSHs = nearestObjects [_thisIntelItem, ["HOUSE"], 200] select {count (_x buildingPos -1) > 2};
    private _SHs = _ALLSHs - _NearSHs;
    private _SH = _SHs - _NOSHs;
    private _HQB = _SH select 0;
    private _dir = getDirVisual _HQB;

    // Create marker and notification
    private _markerName = "InvesMark" + str getPos _HQB;
    private _mrkr = createMarker [_markerName, getPos _HQB];
    _mrkr setMarkerType "mil_warning";
    _mrkr setMarkerColor "colorOPFOR";
    _mrkr setMarkerSize [0.8, 0.8];
    ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", mapGridPosition getMarkerPos _mrkr], "intel"] call FLO_fnc_sendNotification;

    // Spawn patrol groups
    private _patrolPos1 = _HQB getPos [50 + random 50, random 360];
    private _patrolGroup1 = [_patrolPos1, East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
    [_patrolGroup1, getPos _HQB, 500] call BIS_fnc_taskPatrol;

    private _patrolPos2 = _HQB getPos [50 + random 100, random 360];
    private _patrolGroup2 = [_patrolPos2, East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
    [_patrolGroup2, getPos _HQB, 500] call BIS_fnc_taskPatrol;

    // Spawn additional patrol for high aggression
    if (_AGGRSCORE > 10) then {
        private _patrolPos3 = _HQB getPos [50 + random 250, random 360];
        private _patrolGroup3 = [_patrolPos3, East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
        [_patrolGroup3, getPos _HQB, 1000] call BIS_fnc_taskPatrol;

        // Create QRF trigger
        private _trgA = createTrigger ["EmptyDetector", getPos _HQB];
        _trgA setTriggerArea [300, 300, 0, false, 60];
        _trgA setTriggerInterval 3;
        _trgA setTriggerTimeout [1, 1, 1, true];
        _trgA setTriggerActivation ["WEST", "PRESENT", false];
        _trgA setTriggerStatements [
            "this",
            format ["[thisTrigger] execVM selectRandom ['Scripts\HeliInsert_CSAT.sqf', 'Scripts\VehiInsert_CSAT.sqf']"],
            ""
        ];
    };

    // Spawn and setup POW group
    private _buildingPos = selectRandom (_HQB buildingPos -1);
    private _powGroup = [_buildingPos, civilian, ["B_Pilot_F", "B_Pilot_F", "B_Pilot_F", "B_Pilot_F"]] call BIS_fnc_spawnGroup;
    
    {
        _x disableAI "PATH";
        _x setCaptive true;
        _x setUnitPos "MIDDLE";
    } forEach units _powGroup;

    // Set loadouts and positions
    private _loadouts = [F_Assault_TL, F_Assault_Med, F_Assault_Eng, F_Assault_Amm];
    private _buildingPositions = _HQB buildingPos -1;
    {
        (_x select 0) setUnitLoadout (_loadouts select _forEachIndex);
        (_x select 0) setPos (_buildingPositions select (_forEachIndex + 1));
    } forEach (units _powGroup apply {[_x]});

    // Create rescue trigger
    private _rescueTrigger = createTrigger ["EmptyDetector", getPos _HQB];
    _rescueTrigger setTriggerArea [10, 10, 0, false, 5];
    _rescueTrigger setTriggerInterval 2;
    _rescueTrigger setTriggerActivation ["ANYPLAYER", "PRESENT", false];
    _rescueTrigger setTriggerStatements [
        "this",
        "
        playSound3D [(getMissionPath 'Sounds\c_eb_35_natojoin_KER_0.ogg'), player];

        private _MMarks = allMapMarkers select {markerType _x == 'mil_warning'};
        private _M = [_MMarks, thisTrigger] call BIS_fnc_nearestPosition;
        deleteMarker _M;

        private _POW = nearestObjects [thisTrigger, ['B_Pilot_F'], 200];
        private _CPOW = _POW select {side _x == civilian};
        private _THPOW = _CPOW select 0;
        private _GRS = group _THPOW;
        playSound3D [(getMissionPath 'Sounds\c_eb_35_natojoin_MEM_0.ogg'), _THPOW];

        private _Group = createGroup West;
        {
            [_x] join _Group;
            _x enableAI 'PATH';
            _x setCaptive false;
            _x setUnitPos 'AUTO';
        } forEach units _GRS;

        private _headlessClients = entities 'HeadlessClient_F';
        private _humanPlayers = allPlayers - _headlessClients;
        hcRemoveAllGroups player;
        {player hcRemoveGroup _x} forEach (allGroups select {side _x == west});
        private _GRPs = allGroups select {(side _x == (side player)) && !(((units _x) select 0) in switchableUnits)};

        if (count _humanPlayers == 1) then {
            {player hcSetGroup [_x]} forEach _GRPs;
        } else {
            {TheCommander hcSetGroup [_x]} forEach _GRPs;
        };

        playSound3D [(getMissionPath 'Sounds\c_eb_35_natojoin_MEM_0.ogg'), ((units _Group) select 0)];
        [50, 'STR_FLO_MISSINGSQUAD'] call FLO_fnc_sendRewardNotification;
        [50] call FLO_fnc_addReward;
        ",
        ""
    ];
};

sleep 2;
