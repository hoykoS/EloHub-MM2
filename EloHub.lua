if _G.EloHub_Unload then
    pcall(_G.EloHub_Unload)
    task.wait(0.15)
end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local StarterGui        = game:GetService("StarterGui")
local HttpService       = game:GetService("HttpService")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CONFIG = {
    BackgroundId = "",
    CoinFolder   = "CoinContainer",
    CoinName     = "Coin_Server",
}

local S = {
    ESP = {
        Enabled  = false,
        Chams    = true,
        Names    = true,
        Distance = true,
        Role     = true,
        Tracers  = false,
        MaxDist  = 1200,
        Colors   = {
            Murderer = Color3.fromRGB(255, 62, 62),
            Sheriff  = Color3.fromRGB(58, 132, 255),
            Innocent = Color3.fromRGB(52, 224, 122),
        },
    },
    Speed   = { Enabled = false, Value = 32, Mode = "CFrame" },
    Jump    = { Enabled = false, Value = 50 },
    Coins   = {
        Enabled    = false,
        Radius     = 400,
        Delay      = 0.12,
        Teleport   = false,
        Return     = true,
        Mode       = "Авто",
        FlySpeed   = 120,
        FlyTimeout = 3,
        Collected  = 0,
    },
    Safe    = {
        BlockKick = true,
        BlockTP   = true,
        KillAC    = false,
        SoftTP    = true,
        TPStep    = 45,
        StepWait  = 0.06,
    },
    Noclip  = { Enabled = false },
    Walls   = { Enabled = false, Value = 0.65 },
    Aim     = {
        Enabled   = false,
        Mode      = "Авто (по роли)",
        Part      = "Head",
        Smooth    = 0.35,
        Dist      = 400,
        FOV       = 150,
        LoseFOV   = 300,
        Unlock    = 90,
        ShowFOV   = true,
        VisCheck  = false,
        Target    = nil,
    },
    Fly     = { Enabled = false, Speed = 60 },
    Ragdoll = { Active = false },
    TP      = { Name = nil, Offset = 3 },
    Kill    = {
        Delay       = 0.2,
        Hits        = 2,
        Return      = true,
        TPShot      = false,
        ShotDist    = 8,
        LoopDelay   = 1,
        AutoMurder  = false,
        AutoSheriff = false,
        TryRemotes  = true,
    },
    Spin    = { Enabled = false, Power = 12000, Rot = 20000, Move = 22, Hold = true },
    UI      = { Scale = 1, Auto = 1 },
}

local Conns   = {}
local Loops   = {}
local Unloaded = false

local function Bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Conns, c)
    return c
end

local function New(class, props, children)
    local obj = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else obj[k] = v end
    end
    for _, ch in ipairs(children or {}) do ch.Parent = obj end
    if parent then obj.Parent = parent end
    return obj
end

local function Tween(obj, t, props, style, dir)
    local info = TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function Corner(parent, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 10), Parent = parent })
end

local function Stroke(parent, thickness, color, transparency)
    return New("UIStroke", {
        Thickness    = thickness or 1.2,
        Color        = color or Color3.fromRGB(255, 255, 255),
        Transparency = transparency or 0.15,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent       = parent,
    })
end

local function Pad(parent, l, r, t, b)
    return New("UIPadding", {
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        Parent        = parent,
    })
end

local function Round(n, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(n * m + 0.5) / m
end

local function GuiParent()
    local ok, res = pcall(function()
        if gethui then return gethui() end
        if syn and syn.protect_gui then
            local sg = Instance.new("ScreenGui")
            syn.protect_gui(sg)
            sg.Parent = game:GetService("CoreGui")
            sg:Destroy()
            return game:GetService("CoreGui")
        end
        if game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
            return game:GetService("CoreGui")
        end
    end)
    if ok and res then return res end
    return LP:WaitForChild("PlayerGui")
end

local function Dragify(frame, handle)
    handle = handle or frame
    local dragging, dragInput, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            startInput = input.Position
            startPos   = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    Bind(UserInputService.InputChanged, function(input)
        if dragging and input == dragInput then
            local d = input.Position - startInput
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function Char(plr)
    plr = plr or LP
    return plr.Character
end

local function HRP(plr)
    local c = Char(plr)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Hum(plr)
    local c = Char(plr)
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function Alive(plr)
    local h = Hum(plr)
    return h and h.Health > 0 and HRP(plr) ~= nil
end

local function HasTool(plr, name)
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp and bp:FindFirstChild(name) then return true end
    local c = plr.Character
    if c and c:FindFirstChild(name) then return true end
    return false
end

local function GetRole(plr)
    if HasTool(plr, "Knife") then return "Murderer" end
    if HasTool(plr, "Gun")   then return "Sheriff"  end
    return "Innocent"
end

local RoleRU = { Murderer = "УБИЙЦА", Sheriff = "ШЕРИФ", Innocent = "НЕВИННЫЙ" }

local function RoleColor(role)
    return S.ESP.Colors[role] or S.ESP.Colors.Innocent
end

local function MyRole()
    return GetRole(LP)
end

local function IsValidTarget(plr)
    if plr == LP or not Alive(plr) then return false end
    local mode = S.Aim.Mode
    local role = GetRole(plr)
    if mode == "Только убийца" then
        return role == "Murderer"
    elseif mode == "Только шериф" then
        return role == "Sheriff"
    elseif mode == "Любой игрок" then
        return true
    else
        local my = MyRole()
        if my == "Sheriff" then
            return role == "Murderer"
        elseif my == "Murderer" then
            return role ~= "Murderer"
        else
            return role == "Murderer"
        end
    end
end

local function AimPart(plr)
    local c = Char(plr)
    if not c then return nil end
    return c:FindFirstChild(S.Aim.Part) or c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
end

local function Visible(part)
    if not S.Aim.VisCheck then return true end
    local origin = Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { Char(LP), part.Parent, Camera }
    local dir = part.Position - origin
    local hit = Workspace:Raycast(origin, dir, params)
    return hit == nil
end

local Safe = { hooked = false }

function Safe.Hook()
    if Safe.hooked then return true end
    pcall(function()
        if not (hookmetamethod and getnamecallmethod) then return end
        local wrap = newcclosure or function(f) return f end
        local old
        old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
            local method = getnamecallmethod()
            if S.Safe.BlockKick and method == "Kick" then
                return nil
            end
            if S.Safe.BlockTP and (method == "Teleport"
                or method == "TeleportToPlaceInstance"
                or method == "TeleportToPrivateServer") then
                return nil
            end
            return old(self, ...)
        end))
        Safe.hooked = true
    end)
    return Safe.hooked
end

function Safe.KillAntiCheat()
    local n = 0
    local roots = {
        LP:FindFirstChild("PlayerScripts"),
        LP:FindFirstChild("PlayerGui"),
        Char(LP),
    }
    for _, root in ipairs(roots) do
        if root then
            for _, v in ipairs(root:GetDescendants()) do
                if v:IsA("LocalScript") and not v.Disabled then
                    local nm = string.lower(v.Name)
                    if string.find(nm, "anti", 1, true)
                    or string.find(nm, "cheat", 1, true)
                    or string.find(nm, "exploit", 1, true)
                    or string.find(nm, "detect", 1, true) then
                        pcall(function() v.Disabled = true end)
                        n = n + 1
                    end
                end
            end
        end
    end
    return n
end

function Safe.MoveTo(cf)
    local hrp = HRP(LP)
    if not hrp then return false end
    if not S.Safe.SoftTP then
        hrp.CFrame = cf
        return true
    end
    local from  = hrp.Position
    local to    = cf.Position
    local rot   = cf - cf.Position
    local dist  = (to - from).Magnitude
    local steps = math.max(1, math.ceil(dist / math.max(S.Safe.TPStep, 5)))
    for i = 1, steps do
        local h = HRP(LP)
        if not h then return false end
        h.CFrame = CFrame.new(from:Lerp(to, i / steps)) * rot
        if i < steps then task.wait(S.Safe.StepWait) end
    end
    return true
end

local GUIROOT = New("ScreenGui", {
    Name             = "EloHub",
    ResetOnSpawn     = false,
    IgnoreGuiInset   = true,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    DisplayOrder     = 9999,
    Parent           = GuiParent(),
})

local Overlay = New("Frame", {
    Name                   = "Overlay",
    Size                   = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex                 = 1,
    Parent                 = GUIROOT,
})

local ESPFolder = New("Folder", { Name = "EloHub_ESP", Parent = GUIROOT })

local ESP = { objects = {} }

function ESP.Remove(plr)
    local o = ESP.objects[plr]
    if not o then return end
    for _, v in pairs(o) do
        if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end
    end
    ESP.objects[plr] = nil
end

function ESP.Create(plr)
    if ESP.objects[plr] or plr == LP then return end

    local hl = New("Highlight", {
        Name                = "Elo_" .. plr.Name,
        FillTransparency    = 0.6,
        OutlineTransparency = 0,
        DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop,
        Enabled             = false,
        Parent              = ESPFolder,
    })

    local bb = New("BillboardGui", {
        Name             = "Tag_" .. plr.Name,
        Size             = UDim2.fromOffset(200, 42),
        StudsOffset      = Vector3.new(0, 2.6, 0),
        AlwaysOnTop      = true,
        LightInfluence   = 0,
        MaxDistance      = 5000,
        Enabled          = false,
        Parent           = ESPFolder,
    })

    local name = New("TextLabel", {
        Size                   = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 14,
        TextStrokeTransparency = 0.45,
        TextColor3             = Color3.new(1, 1, 1),
        Text                   = plr.Name,
        Parent                 = bb,
    })

    local info = New("TextLabel", {
        Position               = UDim2.new(0, 0, 0, 19),
        Size                   = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.Gotham,
        TextSize               = 12,
        TextStrokeTransparency = 0.55,
        TextColor3             = Color3.new(1, 1, 1),
        Text                   = "",
        Parent                 = bb,
    })

    local tracer = New("Frame", {
        Name                   = "Tracer_" .. plr.Name,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Size                   = UDim2.fromOffset(0, 2),
        BorderSizePixel        = 0,
        BackgroundTransparency = 0.25,
        Visible                = false,
        ZIndex                 = 2,
        Parent                 = Overlay,
    })

    ESP.objects[plr] = { hl = hl, bb = bb, name = name, info = info, tracer = tracer }
end

function ESP.SetAll(state)
    for _, o in pairs(ESP.objects) do
        o.hl.Enabled     = false
        o.bb.Enabled     = false
        o.tracer.Visible = false
    end
    if not state then return end
end

