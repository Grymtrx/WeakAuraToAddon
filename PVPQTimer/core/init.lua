local ADDON_NAME, NS = ...
--------------------------------------------------
-- SavedVariables root
--  - PVPQTimerDB: single account-wide DB
--      * global  -> UI layout, config
--      * chars   -> per-character MMR etc.
--------------------------------------------------
PVPQTimerDB = PVPQTimerDB or {}
NS.db = PVPQTimerDB

-- Global/settings section (account-wide)
NS.db.global = NS.db.global or {}
NS.global    = NS.db.global

-- Per-character data root (MMR etc.)
NS.db.chars = NS.db.chars or {}

--------------------------------------------------
-- Constants
--------------------------------------------------
NS.global.fontSize = NS.global.fontSize or 12
NS.FONT_SIZE   = NS.global.fontSize -- options.lua
NS.FONT_FLAGS  = "OUTLINE"
NS.PADDING_X   = 20
NS.PADDING_Y   = 12
NS.COLOR_GREY  = "|cff9d9d9d"
NS.HINT_TEXT   = "|cff888888Click + Drag me|r"

--------------------------------------------------
-- MMR tracking: brackets we care about
--------------------------------------------------
NS.TRACKED_MMR_BRACKETS = {
    [6] = true,   -- Solo Shuffle
    [8] = true,   -- Rated Battleground Blitz
}

-- Logical names for our brackets
NS.BRACKET_SOLO  = "SOLO_SHUFFLE"
NS.BRACKET_BLITZ = "BLITZ"

--------------------------------------------------
-- Pretty names for queue name display
--------------------------------------------------
NS.PRETTY_NAMES = {
    ["Solo Shuffle: All Arenas"]      = "Solo Shuffle: Arena",
    ["Rated Battleground Blitz"]      = "Battleground Blitz",
    ["Random Epic Battleground"]      = "Random Epic BG",
    ["Random Battleground"]           = "Random BG",
    ["Brawl: Southshore vs. Tarren Mill"] = "Brawl: SS vs TM",
}

--------------------------------------------------
-- Map queue names -> PvP bracket IDs
--------------------------------------------------
NS.BRACKET_BY_QUEUE_NAME = {
    ["Solo Shuffle: All Arenas"] = 6,
    ["Rated Battleground Blitz"] = 8,
}

--------------------------------------------------
-- Runtime state
--------------------------------------------------
NS.baseText     = ""      -- text without hover hint
NS.hasQueues    = false   -- do we currently have active queues?
NS.missedQueue  = false   -- set when we detect a missed / expired queue
