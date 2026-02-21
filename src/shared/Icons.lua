--[[
    Icons Library
    Centralized icon management for the entire UI
    
    HOW TO USE:
    local Icons = require(ReplicatedStorage.Shared.Icons)
    Text = Icons.Get("inventory")  -- Returns emoji or image
    
    HOW TO ADD YOUR OWN ICONS:
    1. Upload PNG images to Roblox (Asset Manager or create.roblox.com)
    2. Replace "rbxassetid://0" with your asset ID
    3. Set Icons.USE_IMAGES = true
]]

local Icons = {}

-- Set to true when you have uploaded your own icon images
Icons.USE_IMAGES = true

--[[
    TEXT/EMOJI ICONS (Default - always works)
    These are used when USE_IMAGES = false
]]
Icons.Text = {
    -- ============ SIDEBAR ============
    inventory = "📦",
    shop = "🛒",
    music = "🎵",
    friends = "👥",
    stats = "📊",
    settings = "⚙",
    emotes = "🎭",
    
    -- ============ TOP RIGHT STATUS ============
    notification = "🔔",
    donate = "💝",
    profile = "👤",
    coin = "💰",
    
    -- ============ PLAYER DROPDOWN ============
    viewProfile = "👤",
    addFriend = "➕",
    trade = "🔄",
    teleport = "📍",
    
    -- ============ MUSIC PLAYER ============
    play = "▶",
    pause = "⏸",
    next = "⏭",
    previous = "⏮",
    volume = "🔊",
    volumeMute = "🔇",
    musicNote = "🎵",
    
    -- ============ FRIENDS VIEW ============
    invite = "📨",
    online = "🟢",
    offline = "⚫",
    
    -- ============ INVENTORY ============
    backpack = "🎒",
    item = "📦",
    equip = "✅",
    unequip = "❌",
    
    -- ============ SHOP ============
    buy = "💳",
    cart = "🛒",
    sale = "🏷️",
    premium = "💎",
    
    -- ============ STATS ============
    level = "⭐",
    xp = "✨",
    kills = "⚔️",
    deaths = "💀",
    playtime = "⏱️",
    
    -- ============ SETTINGS ============
    sound = "🔊",
    graphics = "🖥️",
    controls = "🎮",
    toggle = "🔘",
    
    -- ============ NOTIFICATIONS/UPDATES ============
    update = "🆕",
    changelog = "📋",
    warning = "⚠️",
    error = "❌",
    success = "✅",
    info = "ℹ️",
    
    -- ============ GENERAL UI ============
    close = "✕",
    back = "←",
    forward = "→",
    up = "↑",
    down = "↓",
    search = "🔍",
    filter = "🔽",
    sort = "📶",
    refresh = "🔄",
    edit = "✏️",
    delete = "🗑️",
    copy = "📋",
    share = "📤",
    download = "📥",
    upload = "📤",
    link = "🔗",
    lock = "🔒",
    unlock = "🔓",
    star = "⭐",
    heart = "❤️",
    like = "👍",
    dislike = "👎",
    
    -- ============ GAME SPECIFIC ============
    quest = "📜",
    achievement = "🏆",
    reward = "🎁",
    chest = "📦",
    key = "🔑",
    map = "🗺️",
    compass = "🧭",
    home = "🏠",
    party = "🎉",
    guild = "🏰",
    
    -- ============ HOTBAR ITEMS ============
    sword = "⚔️",
    pickaxe = "⛏️",
    axe = "🪓",
    potion = "🧪",
    food = "🍖",
    tool = "🔧",
    magic = "✨",
    shield = "🛡️",
    bow = "🏹",
}

