--!strict
-- ability-arena.lua — full single-file build
-- Replace the old script entirely, then execute.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local LocalPlayer      = Players.LocalPlayer

local CONFIG_DIR  = "OJBS"
local CONFIG_PATH = CONFIG_DIR .. "/abilityarena.json"

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end
local function ensureDir()
    if type(isfolder) == "function" and not isfolder(CONFIG_DIR) then
        makefolder(CONFIG_DIR)
    end
end
local function loadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return nil end
    ensureDir()
    if not isfile(CONFIG_PATH) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_PATH)) end)
    if ok and type(data) == "table" then return data end
end
local function saveConfig(cfg)
    if type(writefile) ~= "function" then return end
    ensureDir()
    local ok, enc = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok then writefile(CONFIG_PATH, enc) end
end

local Saved = loadConfig()
local Config = {
    theme = "Crimson",
    animations = true,
    uiScale = 1,
    openKey = Enum.KeyCode.RightShift,
    features = {},
    positions = {},
}
if Saved then
    for k, v in pairs(Saved) do Config[k] = v end
    if type(Saved.openKey) == "string" then
        local ok, k = pcall(function() return Enum.KeyCode[Saved.openKey] end)
        if ok then Config.openKey = k end
    end
end

-- ============================================================
-- THEMES
-- ============================================================
local Themes = {
    Crimson = {
        bg = Color3.fromRGB(16, 14, 20), panel = Color3.fromRGB(24, 20, 30),
        panelLight = Color3.fromRGB(34, 28, 42), accent = Color3.fromRGB(220, 40, 60),
        accentLight = Color3.fromRGB(255, 90, 110), text = Color3.fromRGB(240, 238, 245),
        subtext = Color3.fromRGB(160, 152, 170), stroke = Color3.fromRGB(48, 40, 58),
        switchOff = Color3.fromRGB(50, 44, 62),
    },
    Ocean = {
        bg = Color3.fromRGB(10, 16, 24), panel = Color3.fromRGB(16, 24, 34),
        panelLight = Color3.fromRGB(24, 36, 50), accent = Color3.fromRGB(40, 160, 220),
        accentLight = Color3.fromRGB(90, 200, 245), text = Color3.fromRGB(235, 242, 248),
        subtext = Color3.fromRGB(140, 160, 180), stroke = Color3.fromRGB(30, 44, 60),
        switchOff = Color3.fromRGB(36, 50, 68),
    },
    Emerald = {
        bg = Color3.fromRGB(12, 20, 16), panel = Color3.fromRGB(18, 30, 24),
        panelLight = Color3.fromRGB(26, 44, 34), accent = Color3.fromRGB(40, 200, 120),
        accentLight = Color3.fromRGB(90, 235, 160), text = Color3.fromRGB(236, 246, 240),
        subtext = Color3.fromRGB(145, 165, 152), stroke = Color3.fromRGB(32, 50, 40),
        switchOff = Color3.fromRGB(34, 52, 42),
    },
    Amethyst = {
        bg = Color3.fromRGB(18, 12, 24), panel = Color3.fromRGB(26, 18, 36),
        panelLight = Color3.fromRGB(36, 26, 50), accent = Color3.fromRGB(150, 70, 230),
        accentLight = Color3.fromRGB(190, 120, 255), text = Color3.fromRGB(244, 238, 250),
        subtext = Color3.fromRGB(160, 145, 175), stroke = Color3.fromRGB(46, 34, 62),
        switchOff = Color3.fromRGB(48, 36, 64),
    },
}
local Theme = Themes[Config.theme] or Themes.Crimson
local Connections = {}
local function conn(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Connections, c)
    return c
