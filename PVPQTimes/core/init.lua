local ADDON_NAME, NS = ...

-- Global DB
PVPQTimesDB = PVPQTimesDB or {}
NS.db = PVPQTimesDB

-- Constants
NS.FONT_SIZE   = 12
NS.FONT_FLAGS  = "OUTLINE"
NS.PADDING_X   = 20
NS.PADDING_Y   = 12
NS.COLOR_GREY  = "|cff9d9d9d"
NS.HINT_TEXT   = "|cff888888Click + Drag me|r"

-- Track ONLY these MMR brackets
NS.TRACKED_MMR_BRACKETS = {
    [6] = true,  -- Shuffle
    [8] = true,  -- Blitz
}

-- Pretty names
NS.PRETTY_NAMES = {
    ["Solo Shuffle: All Arenas"] = "Solo Shuffle: Arena",
    ["Rated Battleground Blitz"] = "Battleground Blitz",
    ["Random Epic Battleground"] = "Random Epic BG",
    ["Random Battleground"] = "Random BG",
    ["Brawl: Southshore vs. Tarren Mill"] = "Brawl: SS vs TM",
}

NS.BRACKET_BY_QUEUE_NAME = {
    ["Solo Shuffle: All Arenas"] = 6,
    ["Rated Battleground Blitz"] = 8,
}

NS.baseText  = ""   -- text without hover hint
NS.hasQueues = false