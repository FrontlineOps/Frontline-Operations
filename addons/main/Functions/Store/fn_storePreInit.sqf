FLO_StoreDialogIdd = 9800;
FLO_StoreBrowserIdc = 9801;
FLO_StoreActiveBaseNetId = "";
FLO_StoreCatalogCache = createHashMap;
FLO_StorePlaceableMagazineCache = createHashMap;
FLO_StorePlaceableMagazineCacheReady = false;
FLO_StoreCheckoutSequence = 0;
FLO_StoreSavedKitsCurrentSchemaVersion = 1;

FLO_StoreSupplyShipmentClass = "FLO_SUPPLY_SHIPMENT";
FLO_StoreSupplyShipmentCost = 300;

FLO_StoreCategories = [
    ["primary", "Primary"],
    ["handgun", "Handgun"],
    ["secondary", "Launchers"],
    ["uniforms", "Uniforms"],
    ["vests", "Vests"],
    ["headgear", "Headgear"],
    ["facewear", "Facewear"],
    ["backpacks", "Backpacks"],
    ["ammo", "Ammo"],
    ["mines", "Mines"],
    ["misc", "Items"],
    ["cars", "Cars"],
    ["armor", "Armor"],
    ["helis", "Helicopters"],
    ["planes", "Planes"],
    ["naval", "Naval"],
    ["static", "Statics"],
    ["other", "Other"],
    ["recruits", "Recruit AI"],
    ["logistics", "Logistics"]
];

FLO_StoreCatalogCategories = FLO_StoreCategories + [
    ["attachments", "Attachments"]
];

FLO_StoreGearCategories = [
    "primary",
    "handgun",
    "secondary",
    "uniforms",
    "vests",
    "headgear",
    "facewear",
    "backpacks",
    "attachments",
    "ammo",
    "mines",
    "misc"
];

FLO_StoreVehicleCategories = [
    "cars",
    "armor",
    "helis",
    "planes",
    "naval",
    "static",
    "other"
];

FLO_StoreGearContainers = [
    "auto",
    "uniform",
    "vest",
    "backpack"
];

FLO_StoreFreeItemClasses = [
    "ace_earplugs",
    "ace_elasticbandage",
    "ace_fielddressing",
    "ace_packingbandage",
    "ace_quikclot",
    "ace_splint",
    "ace_tourniquet"
];

FLO_StoreRuntimeRadioBaseClasses = [
    "TFAR_anprc152",
    "TFAR_rf7800str",
    "TFAR_anprc148jem",
    "TFAR_fadak",
    "TFAR_pnr1000a",
    "TFAR_anprc154",
    "TFAR_rt1523g",
    "TFAR_rt1523g_big",
    "TFAR_rt1523g_black",
    "TFAR_rt1523g_fabric",
    "TFAR_rt1523g_green",
    "TFAR_rt1523g_rhs",
    "TFAR_rt1523g_sage",
    "TFAR_anprc155",
    "TFAR_anprc155_coyote",
    "TFAR_mr3000",
    "TFAR_mr3000_multicam",
    "TFAR_mr3000_rhs"
];
