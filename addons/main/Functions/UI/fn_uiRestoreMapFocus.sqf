/* Return input to a visible native map without reopening a hidden guide map. */
params ["_map"];
if (isNull _map || {!ctrlShown _map}) exitWith { false };
_map ctrlSetFade 0;
_map ctrlCommit 0;
ctrlSetFocus _map;
true
