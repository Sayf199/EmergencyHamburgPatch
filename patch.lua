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

-- =========================
-- 6) Patch Admin App
-- =========================
-- =========================
-- Patch module moderators
-- =========================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mod = ReplicatedStorage:WaitForChild("Code"):WaitForChild("modules"):WaitForChild("moderators")
local modData = require(mod)

-- Forcer dev/mod permissions
if type(modData.isDevelopper) == "function" then
    modData.isDevelopper = function(...) return true end
end

if type(modData.isModerator) == "function" then
    modData.isModerator = function(...) return true end
end

-- =========================
-- Patch adminAppController et activer menus
-- =========================
local player = game:GetService("Players").LocalPlayer
local mod = player:WaitForChild("PlayerScripts"):WaitForChild("Code")
    :WaitForChild("controllers"):WaitForChild("adminAppController")
local adminApp = require(mod)
local ctrl = adminApp.AdminAppController

if ctrl then
    -- Hook onStateChanged safe
    if type(ctrl.onStateChanged) == "function" then
        local oldFunc = ctrl.onStateChanged
        ctrl.onStateChanged = function(self, ...)
            return oldFunc(self, ...) -- appel original pour activer les menus
        end
    end

    -- Patch stateSelector pour renvoyer toujours "Active" sans spam
    if type(ctrl.stateSelector) == "function" then
        ctrl.stateSelector = function(self, ...)
            return "Active"
        end
    end

    -- Activer tous les menus admin/dev côté client
    local appsFolder = player.PlayerScripts:WaitForChild("Code"):WaitForChild("layout"):WaitForChild("components"):WaitForChild("apps")
    for _, app in pairs(appsFolder:GetChildren()) do
        local nameLower = app.Name:lower()
        if nameLower:find("admin") or nameLower:find("mod") or nameLower:find("dev") then
            local success, appModule = pcall(require, app)
            if success and type(appModule.default) == "function" then
                pcall(appModule.default) -- lance l'app côté client
            end
        end
    end

    print("[Patch] Admin/Mod/Dev menus activés ✅")
else
    warn("[Patch] AdminAppController introuvable")
end

-- =========================
-- 7) Bypass Account
-- =========================
local player = game:GetService("Players").LocalPlayer
local mod = player:WaitForChild("PlayerScripts"):WaitForChild("Code")
    :WaitForChild("layout"):WaitForChild("hooks"):WaitForChild("useUserAccounts")

local userAccounts = require(mod)

-- Patch default pour bypass
if type(userAccounts.default) == "function" then
    local old = userAccounts.default
    userAccounts.default = function(...)
        -- renvoie l’état d’un compte toujours “connecté”
        local data = old(...) -- garde les données originales si besoin
        data = data or {}
        data.isLoggedIn = true
        data.username = player.Name
        data.role = "Admin" -- ou "Dev", selon ce que tu veux
        return data
    end
end

-- Patch fetchAccountInfo pour renvoyer des infos valides
if type(userAccounts.fetchAccountInfo) == "function" then
    userAccounts.fetchAccountInfo = function(...)
        return {
            username = player.Name,
            isLoggedIn = true,
            role = "Admin",
            permissions = {"all"}
        }
    end
end

print("[Patch] useUserAccounts patché ✅ (account bypassed)")
