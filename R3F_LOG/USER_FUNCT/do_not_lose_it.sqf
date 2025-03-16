/**
 * Execute this script to prevent the object to be lost during the mission.
 * Useful for mandatory objects like a flag pole with addAction.
 * It must be executed from the initialisation line or at any other time on the server and all clients.
 * 
 * The script does :
 *     It makes the object indestructible (from any kind of damage).
 *     It denies the ability to send/sell back the object to any creation factory (if applicable).
 *     If the object is loaded in a vehicle/cargo which has been destroyed, it will be unloaded/teleported to a given position.
 *     If the object was lifted to a crashed helicopter, it will be detached/teleported to a given position.
 *     If the object was towed to a destroyed vehicle, it will be untowed/teleported to a given position.
 * 
 * @param 0 the object to protect and to not lose
 * @param 1 (optional) choose where to restore the object if destroyed in transport cargo (default : "spawn_pos")
 *              set to "spawn_pos" to teleport the object on its initial spawn position
 *              set to "exact_spawn_pos" to teleport the object on its exact initial spawn position and direction (no collision check)
 *              set to "cargo_pos" to unload the object around the destroyed cargo
 *              set to any marker name to teleport the object to the marker position
 * 
 * @usage nul = [my_object] execVM "R3F_LOG\USER_FUNCT\do_not_lose_it.sqf";
 * @usage nul = [my_object, "spawn_pos"] execVM "R3F_LOG\USER_FUNCT\do_not_lose_it.sqf";
 * @usage nul = [my_object, "cargo_pos"] execVM "R3F_LOG\USER_FUNCT\do_not_lose_it.sqf";
 * @usage nul = [my_object, "<marker name>"] execVM "R3F_LOG\USER_FUNCT\do_not_lose_it.sqf";
 * 
 * @usage You can replace "my_object" by "this" if you put the line in the initialization line in the mission editor.
 */

private ["_objet", "_pos_respawn"];

_objet = _this select 0;
_pos_respawn = if (count _this > 1) then {_this select 1} else {"spawn_pos"};

if (!isNull _objet) then
{
	waitUntil {!isNil "R3F_LOG_active"};
	
	if (R3F_LOG_active) then
	{
		_objet addEventHandler ["HandleDamage", {0}];
		
		if (isServer) then
		{
			// Attendre le mutex
			waitUntil
			{
				if (R3F_LOG_mutex_local_verrou) then
				{
					false
				}
				else
				{
					R3F_LOG_mutex_local_verrou = true;
					true
				}
			};
			
			R3F_LOG_liste_objets_a_proteger pushBack _objet;
			
			R3F_LOG_mutex_local_verrou = false;
			
			if (_pos_respawn == "spawn_pos" || _pos_respawn == "exact_spawn_pos") then
			{
				_objet setVariable ["R3F_LOG_pos_respawn", getPosASL _objet, false];
				
				if (_pos_respawn == "exact_spawn_pos") then
				{
					_objet setVariable ["R3F_LOG_dir_respawn", getDir _objet, false];
				};
			}
			else
			{
				_objet setVariable ["R3F_LOG_pos_respawn", _pos_respawn, false];
			};
		};
	};
};