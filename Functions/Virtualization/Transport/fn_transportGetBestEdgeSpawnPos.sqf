/*
 * Function: FLO_fnc_transportGetBestEdgeSpawnPos
 */

params [["_preferredEdge", "", [""]]];

private _edgePositions = call FLO_fnc_transportGetMapEdgePositions;
if (count _edgePositions == 0) exitWith { [0,0,0] };

if (_preferredEdge != "") then {
    private _filtered = _edgePositions select { (_x select 1) == _preferredEdge };
    if (count _filtered > 0) then {
        _edgePositions = _filtered;
    };
};

call FLO_fnc_virtualizationCachePlayers;
private _playerPositions = FLO_VirtUpdate get "cachedPlayerPositions";

private _bestPos = [];
private _bestDist = -1;

{
    _x params ["_pos"];
    private _minPlayerDist = if (count _playerPositions == 0) then {
        999999
    } else {
        private _minDist = 999999;
        {
            private _dist = _pos distance2D _x;
            if (_dist < _minDist) then {
                _minDist = _dist;
            };
        } forEach _playerPositions;
        _minDist
    };

    if (_minPlayerDist > _bestDist) then {
        _bestDist = _minPlayerDist;
        _bestPos = _pos;
    };
} forEach _edgePositions;

if (count _bestPos == 0) then {
    _bestPos = (_edgePositions select 0) select 0;
};

_bestPos
