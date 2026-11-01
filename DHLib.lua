--[[
    DH UI Library  v3.0  -  LOGIC FILE
    Host this file (GitHub raw etc.) and load it from the usage file with loadstring.

    local Window = Library:CreateWindow({
        Title = "DH", Subtitle = "v3.0", Theme = "Crimson" | "Black" | "Violet",
        Width = 660, Height = 440, ToggleKey = Enum.KeyCode.RightShift,
        ToggleText = "DH", TogglePosition = Vector2.new(16, 76),
        ConfigFolder = "DHUI", Splash = true,
        Snow = false | {Enabled = true, Count = 90, Wind = 0},
        OnClose = function() end,
    })

    local Tab = Window:CreateTab("Name")
    local Section = Tab:CreateSection({Name = "Title", Side = "Left" | "Right", Collapsed = false})
        Section:CreateLabel(text)            Section:CreateParagraph({Title, Content})
        Section:CreateButton({Name, Callback})
        Section:CreateToggle({Name, Default, Flag, Callback})
        Section:CreateSlider({Name, Range = {min, max}, Increment, Suffix, Default, Flag, Callback})
        Section:CreateDropdown({Name, Options, Default, Multi, Flag, Callback})
        Section:CreateTextbox({Name, Placeholder, Default, Flag, Callback})
        Section:CreateKeybind({Name, Default, Flag, Callback, Changed})
        Section:CreateColorPicker({Name, Default, Flag, Callback})
        Section:CreateDivider()
        Section:SetCollapsed(bool)   Section:Toggle()   Section:SetTitle(text)

    Tab:CreateLeftSection(o)   Tab:CreateRightSection(o)   Tab:Select()

    Window:Notify({Title, Content, Duration, Type = "Info" | "Success" | "Warning" | "Error"})
    Window:SetTheme(name)  Window:SetSnow(bool)  Window:SetSnowCount(n)
    Window:SetVisible(bool)  Window:Toggle()  Window:Minimize()  Window:SetToggleKey(key)
    Window:SetTitle(text)  Window:SaveConfig(name)  Window:LoadConfig(name)  Window:Destroy()
    Library:GetThemes()  Library.Flags
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local Library = {Flags = {}, Version = "3.0"}

---------------------------------------------------------------------
-- Themes (Black / Crimson / Violet)
---------------------------------------------------------------------

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Base = {
    Success = rgb(110, 235, 150),
    Warning = rgb(255, 190, 70),
    Error = rgb(255, 85, 100),
}

local function makeTheme(t)
    for k, v in pairs(Base) do
        if t[k] == nil then
            t[k] = v
        end
    end
    return t
end

local Themes = {
    Black = makeTheme({
        Background = rgb(8, 8, 10), Topbar = rgb(13, 13, 16), Section = rgb(14, 14, 18),
        Element = rgb(22, 22, 27), ElementHover = rgb(33, 33, 40), Stroke = rgb(46, 46, 55),
        Accent = rgb(236, 236, 242), Accent2 = rgb(126, 126, 146), OnAccent = rgb(10, 10, 12),
        Text = rgb(240, 240, 246), SubText = rgb(138, 138, 152),
    }),
    Crimson = makeTheme({
        Background = rgb(11, 7, 9), Topbar = rgb(18, 10, 13), Section = rgb(19, 11, 14),
        Element = rgb(29, 16, 20), ElementHover = rgb(43, 23, 29), Stroke = rgb(76, 36, 46),
        Accent = rgb(225, 29, 62), Accent2 = rgb(255, 96, 92), OnAccent = rgb(255, 255, 255),
        Text = rgb(246, 238, 240), SubText = rgb(164, 130, 138),
    }),
    Violet = makeTheme({
        Background = rgb(10, 7, 17), Topbar = rgb(16, 11, 27), Section = rgb(17, 12, 29),
        Element = rgb(26, 18, 43), ElementHover = rgb(38, 27, 63), Stroke = rgb(68, 50, 112),
        Accent = rgb(150, 92, 255), Accent2 = rgb(208, 122, 255), OnAccent = rgb(255, 255, 255),
        Text = rgb(243, 239, 252), SubText = rgb(148, 136, 180),
    }),
}
Library.Themes = Themes

local Theme = {}
local function applyTheme(name)
    local src = Themes[name]
    if not src then
        return false
    end
    for k, v in pairs(src) do
        Theme[k] = v
    end
    return true
end
applyTheme("Crimson")

function Library:GetThemes()
    return {"Black", "Crimson", "Violet"}
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local WHITE = Color3.new(1, 1, 1)

local function create(className, props, children)
    local inst = Instance.new(className)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            parent = v
        else
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function tween(obj, props, time, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function corner(r)
    return create("UICorner", {CornerRadius = UDim.new(0, r or 8)})
end

local function round()
    return create("UICorner", {CornerRadius = UDim.new(1, 0)})
end

local function safeCall(cb, ...)
    if type(cb) == "function" then
        local ok, err = pcall(cb, ...)
        if not ok then
            warn("[DH UI] " .. tostring(err))
        end
    end
end

local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return hui
        end
    end
    local ok = pcall(function() return CoreGui.Name end)
    if ok then
        return CoreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function pointer(input)
    return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function textWidth(text, size, font)
    return TextService:GetTextSize(text, size, font or Enum.Font.GothamMedium, Vector2.new(1000, 100)).X
end

local function ser(v)
    local t = typeof(v)
    if t == "Color3" then
        return {__t = "c", r = v.R, g = v.G, b = v.B}
    elseif t == "EnumItem" then
        return {__t = "e", n = v.Name}
    end
    return v
end

local function deser(v)
    if type(v) == "table" and v.__t == "c" then
        return Color3.new(v.r, v.g, v.b)
    elseif type(v) == "table" and v.__t == "e" then
        return Enum.KeyCode[v.n]
    end
    return v
end

---------------------------------------------------------------------
-- Window
---------------------------------------------------------------------

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local startTheme = Themes[cfg.Theme or ""] and cfg.Theme or "Crimson"
    applyTheme(startTheme)

    local Window = {
        Tabs = {}, Conns = {}, Hooks = {}, Setters = {},
        Minimized = false, Visible = true, Active = nil, Destroyed = false,
        ThemeName = startTheme,
    }

    local W, H = cfg.Width or 660, cfg.Height or 440
    local TOP = 46
    local title = cfg.Title or "DH"
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
    local folder = cfg.ConfigFolder or "DHUI"
    local ON_COLOR, OFF_COLOR = rgb(126, 240, 160), rgb(220, 20, 60)

    local function connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(Window.Conns, c)
        return c
    end

    -- theme binding -------------------------------------------------
    local function themed(fn)
        fn(false)
        table.insert(Window.Hooks, fn)
    end

    local function bind(inst, prop, key)
        themed(function(animate)
            if animate then
                tween(inst, {[prop] = Theme[key]}, 0.35)
            else
                inst[prop] = Theme[key]
            end
        end)
    end

    local function accentGrad(parent, rotation)
        local g = create("UIGradient", {Color = ColorSequence.new(Theme.Accent, Theme.Accent2), Rotation = rotation or 0, Parent = parent})
        themed(function()
            g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2)
        end)
        return g
    end

    local function label(parent, text, props, key)
        local l = create("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme[key or "Text"],
            Parent = parent,
        })
        for k, v in pairs(props or {}) do
            l[k] = v
        end
        bind(l, "TextColor3", key or "Text")
        return l
    end

    -- screen / state --------------------------------------------------
    local gui = create("ScreenGui", {
        Name = cfg.Name or "DHUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
    gui.Parent = getGuiParent()

    local function screenSize()
        local s = gui.AbsoluteSize
        if s.X < 100 or s.Y < 100 then
            local cam = workspace.CurrentCamera
            return cam and cam.ViewportSize or Vector2.new(1280, 720)
        end
        return s
    end

    local scr = screenSize()
    local posX, posY = (scr.X - W) / 2, (scr.Y - H) / 2
    local tgtX, tgtY = posX, posY
    local slide, slideTarget = 36, 0

    local function clampTarget(x, y)
        local s = screenSize()
        return math.clamp(x, 90 - W, s.X - 90), math.clamp(y, 0, s.Y - 60)
    end

    -- root / main -----------------------------------------------------
    local root = create("Frame", {
        Name = "Root",
        Size = UDim2.fromOffset(W, H),
        Position = UDim2.fromOffset(posX, posY + slide),
        BackgroundTransparency = 1,
        Parent = gui,
    })

    local shadow = create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 70, 1, 70),
        Position = UDim2.new(0, -35, 0, -28),
        Parent = root,
    })

    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    }, {corner(10)})
    bind(main, "BackgroundColor3", "Background")

    local borderStroke = create("UIStroke", {
        Color = WHITE, Thickness = 1.5, Transparency = 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main,
    })
    local function borderSeq()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(0.5, Theme.Accent2),
            ColorSequenceKeypoint.new(1, Theme.Accent),
        })
    end
    local borderGrad = create("UIGradient", {Color = borderSeq(), Parent = borderStroke})
    themed(function()
        borderGrad.Color = borderSeq()
    end)

    -- soft corner glow behind everything
    local glow = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1, Parent = main,
    })
    local glowGrad = create("UIGradient", {
        Rotation = 38,
        Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.42, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = glow,
    })
    themed(function()
        glowGrad.Color = ColorSequence.new(Theme.Accent, Theme.Accent2)
    end)

    -- fade cover used for show / hide
    local cover = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background, BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false, ZIndex = 100, Parent = main,
    }, {corner(10)})
    bind(cover, "BackgroundColor3", "Background")

    ---------------------------------------------------------------------
    -- Snow
    ---------------------------------------------------------------------
    local snowCfg = type(cfg.Snow) == "table" and cfg.Snow or {}
    local snowBuilt = cfg.Snow ~= false
    local snowOn = snowBuilt and snowCfg.Enabled ~= false
    local flakes, snowHolders = {}, {}
    local wind = 0

    local function makeSnowLayer(zindex, count, minS, maxS, minT, maxT, speedMul)
        local holder = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true,
            ZIndex = zindex, Visible = snowOn, Parent = main,
        })
        for _ = 1, count do
            local size = minS + math.random() * (maxS - minS)
            local depth = (size - minS) / (maxS - minS + 0.001)
            local fr = create("Frame", {
                Size = UDim2.fromOffset(size, size),
                BackgroundColor3 = rgb(236, 243, 255),
                BackgroundTransparency = minT + math.random() * (maxT - minT),
                BorderSizePixel = 0,
                Parent = holder,
            }, {round()})
            flakes[#flakes + 1] = {
                f = fr, on = true, x = math.random() * W, y = math.random() * H, size = size,
                depth = 0.35 + depth * 0.65,
                speed = (16 + size * 7 + math.random() * 16) * speedMul,
                drift = (math.random() - 0.5) * 8,
                amp = 6 + math.random() * 16,
                freq = 0.6 + math.random() * 1.4,
                ph = math.random() * 6.28,
            }
        end
        table.insert(snowHolders, holder)
        return holder
    end

    if snowBuilt then
        local total = snowCfg.Count or 90
        makeSnowLayer(1, math.floor(total * 0.45), 3, 7, 0.55, 0.86, 0.8)   -- back: big, soft
        makeSnowLayer(15, math.ceil(total * 0.55), 1.6, 4, 0.3, 0.7, 1.15)  -- front: small, crisp
    end

    local function stepSnow(dt, t, vx)
        local target = math.clamp(-vx * 0.3, -150, 150) + math.sin(t * 0.35) * 10 + (snowCfg.Wind or 0)
        wind = wind + (target - wind) * (1 - math.exp(-dt * 3))
        local mp = UserInputService:GetMouseLocation()
        local org = main.AbsolutePosition
        local mx, my = mp.X - org.X, mp.Y - org.Y
        for _, s in ipairs(flakes) do
            if s.on then
                local x = s.x + (s.drift + wind * s.depth + math.sin(t * s.freq + s.ph) * s.amp) * dt
                local y = s.y + s.speed * dt
                local dx, dy = x - mx, y - my
                local d2 = dx * dx + dy * dy
                if d2 < 6400 and d2 > 1 then
                    local d = math.sqrt(d2)
                    local push = (80 - d) / 80 * 90 * dt
                    x = x + dx / d * push
                    y = y + dy / d * push
                end
                if y > H + 8 then
                    y = -8
                    x = math.random() * W
                end
                if x > W + 10 then
                    x = -10
                elseif x < -10 then
                    x = W + 10
                end
                s.x, s.y = x, y
                s.f.Position = UDim2.fromOffset(x, y)
            end
        end
    end

    function Window:SetSnow(on)
        if snowBuilt then
            snowOn = on and true or false
            for _, h in ipairs(snowHolders) do
                h.Visible = snowOn
            end
        end
    end

    function Window:SetSnowCount(n)
        for i, s in ipairs(flakes) do
            s.on = i <= n
            s.f.Visible = s.on
        end
    end

    ---------------------------------------------------------------------
    -- Topbar
    ---------------------------------------------------------------------
    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, TOP),
        BackgroundColor3 = Theme.Topbar,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = main,
    }, {corner(10)})
    bind(topbar, "BackgroundColor3", "Topbar")

    local topFiller = create("Frame", {
        Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, Parent = topbar,
    })
    bind(topFiller, "BackgroundColor3", "Topbar")

    local logo = create("Frame", {
        Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(14, 10),
        BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = topbar,
    }, {corner(7)})
    accentGrad(logo, 45)
    local logoLbl = create("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = string.upper(string.sub(title, 1, 1)), Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Theme.OnAccent, Parent = logo,
    })
    bind(logoLbl, "TextColor3", "OnAccent")

    local titleLbl = label(topbar, title, {
        Position = UDim2.fromOffset(48, 0), Size = UDim2.new(0, 110, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    if cfg.Subtitle ~= false then
        local pillText = cfg.Subtitle or ("v" .. Library.Version)
        local pw = textWidth(pillText, 10, Enum.Font.GothamBold) + 12
        local tw = math.min(110, textWidth(title, 15, Enum.Font.GothamBold))
        local pill = create("Frame", {
            Size = UDim2.fromOffset(pw, 16), Position = UDim2.fromOffset(48 + tw + 8, 15),
            BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = topbar,
        }, {corner(4)})
        bind(pill, "BackgroundColor3", "Accent")
        label(pill, pillText, {
            Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBold, TextSize = 10,
        }, "Accent")
    end

    -- center tab button ------------------------------------------------
    local tabBtn = create("TextButton", {
        Name = "TabButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(190, 30),
        BackgroundColor3 = Theme.Element,
        Text = "", AutoButtonColor = false, Parent = topbar,
    }, {corner(6)})
    bind(tabBtn, "BackgroundColor3", "Element")
    local tabBtnStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.2, Parent = tabBtn})
    bind(tabBtnStroke, "Color", "Stroke")
    for i = 0, 2 do
        local bar = create("Frame", {
            Position = UDim2.fromOffset(12, 10 + i * 4), Size = UDim2.fromOffset(i == 1 and 9 or 12, 2),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = tabBtn,
        }, {round()})
        bind(bar, "BackgroundColor3", "Accent")
    end
    local tabBtnLbl = label(tabBtn, "Tabs", {
        Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -62, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local chevron = label(tabBtn, ">", {
        Position = UDim2.new(1, -26, 0, 0), Size = UDim2.fromOffset(18, 30),
        TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, Rotation = 90,
    }, "Accent")

    -- minimize / close ---------------------------------------------------
    local function topBtn(xOff, hoverKey)
        local b = create("TextButton", {
            Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, xOff, 0.5, -14),
            BackgroundColor3 = Theme.Element, Text = "", AutoButtonColor = false, Parent = topbar,
        }, {corner(6)})
        bind(b, "BackgroundColor3", "Element")
        connect(b.MouseEnter, function()
            tween(b, {BackgroundColor3 = Theme[hoverKey]}, 0.15)
        end)
        connect(b.MouseLeave, function()
            tween(b, {BackgroundColor3 = Theme.Element}, 0.2)
        end)
        return b
    end

    local closeBtn = topBtn(-40, "Error")
    local minBtn = topBtn(-74, "Warning")

    for _, rot in ipairs({45, -45}) do
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 2), Rotation = rot,
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = closeBtn,
        }, {round()})
    end
    local minLine = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(11, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = minBtn,
    }, {round()})
    local minBox = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Visible = false, Parent = minBtn,
    }, {corner(2), create("UIStroke", {Color = WHITE, Thickness = 2})})

    -- accent line under the topbar
    local line = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, TOP),
        BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = main,
    })
    local lineGrad = accentGrad(line, 0)

    -- smooth window dragging (target position, eased every frame)
    do
        local dragging, grabX, grabY = false, 0, 0
        connect(topbar.InputBegan, function(input)
            if isPress(input) then
                dragging = true
                local p = pointer(input)
                grabX, grabY = p.X - tgtX, p.Y - tgtY
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and isMove(input) then
                local p = pointer(input)
                tgtX, tgtY = clampTarget(p.X - grabX, p.Y - grabY)
            end
        end)
    end

    ---------------------------------------------------------------------
    -- Body + tab menu (popup under the center button)
    ---------------------------------------------------------------------
    local body = create("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(0, TOP + 1),
        Size = UDim2.new(1, 0, 1, -(TOP + 1)),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = main,
    })
    local pageArea = create("Frame", {
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 1, -20),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = body,
    })

    local menuW = math.min(W - 40, 420)
    local menuHeight = 54
    local menuOpen = false

    local backdrop = create("TextButton", {
        Position = UDim2.fromOffset(0, TOP + 1), Size = UDim2.new(1, 0, 1, -(TOP + 1)),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 39, Parent = main,
    })

    local menu = create("CanvasGroup", {
        Name = "TabMenu",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, TOP + 8),
        Size = UDim2.fromOffset(menuW, 0),
        BackgroundColor3 = Theme.Topbar,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 40,
        Parent = main,
    }, {corner(8)})
    bind(menu, "BackgroundColor3", "Topbar")
    local menuStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.1, Parent = menu})
    bind(menuStroke, "Color", "Stroke")

    local function setMenu(open)
        menuOpen = open and true or false
        if menuOpen then
            menu.Visible = true
            backdrop.Visible = true
            tween(menu, {Size = UDim2.fromOffset(menuW, menuHeight), GroupTransparency = 0}, 0.32)
            tween(chevron, {Rotation = -90}, 0.3, Enum.EasingStyle.Back)
            tween(tabBtnStroke, {Color = Theme.Accent}, 0.2)
        else
            backdrop.Visible = false
            local t = tween(menu, {Size = UDim2.fromOffset(menuW, 0), GroupTransparency = 1}, 0.22)
            tween(chevron, {Rotation = 90}, 0.25)
            tween(tabBtnStroke, {Color = Theme.Stroke}, 0.25)
            t.Completed:Connect(function()
                if not menuOpen then
                    menu.Visible = false
                end
            end)
        end
    end
    connect(tabBtn.MouseButton1Click, function()
        setMenu(not menuOpen)
    end)
    connect(backdrop.MouseButton1Click, function()
        setMenu(false)
    end)
    connect(tabBtn.MouseEnter, function()
        tween(tabBtn, {BackgroundColor3 = Theme.ElementHover}, 0.15)
    end)
    connect(tabBtn.MouseLeave, function()
        tween(tabBtn, {BackgroundColor3 = Theme.Element}, 0.2)
    end)

    -- flow layout: chips fill the row, the next one wraps to the next row
    local function reflowTabs()
        local padX, padY, gap, rowH = 10, 10, 6, 30
        local inner = menuW - padX * 2
        local x, y = 0, 0
        for _, t in ipairs(Window.Tabs) do
            if x + t.ChipWidth > inner and x > 0 then
                x = 0
                y = y + rowH + gap
            end
            tween(t.Chip, {Position = UDim2.fromOffset(padX + x, padY + y)}, 0.3)
            x = x + t.ChipWidth + gap
        end
        menuHeight = padY * 2 + y + rowH
        if menuOpen then
            tween(menu, {Size = UDim2.fromOffset(menuW, menuHeight)}, 0.3)
        end
    end

    ---------------------------------------------------------------------
    -- Minimize / close / visibility
    ---------------------------------------------------------------------
    local function setMinimized(state)
        Window.Minimized = state
        setMenu(false)
        minLine.Visible = not state
        minBox.Visible = state
        topFiller.Visible = not state
        if state then
            local t = tween(root, {Size = UDim2.fromOffset(W, TOP + 2)}, 0.3, Enum.EasingStyle.Quint)
            t.Completed:Connect(function()
                if Window.Minimized then
                    body.Visible = false
                end
            end)
        else
            body.Visible = true
            tween(root, {Size = UDim2.fromOffset(W, H)}, 0.38, Enum.EasingStyle.Back)
        end
    end
    function Window:Minimize()
        setMinimized(not Window.Minimized)
    end
    connect(minBtn.MouseButton1Click, function()
        Window:Minimize()
    end)

    function Window:SetVisible(state)
        state = state and true or false
        if Window.Visible == state then
            return
        end
        Window.Visible = state
        Window.PaintToggle(true)
        if state then
            root.Visible = true
            slide, slideTarget = 36, 0
            cover.Visible = true
            cover.BackgroundTransparency = 0
            tween(shadow, {ImageTransparency = 0.4}, 0.4)
            local t = tween(cover, {BackgroundTransparency = 1}, 0.35)
            t.Completed:Connect(function()
                if Window.Visible then
                    cover.Visible = false
                end
            end)
        else
            setMenu(false)
            slideTarget = 36
            cover.Visible = true
            cover.BackgroundTransparency = 1
            tween(shadow, {ImageTransparency = 1}, 0.25)
            local t = tween(cover, {BackgroundTransparency = 0}, 0.25)
            t.Completed:Connect(function()
                if not Window.Visible then
                    root.Visible = false
                end
            end)
        end
    end

    function Window:Toggle()
        Window:SetVisible(not Window.Visible)
    end

    function Window:Destroy()
        if Window.Destroyed then
            return
        end
        Window.Destroyed = true
        safeCall(cfg.OnClose)
        for _, c in ipairs(Window.Conns) do
            c:Disconnect()
        end
        Window.Conns = {}
        cover.Visible = true
        tween(cover, {BackgroundTransparency = 0}, 0.25)
        tween(shadow, {ImageTransparency = 1}, 0.25)
        tween(root, {Position = UDim2.fromOffset(root.Position.X.Offset, root.Position.Y.Offset + 40)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.32, function()
            gui:Destroy()
        end)
    end
    connect(closeBtn.MouseButton1Click, function()
        Window:Destroy()
    end)

    connect(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            Window:Toggle()
        end
    end)

    ---------------------------------------------------------------------
    -- External toggle button ("DH"): green = GUI on, crimson = GUI off
    ---------------------------------------------------------------------
    local tbText = cfg.ToggleText or "DH"
    local tbW = math.max(46, textWidth(tbText, 13, Enum.Font.GothamBold) + 26)
    local tbStart = typeof(cfg.TogglePosition) == "Vector2" and cfg.TogglePosition or Vector2.new(16, 76)
    local btnPos, btnTgt = tbStart, tbStart

    local toggleBtn = create("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.fromOffset(tbW, 26),
        Position = UDim2.fromOffset(tbStart.X, tbStart.Y),
        BackgroundColor3 = ON_COLOR,
        Text = tbText, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = rgb(8, 30, 16),
        AutoButtonColor = false, ZIndex = 5, Parent = gui,
    }, {corner(5)})
    local tbStroke = create("UIStroke", {Color = ON_COLOR, Thickness = 1.5, Transparency = 0.45, Parent = toggleBtn})

    function Window.PaintToggle(animate)
        local on = Window.Visible
        local bg = on and ON_COLOR or OFF_COLOR
        local fg = on and rgb(8, 30, 16) or rgb(255, 255, 255)
        if animate then
            tween(toggleBtn, {BackgroundColor3 = bg, TextColor3 = fg}, 0.3)
            tween(tbStroke, {Color = bg}, 0.3)
        else
            toggleBtn.BackgroundColor3 = bg
            toggleBtn.TextColor3 = fg
            tbStroke.Color = bg
        end
    end
    Window.PaintToggle(false)

    do
        local dragging, moved, startP, grab = false, false, Vector2.new(), Vector2.new()
        connect(toggleBtn.MouseEnter, function()
            tween(tbStroke, {Transparency = 0, Thickness = 2}, 0.15)
        end)
        connect(toggleBtn.MouseLeave, function()
            tween(tbStroke, {Transparency = 0.45, Thickness = 1.5}, 0.2)
        end)
        connect(toggleBtn.InputBegan, function(input)
            if isPress(input) then
                dragging, moved = true, false
                startP = pointer(input)
                grab = startP - btnTgt
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if not moved then
                            Window:Toggle()
                        end
                    end
                end)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and isMove(input) then
                local p = pointer(input)
                if (p - startP).Magnitude > 6 then
                    moved = true
                end
                if moved then
                    local s = screenSize()
                    local t = p - grab
                    btnTgt = Vector2.new(math.clamp(t.X, 0, s.X - tbW), math.clamp(t.Y, 0, s.Y - 26))
                end
            end
        end)
    end

    ---------------------------------------------------------------------
    -- Window methods
    ---------------------------------------------------------------------
    function Window:SetToggleKey(key)
        toggleKey = key
    end

    function Window:SetTitle(text)
        titleLbl.Text = text
    end

    function Window:SetTheme(name)
        if Themes[name] and applyTheme(name) then
            Window.ThemeName = name
            for _, hook in ipairs(Window.Hooks) do
                pcall(hook, true)
            end
        end
    end

    -- notifications (bottom right)
    local notifyHolder = create("Frame", {
        Size = UDim2.new(0, 300, 1, -24), Position = UDim2.new(1, -316, 0, 12),
        BackgroundTransparency = 1, Parent = gui,
    }, {
        create("UIListLayout", {
            Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    function Window:Notify(o)
        o = o or {}
        local colors = {Info = Theme.Accent, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error}
        local color = colors[o.Type or "Info"] or Theme.Accent
        local dur = o.Duration or 4

        local wrap = create("Frame", {Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, Parent = notifyHolder})
        local card = create("Frame", {
            Size = UDim2.fromScale(1, 1), Position = UDim2.new(1.2, 0, 0, 0),
            BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, ClipsDescendants = true, Parent = wrap,
        }, {corner(8), create("UIStroke", {Color = color, Transparency = 0.5})})
        create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = card})
        create("TextLabel", {
            Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -26, 0, 18), BackgroundTransparency = 1,
            Text = o.Title or "Notification", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
        })
        create("TextLabel", {
            Position = UDim2.fromOffset(16, 27), Size = UDim2.new(1, -26, 0, 34), BackgroundTransparency = 1,
            Text = o.Content or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, Parent = card,
        })
        local bar = create("Frame", {
            Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = color, BorderSizePixel = 0, Parent = card,
        })
        tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.45, Enum.EasingStyle.Back)
        tween(bar, {Size = UDim2.new(0, 0, 0, 2)}, dur, Enum.EasingStyle.Linear)
        task.delay(dur, function()
            local t = tween(card, {Position = UDim2.new(1.2, 0, 0, 0)}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            t.Completed:Connect(function()
                wrap:Destroy()
            end)
        end)
    end

    -- config save / load
    function Window:SaveConfig(name)
        local data = {}
        for flag, val in pairs(Library.Flags) do
            data[flag] = ser(val)
        end
        local ok = pcall(function()
            if makefolder and isfolder and not isfolder(folder) then
                makefolder(folder)
            end
            writefile(folder .. "/" .. (name or "default") .. ".json", HttpService:JSONEncode(data))
        end)
        return ok
    end

    function Window:LoadConfig(name)
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(folder .. "/" .. (name or "default") .. ".json"))
        end)
        if not ok or type(data) ~= "table" then
            return false
        end
        for flag, val in pairs(data) do
            local setter = Window.Setters[flag]
            if setter then
                pcall(setter, deser(val))
            end
        end
        return true
    end

    ---------------------------------------------------------------------
    -- Element toolkit
    ---------------------------------------------------------------------

    local function newElement(parent, height)
        local f = create("Frame", {
            Size = UDim2.new(1, 0, 0, height or 38),
            BackgroundColor3 = Theme.Element,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = parent,
        }, {corner(6)})
        bind(f, "BackgroundColor3", "Element")
        local st = create("UIStroke", {
            Color = Theme.Stroke, Transparency = 0.45, Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f,
        })
        bind(st, "Color", "Stroke")
        create("UIGradient", {
            Color = ColorSequence.new(WHITE, rgb(206, 206, 218)),
            Rotation = 90, Parent = f,
        })
        return f, st
    end

    local function hoverFx(btn, frame, stroke, extra)
        connect(btn.MouseEnter, function()
            tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.2)
            tween(stroke, {Color = Theme.Accent, Transparency = 0.2}, 0.2)
            if extra then
                extra(true)
            end
        end)
        connect(btn.MouseLeave, function()
            tween(frame, {BackgroundColor3 = Theme.Element}, 0.25)
            tween(stroke, {Color = Theme.Stroke, Transparency = 0.45}, 0.25)
            if extra then
                extra(false)
            end
        end)
    end

    local function ripple(frame, input)
        local p = pointer(input)
        local x = p.X - frame.AbsolutePosition.X
        local y = p.Y - frame.AbsolutePosition.Y
        local size = math.max(frame.AbsoluteSize.X, frame.AbsoluteSize.Y) * 2.4
        local c = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Parent = frame,
        }, {round()})
        tween(c, {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1}, 0.6)
        task.delay(0.65, function()
            c:Destroy()
        end)
    end

    local function overlay(f, st, extra)
        local b = create("TextButton", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false, ZIndex = 10, Parent = f,
        })
        hoverFx(b, f, st, extra)
        connect(b.InputBegan, function(input)
            if isPress(input) then
                ripple(f, input)
            end
        end)
        return b
    end

    local function commit(o, value, silent)
        if o.Flag then
            Library.Flags[o.Flag] = value
        end
        if not silent then
            safeCall(o.Callback, value)
        end
    end

    local function register(o, setter)
        if o.Flag then
            Window.Setters[o.Flag] = setter
        end
    end

    local E = {}

    -- Label ---------------------------------------------------------------
    function E.Label(parent, o)
        if type(o) == "string" then
            o = {Text = o}
        end
        local f = newElement(parent, 32)
        local l = label(f, o.Text or o.Name or "Label", {
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0),
            TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
        }, "SubText")
        local obj = {}
        function obj:Set(t)
            l.Text = t
        end
        return obj
    end

    -- Paragraph -----------------------------------------------------------
    function E.Paragraph(parent, o)
        local f = newElement(parent, 40)
        f.AutomaticSize = Enum.AutomaticSize.Y
        f.Size = UDim2.new(1, 0, 0, 0)
        create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f})
        create("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = f,
        })
        local t = label(f, o.Title or "Paragraph", {Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, LayoutOrder = 1})
        local c = label(f, o.Content or "", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top, TextSize = 12, Font = Enum.Font.Gotham, LayoutOrder = 2,
        }, "SubText")
        local obj = {}
        function obj:Set(title, content)
            t.Text = title or t.Text
            c.Text = content or c.Text
        end
        return obj
    end

    -- Divider -------------------------------------------------------------
    function E.Divider(parent)
        local d = create("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = parent})
        bind(d, "BackgroundColor3", "Stroke")
        return {}
    end

    -- Button --------------------------------------------------------------
    function E.Button(parent, o)
        local f, st = newElement(parent, 38)
        label(f, o.Name or "Button", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -56, 1, 0)})
        local glyph = label(f, ">", {
            Size = UDim2.fromOffset(20, 38), Position = UDim2.new(1, -30, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold,
        }, "SubText")
        local b = overlay(f, st, function(on)
            tween(glyph, {
                Position = on and UDim2.new(1, -24, 0, 0) or UDim2.new(1, -30, 0, 0),
                TextColor3 = on and Theme.Accent or Theme.SubText,
            }, 0.2)
        end)
        connect(b.MouseButton1Click, function()
            safeCall(o.Callback)
        end)
        return {}
    end

    -- Toggle --------------------------------------------------------------
    function E.Toggle(parent, o)
        local state = o.Default == true
        local f, st = newElement(parent, 38)
        label(f, o.Name or "Toggle", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -72, 1, 0)})
        local track = create("Frame", {
            Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -52, 0.5, -10),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = f,
        }, {round()})
        bind(track, "BackgroundColor3", "Stroke")
        local fill = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1,
            BorderSizePixel = 0, Parent = track,
        }, {round()})
        accentGrad(fill, 0)
        local knob = create("Frame", {
            Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = track,
        }, {round()})

        local function render(anim)
            local pos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            local kc = state and Theme.OnAccent or Theme.SubText
            if anim then
                knob.Size = UDim2.fromOffset(20, 14)
                tween(knob, {Size = UDim2.fromOffset(14, 14), Position = pos, BackgroundColor3 = kc}, 0.35, Enum.EasingStyle.Back)
                tween(fill, {BackgroundTransparency = state and 0 or 1}, 0.25)
            else
                knob.Position = pos
                knob.BackgroundColor3 = kc
                fill.BackgroundTransparency = state and 0 or 1
            end
        end

        local obj = {}
        function obj:Set(v, silent)
            state = v and true or false
            render(true)
            commit(o, state, silent)
        end
        function obj:Get()
            return state
        end

        local b = overlay(f, st)
        connect(b.MouseButton1Click, function()
            obj:Set(not state)
        end)
        themed(function()
            render(false)
        end)
        register(o, function(v)
            obj:Set(v)
        end)
        -- fires the callback once at creation only when it starts enabled
        commit(o, state, (not state) or o.Silent)
        return obj
    end

    -- Slider --------------------------------------------------------------
    function E.Slider(parent, o)
        local min = (o.Range and o.Range[1]) or 0
        local max = (o.Range and o.Range[2]) or 100
        local inc = o.Increment or 1
        local suffix = o.Suffix or ""
        local value = math.clamp(o.Default or min, min, max)

        local f, st = newElement(parent, 54)
        label(f, o.Name or "Slider", {Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -96, 0, 22)})
        local pill = create("Frame", {
            Size = UDim2.fromOffset(68, 20), Position = UDim2.new(1, -80, 0, 6),
            BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = f,
        }, {corner(5)})
        bind(pill, "BackgroundColor3", "Accent")
        local valLbl = label(pill, "", {
            Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.Code, TextSize = 12,
        }, "Accent")
        local bar = create("Frame", {
            Position = UDim2.new(0, 12, 0, 37), Size = UDim2.new(1, -24, 0, 5),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = f,
        }, {round()})
        bind(bar, "BackgroundColor3", "Stroke")
        local fill = create("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar,
        }, {round()})
        accentGrad(fill, 0)
        local knob = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(13, 13), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar,
        }, {round()})
        local knobStroke = create("UIStroke", {Color = Theme.Accent, Thickness = 2, Parent = knob})
        bind(knobStroke, "Color", "Accent")

        local obj = {}
        local function render(v, anim)
            local a = (max == min) and 0 or (v - min) / (max - min)
            if anim then
                tween(fill, {Size = UDim2.fromScale(a, 1)}, 0.12)
                tween(knob, {Position = UDim2.fromScale(a, 0.5)}, 0.12)
            else
                fill.Size = UDim2.fromScale(a, 1)
                knob.Position = UDim2.fromScale(a, 0.5)
            end
            valLbl.Text = tostring(math.floor(v * 1000 + 0.5) / 1000) .. suffix
        end
        function obj:Set(v, silent)
            v = math.clamp(v, min, max)
            v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
            value = v
            render(v, true)
            commit(o, v, silent)
        end
        function obj:Get()
            return value
        end

        local dragging = false
        local function update(input)
            local alpha = math.clamp((pointer(input).X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            obj:Set(min + (max - min) * alpha)
        end
        local function grow(on)
            tween(knob, {Size = on and UDim2.fromOffset(19, 19) or UDim2.fromOffset(13, 13)}, 0.15, Enum.EasingStyle.Back)
        end
        local b = overlay(f, st)
        connect(b.InputBegan, function(input)
            if isPress(input) and pointer(input).Y - f.AbsolutePosition.Y > 26 then
                dragging = true
                grow(true)
                update(input)
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if dragging and isPress(input) then
                dragging = false
                grow(false)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and isMove(input) then
                update(input)
            end
        end)

        render(value, false)
        register(o, function(v)
            obj:Set(v)
        end)
        commit(o, value, true)
        return obj
    end

    -- Dropdown (smooth open / close, optional multi select) ----------------
    function E.Dropdown(parent, o)
        local multi = o.Multi == true
        local options = o.Options or {}
        local IH, MAXV = 28, 6
        local selected
        if multi then
            selected = {}
            if type(o.Default) == "table" then
                for _, v in ipairs(o.Default) do
                    selected[v] = true
                end
            end
        else
            selected = o.Default or options[1]
        end
        local open = false

        local f, st = newElement(parent, 38)
        label(f, o.Name or "Dropdown", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.42, -12, 0, 38)})
        local valLbl = label(f, "", {
            Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, -38, 0, 38),
            TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
            TextSize = 12, Font = Enum.Font.Code,
        }, "SubText")
        local arrow = label(f, ">", {
            Position = UDim2.new(1, -28, 0, 0), Size = UDim2.fromOffset(18, 38),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, Rotation = 90,
        }, "Accent")
        local listWrap = create("ScrollingFrame", {
            Position = UDim2.fromOffset(6, 42), Size = UDim2.new(1, -12, 0, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f,
        }, {create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})})
        bind(listWrap, "ScrollBarImageColor3", "Accent")

        local items = {}
        local function isSel(v)
            if multi then
                return selected[v] == true
            end
            return selected == v
        end
        local function getValue()
            if multi then
                local t = {}
                for _, v in ipairs(options) do
                    if selected[v] then
                        t[#t + 1] = v
                    end
                end
                return t
            end
            return selected
        end
        local function display()
            if multi then
                local names = {}
                for _, v in ipairs(getValue()) do
                    names[#names + 1] = tostring(v)
                end
                valLbl.Text = #names > 0 and table.concat(names, ", ") or "None"
            else
                valLbl.Text = tostring(selected or "None")
            end
        end
        local function paintItems()
            for v, it in pairs(items) do
                local on = isSel(v)
                tween(it.lbl, {TextColor3 = on and Theme.Accent or Theme.SubText}, 0.15)
                tween(it.mark, {BackgroundTransparency = on and 0 or 1}, 0.15)
                tween(it.btn, {BackgroundTransparency = on and 0.88 or 1}, 0.15)
            end
        end
        local function listHeight()
            return math.min(#options, MAXV) * (IH + 2)
        end
        local function resize()
            local h = open and (38 + 6 + listHeight() + 6) or 38
            tween(f, {Size = UDim2.new(1, 0, 0, h)}, open and 0.34 or 0.26)
            tween(arrow, {Rotation = open and -90 or 90}, 0.3, Enum.EasingStyle.Back)
        end
        local function staggerIn()
            local i = 0
            for _, opt in ipairs(options) do
                local it = items[opt]
                if it then
                    it.lbl.TextTransparency = 1
                    task.delay(i * 0.022, function()
                        if open and it.lbl.Parent then
                            tween(it.lbl, {TextTransparency = 0}, 0.2)
                        end
                    end)
                    i = i + 1
                end
            end
        end

        local function build()
            for _, it in pairs(items) do
                it.btn:Destroy()
            end
            items = {}
            for _, opt in ipairs(options) do
                local ib = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, IH), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                    Text = "", AutoButtonColor = false, Parent = listWrap,
                }, {corner(5)})
                local mark = create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0),
                    Size = UDim2.fromOffset(3, 14), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                    BorderSizePixel = 0, Parent = ib,
                }, {round()})
                local il = create("TextLabel", {
                    Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
                    Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.SubText,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = ib,
                })
                items[opt] = {btn = ib, lbl = il, mark = mark}
                connect(ib.MouseEnter, function()
                    if not isSel(opt) then
                        tween(il, {TextColor3 = Theme.Text}, 0.12)
                    end
                end)
                connect(ib.MouseLeave, function()
                    if not isSel(opt) then
                        tween(il, {TextColor3 = Theme.SubText}, 0.15)
                    end
                end)
                connect(ib.MouseButton1Click, function()
                    if multi then
                        selected[opt] = (not selected[opt]) or nil
                    else
                        selected = opt
                        open = false
                        resize()
                    end
                    display()
                    paintItems()
                    commit(o, getValue())
                end)
            end
            listWrap.Size = UDim2.new(1, -12, 0, listHeight())
            display()
            paintItems()
        end

        local obj = {}
        function obj:Set(v, silent)
            if multi then
                selected = {}
                for _, x in ipairs(type(v) == "table" and v or {}) do
                    selected[x] = true
                end
            else
                selected = v
            end
            display()
            paintItems()
            commit(o, getValue(), silent)
        end
        function obj:Get()
            return getValue()
        end
        function obj:Refresh(newOptions)
            options = newOptions or {}
            build()
            if open then
                resize()
            end
        end

        local b = overlay(f, st)
        b.Size = UDim2.new(1, 0, 0, 38)
        connect(b.MouseButton1Click, function()
            open = not open
            resize()
            if open then
                staggerIn()
            end
        end)

        build()
        themed(function()
            paintItems()
        end)
        register(o, function(v)
            obj:Set(v)
        end)
        commit(o, getValue(), true)
        return obj
    end

    -- Textbox ---------------------------------------------------------------
    function E.Textbox(parent, o)
        local f = newElement(parent, 38)
        label(f, o.Name or "Textbox", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.42, -12, 1, 0)})
        local wrapBox = create("Frame", {
            Position = UDim2.new(0.42, 0, 0.5, -14), Size = UDim2.new(0.58, -10, 0, 28),
            BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = f,
        }, {corner(5)})
        bind(wrapBox, "BackgroundColor3", "Background")
        local ws = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.2, Parent = wrapBox})
        bind(ws, "Color", "Stroke")
        local box = create("TextBox", {
            Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -18, 1, 0), BackgroundTransparency = 1,
            Text = o.Default or "", PlaceholderText = o.Placeholder or "Type here...",
            PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text, Font = Enum.Font.Code,
            TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = wrapBox,
        })
        bind(box, "TextColor3", "Text")
        bind(box, "PlaceholderColor3", "SubText")
        connect(box.Focused, function()
            tween(ws, {Color = Theme.Accent, Transparency = 0, Thickness = 1.5}, 0.2)
        end)
        connect(box.FocusLost, function()
            tween(ws, {Color = Theme.Stroke, Transparency = 0.2, Thickness = 1}, 0.25)
            commit(o, box.Text)
        end)
        local obj = {}
        function obj:Set(t, silent)
            box.Text = t
            commit(o, t, silent)
        end
        function obj:Get()
            return box.Text
        end
        register(o, function(v)
            obj:Set(v)
        end)
        commit(o, box.Text, true)
        return obj
    end

    -- Keybind ---------------------------------------------------------------
    function E.Keybind(parent, o)
        local key = o.Default or Enum.KeyCode.F
        local listening = false
        local f = newElement(parent, 38)
        label(f, o.Name or "Keybind", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -110, 1, 0)})
        local kb = create("TextButton", {
            Position = UDim2.new(1, -94, 0.5, -13), Size = UDim2.fromOffset(82, 26),
            BackgroundColor3 = Theme.Background, Text = key.Name, Font = Enum.Font.Code,
            TextSize = 12, TextColor3 = Theme.Accent, AutoButtonColor = false, Parent = f,
        }, {corner(5)})
        bind(kb, "BackgroundColor3", "Background")
        bind(kb, "TextColor3", "Accent")
        local ks = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.2, Parent = kb})
        bind(ks, "Color", "Stroke")

        connect(kb.MouseButton1Click, function()
            listening = true
            kb.Text = "..."
            tween(ks, {Color = Theme.Accent, Transparency = 0}, 0.2)
        end)
        connect(UserInputService.InputBegan, function(input, processed)
            if listening then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    if input.KeyCode ~= Enum.KeyCode.Escape then
                        key = input.KeyCode
                        if o.Flag then
                            Library.Flags[o.Flag] = key
                        end
                        safeCall(o.Changed, key)
                    end
                    kb.Text = key.Name
                    tween(ks, {Color = Theme.Stroke, Transparency = 0.2}, 0.25)
                end
            elseif not processed and input.KeyCode == key then
                safeCall(o.Callback, key)
            end
        end)
        local obj = {}
        function obj:Set(k)
            key = k
            kb.Text = k.Name
            if o.Flag then
                Library.Flags[o.Flag] = k
            end
            safeCall(o.Changed, k)
        end
        function obj:Get()
            return key
        end
        register(o, function(v)
            if v then
                obj:Set(v)
            end
        end)
        if o.Flag then
            Library.Flags[o.Flag] = key
        end
        return obj
    end

    -- Color picker ------------------------------------------------------------
    function E.ColorPicker(parent, o)
        local color = o.Default or rgb(255, 255, 255)
        local h, s, v = color:ToHSV()
        local open = false

        local f, st = newElement(parent, 38)
        label(f, o.Name or "Color", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -140, 0, 38)})
        local hexLbl = label(f, "", {
            Position = UDim2.new(1, -134, 0, 0), Size = UDim2.fromOffset(70, 38),
            TextXAlignment = Enum.TextXAlignment.Right, TextSize = 11, Font = Enum.Font.Code,
        }, "SubText")
        local swatch = create("Frame", {
            Position = UDim2.new(1, -52, 0, 8), Size = UDim2.fromOffset(40, 22),
            BackgroundColor3 = color, BorderSizePixel = 0, Parent = f,
        }, {corner(5), create("UIStroke", {Color = WHITE, Transparency = 0.7})})

        local svBox = create("Frame", {
            Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -58, 0, 104),
            BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, Parent = f,
        }, {corner(5)})
        local whiteOv = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = svBox}, {corner(5)})
        create("UIGradient", {Transparency = NumberSequence.new(0, 1), Parent = whiteOv})
        local blackOv = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = svBox}, {corner(5)})
        create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = blackOv})
        local svCursor = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1, Parent = svBox,
        }, {round(), create("UIStroke", {Color = WHITE, Thickness = 2})})

        local hueBar = create("Frame", {
            Position = UDim2.new(1, -32, 0, 48), Size = UDim2.fromOffset(20, 104),
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = f,
        }, {corner(5)})
        create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, rgb(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, rgb(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, rgb(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, rgb(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, rgb(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, rgb(255, 0, 255)),
                ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
            }),
            Parent = hueBar,
        })
        local hueCursor = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 6, 0, 5),
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = hueBar,
        }, {corner(3), create("UIStroke", {Color = Color3.new(0, 0, 0), Transparency = 0.5})})

        local obj = {}
        local function apply(silent)
            h = math.clamp(h, 0, 0.999)
            color = Color3.fromHSV(h, s, v)
            swatch.BackgroundColor3 = color
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svCursor.Position = UDim2.fromScale(s, 1 - v)
            hueCursor.Position = UDim2.fromScale(0.5, h)
            hexLbl.Text = "#" .. string.upper(color:ToHex())
            commit(o, color, silent)
        end
        function obj:Set(c, silent)
            h, s, v = c:ToHSV()
            apply(silent)
        end
        function obj:Get()
            return color
        end

        local drag
        local function update(input)
            local p = pointer(input)
            if drag == "sv" then
                s = math.clamp((p.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
            elseif drag == "hue" then
                h = math.clamp((p.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.999)
            end
            apply()
        end
        connect(svBox.InputBegan, function(input)
            if isPress(input) then
                drag = "sv"
                update(input)
            end
        end)
        connect(hueBar.InputBegan, function(input)
            if isPress(input) then
                drag = "hue"
                update(input)
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if isPress(input) then
                drag = nil
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if drag and isMove(input) then
                update(input)
            end
        end)

        local b = overlay(f, st)
        b.Size = UDim2.new(1, 0, 0, 38)
        connect(b.MouseButton1Click, function()
            open = not open
            tween(f, {Size = UDim2.new(1, 0, 0, open and 164 or 38)}, open and 0.34 or 0.26)
        end)

        apply(true)
        register(o, function(c)
            obj:Set(c)
        end)
        return obj
    end

    ---------------------------------------------------------------------
    -- Tabs + collapsible sections
    ---------------------------------------------------------------------

    local ELEMENT_NAMES = {
        "Label", "Paragraph", "Button", "Toggle", "Slider",
        "Dropdown", "Textbox", "Keybind", "ColorPicker", "Divider",
    }

    local function paintChips(animate)
        for _, t in ipairs(Window.Tabs) do
            local on = Window.Active == t
            local bgColor = on and Theme.Accent or Theme.Element
            local bgTrans = on and 0.82 or 0
            local strokeColor = on and Theme.Accent or Theme.Stroke
            local textColor = on and Theme.Text or Theme.SubText
            if animate then
                tween(t.Chip, {BackgroundColor3 = bgColor, BackgroundTransparency = bgTrans}, 0.2)
                tween(t.ChipStroke, {Color = strokeColor}, 0.2)
                tween(t.ChipLbl, {TextColor3 = textColor}, 0.2)
            else
                t.Chip.BackgroundColor3 = bgColor
                t.Chip.BackgroundTransparency = bgTrans
                t.ChipStroke.Color = strokeColor
                t.ChipLbl.TextColor3 = textColor
            end
        end
    end
    themed(function(animate)
        paintChips(animate)
    end)

    function Window:CreateTab(name)
        name = name or "Tab"
        local Tab = {Name = name, Sections = {}, NextSide = "Left"}

        -- chip inside the top-center tab menu
        local chipW = textWidth(name, 12, Enum.Font.GothamMedium) + 30
        local chip = create("TextButton", {
            Size = UDim2.fromOffset(chipW, 30), Position = UDim2.fromOffset(10, 10),
            BackgroundColor3 = Theme.Element, Text = "", AutoButtonColor = false, Parent = menu,
        }, {corner(6)})
        local chipStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.25, Parent = chip})
        local chipLbl = create("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = name,
            Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.SubText, Parent = chip,
        })
        Tab.Chip, Tab.ChipWidth, Tab.ChipLbl, Tab.ChipStroke = chip, chipW, chipLbl, chipStroke

        connect(chip.MouseEnter, function()
            if Window.Active ~= Tab then
                tween(chip, {BackgroundColor3 = Theme.ElementHover}, 0.15)
                tween(chipLbl, {TextColor3 = Theme.Text}, 0.15)
            end
        end)
        connect(chip.MouseLeave, function()
            if Window.Active ~= Tab then
                tween(chip, {BackgroundColor3 = Theme.Element}, 0.2)
                tween(chipLbl, {TextColor3 = Theme.SubText}, 0.2)
            end
        end)

        -- page: fading CanvasGroup with two columns
        local holder = create("CanvasGroup", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            GroupTransparency = 1, Visible = false, Parent = pageArea,
        })
        local scroll = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(), Parent = holder,
        })
        bind(scroll, "ScrollBarImageColor3", "Accent")
        Tab.Holder = holder

        local function makeColumn(xScale, xOff)
            local col = create("Frame", {
                Position = UDim2.new(xScale, xOff, 0, 0), Size = UDim2.new(0.5, -8, 0, 0),
                BackgroundTransparency = 1, Parent = scroll,
            })
            local lay = create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col})
            return col, lay
        end
        local leftCol, leftLay = makeColumn(0, 0)
        local rightCol, rightLay = makeColumn(0.5, 2)

        local function updateCanvas()
            local h = math.max(leftLay.AbsoluteContentSize.Y, rightLay.AbsoluteContentSize.Y)
            scroll.CanvasSize = UDim2.fromOffset(0, h + 12)
        end
        connect(leftLay:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
        connect(rightLay:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)

        function Tab:Select()
            if Window.Active == Tab then
                setMenu(false)
                return
            end
            local prev = Window.Active
            Window.Active = Tab
            if prev then
                local ph = prev.Holder
                local t = tween(ph, {GroupTransparency = 1}, 0.15)
                t.Completed:Connect(function()
                    if Window.Active ~= prev then
                        ph.Visible = false
                    end
                end)
            end
            holder.Position = UDim2.fromOffset(0, 16)
            holder.GroupTransparency = 1
            holder.Visible = true
            tween(holder, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.42)
            tabBtnLbl.Text = name
            tabBtnLbl.TextTransparency = 1
            tween(tabBtnLbl, {TextTransparency = 0}, 0.3)
            paintChips(true)
            setMenu(false)
        end
        connect(chip.MouseButton1Click, function()
            Tab:Select()
        end)

        -- sections ---------------------------------------------------------
        function Tab:CreateSection(o)
            if type(o) == "string" then
                o = {Name = o}
            end
            o = o or {}
            local side = o.Side
            if side ~= "Left" and side ~= "Right" then
                side = Tab.NextSide
                Tab.NextSide = (Tab.NextSide == "Left") and "Right" or "Left"
            end
            local col = (side == "Left") and leftCol or rightCol

            local Section = {Count = 0, Collapsed = o.Collapsed == true, Side = side}
            local HEADER = 36
            local collapsed = Section.Collapsed
            local animating, animToken = false, 0

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, HEADER), BackgroundColor3 = Theme.Section,
                BorderSizePixel = 0, ClipsDescendants = true, Parent = col,
            }, {corner(8)})
            bind(frame, "BackgroundColor3", "Section")
            local frameStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.3, Parent = frame})
            bind(frameStroke, "Color", "Stroke")

            local hdr = create("TextButton", {
                Size = UDim2.new(1, 0, 0, HEADER), BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = frame,
            }, {corner(8)})
            connect(hdr.MouseEnter, function()
                tween(hdr, {BackgroundTransparency = 0.55}, 0.15)
            end)
            connect(hdr.MouseLeave, function()
                tween(hdr, {BackgroundTransparency = 1}, 0.2)
            end)
            connect(hdr.InputBegan, function(input)
                if isPress(input) then
                    ripple(hdr, input)
                end
            end)

            local accentBar = create("Frame", {
                Position = UDim2.fromOffset(10, 11), Size = UDim2.fromOffset(3, 14),
                BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = hdr,
            }, {round()})
            accentGrad(accentBar, 90)
            local secTitle = label(hdr, o.Name or "Section", {
                Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -90, 1, 0),
                Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
            })
            local countBox = create("Frame", {
                Position = UDim2.new(1, -58, 0.5, -8), Size = UDim2.fromOffset(24, 16),
                BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = hdr,
            }, {corner(4)})
            bind(countBox, "BackgroundColor3", "Accent")
            local countLbl = label(countBox, "0", {
                Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
                Font = Enum.Font.Code, TextSize = 11,
            }, "Accent")
            local chev = label(hdr, ">", {
                Position = UDim2.new(1, -28, 0, 0), Size = UDim2.fromOffset(18, HEADER),
                TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold,
                Rotation = collapsed and 0 or 90,
            }, "Accent")

            local body = create("Frame", {
                Position = UDim2.fromOffset(0, HEADER), Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1, Visible = not collapsed, Parent = frame,
            })
            local lay = create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body})
            create("UIPadding", {
                PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), Parent = body,
            })

            local function targetHeight()
                if collapsed then
                    return HEADER
                end
                return HEADER + lay.AbsoluteContentSize.Y + 12
            end
            local function refresh()
                if not animating then
                    frame.Size = UDim2.new(1, 0, 0, targetHeight())
                end
            end
            connect(lay:GetPropertyChangedSignal("AbsoluteContentSize"), refresh)

            function Section:SetCollapsed(state)
                state = state and true or false
                if state == collapsed then
                    return
                end
                collapsed = state
                Section.Collapsed = state
                animToken = animToken + 1
                local mine = animToken
                animating = true
                if not state then
                    body.Visible = true
                end
                tween(chev, {Rotation = state and 0 or 90}, 0.3, Enum.EasingStyle.Back)
                local t = tween(frame, {Size = UDim2.new(1, 0, 0, targetHeight())}, 0.34)
                t.Completed:Connect(function()
                    if mine ~= animToken then
                        return
                    end
                    animating = false
                    if collapsed then
                        body.Visible = false
                    end
                    refresh()
                end)
            end
            function Section:Toggle()
                Section:SetCollapsed(not collapsed)
            end
            function Section:SetTitle(text)
                secTitle.Text = text
            end
            connect(hdr.MouseButton1Click, function()
                Section:Toggle()
            end)

            for _, elementName in ipairs(ELEMENT_NAMES) do
                Section["Create" .. elementName] = function(_, opts)
                    Section.Count = Section.Count + 1
                    countLbl.Text = tostring(Section.Count)
                    return E[elementName](body, opts or {})
                end
            end

            refresh()
            table.insert(Tab.Sections, Section)
            return Section
        end

        function Tab:CreateLeftSection(o)
            if type(o) == "string" then
                o = {Name = o}
            end
            o = o or {}
            o.Side = "Left"
            return Tab:CreateSection(o)
        end

        function Tab:CreateRightSection(o)
            if type(o) == "string" then
                o = {Name = o}
            end
            o = o or {}
            o.Side = "Right"
            return Tab:CreateSection(o)
        end

        table.insert(Window.Tabs, Tab)
        reflowTabs()
        paintChips(false)
        if #Window.Tabs == 1 then
            Tab:Select()
        end
        return Tab
    end

    ---------------------------------------------------------------------
    -- Splash, render loop
    ---------------------------------------------------------------------
    if cfg.Splash ~= false then
        local splash = create("CanvasGroup", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0, ZIndex = 50, Parent = main,
        }, {corner(10)})
        bind(splash, "BackgroundColor3", "Background")
        local big = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -34),
            Size = UDim2.fromOffset(58, 58), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = splash,
        }, {corner(14)})
        local bigGrad = accentGrad(big, 45)
        local bigLbl = create("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Text = string.upper(string.sub(title, 1, 1)), Font = Enum.Font.GothamBold, TextSize = 28,
            TextColor3 = Theme.OnAccent, Parent = big,
        })
        bind(bigLbl, "TextColor3", "OnAccent")
        label(splash, cfg.LoadingTitle or title, {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 6), Size = UDim2.fromOffset(300, 24),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 18,
        })
        local sub = label(splash, cfg.LoadingSubtitle or "Initializing interface...", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 32), Size = UDim2.fromOffset(300, 18),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Gotham, TextSize = 12,
        }, "SubText")
        local track = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 64), Size = UDim2.fromOffset(200, 4),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = splash,
        }, {round()})
        bind(track, "BackgroundColor3", "Stroke")
        local fillBar = create("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track,
        }, {round()})
        accentGrad(fillBar, 0)

        task.spawn(function()
            tween(fillBar, {Size = UDim2.fromScale(1, 1)}, 1.4, Enum.EasingStyle.Quad)
            local started = os.clock()
            while os.clock() - started < 1.4 and not Window.Destroyed do
                bigGrad.Rotation = bigGrad.Rotation + 4
                task.wait()
            end
            sub.Text = "Ready"
            task.wait(0.2)
            tween(splash, {GroupTransparency = 1}, 0.45)
            task.wait(0.5)
            splash:Destroy()
        end)
    end

    local clock = 0
    local lastX = posX
    connect(RunService.RenderStepped, function(dt)
        dt = math.min(dt, 0.1)
        clock = clock + dt
        local a = 1 - math.exp(-dt * 16)

        -- toggle button eases toward its target
        btnPos = btnPos:Lerp(btnTgt, a)
        toggleBtn.Position = UDim2.fromOffset(math.floor(btnPos.X + 0.5), math.floor(btnPos.Y + 0.5))

        if not root.Visible then
            return
        end

        -- window eases toward its target (smooth dragging) + show/hide slide
        posX = posX + (tgtX - posX) * a
        posY = posY + (tgtY - posY) * a
        slide = slide + (slideTarget - slide) * (1 - math.exp(-dt * 11))
        root.Position = UDim2.fromOffset(math.floor(posX + 0.5), math.floor(posY + slide + 0.5))

        local vx = (posX - lastX) / math.max(dt, 0.001)
        lastX = posX

        borderGrad.Rotation = (clock * 45) % 360
        lineGrad.Offset = Vector2.new(math.sin(clock * 1.3) * 0.4, 0)
        if snowOn and not Window.Minimized then
            stepSnow(dt, clock, vx)
        end
    end)

    return Window
end

return Library
