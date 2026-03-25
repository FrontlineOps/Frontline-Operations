/*
 * Function: FLO_fnc_virtualizationUpdateGroupPosition
 */

params ["_virt", "_groupId", "_newPosition"];

private _groupData = (_virt get "_groups") get _groupId;
if (isNil "_groupData") exitWith { false };
if ((_newPosition select 0) <= 100 && (_newPosition select 1) <= 100) exitWith { false };

private _oldPosition = _groupData get "position";
private _groupType = _groupData get "groupType";
private _side = _groupData get "side";
private _trackCombatSeed = (_side in [east, west])
    && {([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) == ""}
    && {_groupType in ["infantry", "motorized", "mechanized", "armor", "mobile_aa"]};
private _seedCellSize = if (isNil "FLO_GTN_CombatState") then { 150 } else { FLO_GTN_CombatState get "classificationSeedCellSize" };

_groupData set ["position", _newPosition];
[_groupId, _newPosition, _side] call FLO_fnc_virtualizationSpatialUpdate;

if (_trackCombatSeed) then {
    private _oldSeedCellKey = format [
        "%1_%2",
        floor ((_oldPosition select 0) / _seedCellSize),
        floor ((_oldPosition select 1) / _seedCellSize)
    ];
    private _newSeedCellKey = format [
        "%1_%2",
        floor ((_newPosition select 0) / _seedCellSize),
        floor ((_newPosition select 1) / _seedCellSize)
    ];
    if (_oldSeedCellKey != _newSeedCellKey) then {
        [false] call FLO_fnc_gtnCombatMarkClassificationDirty;
    };
};

true
