/* Moves one human lobby unit into its configured campaign-side group. */
params [["_unit", objNull, [objNull]]];

if (!isServer) exitWith { false };

if !(FLO_ActivePlayerSide in [east, west]) then {
    ["INIT", 1, "Player-side adapter has no valid configured campaign side"] call FLO_fnc_log;
    throw "Player-side adapter has no valid configured campaign side";
};
if (isNull _unit || {!isPlayer _unit}) then {
    ["INIT", 1, "Player-side adapter received a non-player unit"] call FLO_fnc_log;
    throw "Player-side adapter received a non-player unit";
};

private _sourceGroup = group _unit;
private _sourceSide = side _sourceGroup;
if (_sourceSide == FLO_ActivePlayerSide) exitWith { false };

private _sourceGroupKey = format ["%1:%2", [_sourceSide] call FLO_fnc_sideKey, str _sourceGroup];
private _targetGroup = grpNull;
if (_sourceGroupKey in FLO_PlayerSideAdapterGroups) then {
    _targetGroup = FLO_PlayerSideAdapterGroups get _sourceGroupKey;
};

if (isNull _targetGroup) then {
    _targetGroup = createGroup [FLO_ActivePlayerSide, false];
    FLO_PlayerSideAdapterGroups set [_sourceGroupKey, _targetGroup];
};

[_unit] joinSilent _targetGroup;
if ((side group _unit) != FLO_ActivePlayerSide) then {
    ["INIT", 1, format [
        "Failed to adapt human slot from %1 to %2",
        [_sourceSide] call FLO_fnc_sideKey,
        [FLO_ActivePlayerSide] call FLO_fnc_sideKey
    ]] call FLO_fnc_log;
    throw "Player-side adapter failed to change the human unit group side";
};

["INIT", 3, format [
    "Adapted human lobby group %1 from %2 to %3",
    _sourceGroupKey,
    [_sourceSide] call FLO_fnc_sideKey,
    [FLO_ActivePlayerSide] call FLO_fnc_sideKey
]] call FLO_fnc_log;

true