function ESP.Update()
    local myHRP = HRP(LP)
    for plr, o in pairs(ESP.objects) do
        if not plr.Parent then ESP.Remove(plr) end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if not ESP.objects[plr] then ESP.Create(plr) end
            local o = ESP.objects[plr]
            local char = Char(plr)
            local hrp  = HRP(plr)
            local head = char and char:FindFirstChild("Head")

            if not S.ESP.Enabled or not char or not hrp or not Alive(plr) then
                o.hl.Enabled = false
                o.bb.Enabled = false
                o.tracer.Visible = false
            else
                local role  = GetRole(plr)
                local col   = RoleColor(role)
                local dist  = myHRP and (myHRP.Position - hrp.Position).Magnitude or 0

                if dist > S.ESP.MaxDist then
                    o.hl.Enabled = false
                    o.bb.Enabled = false
                    o.tracer.Visible = false
                else

                    o.hl.Adornee      = char
                    o.hl.Enabled      = S.ESP.Chams
                    o.hl.FillColor    = col
                    o.hl.OutlineColor = col

                    o.bb.Adornee   = head or hrp
                    o.bb.Enabled   = S.ESP.Names or S.ESP.Distance or S.ESP.Role
                    o.name.Text    = S.ESP.Names and plr.Name or ""
                    o.name.TextColor3 = col

                    local line = {}
                    if S.ESP.Role     then table.insert(line, RoleRU[role]) end
                    if S.ESP.Distance then table.insert(line, math.floor(dist) .. "m") end
                    o.info.Text       = table.concat(line, "  |  ")
                    o.info.TextColor3 = col

                    if S.ESP.Tracers then
                        local pos, on = Camera:WorldToViewportPoint(hrp.Position)
                        if on then
                            local vp   = Camera.ViewportSize
                            local from = Vector2.new(vp.X / 2, vp.Y)
                            local to   = Vector2.new(pos.X, pos.Y)
                            local d    = to - from
                            local mid  = from + d / 2
                            o.tracer.Visible         = true
                            o.tracer.BackgroundColor3 = col
                            o.tracer.Position        = UDim2.fromOffset(mid.X, mid.Y)
                            o.tracer.Size            = UDim2.fromOffset(d.Magnitude, 2)
                            o.tracer.Rotation        = math.deg(math.atan2(d.Y, d.X))
                        else
                            o.tracer.Visible = false
                        end
                    else
                        o.tracer.Visible = false
                    end
                end
            end
        end
    end
end

local Speed = {}

function Speed.Step(dt)
    if not S.Speed.Enabled then return end
    local hum, hrp = Hum(LP), HRP(LP)
    if not hum or not hrp or hum.Health <= 0 then return end

    if S.Speed.Mode == "WalkSpeed" then
        if hum.WalkSpeed ~= S.Speed.Value then hum.WalkSpeed = S.Speed.Value end
    else

        if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
        if S.Fly.Enabled then return end
        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            local extra = math.max(S.Speed.Value - 16, 0)
            hrp.CFrame = hrp.CFrame + dir * extra * dt
        end
    end
end

function Speed.Reset()
    local hum = Hum(LP)
    if hum then hum.WalkSpeed = 16 end
end

local Jump = {}
function Jump.Apply()
    local hum = Hum(LP)
    if not hum then return end
    if S.Jump.Enabled then
        hum.UseJumpPower = true
        hum.JumpPower = S.Jump.Value
    else
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end
end

local Coins = {}
local firetouch = (typeof(firetouchinterest) == "function" and firetouchinterest)
    or (syn and syn.firetouchinterest)

function Coins.Container()
    local c = Workspace:FindFirstChild(CONFIG.CoinFolder)
    if c then return c end
    c = Workspace:FindFirstChild(CONFIG.CoinFolder, true)
    if c then return c end
    for _, v in ipairs(Workspace:GetChildren()) do
        if (v:IsA("Folder") or v:IsA("Model")) and string.find(string.lower(v.Name), "coin", 1, true) then
            return v
        end
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if (v:IsA("Folder") or v:IsA("Model")) and string.find(string.lower(v.Name), "coin", 1, true) then
            return v
        end
    end
    return nil
end

function Coins.PartOf(coin)
    if coin:IsA("BasePart") then return coin end
    return coin:FindFirstChildWhichIsA("BasePart", true)
end

function Coins.List()
    local cont = Coins.Container()
    local out = {}
    if not cont then return out, nil end
    for _, v in ipairs(cont:GetDescendants()) do
        if v:IsA("BasePart") then table.insert(out, v) end
    end
    if #out == 0 then
        for _, v in ipairs(cont:GetChildren()) do
            local p = Coins.PartOf(v)
            if p then table.insert(out, p) end
        end
    end
    return out, cont
end

function Coins.TouchParts()
    local char = Char(LP)
    local out = {}
    if not char then return out end
    for _, n in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso",
                         "Left Leg", "Right Leg", "LeftFoot", "RightFoot", "Head" }) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then table.insert(out, p) end
    end
    if #out == 0 then
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") then table.insert(out, p) end
        end
    end
    return out
end

function Coins.Touch(part)
    if not firetouch then return false end
    local ok = false
    for _, cp in ipairs(Coins.TouchParts()) do
        pcall(function()
            firetouch(cp, part, 0)
            firetouch(cp, part, 1)
            firetouch(part, cp, 0)
            firetouch(part, cp, 1)
            ok = true
        end)
    end
    return ok
end

function Coins.FlyToPos(goal, timeout, part)
    local deadline = os.clock() + (timeout or S.Coins.FlyTimeout)
    Coins.flying = true
    while not Unloaded and S.Coins.Enabled do
        local h = HRP(LP)
        if not h then break end
        if part and not part.Parent then break end
        local delta = goal - h.Position
        local dist  = delta.Magnitude
        if dist <= 3.5 then break end
        if os.clock() > deadline then break end
        local dt   = task.wait()
        local step = math.min(S.Coins.FlySpeed * dt, dist)
        h.CFrame  = CFrame.new(h.Position + delta.Unit * step)
        h.Velocity = Vector3.zero
        if part then Coins.Touch(part) end
    end
    Coins.flying = false
    local h = HRP(LP)
    if h then h.Velocity = Vector3.zero end
    return true
end

function Coins.FlyTo(part)
    local ok = Coins.FlyToPos(part.Position + Vector3.new(0, 2, 0), S.Coins.FlyTimeout, part)
    Coins.Touch(part)
    return ok
end

function Coins.Take(part, hrp)
    local mode = S.Coins.Mode
    if mode == "Касание" or (mode == "Авто" and firetouch and not S.Coins.Teleport) then
        return Coins.Touch(part)
    end
    if mode == "Телепорт" or S.Coins.Teleport then
        Safe.MoveTo(CFrame.new(part.Position + Vector3.new(0, 1.5, 0)))
        Coins.Touch(part)
        return true
    end
    return Coins.FlyTo(part)
end

function Coins.Diagnose()
    local list, cont = Coins.List()
    local hrp = HRP(LP)
    local near = 0
    if hrp then
        for _, p in ipairs(list) do
            if (p.Position - hrp.Position).Magnitude <= S.Coins.Radius then near = near + 1 end
        end
    end
    local touchable = 0
    for _, p in ipairs(list) do
        if p:FindFirstChildOfClass("TouchTransmitter") then touchable = touchable + 1 end
    end
    return {
        folder    = cont and cont.Name or "не найден",
        path      = cont and cont:GetFullName() or "-",
        total     = #list,
        near      = near,
        touchable = touchable,
        firetouch = firetouch ~= nil,
    }
end

function Coins.Loop()
    while not Unloaded do
        if S.Coins.Enabled then
            local ok = pcall(function()
                local hrp = HRP(LP)
                local list = Coins.List()
                if hrp and #list > 0 then
                    local home  = hrp.CFrame
                    local base  = hrp.Position
                    local moved = false
                    table.sort(list, function(a, b)
                        return (a.Position - base).Magnitude < (b.Position - base).Magnitude
                    end)
                    for _, part in ipairs(list) do
                        if not S.Coins.Enabled then break end
                        local h = HRP(LP)
                        if not h then break end
                        if part.Parent and (part.Position - h.Position).Magnitude <= S.Coins.Radius then
                            local before = h.Position
                            if Coins.Take(part, h) then
                                S.Coins.Collected = S.Coins.Collected + 1
                            end
                            local after = HRP(LP)
                            if after and (after.Position - before).Magnitude > 5 then moved = true end
                            task.wait(S.Coins.Delay)
                        end
                    end
                    local back = HRP(LP)
                    if moved and S.Coins.Return and back then
                        if S.Coins.Mode == "Телепорт" or S.Coins.Teleport then
                            Safe.MoveTo(home)
                        else
                            Coins.FlyToPos(home.Position, 6, nil)
                        end
                    end
                end
            end)
            if not ok then task.wait(0.5) end
        end
        task.wait(0.25)
    end
end

local Noclip = {}
function Noclip.Step()
    if not S.Noclip.Enabled and not Coins.flying then return end
    local char = Char(LP)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            p.CanCollide = false
        end
    end
end

local Walls = { saved = {}, hook = nil, cont = nil }

local function IsCharacterPart(p)
    local m = p:FindFirstAncestorOfClass("Model")
    while m do
        if m:FindFirstChildOfClass("Humanoid") then return true end
        m = m:FindFirstAncestorOfClass("Model")
    end
    return false
end

function Walls.ApplyTo(p)
    if not p:IsA("BasePart") then return end
    if p.Transparency >= 1 then return end
    if IsCharacterPart(p) then return end
    if Walls.cont and p:IsDescendantOf(Walls.cont) then return end
    if Walls.saved[p] == nil then Walls.saved[p] = p.Transparency end
    p.Transparency = S.Walls.Value
end

function Walls.Enable()
    Walls.cont = Coins.Container()
    for _, p in ipairs(Workspace:GetDescendants()) do
        pcall(Walls.ApplyTo, p)
    end
    if not Walls.hook then
        Walls.hook = Workspace.DescendantAdded:Connect(function(p)
            if S.Walls.Enabled then
                task.wait(0.05)
                pcall(Walls.ApplyTo, p)
            end
        end)
        table.insert(Conns, Walls.hook)
    end
end

function Walls.Refresh()
    if not S.Walls.Enabled then return end
    for p, _ in pairs(Walls.saved) do
        if p and p.Parent then p.Transparency = S.Walls.Value end
    end
end

function Walls.Disable()
    for p, t in pairs(Walls.saved) do
        if p and p.Parent then pcall(function() p.Transparency = t end) end
    end
    Walls.saved = {}
    if Walls.hook then Walls.hook:Disconnect() Walls.hook = nil end
end

local Aim = {}
local panEnergy   = 0
local reacquireAt = 0

local FOVCircle = New("Frame", {
    Name                   = "FOVCircle",
    AnchorPoint            = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Size                   = UDim2.fromOffset(300, 300),
    Visible                = false,
    ZIndex                 = 2,
    Parent                 = Overlay,
})
New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FOVCircle })
local FOVStroke = New("UIStroke", {
    Thickness    = 1.6,
    Color        = Color3.fromRGB(255, 255, 255),
    Transparency = 0.25,
    Parent       = FOVCircle,
})

local function ScreenDist(part)
    local pos, on = Camera:WorldToViewportPoint(part.Position)
    if not on then return math.huge, nil end
    local vp = Camera.ViewportSize
    return (Vector2.new(pos.X, pos.Y) - Vector2.new(vp.X / 2, vp.Y / 2)).Magnitude, pos
end

function Aim.FindTarget()
    local myHRP = HRP(LP)
    if not myHRP then return nil end
    local best, bestDist = nil, S.Aim.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            local part = AimPart(plr)
            if part and (part.Position - myHRP.Position).Magnitude <= S.Aim.Dist then
                local sd = ScreenDist(part)
                if sd < bestDist and Visible(part) then
                    best, bestDist = plr, sd
                end
            end
        end
    end
    return best
end

