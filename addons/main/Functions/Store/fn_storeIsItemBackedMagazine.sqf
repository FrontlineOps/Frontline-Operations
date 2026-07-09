params ["_cfg"];

private _isMedicalItem = (getNumber (_cfg >> "ACE_isMedicalItem")) isEqualTo 1;
private _isItemBackedMagazine = (getNumber (_cfg >> "ACE_asItem")) isEqualTo 1;

if (_isMedicalItem || {_isItemBackedMagazine}) exitWith { true };

private _ammo = getText (_cfg >> "ammo");
private _count = getNumber (_cfg >> "count");
private _initSpeed = getNumber (_cfg >> "initSpeed");
private _tracersEvery = getNumber (_cfg >> "tracersEvery");
private _lastRoundsTracer = getNumber (_cfg >> "lastRoundsTracer");

(_ammo isEqualTo "") &&
{_count > 0} &&
{_initSpeed isEqualTo 0} &&
{_tracersEvery isEqualTo 0} &&
{_lastRoundsTracer isEqualTo 0}
