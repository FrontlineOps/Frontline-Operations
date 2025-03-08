sleep 16 ;


COMMSDIS = 1;
publicVariable "COMMSDIS";

FLO_Intel_System call ["showNotification", ["SUPPORT DISABLED", "Enemy Communications Disabled For the Next Hour", "success"]];

sleep 3600 ;

COMMSDIS = 0;
publicVariable "COMMSDIS";