function Aim.Step(dt)

    panEnergy = panEnergy * math.clamp(1 - dt * 6, 0, 1)

    if S.Aim.ShowFOV and S.Aim.Enabled then
        local vp = Camera.ViewportSize
        FOVCircle.Visible  = true
        FOVCircle.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
        FOVCircle.Size     = UDim2.fromOffset(S.Aim.FOV * 2, S.Aim.FOV * 2)
        FOVStroke.Color    = S.Aim.Target and RoleColor(GetRole(S.Aim.Target)) or Color3.fromRGB(255, 255, 255)
    else
        FOVCircle.Visible = false
    end

    if not S.Aim.Enabled then S.Aim.Target = nil return end

    local t = S.Aim.Target
    if t then
        local part = AimPart(t)
        local myHRP = HRP(LP)
        local drop = false
        if not part or not myHRP or not IsValidTarget(t) then
            drop = true
        else
            local sd = ScreenDist(part)
            local wd = (part.Position - myHRP.Position).Magnitude
            if sd > S.Aim.LoseFOV or wd > S.Aim.Dist then drop = true end
            if panEnergy > S.Aim.Unlock then drop = true end
        end
        if drop then
            S.Aim.Target = nil
            reacquireAt  = os.clock() + 0.3
            panEnergy    = 0
        end
    end

    if not S.Aim.Target and os.clock() >= reacquireAt then
        S.Aim.Target = Aim.FindTarget()
    end

    local target = S.Aim.Target
    if target then
        local part = AimPart(target)
        if part then
            local goal  = CFrame.lookAt(Camera.CFrame.Position, part.Position)
            local alpha = math.clamp(S.Aim.Smooth, 0.02, 1)
            Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
        end
    end
end

local Ragdoll = { clone = nil, saved = {} }

function Ragdoll.On()
    local char = Char(LP)
    if not char or Ragdoll.clone then return end
    local hrp = HRP(LP)
    if not hrp then return end

    char.Archivable = true
    local clone = char:Clone()
    clone.Name = LP.Name .. "_Body"

    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("Script") then v:Destroy() end
    end

    local ch = clone:FindFirstChildOfClass("Humanoid")
    if ch then
        ch.PlatformStand = true
        ch.BreakJointsOnDeath = false
        ch:ChangeState(Enum.HumanoidStateType.Physics)
    end

    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("Motor6D") and v.Part0 and v.Part1 then
            local a0 = Instance.new("Attachment")
            local a1 = Instance.new("Attachment")
            a0.CFrame = v.C0
            a1.CFrame = v.C1
            a0.Parent = v.Part0
            a1.Parent = v.Part1
            local bs = Instance.new("BallSocketConstraint")
            bs.Attachment0    = a0
            bs.Attachment1    = a1
            bs.LimitsEnabled  = true
            bs.TwistLimitsEnabled = true
            bs.UpperAngle     = 45
            bs.Parent         = v.Part1
            v:Destroy()
        end
    end
    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored   = false
            v.CanCollide = (v.Name ~= "HumanoidRootPart")
        end
    end

    clone.Parent = Workspace
    Ragdoll.clone = clone

    Ragdoll.saved = {}
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
            Ragdoll.saved[v] = v.Transparency
            v.Transparency = 1
        elseif v:IsA("BillboardGui") or v:IsA("Accessory") then

        end
    end
    local nameTag = char:FindFirstChildOfClass("Humanoid")
    if nameTag then nameTag.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end

    S.Ragdoll.Active = true
end

function Ragdoll.Off()
    if Ragdoll.clone then pcall(function() Ragdoll.clone:Destroy() end) end
    Ragdoll.clone = nil
    for v, t in pairs(Ragdoll.saved) do
        if v and v.Parent then pcall(function() v.Transparency = t end) end
    end
    Ragdoll.saved = {}
    S.Ragdoll.Active = false
end

local Fly = { bv = nil, up = false, down = false }

function Fly.On()
    local hrp = HRP(LP)
    if not hrp or Fly.bv then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name      = "EloFly"
    bv.MaxForce  = Vector3.new(1e6, 1e6, 1e6)
    bv.P         = 8000
    bv.Velocity  = Vector3.zero
    bv.Parent    = hrp
    Fly.bv = bv
end

function Fly.Off()
    if Fly.bv then pcall(function() Fly.bv:Destroy() end) end
    Fly.bv = nil
end

function Fly.Step()
    if not S.Fly.Enabled then
        if Fly.bv then Fly.Off() end
        return
    end
    local hrp, hum = HRP(LP), Hum(LP)
    if not hrp or not hum then return end
    if not Fly.bv or Fly.bv.Parent ~= hrp then Fly.Off() Fly.On() end
    if not Fly.bv then return end

    local dir = hum.MoveDirection
    local v   = Vector3.new(dir.X, 0, dir.Z) * S.Fly.Speed

    local vert = 0
    if Fly.up   or UserInputService:IsKeyDown(Enum.KeyCode.Space)       then vert = vert + 1 end
    if Fly.down or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = vert - 1 end
    v = v + Vector3.new(0, vert * S.Fly.Speed, 0)

    Fly.bv.Velocity = v
end

RunService:BindToRenderStep("EloHub_Aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    pcall(Aim.Step, dt)
end)

Bind(RunService.Stepped, function(_, dt)
    pcall(Noclip.Step)
    pcall(Speed.Step, dt)
    pcall(Fly.Step)
end)

task.spawn(function()
    while not Unloaded do
        pcall(ESP.Update)
        task.wait(0.15)
    end
end)

task.spawn(Coins.Loop)

Bind(LP.CharacterAdded, function(char)
    task.wait(0.8)
    Ragdoll.Off()
    Fly.Off()
    pcall(Jump.Apply)
    if S.Speed.Enabled and S.Speed.Mode == "WalkSpeed" then
        local h = Hum(LP)
        if h then h.WalkSpeed = S.Speed.Value end
    end
end)

Bind(Players.PlayerRemoving, function(plr) ESP.Remove(plr) end)

local Theme = {
    Text   = Color3.fromRGB(32, 38, 52),
    Sub    = Color3.fromRGB(112, 124, 145),
    White  = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(96, 142, 225),
    Soft   = Color3.fromRGB(228, 234, 243),
    Dark   = Color3.fromRGB(60, 70, 92),
}

local function BuildSilk(parent)
    local base = New("Frame", {
        Name                   = "Silk",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.fromRGB(245, 248, 252),
        BorderSizePixel        = 0,
        ZIndex                 = 0,
        Parent                 = parent,
    })
    New("UIGradient", {
        Rotation = 115,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(238, 243, 250)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(214, 224, 238)),
        }),
        Parent = base,
    })

    local waves = {}
    for i = 1, 7 do
        local w = New("Frame", {
            Name                   = "Wave" .. i,
            AnchorPoint            = Vector2.new(0.5, 0.5),
            Position               = UDim2.fromScale(0.5, 0.16 + (i - 1) * 0.13),
            Size                   = UDim2.fromScale(1.75, 0.16),
            Rotation               = -14 + i * 3.2,
            BackgroundColor3       = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.18 + i * 0.045,
            BorderSizePixel        = 0,
            ZIndex                 = 0,
            Parent                 = base,
        })
        New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = w })
        New("UIGradient", {
            Rotation = 0,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(246, 249, 253)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(206, 219, 236)),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0.00, 1),
                NumberSequenceKeypoint.new(0.30, 0.05),
                NumberSequenceKeypoint.new(0.72, 0.12),
                NumberSequenceKeypoint.new(1.00, 1),
            }),
            Parent = w,
        })
        table.insert(waves, w)
    end

    task.spawn(function()
        while not Unloaded and base.Parent do
            for i, w in ipairs(waves) do
                Tween(w, 3.2 + i * 0.35, {
                    Rotation = -14 + i * 3.2 + math.random(-25, 25) / 10,
                    Position = UDim2.fromScale(0.5 + math.random(-25, 25) / 1000, 0.16 + (i - 1) * 0.13),
                }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            end
            task.wait(3.4)
        end
    end)

    local veil = New("Frame", {
        Name                   = "Veil",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.32,
        BorderSizePixel        = 0,
        ZIndex                 = 0,
        Parent                 = base,
    })
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.0, 0.15),
            NumberSequenceKeypoint.new(0.5, 0.45),
            NumberSequenceKeypoint.new(1.0, 0.10),
        }),
        Parent = veil,
    })
    return base
end

local function BuildBackground(parent)
    local holder = New("Frame", {
        Name                   = "BG",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.fromRGB(248, 250, 253),
        BorderSizePixel        = 0,
        ZIndex                 = 0,
        Parent                 = parent,
    })
    local img = New("ImageLabel", {
        Name                   = "Photo",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScaleType              = Enum.ScaleType.Crop,
        Image                  = CONFIG.BackgroundId,
        ImageTransparency      = CONFIG.BackgroundId ~= "" and 0 or 1,
        Visible                = CONFIG.BackgroundId ~= "",
        ZIndex                 = 0,
        Parent                 = holder,
    })
    local silk = BuildSilk(holder)
    silk.Visible = (CONFIG.BackgroundId == "")
    return holder, img, silk
end

local BASE_W, BASE_H = 648, 438

local Main = New("Frame", {
    Name             = "Main",
    Active           = true,
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = UDim2.fromScale(0.5, 0.5),
    Size             = UDim2.fromOffset(BASE_W, BASE_H),
    BackgroundColor3 = Color3.fromRGB(250, 252, 255),
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    Visible          = false,
    ZIndex           = 10,
    Parent           = GUIROOT,
})
Corner(Main, 20)
local MainStroke = Stroke(Main, 2, Theme.White, 0.05)
local UIS_Scale  = New("UIScale", { Scale = 1, Parent = Main })

local BGHolder, BGImage, BGSilk = BuildBackground(Main)

local InnerGlow = New("Frame", {
    Size                   = UDim2.new(1, -8, 1, -8),
    Position               = UDim2.fromOffset(4, 4),
    BackgroundTransparency = 1,
    ZIndex                 = 11,
    Parent                 = Main,
})
Corner(InnerGlow, 16)
Stroke(InnerGlow, 1, Theme.White, 0.55)

local TopBar = New("Frame", {
    Name                   = "TopBar",
    Active                 = true,
    Size                   = UDim2.new(1, 0, 0, 56),
    BackgroundTransparency = 1,
    ZIndex                 = 12,
    Parent                 = Main,
})

local Logo = New("TextLabel", {
    Position               = UDim2.fromOffset(20, 10),
    Size                   = UDim2.fromOffset(200, 26),
    BackgroundTransparency = 1,
    Font                   = Enum.Font.GothamBlack,
    Text                   = "EloHub",
    TextSize               = 24,
    TextColor3             = Theme.Text,
    TextXAlignment         = Enum.TextXAlignment.Left,
    ZIndex                 = 12,
    Parent                 = TopBar,
})
New("UIGradient", {
    Rotation = 25,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 48, 66)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 145, 185)),
    }),
    Parent = Logo,
})

local SubLogo = New("TextLabel", {
    Position               = UDim2.fromOffset(21, 33),
    Size                   = UDim2.fromOffset(280, 14),
    BackgroundTransparency = 1,
    Font                   = Enum.Font.Gotham,
    Text                   = "Murder Mystery 2  |  Mobile Edition",
    TextSize               = 11,
    TextColor3             = Theme.Sub,
    TextXAlignment         = Enum.TextXAlignment.Left,
    ZIndex                 = 12,
    Parent                 = TopBar,
})

local function TopButton(text, offsetX, color)
    local b = New("TextButton", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -offsetX, 0, 28),
        Size             = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.25,
        Text             = text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 15,
        TextColor3       = color or Theme.Dark,
        AutoButtonColor  = false,
        ZIndex           = 13,
        Parent           = TopBar,
    })
    Corner(b, 9)
    Stroke(b, 1.2, Theme.White, 0.1)
    b.MouseEnter:Connect(function() Tween(b, 0.15, { BackgroundTransparency = 0.05 }) end)
    b.MouseLeave:Connect(function() Tween(b, 0.15, { BackgroundTransparency = 0.25 }) end)
    return b
