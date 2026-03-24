/*
 * Function: FLO_fnc_virtualizationProcessAttachedGroup
 */

params ["_groupId", "_groupData", "_virtStats"];

private _attachedTo = [_groupData] call FLO_fnc_virtualizationGetTransportAttachment;
if (_attachedTo == "") exitWith { false };

private _transportData = (FLO_virtualGroups get "_groups") get _attachedTo;
private _transportPos = _transportData get "position";
[FLO_virtualGroups, _groupId, _transportPos] call FLO_fnc_virtualizationUpdateGroupPosition;

_virtStats set ["attachedSyncsTotal", (_virtStats get "attachedSyncsTotal") + 1];
_virtStats set ["attachedSyncsThisBatch", (_virtStats get "attachedSyncsThisBatch") + 1];

true
