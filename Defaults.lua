local addonName, ns = ...

ns.Constants = {
    SCHEMA_VERSION = 2,
    MAIN_HAND_SLOT = 16,
    OFF_HAND_SLOT = 17,
    BUTTON_SIZE = 48,
    BUTTON_GAP = 5,
    UPDATE_INTERVAL = 0.2,
    SECURE_MAIN_NAME = "SimplePoisonsMainHandButton",
    SECURE_OFF_NAME = "SimplePoisonsOffHandButton",
}

ns.Defaults = {
    schemaVersion = ns.Constants.SCHEMA_VERSION,
    clicks = {
        LeftButton = "instant",
        RightButton = "deadly",
        MiddleButton = "crippling",
    },
    lowMinutes = 3,
    lowCharges = 10,
    scale = 1.0,
    textSize = 13,
    orientation = "HORIZONTAL",
    showMinimap = true,
    minimapAngle = 225,
    position = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = -150,
    },
}

ns.Ranges = {
    lowMinutes = { min = 1, max = 30 },
    lowCharges = { min = 1, max = 60 },
    scale = { min = 0.6, max = 1.6 },
    textSize = { min = 9, max = 18 },
}