end

local CloseBtn = TopButton("X", 16, Color3.fromRGB(200, 70, 70))
local MinBtn   = TopButton("-", 54)

local Sidebar = New("Frame", {
    Name                   = "Sidebar",
    Active                 = true,
    Position               = UDim2.fromOffset(14, 62),
    Size                   = UDim2.fromOffset(146, BASE_H - 76),
    BackgroundColor3       = Theme.White,
    BackgroundTransparency = 0.42,
    BorderSizePixel        = 0,
    ZIndex                 = 12,
    Parent                 = Main,
})
Corner(Sidebar, 14)
Stroke(Sidebar, 1.4, Theme.White, 0.08)

local TabList = New("ScrollingFrame", {
    Active                 = true,
    Size                   = UDim2.new(1, -12, 1, -50),
    Position               = UDim2.fromOffset(6, 8),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    ScrollBarThickness     = 0,
    AutomaticCanvasSize    = Enum.AutomaticSize.Y,
    CanvasSize             = UDim2.new(),
    ZIndex                 = 12,
    Parent                 = Sidebar,
})
New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabList })

local UserTag = New("TextLabel", {
    AnchorPoint            = Vector2.new(0.5, 1),
    Position               = UDim2.new(0.5, 0, 1, -10),
    Size                   = UDim2.new(1, -16, 0, 30),
    BackgroundColor3       = Theme.White,
    BackgroundTransparency = 0.3,
    Font                   = Enum.Font.GothamMedium,
    Text                   = LP.Name,
    TextSize               = 12,
    TextColor3             = Theme.Sub,
    TextTruncate           = Enum.TextTruncate.AtEnd,
    ZIndex                 = 12,
    Parent                 = Sidebar,
})
Corner(UserTag, 9)
Stroke(UserTag, 1, Theme.White, 0.25)

local Content = New("Frame", {
    Name                   = "Content",
    Position               = UDim2.fromOffset(170, 62),
    Size                   = UDim2.fromOffset(BASE_W - 184, BASE_H - 76),
    BackgroundTransparency = 1,
    ZIndex                 = 12,
    Parent                 = Main,
})

local Tabs, CurrentTab = {}, nil

local function SelectTab(tab)
    for _, t in ipairs(Tabs) do
        local on = (t == tab)
        t.page.Visible = on
        Tween(t.btn, 0.18, { BackgroundTransparency = on and 0.12 or 1 })
        Tween(t.label, 0.18, { TextColor3 = on and Theme.Text or Theme.Sub })
        Tween(t.bar, 0.18, { BackgroundTransparency = on and 0 or 1,
                             Size = UDim2.fromOffset(3, on and 18 or 4) })
        Tween(t.icon, 0.18, {
            BackgroundTransparency = on and 0 or 0.45,
            Size                   = UDim2.fromOffset(on and 12 or 9, on and 12 or 9),
        })
    end
    CurrentTab = tab
end

