private _thisCaptureWestTrigger = _this select 0;
private _posit = getPos _thisCaptureWestTrigger;

sleep 120;

if !(isNull _thisCaptureWestTrigger) then {
    private _AGGRSCORE = FLO_DifficultyHandle get "value";

    if (triggerActivated _thisCaptureWestTrigger) then {
        private _POWs = allUnits select {(alive _x) && ((side _x) == east) && (position _x inArea _thisCaptureWestTrigger)};
        private _POWsShuffled = _POWs call BIS_fnc_arrayShuffle;
        private _POWsF = _POWsShuffled select [0, 5];
        
        {
            _x disableAI 'PATH';
            _x disableAI 'ANIM';
            removeAllWeapons _x;
            removeBackpack _x;
            _x setCaptive true;
            _x switchMove 'AmovPercMstpSsurWnonDnon';

            _x addEventHandler ['Killed', {
                [1.0, "increase"] call FLO_fnc_adjustAggression;
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
                    [(_this select 0), ''] remoteExec ['playMove', (_this select 0)];
                    (_this select 0) setBehaviour 'AWARE';
                    (_this select 0) setCaptive true;
                    [(_this select 0)] joinSilent player;
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
                    [(_this select 0), ''] remoteExec ['playMove', (_this select 0)];
                    (_this select 0) setBehaviour 'AWARE';
                    removeAllActions (_this select 0);
                    _x removeAllEventHandlers 'Killed';
                    (group (_this select 0)) addWaypoint [player getPos [(3000 + (random 1000)), (0 + (random 360))], 0];
                    [-0.10, 'decrease'] call FLO_fnc_adjustAggression;
                    [(_this select 0), (_this select 2)] remoteExec ['bis_fnc_holdActionRemove', [0, -2] select isDedicated, true];
                },
                {},
                [],
                3,
                0,
                true,
                false
            ] remoteExec ['BIS_fnc_holdActionAdd', 0, _x];
        } forEach _POWsF;

        private _MMarks = allMapMarkers select {markerType _x == 'o_support' or markerType _x == 'n_support'};
        private _M = [_MMarks, _thisCaptureWestTrigger] call BIS_fnc_nearestPosition;

        if (markerType _M == 'o_support') then {
            [50, 'STR_FLO_OUTPOST'] call FLO_fnc_sendRewardNotification;
            [50] call FLO_fnc_addReward;
            [0.35, "increase"] call FLO_fnc_adjustAggression;
        };

        if (markerType _M == 'n_support') then {
            [100, 'STR_FLO_COMMANDPOST'] call FLO_fnc_sendRewardNotification;
            [100] call FLO_fnc_addReward;
            [0.70, "increase"] call FLO_fnc_adjustAggression;
        };

        deleteMarker _M;

        private _markerName = 'AssaultMark' + (str [(0 + (random 1000)), (0 + (random 1000)), 0]);
        private _mrkr = createMarkerLocal [_markerName, [(0 + (random 1000)), (0 + (random 1000)), 0]];
        _mrkr setMarkerTypeLocal 'loc_Bunker';
        _mrkr setMarkerAlpha 0.003;

        if (_AGGRSCORE > 7) then {
            private _markerName = 'AssaultMark' + (str [(0 + (random 1000)), (0 + (random 1000)), 0]);
            private _mrkr = createMarkerLocal [_markerName, [(0 + (random 1000)), (0 + (random 1000)), 0]];
            _mrkr setMarkerTypeLocal 'loc_Bunker';
            _mrkr setMarkerAlpha 0.003;
        };

        if (_AGGRSCORE > 12) then {
            private _markerName = 'AssaultMark' + (str [(0 + (random 1000)), (0 + (random 1000)), 0]);
            private _mrkr = createMarkerLocal [_markerName, [(0 + (random 1000)), (0 + (random 1000)), 0]];
            _mrkr setMarkerTypeLocal 'loc_Bunker';
            _mrkr setMarkerAlpha 0.003;
        };

        private _markerName = 'respawn_west' + (str (getPos _thisCaptureWestTrigger));
        private _mrkr = createMarkerLocal [_markerName, getPos _thisCaptureWestTrigger];
        _mrkr setMarkerTypeLocal 'b_installation';
        _mrkr setMarkerColorLocal 'colorBLUFOR';
        _mrkr setMarkerSize [1.3, 1.3];

        private _alltriggers = allMissionObjects "EmptyDetector";
        private _triggers = _alltriggers select {getPos _x distance _thisCaptureWestTrigger < 10};
        {deleteVehicle _x;} forEach _triggers;

        private _trg = createTrigger ["EmptyDetector", _posit, false];
        _trg setTriggerArea [120, 120, 0, false, 200];
        _trg setTriggerTimeout [10, 10, 10, true];
        _trg setTriggerActivation ["EAST SEIZED", "PRESENT", true];
        _trg setTriggerStatements [
            "this",
            "
                [parseText '<t color=""#FF3619"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#7c7c7c""  align = ""right"" shadow = ""1"" size=""0.8"">Enemy Forces Dominating the Battle,</t><br /><t color=""#7c7c7c"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We Must Defend and Take Back the Outpost, </t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
                _allMarks = allMapMarkers select {markerType _x == 'b_installation'};
                _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
                _FOBMrk setMarkerColor 'ColorGrey';
                _attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
                [[west,'HQ'], 'Enemy Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];
                [thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT_CAPTURE_East.sqf';
            ",
            "
                _allMarks = allMapMarkers select {markerType _x == 'b_installation'};
                _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
                _FOBMrk setMarkerColor 'colorBLUFOR';
            "
        ];
    };
};

