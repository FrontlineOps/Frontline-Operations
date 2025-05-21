/*
 * Function: FLO_fnc_militaryIntel
 * Author: Frontline Operations Development Group
 * Description:
 * Handles military intelligence events (marker reveals, optional missions, notifications).
 * Arguments: None
 * Returns: Nothing
 * Usage: [] call FLO_fnc_militaryIntel;
 */

params [];

sleep 2;
private _ChanceS = [1, 2, 3, 4, 5, 6, 7, 8];

if (count (allMapMarkers select {(markerAlpha _x == 0.001 or markerAlpha _x == 0) && (markerType _x == 'o_armor' || markerType _x == 'o_plane' || markerType _x == 'o_antiair' || markerType _x == 'loc_Transmitter' || markerType _x == 'o_service' || markerType _x == 'loc_Power' || markerType _x == 'o_support' || markerType _x == 'n_support' || markerType _x == 'loc_Ruin' || markerType _x == 'n_installation' || markerType _x == 'o_installation')}) == 0) then {
    _ChanceS = [5, 6, 7, 8];
};

private _Chance = selectRandom _ChanceS;

if (count (nearestobjects [position player, ["LocationArea_F"], 40000]) == 0) then {
    private _ChancesNew = _ChanceS - [5];
    _Chance = selectRandom _ChancesNew;
};

if (_Chance < 5) then {
    private _INTL = allMapMarkers select { (markerAlpha _x == 0.001 or markerAlpha _x == 0) && markerColor _x == "colorOPFOR" && markerType _x != "o_unknown" && markerType _x != "o_inf" && markerType _x != "o_Ordnance" && markerType _x != "o_maint" && markerShape _x != "RECTANGLE" && markerShape _x != "ELLIPSE"};
    private _x = [_INTL, player] call BIS_fnc_nearestPosition;
    _x setMarkerAlpha 1;

    sleep 1;
    private _attackingAtGrid = mapGridPosition getMarkerPos _x;
    ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
};