local function AddTab(name, icon)
    local btn = New("TextButton", {
        Size                   = UDim2.new(1, 0, 0, 36),
        BackgroundColor3       = Theme.White,
        BackgroundTransparency = 1,
        AutoButtonColor        = false,
        Text                   = "",
        ZIndex                 = 12,
        Parent                 = TabList,
    })
    Corner(btn, 10)

    local bar = New("Frame", {
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 4, 0.5, 0),
        Size                   = UDim2.fromOffset(3, 4),
        BackgroundColor3       = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 13,
        Parent                 = btn,
    })
    Corner(bar, 2)

    local ic = New("Frame", {
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 14, 0.5, 0),
        Size                   = UDim2.fromOffset(9, 9),
        BackgroundColor3       = icon or Theme.Accent,
        BackgroundTransparency = 0.45,
        BorderSizePixel        = 0,
        ZIndex                 = 13,
        Parent                 = btn,
    })
    Corner(ic, 5)
    Stroke(ic, 1, Theme.White, 0.3)

    local lbl = New("TextLabel", {
        Position               = UDim2.fromOffset(36, 0),
        Size                   = UDim2.new(1, -42, 1, 0),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.GothamMedium,
        Text                   = name,
        TextSize               = 13,
        TextColor3             = Theme.Sub,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 13,
        Parent                 = btn,
    })

    local page = New("ScrollingFrame", {
        Name                   = name,
        Active                 = true,
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = Color3.fromRGB(160, 175, 200),
        ScrollBarImageTransparency = 0.3,
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        CanvasSize             = UDim2.new(),
        Visible                = false,
        ZIndex                 = 12,
        Parent                 = Content,
    })
    New("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    Pad(page, 2, 10, 2, 14)

    local tab = { btn = btn, label = lbl, icon = ic, bar = bar, page = page }
    table.insert(Tabs, tab)
    btn.MouseButton1Click:Connect(function() SelectTab(tab) end)
    if #Tabs == 1 then SelectTab(tab) end

    local API = {}

    local function Card(h)
        local f = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, h),
            BackgroundColor3       = Theme.White,
            BackgroundTransparency = 0.36,
            BorderSizePixel        = 0,
            ZIndex                 = 12,
            Parent                 = page,
        })
        Corner(f, 11)
        Stroke(f, 1.2, Theme.White, 0.12)
        return f
    end

    function API:Section(text)
        local l = New("TextLabel", {
            Size                   = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamBold,
            Text                   = "  " .. string.upper(text),
            TextSize               = 11,
            TextColor3             = Theme.Sub,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 12,
            Parent                 = page,
        })
        return l
    end

    function API:Label(text)
        local f = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundColor3       = Theme.White,
            BackgroundTransparency = 0.36,
            BorderSizePixel        = 0,
            ZIndex                 = 12,
            Parent                 = page,
        })
        Corner(f, 11)
        Stroke(f, 1.2, Theme.White, 0.12)
        Pad(f, 12, 12, 9, 9)
        local l = New("TextLabel", {
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font                   = Enum.Font.Gotham,
            Text                   = text,
            TextSize               = 12,
            TextColor3             = Theme.Sub,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextYAlignment         = Enum.TextYAlignment.Top,
            TextWrapped            = true,
            RichText               = true,
            ZIndex                 = 13,
            Parent                 = f,
        })
        return l
    end

    function API:Toggle(text, default, callback)
        local f = Card(40)
        New("TextLabel", {
            Size                   = UDim2.new(1, -80, 1, 0),
            Position               = UDim2.fromOffset(13, 0),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamMedium,
            Text                   = text,
            TextSize               = 13,
            TextColor3             = Theme.Text,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextTruncate           = Enum.TextTruncate.AtEnd,
            ZIndex                 = 13,
            Parent                 = f,
        })

        local track = New("Frame", {
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -12, 0.5, 0),
            Size             = UDim2.fromOffset(46, 24),
            BackgroundColor3 = Theme.Soft,
            BorderSizePixel  = 0,
            ZIndex           = 13,
            Parent           = f,
        })
        Corner(track, 12)
        Stroke(track, 1.2, Theme.White, 0.15)

        local knob = New("Frame", {
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 3, 0.5, 0),
            Size             = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Theme.White,
            BorderSizePixel  = 0,
            ZIndex           = 14,
            Parent           = track,
        })
        Corner(knob, 9)
        Stroke(knob, 1, Color3.fromRGB(205, 214, 228), 0.2)

        local hit = New("TextButton", {
            Size                   = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 15,
            Parent                 = f,
        })

        local state = default and true or false
        local function render(anim)
            local t = anim and 0.18 or 0
            Tween(track, t, { BackgroundColor3 = state and Theme.Accent or Theme.Soft })
            Tween(knob,  t, { Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
            Tween(f, t, { BackgroundTransparency = state and 0.18 or 0.36 })
        end
        render(false)

        local obj = {}
        function obj:Set(v, silent)
            state = v and true or false
            render(true)
            if not silent then pcall(callback, state) end
        end
        function obj:Get() return state end

        hit.MouseButton1Click:Connect(function() obj:Set(not state) end)
        if default then task.defer(function() pcall(callback, true) end) end
        return obj
    end

    function API:Slider(text, min, max, default, dec, callback)
        local f = Card(54)
        local title = New("TextLabel", {
            Size                   = UDim2.new(1, -80, 0, 20),
            Position               = UDim2.fromOffset(13, 7),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamMedium,
            Text                   = text,
            TextSize               = 13,
            TextColor3             = Theme.Text,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
            Parent                 = f,
        })
        local valueLbl = New("TextLabel", {
            AnchorPoint            = Vector2.new(1, 0),
            Position               = UDim2.new(1, -13, 0, 7),
            Size                   = UDim2.fromOffset(70, 20),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamBold,
            Text                   = tostring(default),
            TextSize               = 13,
            TextColor3             = Theme.Accent,
            TextXAlignment         = Enum.TextXAlignment.Right,
            ZIndex                 = 13,
            Parent                 = f,
        })

        local bar = New("Frame", {
            Position         = UDim2.fromOffset(13, 36),
            Size             = UDim2.new(1, -26, 0, 6),
            BackgroundColor3 = Theme.Soft,
            BorderSizePixel  = 0,
            ZIndex           = 13,
            Parent           = f,
        })
        Corner(bar, 3)

        local fill = New("Frame", {
            Size             = UDim2.fromScale(0, 1),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 14,
            Parent           = bar,
        })
        Corner(fill, 3)

        local knob = New("Frame", {
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.fromScale(0, 0.5),
            Size             = UDim2.fromOffset(16, 16),
            BackgroundColor3 = Theme.White,
            BorderSizePixel  = 0,
            ZIndex           = 15,
            Parent           = bar,
        })
        Corner(knob, 8)
        Stroke(knob, 1.4, Theme.Accent, 0.15)

        local hit = New("TextButton", {
            Position               = UDim2.fromOffset(0, 24),
            Size                   = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 16,
            Parent                 = f,
        })

        local value = default
        local function apply(v, fire)
            value = math.clamp(Round(v, dec or 0), min, max)
            local a = (max - min) == 0 and 0 or (value - min) / (max - min)
            valueLbl.Text  = tostring(value)
            fill.Size      = UDim2.fromScale(a, 1)
            knob.Position  = UDim2.fromScale(a, 0.5)
            if fire then pcall(callback, value) end
        end
        apply(default, false)

        local dragging = false
        local function fromX(x)
            local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            apply(min + (max - min) * a, true)
        end

        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                fromX(i.Position.X)
            end
        end)
        hit.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        Bind(UserInputService.InputChanged, function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                fromX(i.Position.X)
            end
        end)
        Bind(UserInputService.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local obj = {}
        function obj:Set(v) apply(v, true) end
        function obj:Get() return value end
        if default ~= nil then task.defer(function() pcall(callback, value) end) end
        return obj
    end

    function API:Dropdown(text, options, default, callback)
        local rowH   = 34
        local optH   = 30
        local holder = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 42),
            BackgroundColor3       = Theme.White,
            BackgroundTransparency = 0.36,
            BorderSizePixel        = 0,
            ClipsDescendants       = true,
            ZIndex                 = 12,
            Parent                 = page,
        })
        Corner(holder, 11)
        Stroke(holder, 1.2, Theme.White, 0.12)

        local head = New("TextButton", {
            Size                   = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 13,
            Parent                 = holder,
        })
        New("TextLabel", {
            Size                   = UDim2.new(0.5, -13, 1, 0),
            Position               = UDim2.fromOffset(13, 0),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamMedium,
            Text                   = text,
            TextSize               = 13,
            TextColor3             = Theme.Text,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 14,
            Parent                 = head,
        })
        local cur = New("TextLabel", {
            AnchorPoint            = Vector2.new(1, 0),
            Position               = UDim2.new(1, -30, 0, 0),
            Size                   = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamBold,
            Text                   = tostring(default),
            TextSize               = 12,
            TextColor3             = Theme.Accent,
            TextXAlignment         = Enum.TextXAlignment.Right,
            TextTruncate           = Enum.TextTruncate.AtEnd,
            ZIndex                 = 14,
            Parent                 = head,
        })
        local arrow = New("TextLabel", {
            AnchorPoint            = Vector2.new(1, 0.5),
            Position               = UDim2.new(1, -12, 0.5, 0),
            Size                   = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamBold,
            Text                   = "v",
            TextSize               = 12,
            TextColor3             = Theme.Sub,
            ZIndex                 = 14,
            Parent                 = head,
        })

        local list = New("Frame", {
            Position               = UDim2.fromOffset(0, 42),
            Size                   = UDim2.new(1, 0, 0, #options * optH + 6),
            BackgroundTransparency = 1,
            ZIndex                 = 13,
            Parent                 = holder,
        })
        New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
        Pad(list, 8, 8, 0, 6)

        local selected = default
        local open     = false
        local optBtns  = {}

        local function paint()
            for name, b in pairs(optBtns) do
                local on = (name == selected)
                b.BackgroundTransparency = on and 0.15 or 0.72
                b.TextColor3 = on and Theme.Text or Theme.Sub
            end
            cur.Text = tostring(selected or "-")
        end

        local function addOption(opt)
            local b = New("TextButton", {
                Size                   = UDim2.new(1, 0, 0, optH - 2),
                BackgroundColor3       = Theme.White,
                BackgroundTransparency = 0.72,
                Font                   = Enum.Font.Gotham,
                Text                   = tostring(opt),
                TextSize               = 12,
                TextColor3             = Theme.Sub,
                AutoButtonColor        = false,
                ZIndex                 = 14,
                Parent                 = list,
            })
            Corner(b, 8)
            optBtns[opt] = b
            b.MouseButton1Click:Connect(function()
                selected = opt
                paint()
                pcall(callback, opt)
            end)
        end

        for _, opt in ipairs(options) do addOption(opt) end
        paint()

        head.MouseButton1Click:Connect(function()
            open = not open
            Tween(holder, 0.22, { Size = UDim2.new(1, 0, 0, open and (42 + #options * optH + 6) or 42) })
            Tween(arrow, 0.22, { Rotation = open and 180 or 0 })
        end)

        local obj = {}
        function obj:Set(v) selected = v paint() pcall(callback, v) end
        function obj:Get() return selected end
        function obj:Refresh(newOptions)
            options = newOptions or {}
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            optBtns = {}
            for _, opt in ipairs(options) do addOption(opt) end
            if not table.find(options, selected) then selected = options[1] end
            list.Size = UDim2.new(1, 0, 0, #options * optH + 6)
            if open then
                holder.Size = UDim2.new(1, 0, 0, 42 + #options * optH + 6)
            end
            paint()
            return selected
        end
        return obj
    end

    function API:Button(text, callback)
        local f = New("TextButton", {
            Size                   = UDim2.new(1, 0, 0, 38),
            BackgroundColor3       = Theme.White,
            BackgroundTransparency = 0.28,
            Font                   = Enum.Font.GothamBold,
            Text                   = text,
            TextSize               = 13,
            TextColor3             = Theme.Text,
            AutoButtonColor        = false,
            ZIndex                 = 12,
            Parent                 = page,
        })
        Corner(f, 11)
        Stroke(f, 1.2, Theme.White, 0.1)
        f.MouseButton1Click:Connect(function()
            Tween(f, 0.08, { BackgroundTransparency = 0.05 })
            task.delay(0.12, function() Tween(f, 0.15, { BackgroundTransparency = 0.28 }) end)
            pcall(callback)
        end)
        return f
    end

    function API:Textbox(text, placeholder, callback)
        local f = Card(44)
        New("TextLabel", {
            Size                   = UDim2.new(0.42, -13, 1, 0),
            Position               = UDim2.fromOffset(13, 0),
            BackgroundTransparency = 1,
            Font                   = Enum.Font.GothamMedium,
            Text                   = text,
            TextSize               = 13,
            TextColor3             = Theme.Text,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
            Parent                 = f,
        })
        local box = New("TextBox", {
            AnchorPoint            = Vector2.new(1, 0.5),
            Position               = UDim2.new(1, -12, 0.5, 0),
            Size                   = UDim2.new(0.55, 0, 0, 28),
            BackgroundColor3       = Theme.White,
            BackgroundTransparency = 0.25,
            Font                   = Enum.Font.Gotham,
            PlaceholderText        = placeholder or "",
            Text                   = "",
            TextSize               = 12,
            TextColor3             = Theme.Text,
            ClearTextOnFocus       = false,
            ZIndex                 = 13,
            Parent                 = f,
        })
        Corner(box, 8)
        Stroke(box, 1, Theme.White, 0.2)
        box.FocusLost:Connect(function(enter)
            if enter then pcall(callback, box.Text) end
        end)
        return box
    end

    return API
end

local ToastHolder = New("Frame", {
    AnchorPoint            = Vector2.new(0.5, 0),
    Position               = UDim2.new(0.5, 0, 0, 14),
    Size                   = UDim2.fromOffset(300, 200),
    BackgroundTransparency = 1,
    ZIndex                 = 40,
    Parent                 = GUIROOT,
})
New("UIListLayout", {
    Padding          = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Parent           = ToastHolder,
})

local function Notify(text, color)
    local f = New("Frame", {
        Size                   = UDim2.fromOffset(280, 36),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 41,
        Parent                 = ToastHolder,
    })
    Corner(f, 10)
    local st = Stroke(f, 1.4, Theme.White, 1)
    local bar = New("Frame", {
        Size             = UDim2.fromOffset(4, 20),
        Position         = UDim2.new(0, 10, 0.5, -10),
        BackgroundColor3 = color or Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 42,
        Parent           = f,
    })
    Corner(bar, 2)
    local l = New("TextLabel", {
        Position               = UDim2.fromOffset(22, 0),
        Size                   = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.GothamMedium,
        Text                   = text,
        TextSize               = 12,
        TextColor3             = Theme.Text,
        TextTransparency       = 1,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 42,
        Parent                 = f,
    })
    Tween(f, 0.2, { BackgroundTransparency = 0.08 })
    Tween(st, 0.2, { Transparency = 0.1 })
    Tween(l, 0.2, { TextTransparency = 0 })
    task.delay(2.2, function()
        Tween(f, 0.3, { BackgroundTransparency = 1 })
        Tween(st, 0.3, { Transparency = 1 })
        Tween(l, 0.3, { TextTransparency = 1 })
        Tween(bar, 0.3, { BackgroundTransparency = 1 })
        task.delay(0.35, function() f:Destroy() end)
    end)
end

local RED = Color3.fromRGB(220, 90, 90)

local Teleport = { saved = nil }

function Teleport.Save()
    local hrp = HRP(LP)
    if not hrp then return end
    Teleport.saved = hrp.CFrame
    Notify("Позиция сохранена")
end

function Teleport.Back()
    local hrp = HRP(LP)
    if not hrp or not Teleport.saved then Notify("Точка не задана", RED) return end
    Safe.MoveTo(Teleport.saved)
    Notify("Возврат на точку")
end

function Teleport.To(plr, silent)
    if not plr or plr == LP then
        if not silent then Notify("Игрок не выбран", RED) end
        return false
    end
    local me, them = HRP(LP), HRP(plr)
    if not me or not them then
        if not silent then Notify("Игрок недоступен", RED) end
        return false
    end
    Safe.MoveTo(them.CFrame * CFrame.new(0, 0, S.TP.Offset))
    if not silent then Notify("ТП к " .. plr.Name, RoleColor(GetRole(plr))) end
    return true
end

function Teleport.ByName(name)
    if not name then Notify("Игрок не выбран", RED) return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Name == name then return Teleport.To(p) end
    end
    local low = string.lower(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (string.find(string.lower(p.Name), low, 1, true)
            or string.find(string.lower(p.DisplayName), low, 1, true)) then
            return Teleport.To(p)
        end
    end
    Notify("Игрок не найден", RED)
end

function Teleport.ToRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and Alive(p) and GetRole(p) == role then return Teleport.To(p) end
    end
    Notify(RoleRU[role] .. " не найден", RED)
end

function Teleport.Nearest()
    local me = HRP(LP)
    if not me then return end
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        local h = HRP(p)
        if p ~= LP and Alive(p) and h then
            local d = (h.Position - me.Position).Magnitude
            if d < bd then best, bd = p, d end
        end
    end
    if best then Teleport.To(best) else Notify("Рядом никого нет", RED) end
end

function Teleport.NearestCoin()
    local me = HRP(LP)
    local cont = Coins.Container()
    if not me or not cont then Notify("Монеты не найдены", RED) return end
    local best, bd = nil, math.huge
    for _, c in ipairs(cont:GetChildren()) do
        local part = Coins.PartOf(c)
        if part then
            local d = (part.Position - me.Position).Magnitude
            if d < bd then best, bd = part, d end
        end
    end
    if not best then Notify("Монеты не найдены", RED) return end
    Safe.MoveTo(CFrame.new(best.Position + Vector3.new(0, 2, 0)))
    Notify("ТП к монете (" .. math.floor(bd) .. "m)")
end

local Combat = { busy = false }

local function GetTool(name)
    local c = Char(LP)
    local t = c and c:FindFirstChild(name)
    if t then return t end
    local bp = LP:FindFirstChildOfClass("Backpack")
    return bp and bp:FindFirstChild(name)
end

local function EquipTool(name)
    local t = GetTool(name)
    if not t then return nil end
    local c, h = Char(LP), Hum(LP)
    if c and h and t.Parent ~= c then
        pcall(function() h:EquipTool(t) end)
    end
    return t
end

local function HitParts(char)
    local out = {}
    for _, n in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head" }) do
        local p = char:FindFirstChild(n)
        if p then table.insert(out, p) end
    end
    return out
end

local function KnownRemote(tool)
    local kl = tool:FindFirstChild("KnifeLocal") or tool:FindFirstChild("GunLocal")
    if kl then
        local cb = kl:FindFirstChild("CreateBeam")
        if cb then
            local r = cb:FindFirstChildWhichIsA("RemoteFunction")
                   or cb:FindFirstChildWhichIsA("RemoteEvent")
            if r then return r end
        end
        local r = kl:FindFirstChildWhichIsA("RemoteFunction", true)
               or kl:FindFirstChildWhichIsA("RemoteEvent", true)
        if r then return r end
    end
    return tool:FindFirstChildWhichIsA("RemoteFunction", true)
        or tool:FindFirstChildWhichIsA("RemoteEvent", true)
end

local function CallRemote(rem, sets)
    if rem:IsA("RemoteFunction") then
        for _, a in ipairs(sets) do
            local ok = pcall(function() rem:InvokeServer(table.unpack(a)) end)
            if ok then return true end
        end
        return false
    end
    local fired = false
    for _, a in ipairs(sets) do
        pcall(function() rem:FireServer(table.unpack(a)) end)
        fired = true
    end
    return fired
end

function Combat.Fire(tool, pos, plr)
    if not tool then return false end
    pcall(function() tool:Activate() end)
    if not pos then return false end
    local target = plr and Char(plr) or nil
    local sets = {
        { 1, pos },
        { pos },
        { 1, pos, target },
        { target },
        { "Shoot", pos },
    }
    local main = KnownRemote(tool)
    local fired = false
    if main then fired = CallRemote(main, sets) end
    if not fired and S.Kill.TryRemotes then
        for _, d in ipairs(tool:GetDescendants()) do
            if d ~= main and (d:IsA("RemoteFunction") or d:IsA("RemoteEvent")) then
                if CallRemote(d, sets) then fired = true break end
            end
        end
    end
    return fired
end

function Combat.ToolInfo()
    local tool = GetTool("Gun") or GetTool("Knife")
    if not tool then return "Оружие не найдено: ни ножа, ни револьвера в руках и рюкзаке." end
    local lines = { "Оружие: <b>" .. tool.Name .. "</b>" }
    local all = tool:GetDescendants()
    for i, d in ipairs(all) do
        if i <= 16 then
            table.insert(lines, d.ClassName .. " : " .. d.Name)
        end
    end
    if #all > 16 then table.insert(lines, "... ещё " .. (#all - 16) .. " объектов") end
    return table.concat(lines, "\n")
end

local function SwingAt(tool, plr)
    local char = Char(plr)
    if not tool or not char then return end
    local aim = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    Combat.Fire(tool, aim and aim.Position or nil, plr)
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
    if handle and firetouch then
        for _, p in ipairs(HitParts(char)) do
            pcall(function()
                firetouch(handle, p, 0)
                firetouch(handle, p, 1)
            end)
        end
    end
end

function Combat.FindRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and Alive(p) and GetRole(p) == role then return p end
    end
end

function Combat.Stop()
    Combat.busy = false
end

function Combat.KillAll()
    if Combat.busy then return end
    if MyRole() ~= "Murderer" then
        Notify("Ты не убийца — ножа нет", RED)
        return
    end
    local knife = EquipTool("Knife")
    if not knife then
        Notify("Нож не найден", RED)
        return
    end
    Combat.busy = true
    task.spawn(function()
        local me = HRP(LP)
        local start = me and me.CFrame
        local killed = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if not Combat.busy then break end
            if plr ~= LP and Alive(plr) and GetRole(plr) ~= "Murderer" then
                for _ = 1, S.Kill.Hits do
                    if not Combat.busy then break end
                    local a, b = HRP(LP), HRP(plr)
                    if not a or not b then break end
                    Safe.MoveTo(b.CFrame * CFrame.new(0, 0, -1.5))
                    SwingAt(knife, plr)
                    task.wait(S.Kill.Delay)
                    if not Alive(plr) then break end
                end
                if not Alive(plr) then killed = killed + 1 end
            end
        end
        local back = HRP(LP)
        if S.Kill.Return and start and back then Safe.MoveTo(start) end
        Combat.busy = false
        Notify("Кил-олл: убито " .. killed)
    end)
end

function Combat.ShootMurderer(silent)
    if MyRole() ~= "Sheriff" then
        if not silent then Notify("Ты не шериф", RED) end
        return
    end
    local m = Combat.FindRole("Murderer")
    if not m then
        if not silent then Notify("Убийца не найден", RED) end
        return
    end
    local gun = EquipTool("Gun")
    if not gun then
        if not silent then Notify("Револьвера нет", RED) end
        return
    end
    local part = AimPart(m)
    local me = HRP(LP)
    if not part or not me then return end

    local start = me.CFrame
    if S.Kill.TPShot then
        Safe.MoveTo(part.CFrame * CFrame.new(0, 0, S.Kill.ShotDist))
        task.wait(0.08)
    end
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    task.wait(0.05)
    local fired = Combat.Fire(gun, part.Position, m)
    if not fired then
        task.wait(0.1)
        local again = AimPart(m)
        if again then fired = Combat.Fire(gun, again.Position, m) end
    end
    if not fired and not silent then
        Notify("Ремоут выстрела не сработал - нажми «Тест оружия»", RED)
    end
    if S.Kill.TPShot and S.Kill.Return then
        task.wait(0.2)
        local back = HRP(LP)
        if back then Safe.MoveTo(start) end
    end
    if not silent then Notify("Выстрел по " .. m.Name, S.ESP.Colors.Murderer) end
end

task.spawn(function()
    while not Unloaded do
        pcall(function()
            if S.Kill.AutoMurder and MyRole() == "Murderer" then
                Combat.KillAll()
            end
            if S.Kill.AutoSheriff and MyRole() == "Sheriff" then
                Combat.ShootMurderer(true)
            end
        end)
        task.wait(S.Kill.LoopDelay)
    end
end)

local Spin = { bav = nil, angle = 0, flip = false, cf = nil }

function Spin.On()
    local hrp = HRP(LP)
    if not hrp or Spin.bav then return end
    local bav = Instance.new("BodyAngularVelocity")
    bav.Name            = "EloSpin"
    bav.MaxTorque       = Vector3.new(9e9, 9e9, 9e9)
    bav.AngularVelocity = Vector3.new(0, S.Spin.Rot, 0)
    bav.P               = 9e9
    bav.Parent          = hrp
    Spin.bav = bav
    Spin.cf  = hrp.CFrame
end

function Spin.Off()
    if Spin.bav then pcall(function() Spin.bav:Destroy() end) end
    Spin.bav = nil
    Spin.cf  = nil
end

function Spin.Step(dt)
    if not S.Spin.Enabled then
        if Spin.bav then Spin.Off() end
        return
    end
    local hrp, hum = HRP(LP), Hum(LP)
    if not hrp or not hum or hum.Health <= 0 then return end
    if not Spin.bav or Spin.bav.Parent ~= hrp then
        Spin.Off()
        Spin.On()
    end
    if not Spin.bav then return end

    Spin.bav.AngularVelocity = Vector3.new(0, S.Spin.Rot, 0)
    Spin.flip = not Spin.flip
    local p = S.Spin.Power
    hrp.Velocity = Spin.flip and Vector3.new(p, p, p) or Vector3.new(-p, -p, -p)

    if S.Spin.Hold then
        if not Spin.cf then Spin.cf = hrp.CFrame end
        Spin.angle = (Spin.angle + dt * 28) % (math.pi * 2)
        local pos = Spin.cf.Position + hum.MoveDirection * S.Spin.Move * dt
        Spin.cf = CFrame.new(pos)
        hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, Spin.angle, 0)
    else
        Spin.cf = hrp.CFrame
    end
end

Bind(RunService.Heartbeat, function(dt)
    pcall(Spin.Step, dt)
end)

Bind(UserInputService.InputChanged, function(input, gameProcessed)
    if not S.Aim.Enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        panEnergy = panEnergy + Vector2.new(input.Delta.X, input.Delta.Y).Magnitude
    elseif input.UserInputType == Enum.UserInputType.Touch and not gameProcessed then

        local vp = Camera.ViewportSize
        if input.Position.X > vp.X * 0.38 then
            panEnergy = panEnergy + Vector2.new(input.Delta.X, input.Delta.Y).Magnitude
        end
    end
end)

local FlyPad = New("Frame", {
    Name                   = "FlyPad",
    AnchorPoint            = Vector2.new(1, 1),
    Position               = UDim2.new(1, -24, 1, -140),
    Size                   = UDim2.fromOffset(58, 128),
    BackgroundTransparency = 1,
    Visible                = false,
    ZIndex                 = 20,
    Parent                 = GUIROOT,
})

local function PadButton(txt, y, onDown, onUp)
    local b = New("TextButton", {
        Position               = UDim2.fromOffset(0, y),
        Size                   = UDim2.fromOffset(58, 58),
        BackgroundColor3       = Theme.White,
        BackgroundTransparency = 0.25,
        Font                   = Enum.Font.GothamBold,
        Text                   = txt,
        TextSize               = 15,
        TextColor3             = Theme.Text,
        AutoButtonColor        = false,
        ZIndex                 = 21,
        Parent                 = FlyPad,
    })
    Corner(b, 29)
    Stroke(b, 1.6, Theme.White, 0.05)
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            onDown()
            Tween(b, 0.1, { BackgroundTransparency = 0.05 })
        end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            onUp()
            Tween(b, 0.15, { BackgroundTransparency = 0.25 })
        end
    end)
    return b
end

PadButton("UP", 0,  function() Fly.up = true end,   function() Fly.up = false end)
PadButton("DN", 70, function() Fly.down = true end, function() Fly.down = false end)

local OpenBtn = New("TextButton", {
    Name                   = "EloOpen",
    AnchorPoint            = Vector2.new(0, 0.5),
    Position               = UDim2.new(0, 18, 0.32, 0),
    Size                   = UDim2.fromOffset(52, 52),
    BackgroundColor3       = Theme.White,
    BackgroundTransparency = 0.15,
    Font                   = Enum.Font.GothamBlack,
    Text                   = "E",
    TextSize               = 22,
    TextColor3             = Theme.Text,
    AutoButtonColor        = false,
    ZIndex                 = 30,
    Parent                 = GUIROOT,
})
Corner(OpenBtn, 26)
Stroke(OpenBtn, 2, Theme.White, 0.02)
New("UIGradient", {
    Rotation = 40,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(216, 226, 240)),
    }),
    Parent = OpenBtn,
})
Dragify(OpenBtn)

local menuOpen, collapsed = false, false

local function ApplyScale()
    local vp = Camera.ViewportSize
    S.UI.Auto = math.clamp(math.min(vp.Y / 760, vp.X / 1000), 0.45, 1)
    UIS_Scale.Scale = S.UI.Auto * S.UI.Scale
end
ApplyScale()
Bind(Camera:GetPropertyChangedSignal("ViewportSize"), ApplyScale)

local function SetMenu(open)
    menuOpen = open
    if open then
        Main.Visible = true
        Main.Size    = UDim2.fromOffset(BASE_W * 0.55, BASE_H * 0.55)
        MainStroke.Transparency = 1
        Tween(Main, 0.38, { Size = UDim2.fromOffset(BASE_W, collapsed and 56 or BASE_H) },
              Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(MainStroke, 0.4, { Transparency = 0.05 })
        Tween(OpenBtn, 0.2, { BackgroundTransparency = 0.55, TextTransparency = 0.5 })
    else
        Tween(Main, 0.24, { Size = UDim2.fromOffset(BASE_W * 0.6, BASE_H * 0.6) },
              Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Tween(MainStroke, 0.2, { Transparency = 1 })
        Tween(OpenBtn, 0.2, { BackgroundTransparency = 0.15, TextTransparency = 0 })
        task.delay(0.26, function() if not menuOpen then Main.Visible = false end end)
    end
end

do
    local pressing, pressPos = false, nil
    OpenBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            pressing, pressPos = true, i.Position
        end
    end)
    Bind(UserInputService.InputEnded, function(i)
        if pressing and (i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch) then
            pressing = false
            if pressPos and (i.Position - pressPos).Magnitude < 14 then
                SetMenu(not menuOpen)
            end
        end
    end)
end

CloseBtn.MouseButton1Click:Connect(function() SetMenu(false) end)
MinBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    Tween(Main, 0.28, { Size = UDim2.fromOffset(BASE_W, collapsed and 56 or BASE_H) })
end)

Dragify(Main, TopBar)

Bind(UserInputService.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift or i.KeyCode == Enum.KeyCode.Insert then
        SetMenu(not menuOpen)
    end
end)

local Panic = {}

local Home     = AddTab("Главная",   Color3.fromRGB(96, 142, 225))
local PlayerT  = AddTab("Игрок",     Color3.fromRGB(72, 190, 205))
local TPTab    = AddTab("Телепорт",  Color3.fromRGB(140, 130, 235))
local VisualT  = AddTab("Визуал",    Color3.fromRGB(52, 224, 122))
local AimT     = AddTab("Аим",       Color3.fromRGB(240, 165, 60))
local KillT    = AddTab("Убийство",  Color3.fromRGB(255, 62, 62))
local MiscT    = AddTab("Прочее",    Color3.fromRGB(180, 190, 210))
local SetsT    = AddTab("Настройки", Color3.fromRGB(120, 132, 155))

Home:Section("Статус")
local RoleLabel = Home:Label("Твоя роль: <b>...</b>")
local CoinLabel = Home:Label("Монет собрано: <b>0</b>")
local PingLabel = Home:Label("Игроков на сервере: <b>0</b>")

Home:Section("Легенда ESP")
Home:Label('<font color="rgb(255,62,62)">УБИЙЦА</font>   <font color="rgb(58,132,255)">ШЕРИФ</font>   <font color="rgb(52,224,122)">НЕВИННЫЙ</font>')

Home:Section("Быстрые действия")
Home:Button("Сбросить персонажа", function()
    local h = Hum(LP)
    if h then h.Health = 0 end
    Notify("Персонаж сброшен")
end)
Home:Button("Выключить всё (паника)", function()
    for _, t in ipairs(Panic) do pcall(function() t:Set(false) end) end
    Notify("Все функции выключены", Color3.fromRGB(220, 90, 90))
end)
Home:Label("ПК: <b>RightShift</b> или <b>Insert</b> — открыть/закрыть меню.\nТелефон: круглая кнопка <b>E</b> (её можно перетаскивать).")

PlayerT:Section("Движение")
table.insert(Panic, PlayerT:Toggle("Спид хак", false, function(v)
    S.Speed.Enabled = v
    if not v then Speed.Reset() end
    Notify("Спид хак: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
PlayerT:Slider("Скорость", 16, 250, 32, 0, function(v) S.Speed.Value = v end)
PlayerT:Dropdown("Режим скорости", { "CFrame", "WalkSpeed" }, "CFrame", function(v)
    S.Speed.Mode = v
    Speed.Reset()
end)
PlayerT:Label("<b>CFrame</b> — мягкий сдвиг, работает с джойстиком и реже ловится античитом.\n<b>WalkSpeed</b> — классика, быстрее, но заметнее.")

PlayerT:Section("Прыжок")
table.insert(Panic, PlayerT:Toggle("Высокий прыжок", false, function(v)
    S.Jump.Enabled = v
    Jump.Apply()
end))
PlayerT:Slider("Сила прыжка", 50, 350, 50, 0, function(v)
    S.Jump.Value = v
    Jump.Apply()
end)

PlayerT:Section("Проходимость")
table.insert(Panic, PlayerT:Toggle("Wallhack — проход сквозь стены", false, function(v)
    S.Noclip.Enabled = v
    if not v then
        local c = Char(LP)
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    pcall(function() p.CanCollide = true end)
                end
            end
        end
    end
    Notify("Wallhack: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))

PlayerT:Section("Полёт")
table.insert(Panic, PlayerT:Toggle("Полёт", false, function(v)
    S.Fly.Enabled = v
    FlyPad.Visible = v
    if v then Fly.On() else Fly.Off() end
    Notify("Полёт: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
PlayerT:Slider("Скорость полёта", 20, 300, 60, 0, function(v) S.Fly.Speed = v end)
PlayerT:Label("Направление — джойстик/WASD, высота — кнопки <b>UP / DN</b> справа (на ПК ещё Space / Ctrl).")

local function PlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    if #t == 0 then table.insert(t, "нет игроков") end
    return t
end

TPTab:Section("Телепорт к игроку")
local TPDrop
TPDrop = TPTab:Dropdown("Цель", PlayerNames(), PlayerNames()[1], function(v)
    S.TP.Name = v
end)
S.TP.Name = PlayerNames()[1]

TPTab:Button("Обновить список игроков", function()
    S.TP.Name = TPDrop:Refresh(PlayerNames())
    Notify("Список обновлён")
end)
TPTab:Slider("Отступ от цели", 0, 15, 3, 1, function(v) S.TP.Offset = v end)
TPTab:Button("ТП к выбранному", function() Teleport.ByName(S.TP.Name) end)

TPTab:Section("Быстрый ТП")
TPTab:Button("ТП к убийце", function() Teleport.ToRole("Murderer") end)
TPTab:Button("ТП к шерифу", function() Teleport.ToRole("Sheriff") end)
TPTab:Button("ТП к ближайшему игроку", function() Teleport.Nearest() end)
TPTab:Button("ТП к ближайшей монете", function() Teleport.NearestCoin() end)

TPTab:Section("Точка возврата")
TPTab:Button("Сохранить позицию", function() Teleport.Save() end)
TPTab:Button("Вернуться на позицию", function() Teleport.Back() end)
TPTab:Label("Список обновляется сам при заходе и выходе игроков. Отступ — на сколько студов встать позади цели.")

Bind(Players.PlayerAdded, function()
    task.wait(1)
    if TPDrop then S.TP.Name = TPDrop:Refresh(PlayerNames()) end
end)
Bind(Players.PlayerRemoving, function()
    task.wait(0.5)
    if TPDrop then S.TP.Name = TPDrop:Refresh(PlayerNames()) end
end)

VisualT:Section("ESP игроков")
table.insert(Panic, VisualT:Toggle("Включить ESP", false, function(v)
    S.ESP.Enabled = v
    if not v then ESP.SetAll(false) end
    Notify("ESP: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
VisualT:Toggle("Заливка тела (Chams)", true, function(v) S.ESP.Chams = v end)
VisualT:Toggle("Имена", true,      function(v) S.ESP.Names = v end)
VisualT:Toggle("Роль", true,       function(v) S.ESP.Role = v end)
VisualT:Toggle("Дистанция", true,  function(v) S.ESP.Distance = v end)
VisualT:Toggle("Трейсеры (линии)", false, function(v) S.ESP.Tracers = v end)
VisualT:Slider("Дальность ESP", 100, 3000, 1200, 0, function(v) S.ESP.MaxDist = v end)
VisualT:Label('Цвета: <font color="rgb(255,62,62)">убийца</font> / <font color="rgb(58,132,255)">шериф</font> / <font color="rgb(52,224,122)">невинный</font>. Роль определяется по ножу и револьверу, обновляется автоматически.')

VisualT:Section("Стены")
table.insert(Panic, VisualT:Toggle("Прозрачные стены", false, function(v)
    S.Walls.Enabled = v
    if v then Walls.Enable() else Walls.Disable() end
    Notify("Прозрачность стен: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
VisualT:Slider("Уровень прозрачности", 0, 1, 0.65, 2, function(v)
    S.Walls.Value = v
    Walls.Refresh()
end)
VisualT:Button("Обновить стены (после новой карты)", function()
    if S.Walls.Enabled then Walls.Enable() Notify("Стены обновлены") end
end)

AimT:Section("Захват цели")
table.insert(Panic, AimT:Toggle("Включить AIM", false, function(v)
    S.Aim.Enabled = v
    if not v then S.Aim.Target = nil end
    Notify("AIM: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
AimT:Dropdown("Приоритет цели",
    { "Авто (по роли)", "Только убийца", "Только шериф", "Любой игрок" },
    "Авто (по роли)", function(v) S.Aim.Mode = v S.Aim.Target = nil end)
AimT:Dropdown("Точка прицеливания", { "Head", "HumanoidRootPart" }, "Head",
    function(v) S.Aim.Part = v end)

AimT:Section("Настройка")
AimT:Slider("Жёсткость лока (1 = хард)", 0.05, 1, 0.35, 2, function(v) S.Aim.Smooth = v end)
AimT:Slider("Дальность захвата (studs)", 50, 2000, 400, 0, function(v) S.Aim.Dist = v end)
AimT:Slider("Площадь захвата (радиус, px)", 30, 700, 150, 0, function(v) S.Aim.FOV = v end)
AimT:Slider("Радиус срыва цели (px)", 60, 1000, 300, 0, function(v) S.Aim.LoseFOV = v end)
AimT:Slider("Чувствительность срыва", 20, 400, 90, 0, function(v) S.Aim.Unlock = v end)
AimT:Toggle("Показывать круг захвата", true, function(v) S.Aim.ShowFOV = v end)
AimT:Toggle("Только видимые цели", false, function(v) S.Aim.VisCheck = v end)

AimT:Section("Как работает")
AimT:Label("Цель ловится, если она внутри круга захвата и ближе дальности. Пока цель держится — камера жёстко ведёт её.\nЕсли <b>отвести камеру</b> (свайп по правой половине экрана / мышь) сильнее чувствительности срыва — цель отпускается.")
AimT:Label("Авто-режим: ты <font color=\"rgb(255,62,62)\">убийца</font> → цели шериф и невинные. Ты <font color=\"rgb(58,132,255)\">шериф</font> → только убийца. Ты невинный → убийца.")

KillT:Section("За убийцу (нож)")
KillT:Button("Убить всех (кил-олл)", function() Combat.KillAll() end)
table.insert(Panic, KillT:Toggle("Авто-убийство всех", false, function(v)
    S.Kill.AutoMurder = v
    if not v then Combat.Stop() end
    Notify("Авто-килл (убийца): " .. (v and "ВКЛ" or "ВЫКЛ"), v and S.ESP.Colors.Murderer or nil)
end))
KillT:Slider("Задержка удара", 0.05, 1, 0.2, 2, function(v) S.Kill.Delay = v end)
KillT:Slider("Ударов по цели", 1, 8, 2, 0, function(v) S.Kill.Hits = v end)

KillT:Section("За шерифа (револьвер)")
KillT:Button("Убить убийцу", function() Combat.ShootMurderer() end)
table.insert(Panic, KillT:Toggle("Авто-убийство мардера", false, function(v)
    S.Kill.AutoSheriff = v
    Notify("Авто-килл (шериф): " .. (v and "ВКЛ" or "ВЫКЛ"), v and S.ESP.Colors.Sheriff or nil)
end))
KillT:Toggle("Телепорт к цели перед выстрелом", false, function(v) S.Kill.TPShot = v end)
KillT:Slider("Дистанция выстрела", 3, 40, 8, 0, function(v) S.Kill.ShotDist = v end)

KillT:Section("Общее")
KillT:Toggle("Возвращаться на своё место", true, function(v) S.Kill.Return = v end)
KillT:Slider("Пауза авто-режима", 0.2, 5, 1, 2, function(v) S.Kill.LoopDelay = v end)
KillT:Button("СТОП (прервать кил-олл)", function()
    Combat.Stop()
    Notify("Остановлено", Color3.fromRGB(220, 90, 90))
end)
KillT:Toggle("Пробовать все ремоуты оружия", true, function(v) S.Kill.TryRemotes = v end)
local ToolDiag = KillT:Label("Если выстрел не проходит — нажми «Тест оружия» и пришли мне этот список.")
KillT:Button("Тест оружия", function()
    ToolDiag.Text = Combat.ToolInfo()
    Notify("Структура оружия выведена ниже")
end)
KillT:Label("Кил-олл работает только когда ты <b>убийца</b>: телепорт к каждому и удар ножом. Авто-режим за <b>шерифа</b> наводит револьвер на мардера, дёргает ремоут выстрела и жмёт Activate.")

KillT:Section("Мега-крутилка")
table.insert(Panic, KillT:Toggle("Мега-крутилка (отбрасывает игроков)", false, function(v)
    S.Spin.Enabled = v
    if v then Spin.On() else Spin.Off() end
    Notify("Крутилка: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
KillT:Slider("Сила отброса", 1000, 60000, 12000, 0, function(v) S.Spin.Power = v end)
KillT:Slider("Скорость вращения", 2000, 80000, 20000, 0, function(v) S.Spin.Rot = v end)
KillT:Slider("Скорость ходьбы в крутилке", 5, 80, 22, 0, function(v) S.Spin.Move = v end)
KillT:Toggle("Держать позицию (не улетать самому)", true, function(v) S.Spin.Hold = v end)
KillT:Label("Персонаж бешено крутится: любого, кто подойдёт вплотную, выбрасывает за карту. Держи опцию «не улетать самому» включённой, иначе улетишь вместе с ним.")

MiscT:Section("Монеты (" .. CONFIG.CoinName .. " в " .. CONFIG.CoinFolder .. ")")
table.insert(Panic, MiscT:Toggle("Авто-сбор монет", false, function(v)
    S.Coins.Enabled = v
    Notify("Авто-сбор монет: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
MiscT:Slider("Радиус сбора", 50, 2000, 400, 0, function(v) S.Coins.Radius = v end)
MiscT:Slider("Задержка между монетами", 0.02, 1, 0.12, 2, function(v) S.Coins.Delay = v end)
MiscT:Dropdown("Способ сбора", { "Авто", "Касание", "Полёт", "Телепорт" }, "Авто", function(v)
    S.Coins.Mode = v
    S.Coins.Teleport = (v == "Телепорт")
end)
MiscT:Slider("Скорость полёта к монете", 40, 400, 120, 0, function(v) S.Coins.FlySpeed = v end)
MiscT:Slider("Лимит времени на монету", 1, 8, 3, 1, function(v) S.Coins.FlyTimeout = v end)
MiscT:Toggle("Возвращаться на место после сбора", true, function(v) S.Coins.Return = v end)
local CoinLabel2 = MiscT:Label("Собрано за сессию: <b>0</b>")
local CoinDiag = MiscT:Label("Если монеты не собираются — нажми «Тест монет»: покажет, что скрипт реально видит на карте.")
MiscT:Button("Тест монет", function()
    local d = Coins.Diagnose()
    CoinDiag.Text = "Папка: <b>" .. d.path .. "</b>\nЧастей всего: <b>" .. d.total
        .. "</b>, в радиусе: <b>" .. d.near .. "</b>, с TouchTransmitter: <b>" .. d.touchable
        .. "</b>\nfiretouchinterest: <b>" .. (d.firetouch and "есть" or "нет") .. "</b>"
    Notify("Монет: " .. d.total .. ", рядом: " .. d.near, d.total > 0 and nil or RED)
end)
MiscT:Label(firetouch and "Метод <b>Касание</b> доступен: монеты берутся на месте, без движения."
                       or "В этом эксплойте нет <b>firetouchinterest</b> — работает режим <b>Полёт</b>.")
MiscT:Label("<b>Полёт</b> — персонаж плавно летит к каждой монете сквозь стены (ноклип включается сам на время полёта) и возвращается назад. <b>Телепорт</b> — мгновенный рывок, ловится античитом чаще.")

MiscT:Section("Тело")
table.insert(Panic, MiscT:Toggle("Фейк рагдолл", false, function(v)
    if v then Ragdoll.On() else Ragdoll.Off() end
    Notify("Фейк рагдолл: " .. (v and "ВКЛ" or "ВЫКЛ"))
end))
MiscT:Label("Оставляет на месте «тело», а твой персонаж становится невидимым для тебя и продолжает двигаться. Эффект локальный (виден только тебе).")
MiscT:Button("Сбросить персонажа", function()
    Ragdoll.Off()
    local h = Hum(LP)
    if h then h.Health = 0 end
end)

SetsT:Section("Интерфейс")
SetsT:Slider("Размер UI", 0.6, 1.6, 1, 2, function(v)
    S.UI.Scale = v
    ApplyScale()
end)
SetsT:Textbox("ID фона", "rbxassetid://...", function(txt)
    txt = (txt or ""):gsub("%s+", "")
    if txt == "" then return end
    if not txt:match("^rbxassetid://") then txt = "rbxassetid://" .. txt:gsub("%D", "") end
    CONFIG.BackgroundId = txt
    BGImage.Image             = txt
    BGImage.ImageTransparency = 0
    BGImage.Visible           = true
    BGSilk.Visible            = false
    Notify("Фон обновлён")
end)
SetsT:Button("Вернуть стандартный фон", function()
    CONFIG.BackgroundId = ""
    BGImage.Visible = false
    BGSilk.Visible  = true
    Notify("Фон по умолчанию")
end)
SetsT:Button("Меню по центру", function()
    Main.Position = UDim2.fromScale(0.5, 0.5)
end)

SetsT:Section("Анти-кик")
SetsT:Toggle("Блокировать кик клиента", true, function(v)
    S.Safe.BlockKick = v
    if v and not Safe.Hook() then
        Notify("Хук кика недоступен в этом эксплойте", RED)
    end
end)
SetsT:Toggle("Блокировать телепорт в лобби", true, function(v)
    S.Safe.BlockTP = v
    if v then Safe.Hook() end
end)
SetsT:Toggle("Плавный телепорт (шагами)", true, function(v) S.Safe.SoftTP = v end)
SetsT:Slider("Длина шага телепорта", 10, 200, 45, 0, function(v) S.Safe.TPStep = v end)
SetsT:Slider("Пауза между шагами", 0.02, 0.3, 0.06, 2, function(v) S.Safe.StepWait = v end)
SetsT:Button("Отключить локальный античит", function()
    local n = Safe.KillAntiCheat()
    Notify("Отключено скриптов: " .. n, n > 0 and nil or RED)
end)
SetsT:Label("Кик обычно прилетает за резкий телепорт и большую скорость. Держи <b>плавный телепорт</b> включённым, скорость до 60-80, а крутилку включай короткими включениями.")

SetsT:Section("Система")
SetsT:Button("Выключить все функции", function()
    for _, t in ipairs(Panic) do pcall(function() t:Set(false) end) end
    Notify("Все функции выключены", Color3.fromRGB(220, 90, 90))
end)
SetsT:Button("Выгрузить EloHub", function()
    if _G.EloHub_Unload then _G.EloHub_Unload() end
end)
SetsT:Label("<b>EloHub</b> | Murder Mystery 2 | Mobile Edition\nВсе функции клиентские. Используй на своём плейсе / приватном сервере.")

task.spawn(function()
    while not Unloaded do
        pcall(function()
            local role = MyRole()
            local col  = RoleColor(role)
            RoleLabel.Text = string.format(
                'Твоя роль: <b><font color="rgb(%d,%d,%d)">%s</font></b>',
                math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255),
                RoleRU[role])
            CoinLabel.Text  = "Монет собрано: <b>" .. S.Coins.Collected .. "</b>"
            CoinLabel2.Text = "Собрано за сессию: <b>" .. S.Coins.Collected .. "</b>"
            PingLabel.Text  = "Игроков на сервере: <b>" .. #Players:GetPlayers() .. "</b>"
        end)
        task.wait(0.5)
    end
end)

local function PlayIntro(done)
    local scrim = New("Frame", {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.fromRGB(18, 22, 32),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 50,
        Parent                 = GUIROOT,
    })

    local ring = New("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        Size                   = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        ZIndex                 = 51,
        Parent                 = scrim,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
    local ringStroke = New("UIStroke", {
        Thickness = 2, Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Parent = ring })

    local ring2 = ring:Clone()
    ring2.Parent = scrim
    local ringStroke2 = ring2:FindFirstChildOfClass("UIStroke")

    local logo = New("TextLabel", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        Size                   = UDim2.fromOffset(420, 74),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.GothamBlack,
        Text                   = "EloHub",
        TextSize               = 12,
        TextColor3             = Color3.fromRGB(255, 255, 255),
        TextTransparency       = 1,
        ZIndex                 = 52,
        Parent                 = scrim,
    })
    New("UIGradient", {
        Rotation = 20,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(226, 236, 250)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(168, 192, 226)),
        }),
        Parent = logo,
    })

    local sub = New("TextLabel", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 44),
        Size                   = UDim2.fromOffset(420, 20),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.Gotham,
        Text                   = "MURDER  MYSTERY  2",
        TextSize               = 13,
        TextColor3             = Color3.fromRGB(215, 226, 242),
        TextTransparency       = 1,
        ZIndex                 = 52,
        Parent                 = scrim,
    })

    local line = New("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 70),
        Size                   = UDim2.fromOffset(0, 2),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.2,
        BorderSizePixel        = 0,
        ZIndex                 = 52,
        Parent                 = scrim,
    })
    Corner(line, 1)

    Tween(scrim, 0.35, { BackgroundTransparency = 0.28 })
    Tween(logo, 0.55, { TextSize = 54, TextTransparency = 0 }, Enum.EasingStyle.Back)
    task.delay(0.25, function()
        Tween(sub, 0.4, { TextTransparency = 0.05 })
        Tween(line, 0.55, { Size = UDim2.fromOffset(230, 2) })
    end)
    task.delay(0.1, function()
        Tween(ringStroke, 0.1, { Transparency = 0.4 })
        Tween(ring, 1.1, { Size = UDim2.fromOffset(340, 340) }, Enum.EasingStyle.Quint)
        Tween(ringStroke, 1.1, { Transparency = 1 })
    end)
    task.delay(0.42, function()
        Tween(ringStroke2, 0.1, { Transparency = 0.55 })
        Tween(ring2, 1.2, { Size = UDim2.fromOffset(520, 520) }, Enum.EasingStyle.Quint)
        Tween(ringStroke2, 1.2, { Transparency = 1 })
    end)

    task.delay(1.65, function()
        Tween(logo, 0.35, { TextTransparency = 1, TextSize = 64 })
        Tween(sub, 0.3, { TextTransparency = 1 })
        Tween(line, 0.3, { BackgroundTransparency = 1 })
        Tween(scrim, 0.4, { BackgroundTransparency = 1 })
        task.delay(0.42, function()
            scrim:Destroy()
            if done then done() end
        end)
    end)
end

_G.EloHub_Unload = function()
    if Unloaded then return end
    Unloaded = true
    pcall(function() S.Aim.Enabled = false end)
    pcall(function() RunService:UnbindFromRenderStep("EloHub_Aim") end)
    S.Kill.AutoMurder  = false
    S.Kill.AutoSheriff = false
    S.Spin.Enabled     = false
    pcall(Combat.Stop)
    pcall(Spin.Off)
    pcall(Ragdoll.Off)
    pcall(Fly.Off)
    pcall(Walls.Disable)
    pcall(Speed.Reset)
    S.Noclip.Enabled = false
    for plr, _ in pairs(ESP.objects) do pcall(ESP.Remove, plr) end
    for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    Conns = {}
    pcall(function() GUIROOT:Destroy() end)
    _G.EloHub_Unload = nil
end

if S.Safe.BlockKick or S.Safe.BlockTP then Safe.Hook() end

PlayIntro(function()
    SetMenu(true)
    Notify("EloHub загружен", Theme.Accent)
    if not Safe.hooked then
        task.delay(1.2, function()
            Notify("Анти-кик недоступен: нет hookmetamethod", RED)
        end)
    end
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title    = "EloHub",
        Text     = "Murder Mystery 2 — загружено",
        Duration = 4,
    })
end)
