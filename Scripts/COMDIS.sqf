sleep 16 ;


COMMSDIS = 1;
publicVariable "COMMSDIS";

["showNotification", ["SUPPORT DISABLED", "Enemy Communications Disabled For the Next Hour", "success"]] call FLO_fnc_intelSystem;

sleep 3600 ;

COMMSDIS = 0;
publicVariable "COMMSDIS";