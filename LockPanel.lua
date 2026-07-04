-- ============================================================
--  LOCKPANEL  by naraka   |   key: ALLHAILNARAKA
--  Load:  loadstring(readfile("LockPanel.lua"))()
--  Revision: aimbot=closest-part+full XY trace | hitbox + rapid fire removed
--            | perf pass: hoisted per-frame allocations, memoized keycodes
-- ============================================================
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local CoreGui=game:GetService("CoreGui")
local LP=Players.LocalPlayer
local genv=getgenv()
local rG=getrenv()._G

genv.Cfg=genv.Cfg or {}
local C=genv.Cfg
pcall(function() if readfile then
    local d=HttpService:JSONDecode(readfile("LockPanelConfig.json"))
    if type(d)=="table" then for k,v in pairs(d) do if C[k]==nil then C[k]=v end end end
end end)
local function def(k,v) if C[k]==nil then C[k]=v end end
def("Master",true)
def("SnapPacket",false)
def("RangeOn",false) def("RangeOverride",2000) def("SpreadOn",false) def("SpreadFactor",0)
def("Trigger",false) def("TriggerMult",1.5) def("TriggerBind","MouseButton2")
def("Sauce",false) def("Smoothness",10) def("Shake",false) def("SauceBind","MouseButton1")
def("ShotDetect",false) def("ShotTarget","") def("ShotDelay",0) def("ShotBind","F")
def("WallCheck",false) def("KnockCheck",false)
def("ESP",false) def("Spectate",false) def("SpectateTarget","")

local ACCENT1=Color3.fromRGB(196,24,32)
local ACCENT2=Color3.fromRGB(90,10,16)
local BG=Color3.fromRGB(12,12,14)
local PANEL=Color3.fromRGB(22,22,26)
local PANEL2=Color3.fromRGB(36,36,42)
local TXT=Color3.fromRGB(235,235,240)
local MUT=Color3.fromRGB(120,120,132)
local function notify(m) pcall(function() game.StarterGui:SetCore("SendNotification",{Title="LOCKPANEL",Text=m,Duration=2}) end) end
local function new(cls,props,kids) local o=Instance.new(cls) for k,v in pairs(props or {}) do if k~="Parent" then o[k]=v end end for _,c in ipairs(kids or {}) do c.Parent=o end if props and props.Parent then o.Parent=props.Parent end return o end
local function corner(o,r) new("UICorner",{CornerRadius=UDim.new(0,r or 8),Parent=o}) end
local function stroke(o,col,tr) new("UIStroke",{Color=col or PANEL2,Thickness=1,Transparency=tr or 0,Parent=o}) end
local function guiRoot() local gp pcall(function() gp=gethui and gethui() end) return gp or CoreGui end
local function friendly(n) if n=="MouseButton1" then return "LMB" elseif n=="MouseButton2" then return "RMB" elseif n=="MouseButton3" then return "MMB" else return n end end
local kcCache={} -- memoize keycode lookups so the hot loops don't pcall+alloc every frame
local function keyCodeFor(b) local c=kcCache[b] if c==nil then local ok,kc=pcall(function() return Enum.KeyCode[b] end) c=(ok and kc) or false kcCache[b]=c end return c end
local function isHeld(b)
    if b=="MouseButton1" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    if b=="MouseButton2" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if b=="MouseButton3" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) end
    local kc=keyCodeFor(b) return kc~=false and UIS:IsKeyDown(kc)
end
local function overPanel()
    local g=genv.__lpGui if not g or not g.Enabled then return false end
    if g:FindFirstChild("Picker") then return true end
    local w=g:FindFirstChild("Window") if not w then return false end
    local mp=UIS:GetMouseLocation() local wp,ws=w.AbsolutePosition,w.AbsoluteSize
    return mp.X>=wp.X-8 and mp.X<=wp.X+ws.X+8 and mp.Y>=wp.Y-8 and mp.Y<=wp.Y+ws.Y+8
end

