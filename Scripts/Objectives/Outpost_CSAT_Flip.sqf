private _thisOutpostTrigger = _this select 0;
private _AGGRSCORE = FLO_DifficultyHandle get "value"; 

sleep 10;

private _trg = createTrigger ["EmptyDetector", getPos _thisOutpostTrigger, false];
_trg setTriggerArea [120, 120, 0, false, 200];
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["WEST SEIZED", "PRESENT", true];
_trg setTriggerStatements [
    "this",
    "
    [parseText '<t color=""#1AA3FF"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Friendly Forces Dominating the Battle,</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We will Capture and Secure the Outpost,</t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
    _allMarks = allMapMarkers select {markerType _x == 'o_support'};
    _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
    _FOBMrk setMarkerColor 'ColorGrey';
    _attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
    [[west,'HQ'], 'Friendly Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];
    [thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT_CAPTURE_West.sqf';
    ",
    "
    _allMarks = allMapMarkers select {markerType _x == 'o_support'};
    _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
    _FOBMrk setMarkerColor 'colorOPFOR';
    _attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
    [[west,'HQ'], 'Friendly Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];
    "
];

[_thisOutpostTrigger, 200] execVM "Scripts\INTLitems.sqf";

sleep 2;