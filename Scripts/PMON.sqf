

/*
	Title: FPS Monitoring Script
	Author: Dylan Plecki (Naught)
	Version: 1.0.2.1 - v1.0 RC b1
	
	Description:
		Monitors and displays FPS of the server and clients on
		a regular interval with a silent hint in this format:
			Local FPS: minFPS - avgFPS
			Server FPS: minFPS - avgFPS / count
			Headless FPS: avgMinFPS - avgAvgFPS / count
			Client FPS: avgMinFPS - avgAvgFPS / count
		This script can be loaded and executed on any machine,
		without a need to install anything on the others.
	
	Syntax:
		call FPSMON_fnc_monitor; // Turns off script
		delayInt call FPSMON_fnc_monitor; // Turns on/off script with delay
		[delayInt] call FPSMON_fnc_monitor; // Turns on/off script with delay
		
	Requirements:
		Arma 3 1.0
		Arma 2 OA 1.62
		CBA A2/OA/A3 1.0
	
	License:
		Copyright � 2013 Dylan Plecki. All rights reserved.
		Except where otherwise noted, this work is licensed under CC BY 4.0,
		available for reference at <http://creativecommons.org/licenses/by/4.0/>.
*/

FPSMON_fnc_monitor = {
	_this spawn {
		if (isNil "_this") then {_this = []};
		if (typeName(_this) != "ARRAY") then {_this = [_this]};
		private ["_delay","_syncTime"];
		_delay	= if ((count _this) > 0) then {_this select 0} else {0};
		_syncTime = 3; // Seconds
		if (_delay >= _syncTime) then {_delay = _delay - _syncTime};
		if (isNil "FPSMON_init") then {
			FPSMON_init = true;
			FPSMON_clientID = nil;
			FPSMON_syncData = [-1,0,0];
			[0, {
				FPSMON_clientID = owner _this;
				FPSMON_clientID publicVariableClient "FPSMON_clientID";
			}, player] call CBA_fnc_globalExecute;
			waitUntil {!isNil "FPSMON_clientID"};
			"FPSMON_syncData" addPublicVariableEventHandler {
				private ["_value", "_machine", "_avgFPS", "_minFPS"];
				_value = _this select 1;
				_machine = _value select 0;
				_avgFPS = _value select 1;
				_minFPS = _value select 2;
				if ((_machine >= 0) && {_machine < (count FPSMON_data)}) then {
					(FPSMON_data select _machine) set [0, (((FPSMON_data select _machine) select 0) + _avgFPS)];
					(FPSMON_data select _machine) set [1, (((FPSMON_data select _machine) select 1) + _minFPS)];
					(FPSMON_data select _machine) set [2, (((FPSMON_data select _machine) select 2) + 1)];
				};
			};
		};
		if ((_delay > 0) && (isNil "FPSMON_handle")) then {
			FPSMON_handle = [_syncTime, _delay] spawn {
				waitUntil {
					FPSMON_data = [[0,0,0],[0,0,0],[0,0,0]]; // Clear Data
					[-2, {
						if (isNil "FPSMON_MACHINE") then {
							FPSMON_MACHINE = switch (true) do {
								case (isServer): {0};
								case (!hasInterface && !isDedicated): {1};
								default {2};
							};
						};
						FPSMON_syncData = [FPSMON_MACHINE, diag_fps, diag_fpsmin];
						(_this select 0) publicVariableClient "FPSMON_syncData";
					}, [FPSMON_clientID]] call CBA_fnc_globalExecute;
					uisleep (_this select 0); // Sync Time
					private ["_output"];
					_output = [];
					{ // forEach
						_output = _output + [
							round((_x select 1) / ((_x select 2) max (1))),
							round((_x select 0) / ((_x select 2) max (1))),
							(_x select 2)
						];
					} forEach FPSMON_data;
					hintSilent format (["Local FPS: %1 - %2\nServer FPS: %3 - %4 / %5\nHeadless FPS: %6 - %7 / %8\nClient FPS: %9 - %10 / %11",
						round(diag_fpsmin),
						round(diag_fps)
					] + _output);
					uisleep (_this select 1); // Delay
					false;
				};
			};
			hint format["FPS Monitoring Started.\n%1 Second Interval.", (_delay + _syncTime)];
		} else {
			terminate FPSMON_handle;
			FPSMON_handle = nil;
			hint "FPS Monitoring Stopped.";
		};
	};
};