local function runPanel()
    pcall(function() local GC=require(RS.Modules.Gun.GunClient)
        if not genv.__origShoot then genv.__origShoot=GC.Shoot GC.Shoot=function(s,m,p) if C.Master and C.RangeOn and type(p)=="table" and type(p.Range)=="number" then p.Range=math.max(p.Range,C.RangeOverride) end return genv.__origShoot(s,m,p) end end end)
    local function applySpread() pcall(function()
        local tbl=rG[192401] and rG[rG[192401]] if type(tbl)~="table" then return end
        if not genv.__spreadOrig then genv.__spreadOrig={} for gun,pats in pairs(tbl) do local g={} for pi,pat in ipairs(pats) do local q={} for i=1,#pat do q[i]=pat[i] end g[pi]=q end genv.__spreadOrig[gun]=g end end
        local f=(C.Master and C.SpreadOn) and C.SpreadFactor or 1
        for gun,pats in pairs(tbl) do local o=genv.__spreadOrig[gun] for pi,pat in ipairs(pats) do for i=1,#pat do if o and o[pi] and o[pi][i] then pat[i]=o[pi][i]*f end end end end end) end
    applySpread()

    -- rapid fire removed; kill any lingering rapid-fire loop from a prior run
    if genv.__rapidConn then pcall(function() genv.__rapidConn:Disconnect() end) genv.__rapidConn=nil end

    pcall(function() local bh=require(RS.Modules.Extras.packets).BulletHit if setreadonly then pcall(setreadonly,bh,false) end
        if not genv.__origBH then genv.__origBH=bh.send bh.send=function(d) if C.Master and C.SnapPacket and type(d)=="table" and d.HitPart then local m=d.HitPart:FindFirstAncestorOfClass("Model") local pl=m and Players:GetPlayerFromCharacter(m) if pl and pl~=LP then d.Position=d.HitPart.Position d.Offset=Vector3.new(0,0,0) end end return genv.__origBH(d) end end end)
    local function knocked(char) local be=char:FindFirstChild("BodyEffects") if not be then return false end
        local function tv(n) local o=be:FindFirstChild(n) return o~=nil and o.Value==true end
        return tv("K.O") or tv("Dead") or tv("Ragdoll") end
    local vrp=RaycastParams.new() vrp.FilterType=Enum.RaycastFilterType.Exclude
    local trp=RaycastParams.new() trp.FilterType=Enum.RaycastFilterType.Exclude -- reused by triggerbot (was alloc'd per frame)
    local TRIG_PARTS={"Head","UpperTorso","Torso"} -- hoisted out of the per-frame loop
    local ignoredCache
    local function ignored() if not ignoredCache or ignoredCache.Parent~=workspace then ignoredCache=workspace:FindFirstChild("Ignored") end return ignoredCache end
    local function visible(pos,tc) local Cam=workspace.CurrentCamera if not Cam then return true end
        vrp.FilterDescendantsInstances={LP.Character, ignored(), tc}
        return workspace:Raycast(Cam.CFrame.Position, pos-Cam.CFrame.Position, vrp)==nil end
    local function nearestChar(radius) local Cam=workspace.CurrentCamera if not Cam then return end
        local ml=UIS:GetMouseLocation() local best,bestD=nil,radius
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then local char=p.Character
            if not (C.KnockCheck and knocked(char)) then local hrp=char:FindFirstChild("HumanoidRootPart") local hum=char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health>0 then local sp,on=Cam:WorldToViewportPoint(hrp.Position) if on and sp.Z>0 then local ddx,ddy=sp.X-ml.X,sp.Y-ml.Y local d=math.sqrt(ddx*ddx+ddy*ddy) if d<bestD then bestD=d best=char end end end end end end
        return best end
    if genv.__trigConn then pcall(function() genv.__trigConn:Disconnect() end) end
    genv.__trigConn=RunService.Heartbeat:Connect(function()
        if not (C.Master and C.Trigger and isHeld(C.TriggerBind)) or overPanel() then return end
        local ch=LP.Character if not ch then return end
        local tool=ch:FindFirstChildWhichIsA("Tool") if not tool or type(tool:GetAttribute("ShootingCooldown"))~="number" then return end
        local ammo=tool:FindFirstChild("Ammo") if ammo and ammo.Value<1 then return end
        local Cam=workspace.CurrentCamera if not Cam then return end
        local mp=UIS:GetMouseLocation()
        local fire=false
        local ray=Cam:ViewportPointToRay(mp.X,mp.Y)
        trp.FilterDescendantsInstances={ch, ignored()}
        local res=workspace:Raycast(ray.Origin, ray.Direction*3000, trp)
        if res then
            local m=res.Instance:FindFirstAncestorOfClass("Model")
            local plr=m and Players:GetPlayerFromCharacter(m)
            if plr and plr~=LP and not (C.KnockCheck and knocked(m)) then fire=true end
        end
        if not fire then
            local r2=(30*C.TriggerMult)^2
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LP and p.Character and not (C.KnockCheck and knocked(p.Character)) then
                    local char=p.Character
                    for _,pn in ipairs(TRIG_PARTS) do
                        local part=char:FindFirstChild(pn)
                        if part then
                            local sp,on=Cam:WorldToViewportPoint(part.Position)
                            if on and sp.Z>0 then
                                local ddx,ddy=sp.X-mp.X,sp.Y-mp.Y
                                if ddx*ddx+ddy*ddy<=r2 and ((not C.WallCheck) or visible(part.Position,char)) then fire=true break end
                            end
                        end
                    end
                end
                if fire then break end
            end
        end
        if fire then pcall(function() tool:Activate() end) end
    end)

    -- === SAUCE (mouse-lock aimbot) : closest visible part + full X/Y trace ===
    local AIM_PARTS={"Head","UpperTorso","LowerTorso","Torso","HumanoidRootPart",
        "LeftUpperArm","RightUpperArm","LeftHand","RightHand",
        "LeftUpperLeg","RightUpperLeg","LeftFoot","RightFoot"}
    -- Nearest on-screen part to the cursor. GetMouseLocation() and WorldToViewportPoint()
    -- share the SAME space (verified in-game) so we compare them directly, no GUI inset.
    -- Head gets a priority bias so head locks win when aiming center-mass / upward.
    local HEAD_BIAS=35
    local function closestPart(char,Cam,mouse)
        local bestPart,bestPos,bestD
        for _,pn in ipairs(AIM_PARTS) do
            local part=char:FindFirstChild(pn)
            if part and part:IsA("BasePart") then
                local sp,on=Cam:WorldToViewportPoint(part.Position)
                if on and sp.Z>0 then
                    local ddx,ddy=sp.X-mouse.X,sp.Y-mouse.Y
                    local d=math.sqrt(ddx*ddx+ddy*ddy)
                    if pn=="Head" then d=d-HEAD_BIAS end
                    if not bestD or d<bestD then bestD,bestPart,bestPos=d,part,part.Position end
                end
            end
        end
        return bestPart,bestPos
    end
    if genv.__sauceConn then pcall(function() genv.__sauceConn:Disconnect() end) end
    genv.__sauceHeld=false genv.__sauceTgt=nil
    genv.__sauceConn=RunService.RenderStepped:Connect(function(dt)
        if not (C.Master and C.Sauce and isHeld(C.SauceBind)) or overPanel() then genv.__sauceHeld=false genv.__sauceTgt=nil return end
        local Cam=workspace.CurrentCamera if not Cam then return end
        -- lock a target once per hold, then trace it continuously
        if not genv.__sauceHeld then genv.__sauceTgt=nearestChar(400) genv.__sauceHeld=true end
        local char=genv.__sauceTgt if not char or not char.Parent then genv.__sauceTgt=nil return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 or (C.KnockCheck and knocked(char)) then genv.__sauceTgt=nil return end
        local mouse=UIS:GetMouseLocation()
        local _,pos=closestPart(char,Cam,mouse)
        if not pos then return end
        if C.WallCheck and not visible(pos,char) then return end
        local sp=Cam:WorldToViewportPoint(pos) -- same coord space as GetMouseLocation (no inset)
        local targetX,targetY=sp.X,sp.Y
        if C.Shake then targetX=targetX+math.sin(tick()*7)*1.5 targetY=targetY+math.cos(tick()*9)*1.5 end
        local alpha=math.clamp((dt*60)/math.max(C.Smoothness,1),0,1)
        local dx=(targetX-mouse.X)*alpha
        local dy=(targetY-mouse.Y)*alpha
        if mousemoverel then pcall(mousemoverel,dx,dy) end
    end)

    if genv.__shotLoop then pcall(function() genv.__shotLoop:Disconnect() end) end
    genv.__shotLoop=RunService.Heartbeat:Connect(function()
        if not genv.__shotActive then return end
        if not (C.Master and C.ShotDetect and isHeld(C.ShotBind)) then genv.__shotActive=false return end
        local ch=LP.Character local tool=ch and ch:FindFirstChildWhichIsA("Tool")
        if tool and type(tool:GetAttribute("ShootingCooldown"))=="number" then pcall(function() tool:Activate() end) end
    end)
    if not genv.__shotHooked then
        pcall(function()
            local gbe=require(RS.Modules.Extras.packets).GunBulletEffect
            gbe.listen(function(d)
                if not (C.Master and C.ShotDetect and C.ShotTarget~="" and isHeld(C.ShotBind)) then return end
                if type(d)~="table" or not d.Shooter or not d.Tool then return end
                local m=d.Shooter local plr=Players:GetPlayerFromCharacter(m)
                if not plr and typeof(m)=="Instance" then local mm=m:FindFirstAncestorOfClass("Model") if mm then plr=Players:GetPlayerFromCharacter(mm) end end
                if not plr or plr.Name~=C.ShotTarget then return end
                if not string.find(string.lower(d.Tool.Name or ""),"double barrel") then return end
                local now=tick() if now-(genv.__lastShotDet or 0)<0.15 then return end genv.__lastShotDet=now
                task.delay((C.ShotDelay or 0)/1000, function() if C.Master and C.ShotDetect and isHeld(C.ShotBind) then genv.__shotActive=true end end)
            end)
            genv.__shotHooked=true
        end)
    end
    local espFolder=guiRoot():FindFirstChild("LP_ESPFolder") if espFolder then espFolder:Destroy() end
    espFolder=new("Folder",{Name="LP_ESPFolder",Parent=guiRoot()})
    local espTags={}
    local function updESP()
        if not (C.Master and C.ESP) then if next(espTags) then for p,b in pairs(espTags) do if b then b:Destroy() end espTags[p]=nil end end return end
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP then local head=p.Character and p.Character:FindFirstChild("Head") local tag=espTags[p]
            if head then if not tag or not tag.Parent then
                    tag=new("BillboardGui",{Name="t",Size=UDim2.fromOffset(200,18),StudsOffset=Vector3.new(0,2.6,0),AlwaysOnTop=true,Adornee=head,Parent=espFolder})
                    new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=0.3,Text=p.Name,Parent=tag})
                    espTags[p]=tag
                elseif tag.Adornee~=head then tag.Adornee=head end
            elseif tag then tag:Destroy() espTags[p]=nil end end end
        for p,tag in pairs(espTags) do if not p.Parent then tag:Destroy() espTags[p]=nil end end
    end
    local function updSpec() local Cam=workspace.CurrentCamera if not Cam then return end
        if C.Master and C.Spectate and C.SpectateTarget~="" then local tp=Players:FindFirstChild(C.SpectateTarget) local hum=tp and tp.Character and tp.Character:FindFirstChildOfClass("Humanoid")
            if hum and Cam.CameraSubject~=hum then Cam.CameraSubject=hum end genv.__specOn=true
        elseif genv.__specOn then local mh=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") if mh then Cam.CameraSubject=mh end genv.__specOn=false end
    end
    if genv.__slowConn then pcall(function() genv.__slowConn:Disconnect() end) genv.__slowConn=nil end
    local acc,sacc=0,0
    genv.__slowConn=RunService.Heartbeat:Connect(function(dt)
        sacc=sacc+dt
        if sacc>=2 then sacc=0
            if genv.__cfgDirty and writefile then genv.__cfgDirty=false pcall(function() writefile("LockPanelConfig.json",HttpService:JSONEncode(C)) end) end
        end
        acc=acc+dt if acc<0.08 then return end acc=0
        updESP() updSpec()
    end)

    local gp=guiRoot() local old=gp:FindFirstChild("LockPanelUI") if old then old:Destroy() end
    local gui=new("ScreenGui",{Name="LockPanelUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=999,Parent=gp})
    genv.__lpGui=gui
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    -- clean leaked UI listeners + shared input handlers (FPS)
    if genv.__uiConns then for _,c in ipairs(genv.__uiConns) do pcall(function() c:Disconnect() end) end end
    genv.__uiConns={}
    local function ucon(sig,fn) local c=sig:Connect(fn) table.insert(genv.__uiConns,c) return c end
    local activeSlider,activeBind,dragA,dS,sPos=nil,nil,false
    ucon(UIS.InputChanged,function(i) if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        if activeSlider then activeSlider(i.Position.X) end
        if dragA then local d=i.Position-dS local w=gui:FindFirstChild("Window") if w then w.Position=UDim2.new(sPos.X.Scale,sPos.X.Offset+d.X,sPos.Y.Scale,sPos.Y.Offset+d.Y) end end
    end end)
    ucon(UIS.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then activeSlider=nil dragA=false end end)
    ucon(UIS.InputBegan,function(i,gpe)
        if activeBind then local name if i.UserInputType==Enum.UserInputType.Keyboard then name=i.KeyCode.Name elseif i.UserInputType==Enum.UserInputType.MouseButton1 then name="MouseButton1" elseif i.UserInputType==Enum.UserInputType.MouseButton2 then name="MouseButton2" elseif i.UserInputType==Enum.UserInputType.MouseButton3 then name="MouseButton3" end if name then activeBind(name) activeBind=nil end return end
        if gpe then return end
        if i.KeyCode==Enum.KeyCode.RightShift then gui.Enabled=not gui.Enabled end
    end)
    local win=new("Frame",{Name="Window",Size=UDim2.fromOffset(360,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(0,50,0.5,-210),BackgroundColor3=BG,BorderSizePixel=0,ClipsDescendants=true,Parent=gui})
    corner(win,12) stroke(win,ACCENT1,0.5)
    new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Parent=win})
    local header=new("Frame",{Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,LayoutOrder=1,Parent=win})
    local av=new("Frame",{Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(16,13),BackgroundColor3=Color3.fromRGB(5,5,6),BorderSizePixel=0,Parent=header}) corner(av,20) stroke(av,ACCENT1,0.1)
    new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.GothamBlack,Text="\u{25C9}",TextSize=20,TextColor3=ACCENT1,Parent=av})
    local title=new("TextLabel",{Size=UDim2.new(1,-120,0,24),Position=UDim2.fromOffset(64,15),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text="LOCKPANEL",TextSize=21,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=TXT,Parent=header})
    new("UIGradient",{Color=ColorSequence.new(TXT,Color3.fromRGB(215,120,125)),Parent=title})
    new("TextLabel",{Size=UDim2.new(1,-120,0,14),Position=UDim2.fromOffset(64,40),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text="by naraka",TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=MUT,Parent=header})
    local closeBtn=new("TextButton",{Size=UDim2.fromOffset(26,26),Position=UDim2.new(1,-40,0,19),BackgroundColor3=PANEL2,Text="X",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=MUT,Parent=header}) corner(closeBtn,7)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled=false end)
    local function bd(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragA=true dS=i.Position sPos=win.Position end end
    header.InputBegan:Connect(bd) title.InputBegan:Connect(bd)
    local body=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=2,Parent=win})
    new("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingBottom=UDim.new(0,14),Parent=body})
    new("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder,Parent=body})
    local function mkToggle(parent,order,labelText,default,cb)
        local row=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=PANEL,BorderSizePixel=0,LayoutOrder=order,Parent=parent}) corner(row,8)
        new("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text=labelText,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=TXT,Parent=row})
        local sw=new("Frame",{Size=UDim2.fromOffset(44,22),Position=UDim2.new(1,-56,0.5,-11),BackgroundColor3=default and ACCENT1 or PANEL2,BorderSizePixel=0,Parent=row}) corner(sw,11)
        local knob=new("Frame",{Size=UDim2.fromOffset(16,16),Position=default and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Parent=sw}) corner(knob,8)
        local st=default local function set(v) st=v TweenService:Create(sw,TweenInfo.new(0.15),{BackgroundColor3=v and ACCENT1 or PANEL2}):Play() TweenService:Create(knob,TweenInfo.new(0.15),{Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play() end
        new("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=row}).MouseButton1Click:Connect(function() set(not st) cb(st) genv.__cfgDirty=true end)
        return function(v) set(v) end
    end
    local function mkSlider(parent,order,labelText,minv,maxv,default,suffix,cb,divisor) divisor=divisor or 1
        local row=new("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=PANEL,BorderSizePixel=0,LayoutOrder=order,Parent=parent}) corner(row,8)
        new("TextLabel",{Size=UDim2.new(1,-110,0,16),Position=UDim2.fromOffset(14,9),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text=labelText,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=MUT,Parent=row})
        local val=new("TextLabel",{Size=UDim2.new(0,100,0,16),Position=UDim2.new(1,-114,0,9),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text=(default/divisor)..suffix,TextSize=13,TextXAlignment=Enum.TextXAlignment.Right,TextColor3=ACCENT1,Parent=row})
        local track=new("Frame",{Size=UDim2.new(1,-28,0,6),Position=UDim2.fromOffset(14,34),BackgroundColor3=PANEL2,BorderSizePixel=0,Parent=row}) corner(track,3)
        local r0=(default-minv)/(maxv-minv) local fill=new("Frame",{Size=UDim2.fromScale(r0,1),BackgroundColor3=ACCENT1,BorderSizePixel=0,Parent=track}) corner(fill,3)
        local knob=new("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new(r0,-7,0.5,-7),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Parent=track}) corner(knob,7)
        local function setv(px) local r=math.clamp((px-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1) local v=math.floor(minv+(maxv-minv)*r+0.5) r=(v-minv)/(maxv-minv) fill.Size=UDim2.fromScale(r,1) knob.Position=UDim2.new(r,-7,0.5,-7) val.Text=(v/divisor)..suffix cb(v/divisor) genv.__cfgDirty=true end
        local function down(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then activeSlider=setv setv(i.Position.X) end end
        track.InputBegan:Connect(down) knob.InputBegan:Connect(down)
    end
    local function mkKeybind(parent,order,labelText,getBind,cb)
        local row=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=PANEL,BorderSizePixel=0,LayoutOrder=order,Parent=parent}) corner(row,8)
        new("TextLabel",{Size=UDim2.new(1,-96,1,0),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text=labelText,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=TXT,Parent=row})
        local kb=new("TextButton",{Size=UDim2.fromOffset(70,24),Position=UDim2.new(1,-82,0.5,-12),BackgroundColor3=PANEL2,Text=friendly(getBind()),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=ACCENT1,Parent=row}) corner(kb,6) stroke(kb,ACCENT1,0.6)
        kb.MouseButton1Click:Connect(function() kb.Text="..." activeBind=function(name) kb.Text=friendly(name) cb(name) genv.__cfgDirty=true end end)
    end
    local function openPicker(setT)
        local ov=gui:FindFirstChild("Picker") if ov then ov:Destroy() end
        ov=new("Frame",{Name="Picker",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=5,Parent=gui})
        new("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=5,Parent=ov}).MouseButton1Click:Connect(function() ov:Destroy() end)
        local box=new("Frame",{Size=UDim2.fromOffset(260,300),Position=UDim2.new(0.5,-130,0.5,-150),BackgroundColor3=BG,BorderSizePixel=0,ZIndex=6,Parent=ov}) corner(box,10) stroke(box,ACCENT1,0.3)
        new("TextLabel",{Size=UDim2.new(1,0,0,30),Position=UDim2.fromOffset(0,10),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text="SELECT PLAYER",TextSize=13,TextColor3=TXT,ZIndex=6,Parent=box})
        local sf=new("ScrollingFrame",{Size=UDim2.new(1,-16,1,-50),Position=UDim2.fromOffset(8,42),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=ACCENT1,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=6,Parent=box}) new("UIListLayout",{Padding=UDim.new(0,5),Parent=sf})
        local function add(name) local b=new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=PANEL,Text=name,Font=Enum.Font.Gotham,TextSize=12,TextColor3=TXT,ZIndex=6,Parent=sf}) corner(b,6) b.MouseButton1Click:Connect(function() setT(name) ov:Destroy() end) end
        add("None") for _,p in ipairs(Players:GetPlayers()) do if p~=LP then add(p.Name) end end
    end
    local function mkDropdown(parent,order,labelText,getCur,setCur)
        local row=new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=PANEL,BorderSizePixel=0,LayoutOrder=order,Parent=parent}) corner(row,8)
        new("TextLabel",{Size=UDim2.new(0.42,0,1,0),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text=labelText,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=TXT,Parent=row})
        local btn=new("TextButton",{Size=UDim2.new(0.55,-16,0,26),Position=UDim2.new(0.45,0,0.5,-13),BackgroundColor3=PANEL2,Text=(getCur()~="" and getCur() or "None"),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=ACCENT1,TextTruncate=Enum.TextTruncate.AtEnd,Parent=row}) corner(btn,6) stroke(btn,ACCENT1,0.6)
        btn.MouseButton1Click:Connect(function() openPicker(function(name) setCur(name=="None" and "" or name) btn.Text=(getCur()~="" and getCur() or "None") genv.__cfgDirty=true end) end)
    end

    local snapSet
    local function needSnap() if not C.SnapPacket then C.SnapPacket=true genv.__cfgDirty=true if snapSet then snapSet(true) end end end
    mkToggle(body,1,"Master Enable",C.Master,function(s) C.Master=s applySpread() notify("Master "..(s and "ON" or "OFF")) end)
    local tabbar=new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=PANEL,BorderSizePixel=0,LayoutOrder=2,Parent=body}) corner(tabbar,8)
    local holder=new("Frame",{Size=UDim2.new(1,0,0,300),BackgroundTransparency=1,ClipsDescendants=true,LayoutOrder=3,Parent=body})
    local pages,tabBtns={},{}
    local function mkPage(name) local pg=new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=ACCENT1,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,Parent=holder}) new("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder,Parent=pg}) new("UIPadding",{PaddingTop=UDim.new(0,1),PaddingRight=UDim.new(0,5),Parent=pg}) pages[name]=pg return pg end
    local function selTab(name) for n,pg in pairs(pages) do pg.Visible=(n==name) end for n,t in pairs(tabBtns) do t[1].TextColor3=(n==name) and TXT or MUT t[2].Visible=(n==name) end end
    local tabs={"COMBAT","TRIGGER","SAUCE","SHOT","MISC"}
    for idx,name in ipairs(tabs) do
        local b=new("TextButton",{Size=UDim2.new(1/#tabs,0,1,0),Position=UDim2.new((idx-1)/#tabs,0,0,0),BackgroundTransparency=1,Text=name,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=MUT,Parent=tabbar})
        local ind=new("Frame",{Size=UDim2.new(0.6,0,0,2),Position=UDim2.new(0.2,0,1,-4),BackgroundColor3=ACCENT1,Visible=false,BorderSizePixel=0,Parent=b}) corner(ind,1)
        tabBtns[name]={b,ind} b.MouseButton1Click:Connect(function() selTab(name) end)
    end
    local cP=mkPage("COMBAT") local trP=mkPage("TRIGGER") local sP=mkPage("SAUCE") local shP=mkPage("SHOT") local mP=mkPage("MISC")
    snapSet=mkToggle(cP,1,"Server Hit Snap",C.SnapPacket,function(s) C.SnapPacket=s end)
    mkToggle(cP,2,"Long Range",C.RangeOn,function(s) C.RangeOn=s end)
    mkSlider(cP,3,"Range",50,5000,C.RangeOverride," studs",function(v) C.RangeOverride=v end)
    mkToggle(cP,4,"Custom Spread",C.SpreadOn,function(s) C.SpreadOn=s applySpread() end)
    mkSlider(cP,5,"Spread %",0,100,math.floor((C.SpreadFactor or 0)*100),"%",function(v) C.SpreadFactor=v/100 applySpread() end)
    mkToggle(trP,1,"Triggerbot",C.Trigger,function(s) C.Trigger=s if s then needSnap() end end)
    mkSlider(trP,2,"Hitbox Multiplier",10,30,math.floor((C.TriggerMult or 1.5)*10),"x",function(v) C.TriggerMult=v end,10)
    mkKeybind(trP,3,"Trigger Bind",function() return C.TriggerBind end,function(n) C.TriggerBind=n end)
    mkToggle(trP,4,"Wall Check",C.WallCheck,function(s) C.WallCheck=s end)
    mkToggle(trP,5,"Knock Check",C.KnockCheck,function(s) C.KnockCheck=s end)
    mkToggle(sP,1,"SAUCE (Mouse Lock)",C.Sauce,function(s) C.Sauce=s if s then needSnap() end end)
    mkSlider(sP,2,"Smoothness",1,25,C.Smoothness or 10,"",function(v) C.Smoothness=v end)
    mkToggle(sP,3,"Shake",C.Shake,function(s) C.Shake=s end)
    mkKeybind(sP,4,"SAUCE Bind",function() return C.SauceBind end,function(n) C.SauceBind=n end)
    mkToggle(sP,5,"Wall Check",C.WallCheck,function(s) C.WallCheck=s end)
    mkToggle(sP,6,"Knock Check",C.KnockCheck,function(s) C.KnockCheck=s end)
    mkToggle(shP,1,"Shot Detection",C.ShotDetect,function(s) C.ShotDetect=s end)
    mkDropdown(shP,2,"Target",function() return C.ShotTarget end,function(v) C.ShotTarget=v end)
    mkSlider(shP,3,"Delay",0,250,C.ShotDelay or 0," ms",function(v) C.ShotDelay=v end)
    mkKeybind(shP,4,"Shot Bind",function() return C.ShotBind end,function(n) C.ShotBind=n end)
    mkToggle(mP,1,"ESP Names",C.ESP,function(s) C.ESP=s end)
    mkToggle(mP,2,"Spectate",C.Spectate,function(s) C.Spectate=s end)
    mkDropdown(mP,3,"Spectate",function() return C.SpectateTarget end,function(v) C.SpectateTarget=v end)
    selTab("COMBAT")
    notify("LOCKPANEL unlocked - RightShift to hide")
end

genv.__unlocked=nil
local function showGate()
    if genv.__unlocked then runPanel() return end
    local gp=guiRoot() local g=gp:FindFirstChild("LockPanelGate") if g then g:Destroy() end
    g=new("ScreenGui",{Name="LockPanelGate",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=1000,Parent=gp})
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(g) end end)
    new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.3,BorderSizePixel=0,Parent=g})
    local box=new("Frame",{Size=UDim2.fromOffset(340,220),Position=UDim2.new(0.5,-170,0.5,-110),BackgroundColor3=BG,BorderSizePixel=0,ClipsDescendants=true,Parent=g}) corner(box,12) stroke(box,ACCENT1,0.35)
    local av=new("Frame",{Size=UDim2.fromOffset(48,48),Position=UDim2.new(0.5,-24,0,20),BackgroundColor3=Color3.fromRGB(5,5,6),BorderSizePixel=0,Parent=box}) corner(av,24) stroke(av,ACCENT1,0.1)
    new("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.GothamBlack,Text="\u{25C9}",TextSize=24,TextColor3=ACCENT1,Parent=av})
    new("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.fromOffset(0,76),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text="LOCKPANEL",TextSize=21,TextColor3=TXT,Parent=box})
    new("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.fromOffset(0,102),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Text="ENTER ACCESS KEY",TextSize=10,TextColor3=MUT,Parent=box})
    local tb=new("TextBox",{Size=UDim2.new(1,-48,0,38),Position=UDim2.fromOffset(24,126),BackgroundColor3=PANEL,BorderSizePixel=0,Font=Enum.Font.Gotham,PlaceholderText="key...",Text="",TextSize=14,TextColor3=TXT,ClearTextOnFocus=false,Parent=box}) corner(tb,8) stroke(tb,PANEL2,0)
    local btn=new("TextButton",{Size=UDim2.new(1,-48,0,36),Position=UDim2.fromOffset(24,170),BackgroundColor3=ACCENT2,Font=Enum.Font.GothamBold,Text="UNLOCK",TextSize=14,TextColor3=TXT,Parent=box}) corner(btn,8) new("UIGradient",{Color=ColorSequence.new(ACCENT1,ACCENT2),Rotation=20,Parent=btn})
    local function try() if tb.Text=="ALLHAILNARAKA" then genv.__unlocked=true g:Destroy() runPanel() else tb.Text="" end end
    btn.MouseButton1Click:Connect(try) tb.FocusLost:Connect(function(e) if e then try() end end)
end
showGate()