end
local function tween(o, props, dur)
    local d = Config.animations and (dur or 0.16) or 0
    local t = TweenService:Create(o, TweenInfo.new(d, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- ============================================================
-- UTIL
-- ============================================================
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function stroke(p, c, t) return new("UIStroke", { Color = c or Theme.stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function pad(p, n) return new("UIPadding", { PaddingTop = UDim.new(0,n), PaddingBottom = UDim.new(0,n), PaddingLeft = UDim.new(0,n), PaddingRight = UDim.new(0,n) }, p) end

-- ============================================================
-- ROOT
-- ============================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local old = PlayerGui:FindFirstChild("OJBS_CombatGUI")
if old then old:Destroy() end

local ScreenGui = new("ScreenGui", {
    Name = "OJBS_CombatGUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, PlayerGui)

local Window = new("Frame", {
    Name = "Window", Size = UDim2.new(0, 660, 0, 480),
    Position = UDim2.new(0.5, -330, 0.5, -240),
    BackgroundColor3 = Theme.bg, BorderSizePixel = 0, ClipsDescendants = true,
}, ScreenGui)
corner(Window, 14); stroke(Window, Theme.stroke, 1)

local TitleBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.panel,
    BorderSizePixel = 0, ZIndex = 5,
}, Window)
corner(TitleBar, 14)
new("Frame", { Size = UDim2.new(1,0,0,16), Position = UDim2.new(0,0,1,-16), BackgroundColor3 = Theme.panel, BorderSizePixel = 0 }, TitleBar)

new("TextLabel", {
    Size = UDim2.new(0,220,1,0), Position = UDim2.new(0,18,0,0),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
    Text = "ABILITY ARENA", TextColor3 = Theme.accentLight,
    TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
}, TitleBar)
new("TextLabel", {
    Size = UDim2.new(0,220,0,14), Position = UDim2.new(0,19,0,26),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham,
    Text = "combat suite", TextColor3 = Theme.subtext, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TitleBar)

local function tbtn(text, xo, col)
    local b = new("TextButton", {
        Size = UDim2.new(0,26,0,26), Position = UDim2.new(1, xo, 0.5, -13),
        BackgroundColor3 = Theme.panelLight, Text = text, Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = col or Theme.subtext, AutoButtonColor = false, ZIndex = 6,
    }, TitleBar)
    corner(b, 7)
    return b
end
local CollapseBtn = tbtn("—", -96)
local ThemeBtn    = tbtn("◐", -66)
local CloseBtn    = tbtn("✕", -36, Theme.accent)

-- ============================================================
-- TABS + CONTENT
-- ============================================================
local TabRail = new("Frame", {
    Size = UDim2.new(0, 150, 1, -46), Position = UDim2.new(0, 0, 0, 46),
    BackgroundColor3 = Theme.panel, BorderSizePixel = 0,
}, Window)
new("Frame", { Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0), BackgroundColor3 = Theme.stroke, BorderSizePixel = 0 }, TabRail)
pad(TabRail, 8)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, TabRail)

local Content = new("Frame", {
    Size = UDim2.new(1, -150, 1, -46), Position = UDim2.new(0, 150, 0, 46),
    BackgroundColor3 = Theme.bg, BorderSizePixel = 0, ClipsDescendants = true,
}, Window)

-- ============================================================
-- ELEMENT FACTORY
-- ============================================================
local Pages = {}
local activeTab = nil
local tabOrder = 0

local function selectTab(btn, page)
    if activeTab == btn then return end
    for _, p in pairs(Pages) do p.Visible = false end
    for _, c in ipairs(TabRail:GetChildren()) do
        if c:IsA("TextButton") then
            c.TextColor3 = Theme.subtext
            c.BackgroundColor3 = Theme.panel
        end
    end
    activeTab = btn
    btn.TextColor3 = Theme.text
    btn.BackgroundColor3 = Theme.panelLight
    page.Visible = true
end

local function makeTab(name)
    tabOrder = tabOrder + 1
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.panel,
        Text = name, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Theme.subtext, TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false, LayoutOrder = tabOrder,
    }, TabRail)
    corner(btn, 7)
    new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, btn)
    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1, ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, Content)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, page)
    conn(btn.MouseButton1Click, function() selectTab(btn, page) end)
    Pages[name] = page
    if not activeTab then selectTab(btn, page) end
    return page
end

local sectionOrder = 0
local function makeSection(page, title)
    sectionOrder = sectionOrder + 1
    local f = new("Frame", {
        Size = UDim2.new(1, -2, 0, 0), BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = sectionOrder,
    }, page)
    corner(f, 10); stroke(f, Theme.stroke, 1); pad(f, 8)
    local body = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, f)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, body)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = title,
        Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.accentLight,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -1,
    }, body)
    return body
end

local function makeToggle(parent, label, default, callback)
    local row = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false,
    }, parent)
    new("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = label,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.text,
        TextXAlignment = Enum.TextXAlignment.Left, Active = false, Selectable = false,
    }, row)
    local track = new("Frame", {
        Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -30, 0.5, -8),
        BackgroundColor3 = default and Theme.accent or Theme.switchOff, BorderSizePixel = 0,
    }, row)
    corner(track, 8)
    local knob = new("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = default and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6),
        BackgroundColor3 = Theme.text, BorderSizePixel = 0,
    }, track)
    corner(knob, 6)
    local state = default and true or false
    local function set(v, silent)
        state = v
        tween(track, { BackgroundColor3 = v and Theme.accent or Theme.switchOff }, 0.12)
        tween(knob, { Position = v and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6) }, 0.12)
        if not silent and callback then callback(v) end
    end
