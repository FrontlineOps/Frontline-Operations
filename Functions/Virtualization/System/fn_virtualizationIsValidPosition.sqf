/*
 * Function: FLO_fnc_virtualizationIsValidPosition
 */

params ["_pos"];

(_pos isEqualType []) &&
{count _pos >= 2} &&
{((_pos select 0) > 100) || {(_pos select 1) > 100}}
