

_thisMarker = _this select 0;


if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_armor") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "ArmouredBattalion"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_plane") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "AerialPatrol"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_unknown") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Insurgency"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_service") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "RoadBlocks"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_support") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Outpost"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "n_support") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "BOutpost"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_installation") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "City"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "n_installation") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Capital"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_antiair") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "AntiAir"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_maint") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Logistic"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "loc_Ruin") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Barracks"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "loc_Power") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "RadarSite"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "mil_warning") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Missquad"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "mil_unknown") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "CrashSite"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_naval") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Ship"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "loc_mine") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "MineField"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "o_recon") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "Recon"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "loc_Transmitter") && ((markerColor _thisMarker == "colorOPFOR") or (markerColor _thisMarker == "ColorEAST"))) then {
[["ConventionalOperations", "RadioTower"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "b_installation") && ((markerColor _thisMarker == "colorBLUFOR") or (markerColor _thisMarker == "ColorWEST"))) then {
[["ConventionalOperations", "BluZone"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};

if ((markerAlpha _thisMarker == 1) && (markerType _thisMarker == "b_installation") && (markerColor _thisMarker == "ColorYellow")) then {
[["ConventionalOperations", "FOB"], 15, "", 15, "", true, true, false, true] call BIS_fnc_advHint;
};