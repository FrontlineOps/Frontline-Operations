/*
 * Function: FLO_fnc_gtnBuildFriendlySupplyNodeMarkers
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds commander COP support markers for the maintained friendly logistics
 *   supply chain. These markers are player-facing and intentionally limited to
 *   the elected HQ and active supply nodes.
 *
 * Arguments:
 *   0: GTN world state <HASHMAPOBJECT>
 *
 * Return Value:
 *   ARRAY - Generic marker records
 */

params [["_worldState", nil]];

if (isNil "_worldState") exitWith { [] };

private _sideKey = _worldState get "_sideKey";
private _ownSide = _worldState get "_ownSide";
private _friendlyColor = if (_ownSide isEqualTo east) then { "ColorOPFOR" } else { "ColorBLUFOR" };
private _hqMarkerType = if (_ownSide isEqualTo east) then { "o_hq" } else { "b_hq" };
private _net = FLO_Logistics_Networks get _sideKey;
private _hqObjectiveId = _net get "_hqObjectiveId";
private _activeNodes = _net get "_activeSupplyNodes";
private _markers = [];

if (_hqObjectiveId != "") then {
    private _hqObjective = FLO_Objectives get _hqObjectiveId;
    _markers pushBack [
        format ["FLO_GTN_INTEL_%1_SUP_LOG_HQ", _sideKey],
        "ICON",
        _hqObjective get "position",
        _hqMarkerType,
        [0.75, 0.75],
        0.85,
        "SUP HQ",
        _friendlyColor,
        ""
    ];
};

{
    private _objectiveId = _x;
    if (_objectiveId == _hqObjectiveId) then { continue };

    private _nodeInfo = _activeNodes get _objectiveId;
    private _objective = FLO_Objectives get _objectiveId;

    _markers pushBack [
        format ["FLO_GTN_INTEL_%1_SUP_LOG_NODE_%2", _sideKey, _objectiveId],
        "ICON",
        _objective get "position",
        "mil_box",
        [0.55, 0.55],
        0.7,
        format ["SUP d%1", _nodeInfo get "depth"],
        _friendlyColor,
        ""
    ];
} forEach (keys _activeNodes);

_markers
