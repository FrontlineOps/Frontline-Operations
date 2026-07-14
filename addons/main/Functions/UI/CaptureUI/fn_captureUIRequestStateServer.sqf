/* Replays authoritative Capture visibility/state to an owner-validated client. */
params [["_requester", objNull, [objNull]]];

if (!isServer) exitWith { false };
if (isNull _requester || {!isPlayer _requester}) exitWith {
    ["UI", 2, "Rejected Capture UI state request without a player requester"] call FLO_fnc_log;
    false
};
if (remoteExecutedOwner != owner _requester) exitWith {
    ["UI", 2, format [
        "Rejected Capture UI state request: caller owner %1 does not own requester %2",
        remoteExecutedOwner,
        owner _requester
    ]] call FLO_fnc_log;
    false
};
if !((side group _requester) in [west, east]) exitWith {
    ["UI", 2, "Rejected Capture UI state request from a non-campaign side"] call FLO_fnc_log;
    false
};

if (isNil "FLO_Objectives" || {isNil "FLO_PlayerObjectiveStates"}) then {
    private _message = "Capture UI state request reached the server before objective monitor ownership initialized";
    ["UI", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _match = [_requester, keys FLO_Objectives] call FLO_fnc_captureUIResolvePlayerObjective;
[_requester, _match, true] call FLO_fnc_captureUIPublishPlayerState