if (_Chance == 6) then {
    private _GNRT = "YES";
    private _DVRT = "NO";
    0 = [] spawn {
        private _result = ["Intel is about a Friendly Aircraft CrashSite, We can Track them Down and Rescue the Pilot and Destroy the Wreck,  (Optional Mission : Rescue Captured Pilot)", "", _DVRT, _GNRT,nil, false, false] call BIS_fnc_guiMessage;

        if (_result) then {
            private _INTL = allMapMarkers select { (markerAlpha _x == 0.001 or markerAlpha _x == 0) && markerColor _x == "colorOPFOR" && markerType _x != "o_unknown" && markerType _x != "o_inf" && markerType _x != "o_Ordnance" && markerType _x != "o_maint" && markerShape _x != "RECTANGLE" && markerShape _x != "ELLIPSE"};
            private _x = [_INTL, player] call BIS_fnc_nearestPosition;
            _x setMarkerAlpha 1;

            sleep 1;
            private _attackingAtGrid = mapGridPosition getMarkerPos _x;
            ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
        };

        if (!_result) then {
            private _allMarks = allMapMarkers select {(markerType _x == "b_installation") or (markerType _x == "o_installation") or (markerType _x == "n_installation") or (markerType _x == "o_support") or (markerType _x == "n_support") or  (markerType _x == "loc_Power") or  (markerType _x == "loc_Ruin")};
            private _NOSHs = [];
            {
                private _NOSH = nearestObjects [getMarkerPos _x, ["HOUSE"], 400];
                _NOSHs append _NOSH;
            } forEach _allMarks;

            private _ALLSHs = nearestObjects [player, ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
            private _NearSHs = nearestObjects [player, ["HOUSE"], 500] select {count (_x buildingPos -1) > 2};
            private _SHs = _ALLSHs - _NearSHs;
            private _SH = _SHs - _NOSHs;

            private _HQB = _SH select 0;

            private _markerName = "InvesMark" + (str (getPos _HQB));
            private _mrkr = createMarker [_markerName, (getPos _HQB)];
            _mrkr setMarkerType "mil_unknown";
            _mrkr setMarkerColor "colorOPFOR";
            _mrkr setMarkerSize [0.8, 0.8];

            private _trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
            _trgA setTriggerArea [2000, 2000, 0, false, 60];
            _trgA setTriggerInterval 3;
            _trgA setTriggerTimeout [7, 7, 7, true];
            _trgA setTriggerActivation ["WEST", "PRESENT", false];
            _trgA setTriggerStatements [
                "this",
                "[thisTrigger] execVM 'Scripts/Mission_Pilot.sqf';",
                "",
                ""
            ];

            sleep 1;
            private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
            ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
        };
    };
};

if (_Chance == 7) then {
    private _GNRT = "YES";
    private _DVRT = "NO";
    0 = [] spawn {
        private _result = ["Intel Suggest the whereabouts of the Friendly Squad we Lost Contact with Earlier, We can Track them down and Rescue Them,  (Optional Mission : Rescue Missing Squad)", "", _DVRT, _GNRT,nil, false, false] call BIS_fnc_guiMessage;

        if (_result) then {
            private _INTL = allMapMarkers select { (markerAlpha _x == 0.001 or markerAlpha _x == 0) && markerColor _x == "colorOPFOR" && markerType _x != "o_unknown" && markerType _x != "o_inf" && markerType _x != "o_Ordnance" && markerType _x != "o_maint" && markerShape _x != "RECTANGLE" && markerShape _x != "ELLIPSE"};
            private _x = [_INTL, player] call BIS_fnc_nearestPosition;
            _x setMarkerAlpha 1;

            sleep 1;
            private _attackingAtGrid = mapGridPosition getMarkerPos _x;
            ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
        };

        if (!_result) then {
            private _allMarks = allMapMarkers select {(markerType _x == "b_installation") or (markerType _x == "o_installation") or (markerType _x == "n_installation") or (markerType _x == "o_support") or (markerType _x == "n_support") or  (markerType _x == "loc_Power") or  (markerType _x == "loc_Ruin")};
            private _NOSHs = [];
            {
                private _NOSH = nearestObjects [getMarkerPos _x, ["HOUSE"], 400];
                _NOSHs append _NOSH;
            } forEach _allMarks;

            private _ALLSHs = nearestObjects [player, ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
            private _NearSHs = nearestObjects [player, ["HOUSE"], 500] select {count (_x buildingPos -1) > 2};
            private _SHs = _ALLSHs - _NearSHs;
            private _SH = _SHs - _NOSHs;

            private _HQB = _SH select 0;

            private _markerName = "InvesMark" + (str (getPos _HQB));
            private _mrkr = createMarker [_markerName, (getPos _HQB)];
            _mrkr setMarkerType "mil_warning";
            _mrkr setMarkerColor "colorOPFOR";
            _mrkr setMarkerSize [0.8, 0.8];

            private _trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
            _trgA setTriggerArea [2000, 2000, 0, false, 60];
            _trgA setTriggerInterval 3;
            _trgA setTriggerTimeout [7, 7, 7, true];
            _trgA setTriggerActivation ["WEST", "PRESENT", false];
            _trgA setTriggerStatements [
                "this",
                "[thisTrigger] execVM 'Scripts/Mission_Squad.sqf';",
                "",
                ""
            ];

            sleep 1;
            private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
            ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
        };
    };
};

if (_Chance == 8) then {
    private _GNRT = "YES";
    private _DVRT = "NO";
    0 = [] spawn {
        private _result = ["Intel Suggests Enemy Support Convoy will be Launched toward Frontlines, We can Intercept the Convoy and Dismantle their Reinforcements and Support operation,  (Optional Mission : Destroy Enemy Convoy)", "", _DVRT, _GNRT,nil, false, false] call BIS_fnc_guiMessage;

        if (_result) then {
            private _INTL = allMapMarkers select { (markerAlpha _x == 0.001 or markerAlpha _x == 0) && markerColor _x == "colorOPFOR" && markerType _x != "o_unknown" && markerType _x != "o_inf" && markerType _x != "o_Ordnance" && markerType _x != "o_maint" && markerShape _x != "RECTANGLE" && markerShape _x != "ELLIPSE"};
            private _x = [_INTL, player] call BIS_fnc_nearestPosition;
            _x setMarkerAlpha 1;

            sleep 1;
            private _attackingAtGrid = mapGridPosition getMarkerPos _x;
            ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
        };

        if (!_result) then {
            // TODO: Refactor Scripts/Mission_Convoy.sqf into a function and call it here
            _Enemy_Convoy = execVM "Scripts/Mission_Convoy.sqf";
        };
    };
}; 