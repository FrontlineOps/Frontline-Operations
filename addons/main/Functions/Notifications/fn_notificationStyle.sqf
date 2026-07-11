params [["_type", "info", [""]]];

_type = toLower _type;
if !(_type in ["info", "intel", "success", "warning", "error"]) then {
    throw format ["Unsupported notification type %1", _type];
};

switch _type do {
    case "success": {
        createHashMapFromArray [
            ["label", "READY"],
            ["accent", [0.65, 1, 0.35, 1]],
            ["accentHtml", "#A7FF5A"],
            ["background", [0.05, 0.12, 0.09, 0.86]]
        ]
    };
    case "warning": {
        createHashMapFromArray [
            ["label", "CAUTION"],
            ["accent", [1, 0.72, 0.29, 1]],
            ["accentHtml", "#FFB84A"],
            ["background", [0.14, 0.10, 0.04, 0.88]]
        ]
    };
    case "error": {
        createHashMapFromArray [
            ["label", "DENIED"],
            ["accent", [1, 0.30, 0.37, 1]],
            ["accentHtml", "#FF4D5E"],
            ["background", [0.15, 0.04, 0.06, 0.90]]
        ]
    };
    case "intel": {
        createHashMapFromArray [
            ["label", "INTEL"],
            ["accent", [0.15, 0.84, 1, 1]],
            ["accentHtml", "#25D7FF"],
            ["background", [0.03, 0.08, 0.13, 0.90]]
        ]
    };
    default {
        createHashMapFromArray [
            ["label", "INFO"],
            ["accent", [0.15, 0.84, 1, 1]],
            ["accentHtml", "#25D7FF"],
            ["background", [0.05, 0.09, 0.13, 0.86]]
        ]
    };
}
