/*
 * Function: FLO_fnc_gtnSelectBestReserveGroupForTrack
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Select the best available reserve group for an attack track. Reserve-band
 * locality is preferred first, then distance to the track anchor.
 *
 * Arguments:
 * 0: Track <HASHMAP>
 * 1: Candidate Group IDs <ARRAY>
 * 2: Group Map <HASHMAP>
 * 3: Reserve Bands <HASHMAP>
 * 4: Fallback Band <NUMBER>
 *
 * Return Value:
 * [Group ID, Band, Distance] <ARRAY>
 */

params [
    ["_track", nil],
    ["_candidateGroupIds", [], [[]]],
    ["_groups", createHashMap, [createHashMap]],
    ["_reserveBands", createHashMap, [createHashMap]],
    ["_fallbackBand", 0, [0]]
];

private _bestGroupId = "";
private _bestBand = 1e12;
private _bestDist = 1e12;

if (isNil "_track" || {(count _candidateGroupIds) == 0}) exitWith {
    [_bestGroupId, _bestBand, _bestDist]
};

private _anchorPos = +(_track get "frontSectorAnchorPos");

{
    private _groupId = _x;
    private _gData = _groups get _groupId;
    if (isNil "_gData") then { continue };
    if !((_gData get "groupType") in ["infantry", "recon", "motorized", "mechanized", "armor"]) then { continue };

    private _groupPos = _gData get "position";
    private _homeObjective = _gData get "homeObjective";
    private _band = _fallbackBand;
    if (_homeObjective != "" && {_homeObjective in _reserveBands}) then {
        _band = _reserveBands get _homeObjective;
    };

    private _dist = if ((count _anchorPos) >= 2) then {
        _groupPos distance2D _anchorPos
    } else {
        1e12
    };

    if (
        _bestGroupId == ""
        || { _band < _bestBand }
        || { _band == _bestBand && { _dist < _bestDist } }
    ) then {
        _bestGroupId = _groupId;
        _bestBand = _band;
        _bestDist = _dist;
    };
} forEach _candidateGroupIds;

[_bestGroupId, _bestBand, _bestDist]
