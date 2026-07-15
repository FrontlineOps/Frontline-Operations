FLO_StoreDialogIdd = 9800;
FLO_StoreBrowserIdc = 9801;
FLO_StoreKitsDialogIdd = 9810;
FLO_StoreKitsBrowserIdc = 9811;
FLO_StoreActiveBaseNetId = "";
FLO_StoreCatalogCache = createHashMap;
FLO_StorePlaceableMagazineCache = createHashMap;
FLO_StorePlaceableMagazineCacheReady = false;
FLO_StoreCheckoutSequence = 0;
FLO_StoreOptionalModDefinitions = [
    ["ACE", "ace_"],
    ["KAT", "kat_"],
    ["ACM", "acm_"]
];
FLO_StoreOptionalModIndex = [] call FLO_fnc_storeBuildOptionalModIndex;
FLO_StoreSupportCatalogCache = createHashMapFromArray [
    ["ready", false],
    ["items", []],
    ["counts", createHashMap]
];

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

FLO_StoreSupportCatalogItems = [
    ["FirstAidKit", "gear", "misc"],
    ["Medikit", "gear", "misc"],
    ["ItemGPS", "gear", "misc"],

    ["ACE_adenosine", "gear", "misc"],
    ["ACE_atropine", "gear", "misc"],
    ["ACE_bloodIV", "gear", "misc"],
    ["ACE_bloodIV_250", "gear", "misc"],
    ["ACE_bloodIV_500", "gear", "misc"],
    ["ACE_bodyBag", "gear", "misc"],
    ["ACE_EarPlugs", "gear", "misc"],
    ["ACE_elasticBandage", "gear", "misc"],
    ["ACE_epinephrine", "gear", "misc"],
    ["ACE_fieldDressing", "gear", "misc"],
    ["ACE_MapTools", "gear", "misc"],
    ["ACE_microDAGR", "gear", "misc"],
    ["ACE_morphine", "gear", "misc"],
    ["ACE_packingBandage", "gear", "misc"],
    ["ACE_personalAidKit", "gear", "misc"],
    ["ACE_plasmaIV", "gear", "misc"],
    ["ACE_plasmaIV_250", "gear", "misc"],
    ["ACE_plasmaIV_500", "gear", "misc"],
    ["ACE_quikclot", "gear", "misc"],
    ["ACE_RangeCard", "gear", "misc"],
    ["ACE_salineIV", "gear", "misc"],
    ["ACE_salineIV_250", "gear", "misc"],
    ["ACE_salineIV_500", "gear", "misc"],
    ["ACE_splint", "gear", "misc"],
    ["ACE_surgicalKit", "gear", "misc"],
    ["ACE_tourniquet", "gear", "misc"],

    ["TFAR_anprc152", "gear", "misc"],
    ["TFAR_rf7800str", "gear", "misc"],
    ["TFAR_anprc148jem", "gear", "misc"],
    ["TFAR_fadak", "gear", "misc"],
    ["TFAR_pnr1000a", "gear", "misc"],
    ["TFAR_anprc154", "gear", "misc"],
    ["TFAR_rt1523g", "gear", "backpacks"],
    ["TFAR_rt1523g_big", "gear", "backpacks"],
    ["TFAR_rt1523g_black", "gear", "backpacks"],
    ["TFAR_rt1523g_fabric", "gear", "backpacks"],
    ["TFAR_rt1523g_green", "gear", "backpacks"],
    ["TFAR_rt1523g_rhs", "gear", "backpacks"],
    ["TFAR_rt1523g_sage", "gear", "backpacks"],
    ["TFAR_anprc155", "gear", "backpacks"],
    ["TFAR_anprc155_coyote", "gear", "backpacks"],
    ["TFAR_mr3000", "gear", "backpacks"],
    ["TFAR_mr3000_multicam", "gear", "backpacks"],
    ["TFAR_mr3000_rhs", "gear", "backpacks"]
];
