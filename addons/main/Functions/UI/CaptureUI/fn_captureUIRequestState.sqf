/* Requests the local player's current Capture state from the server. */
if (!hasInterface || {isNull player} || {!FLO_ClientUiReady}) exitWith { false };

[player] remoteExecCall ["FLO_fnc_captureUIRequestStateServer", 2];
true
