class IDS_Logistics {
    tag = "IDS_Logistics";
    class Functions {
        file = "IDS_Logistics\functions";

        class getEntityConfig {};
        class initLogistics {};
        class pickupEntity {};
        class placeEntity {};
        class startPlacement {};
        class updateEntityPlacement {};
    };

    class Server {
        file = "IDS_Logistics\functions\server";

        class createEntity {};
        class finalizeEntity {};
        class onEntityKilled {};
        class saveEntities {};
        class toggleEntityVisibility {};
    };

    class UI {
        file = "IDS_Logistics\functions\ui";

        class handlePreview {};
        class openBuildMenu {};
        class searchEntities {};
        class selectEntity {};
        class updateEntityList {};
        class updatePreview {};
    };
};