-- =========================
-- 1) Patch AntiCheatController
-- =========================
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- on récupère le module
local mod = player:WaitForChild("PlayerScripts")
    :WaitForChild("Code")
    :WaitForChild("controllers")
    :WaitForChild("antiCheatController")

local ac = require(mod)

-- vérif de l'API
if not ac or not ac.AntiCheatController then
    warn("[Patch] Impossible de trouver AntiCheatController")
    return
end

-- liste des fonctions de contrôle qu'on veut neutraliser
local checks = {"checkWalkSpeed", "checkJumpHeight", "checkUseJumpPower"}

for _, fnName in ipairs(checks) do
    if type(ac.AntiCheatController[fnName]) == "function" then
        ac.AntiCheatController[fnName] = function(...)
            print("[Patch] " .. fnName .. " -> toujours true")
            return true
        end
        print("[OK] Patch appliqué sur " .. fnName)
    else
        print("[!] Fonction " .. fnName .. " introuvable")
    end
end

-- =========================
-- 2) Patch speedLimit
-- =========================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mod = ReplicatedStorage:WaitForChild("Code"):WaitForChild("modules"):WaitForChild("speedLimit")
local speedLimit = require(mod)

if type(speedLimit) == "table" and type(speedLimit.getSpeedLimit) == "function" then
    speedLimit.getSpeedLimit = function(...)
        print("[Patch] getSpeedLimit appelé -> valeur maximale renvoyée")
        return 1e9 -- vitesse très élevée
    end
    print("[OK] Patch appliqué sur getSpeedLimit")
else
    warn("getSpeedLimit introuvable ou module invalide")
end

-- =========================
-- 3) Patch policeApp
-- =========================
local mod = player:WaitForChild("PlayerScripts"):WaitForChild("Code")
    :WaitForChild("layout"):WaitForChild("components"):WaitForChild("apps")
    :WaitForChild("policeApp")

local policeApp = require(mod)

if type(policeApp.default) == "function" then
    local old = policeApp.default
    policeApp.default = function(...)
        print("[PATCH] policeApp.default appelé -> bypass rôle police")
        return old(...)
    end
    print("[OK] Logger + patch appliqué sur policeApp.default")
end

-- =========================
-- 3a) Team temporaire Police
-- =========================
if player.Team then
    player.Team = game:GetService("Teams"):FindFirstChild("Police")
end

-- =========================
-- 4) Patch GodMode
-- =========================
player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.HealthChanged:Connect(function()
        hum.Health = hum.MaxHealth
    end)
    print("[Patch] Godmode appliqué sur", char.Name)
end)

if player.Character then
    local hum = player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.HealthChanged:Connect(function()
            hum.Health = hum.MaxHealth
        end)
        print("[Patch] Godmode appliqué (perso actuel)")
    end
end

-- =========================
-- 5) Activer le fly Admin
-- =========================
local flyModule = require(player.PlayerScripts.Code.controllers.flyController)
local flyCtrl = flyModule.FlyController

if flyCtrl then
    if type(flyCtrl.setFlyEnabled) == "function" then
        flyCtrl:setFlyEnabled(true)
        print("[Fly] Vol activé côté client")
    end

    if type(flyCtrl.isFlying) == "function" then
        local oldIsFlying = flyCtrl.isFlying
        flyCtrl.isFlying = function(self)
            return true
        end
        print("[Fly] AlwaysFlying patch appliqué")
    end
end

-- =========================
-- 5a) Patch Fly Client (safe)
-- =========================
if not flyCtrl then
    warn("[Fly Patch] FlyController introuvable")
    return
end

if type(flyCtrl.isFlying) == "function" then
    local oldIsFlying = flyCtrl.isFlying
    flyCtrl.isFlying = function(self)
        return oldIsFlying(self)
    end
end

if type(flyCtrl.toggleFlying) == "function" then
    local oldToggle = flyCtrl.toggleFlying
    flyCtrl.toggleFlying = function(self, ...)
        return oldToggle(self, ...)
    end
end

if type(flyCtrl.setFlyEnabled) == "function" then
    local oldSetFly = flyCtrl.setFlyEnabled
    flyCtrl.setFlyEnabled = function(self, enabled)
        return oldSetFly(self, false)
    end
end

if type(flyCtrl.getSpeed) == "function" then
    local oldGetSpeed = flyCtrl.getSpeed
    flyCtrl.getSpeed = function(self)
        return oldGetSpeed(self)
    end
end

if type(flyCtrl.applyMovement) == "function" then
    local oldApply = flyCtrl.applyMovement
    flyCtrl.applyMovement = function(self, direction)
        return oldApply(self, Vector3.new(0,0,0))
    end
end

if type(flyCtrl.applyOrientation) == "function" then
    local oldOrient = flyCtrl.applyOrientation
    flyCtrl.applyOrientation = function(self, orientation)
        return oldOrient(self, orientation)
    end
end

print("[Fly Patch] Toutes les valeurs FlyController patchées ✅ (vol inactif, safe)")
