/* Initializes persistent formation state after GTN commanders exist. */
params [
    "_state",
    "_director",
    "_resourceManager"
];

if (!isServer) exitWith { false };
if ((keys FLO_GTN_CommandersBySide) isEqualTo []) then {
    throw "Formation initialization requires side commanders";
};
[_state] call FLO_fnc_formationValidateState;
FLO_FormationState = _state;
FLO_FormationDirector = _director;
FLO_FormationResourceManager = _resourceManager;
FLO_FormationReconcileDirty = true;

[_state] call FLO_fnc_formationReconcile;
[(_director call ["_getState", []])] call FLO_fnc_campaignValidateProbeOwnership;
if ((_state get "lastDoctrineUpdateAtDateNum") < 0) then {
    [_state, "WEST"] call FLO_fnc_formationSelectDoctrine;
    [_state, "EAST"] call FLO_fnc_formationSelectDoctrine;
};
call FLO_fnc_formationRegisterEvents;

if (isNil "FLO_FormationPFH") then { FLO_FormationPFH = -1; };
if (FLO_FormationPFH < 0) then {
    FLO_FormationPFH = [{
        call FLO_fnc_formationUpdate;
    }, 30] call CBA_fnc_addPerFrameHandler;
};

["FORMATIONS", 3, format ["Formation system ready with %1 formations", count (keys (_state get "formations"))]] call FLO_fnc_log;
true
