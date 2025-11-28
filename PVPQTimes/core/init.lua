local ADDON_NAME, NS = ...

--------------------------------------------------
-- SavedVariables root (account-wide)
--------------------------------------------------
PVPQTimesDB = PVPQTimesDB or {}
NS.db = PVPQTimesDB

--------------------------------------------------
-- Constants
--------------------------------------------------
NS.FONT_SIZE   = 12
NS.FONT_FLAGS  = "OUTLINE"
NS.PADDING_X   = 20
NS.PADDING_Y   = 12
NS.COLOR_GREY  = "|cff9d9d9d"
NS.HINT_TEXT   = "|cff888888Click + Drag me|r"

--------------------------------------------------
-- MMR tracking: which brackets we care about
-- 6 = Rated Solo Shuffle
-- 8 = Rated Battleground Blitz
--------------------------------------------------
NS.TRACKED_MMR_BRACKETS = {
    [6] = true,   -- Solo Shuffle
    [8] = true,   -- Blitz
}

--------------------------------------------------
-- Pretty names for queue name display
--------------------------------------------------
NS.PRETTY_NAMES = {
    ["Solo Shuffle: All Arenas"] = "Solo Shuffle: Arena",
    ["Rated Battleground Blitz"] = "Battleground Blitz",
    ["Random Epic Battleground"] = "Random Epic BG",
    ["Random Battleground"] = "Random BG",
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

--  QPopCV URL (PermaLink Discord Server)
NS.QPOPCV_LINK  = "https://discord.gg/KpupS6N3Zj"
