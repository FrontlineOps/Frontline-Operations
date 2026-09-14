/* The local single-player/host player owns the campaign. Remote players need
   server-admin authority; caller identity is checked by saveRequest. */
params ["_requester"];
if (isNull _requester) exitWith { false };
if (isServer && {hasInterface} && {_requester isEqualTo player}) exitWith { true };
(admin (owner _requester)) > 0