--[[
    IMAGE ICONS (Upload your own)
    Replace "rbxassetid://0" with your uploaded image IDs
    These are used when USE_IMAGES = true
]]
Icons.Images = {
    -- ============ SIDEBAR ============
    inventory = "rbxassetid://112433350871424",
    shop = "rbxassetid://81313272697052",
    music = "rbxassetid://92967637555479",
    friends = "rbxassetid://118706001075503",
    emotes = "rbxassetid://110450974018538",
    settings = "rbxassetid://85973513160341",
    
    -- ============ TOP RIGHT STATUS ============
    notification = "rbxassetid://140726344771666",
    donate = "rbxassetid://135752298366939",
    profile = "rbxassetid://93768080173550",
    coin = "rbxassetid://84567587454869",
    
    -- ============ PLAYER DROPDOWN ============
    viewProfile = "rbxassetid://105971890591064",
    addFriend = "rbxassetid://117759248558481",
    trade = "rbxassetid://107271756015838",
    teleport = "rbxassetid://122570464374467",
    
    -- ============ MUSIC PLAYER ============
    play = "rbxassetid://138254529729419",
    pause = "rbxassetid://126577426902117",
    next = "rbxassetid://134753070851801",
    previous = "rbxassetid://137934880488539",
    volume = "rbxassetid://127046613574560",
    volumeMute = "rbxassetid://120718738861117",
    musicNote = "rbxassetid://74158662778942",
    
    -- ============ FRIENDS VIEW ============
    invite = "rbxassetid://73732580540052",
    online = "rbxassetid://97703882386046",
    offline = "rbxassetid://97703882386046",
    
    -- ============ INVENTORY ============
    backpack = "rbxassetid://112433350871424",
    item = "rbxassetid://90116170905222",
    equip = "rbxassetid://79691418370516",
    unequip = "rbxassetid://107644993030012",
    
    -- ============ SHOP ============
    buy = "rbxassetid://0",
    cart = "rbxassetid://0",
    sale = "rbxassetid://0",
    premium = "rbxassetid://0",
    
    -- ============ STATS ============
    level = "rbxassetid://0",
    xp = "rbxassetid://0",
    kills = "rbxassetid://0",
    deaths = "rbxassetid://0",
    playtime = "rbxassetid://0",
    
    -- ============ SETTINGS ============
    sound = "rbxassetid://0",
    graphics = "rbxassetid://0",
    controls = "rbxassetid://0",
    toggle = "rbxassetid://0",
    
    -- ============ NOTIFICATIONS/UPDATES ============
    update = "rbxassetid://0",
    changelog = "rbxassetid://0",
    warning = "rbxassetid://0",
    error = "rbxassetid://0",
    success = "rbxassetid://0",
    info = "rbxassetid://0",
    
    -- ============ GENERAL UI ============
    close = "rbxassetid://107644993030012", -- Using standard X image
    back = "rbxassetid://0",
    forward = "rbxassetid://0",
    up = "rbxassetid://0",
    down = "rbxassetid://0",
    search = "rbxassetid://0",
    filter = "rbxassetid://0",
    sort = "rbxassetid://0",
    refresh = "rbxassetid://0",
    edit = "rbxassetid://0",
    delete = "rbxassetid://0",
    copy = "rbxassetid://0",
    share = "rbxassetid://0",
    download = "rbxassetid://0",
    upload = "rbxassetid://0",
    link = "rbxassetid://0",
    lock = "rbxassetid://0",
    unlock = "rbxassetid://0",
    star = "rbxassetid://0",
    heart = "rbxassetid://0",
    like = "rbxassetid://0",
    dislike = "rbxassetid://0",
    
    -- ============ GAME SPECIFIC ============
    quest = "rbxassetid://0",
    achievement = "rbxassetid://0",
    reward = "rbxassetid://0",
    chest = "rbxassetid://0",
    key = "rbxassetid://0",
    map = "rbxassetid://0",
    compass = "rbxassetid://0",
    home = "rbxassetid://0",
    party = "rbxassetid://0",
    guild = "rbxassetid://0",
    
    -- ============ HOTBAR ITEMS ============
    sword = "rbxassetid://0",
    pickaxe = "rbxassetid://0",
    axe = "rbxassetid://0",
    potion = "rbxassetid://0",
    food = "rbxassetid://0",
    tool = "rbxassetid://0",
    magic = "rbxassetid://0",
    shield = "rbxassetid://0",
    bow = "rbxassetid://0",
    
    -- ============ OVERHEAD / COUNTRY FLAGS ============
    flagID = "rbxassetid://123657612842861", -- Indonesia
    flagUS = "rbxassetid://88839299588699", -- USA
    flagGB = "rbxassetid://107602767795588", -- UK
    flagJP = "rbxassetid://128872409056951", -- Japan
    flagKR = "rbxassetid://135610785541844", -- Korea
    flagBR = "rbxassetid://82688448764523", -- Brazil
    flagPH = "rbxassetid://81683359918706", -- Philippines
    flagMY = "rbxassetid://133249300329278", -- Malaysia
    flagSG = "rbxassetid://128869963520735", -- Singapore
    flagAU = "rbxassetid://95381251816929", -- Australia
    flagDE = "rbxassetid://104639554675665", -- Germany
    flagFR = "rbxassetid://104639554675665", -- France
    flagTH = "rbxassetid://80449589649641", -- Thailand
    flagVN = "rbxassetid://100422172618804", -- Vietnam
    flagRU = "rbxassetid://134710837659572", -- Russia
    flagIN = "rbxassetid://95667720094155", -- India
    
    -- ============ STREAK / OVERHEAD ============
    streak = "rbxassetid://91012672710878", -- Fire icon for streak
}

-- Get icon - automatically uses image if available, otherwise falls back to text/emoji
function Icons.Get(name)
    local imageIcon = Icons.Images[name]
    local textIcon = Icons.Text[name]
    
    -- Check if image asset exists (not "rbxassetid://0")
    if imageIcon and imageIcon ~= "rbxassetid://0" then
        return imageIcon
    end
    
    -- Fallback to text/emoji
    return textIcon or "?"
end

-- Check if specific icon is using text (for components that need to know)
function Icons.IsTextIcon(name)
    local imageIcon = Icons.Images[name]
    return not imageIcon or imageIcon == "rbxassetid://0"
end

-- Check if using text/emoji icons (legacy - checks global setting)
function Icons.IsText()
    return not Icons.USE_IMAGES
end

-- Get all icon names (for debugging)
function Icons.GetAllNames()
    local names = {}
    for name, _ in pairs(Icons.Text) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

return Icons
