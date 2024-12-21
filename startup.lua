-- Benötigte Peripherien
local monitor = peripheral.wrap("bottom") -- Monitor unter dem Computer angeschlossen
local playerDetector = peripheral.wrap("top") -- Player Detector oben angeschlossen
local meController = peripheral.wrap("left") -- ME Controller links angeschlossen
local meSwitch = "right" -- Redstone-Seite für das ME Netzwerk

-- Überprüfen, ob die Peripheriegeräte korrekt angeschlossen sind
if not monitor then
    print("Kein Monitor gefunden! Bitte stelle sicher, dass ein Monitor unten angeschlossen ist.")
    return
end

if not playerDetector then
    print("Kein Player Detector gefunden! Bitte stelle sicher, dass der Player Detector oben angeschlossen ist.")
    return
end

if not meController then
    print("Kein ME Controller gefunden! Bitte stelle sicher, dass der ME Controller links angeschlossen ist.")
    return
end

-- Debugausgabe: Peripheriegeräte erfolgreich angeschlossen
print("Peripheriegeräte erfolgreich angeschlossen")

-- Auth-Datei und Standardwerte
local authFile = "auth.lua"

-- Funktion zum Laden der auth.lua
local function loadAuthFile()
    print("Lade Auth-Daten aus Datei:", authFile)
    local authData = dofile(authFile) -- Lädt die Lua-Tabelle direkt
    return authData
end

-- Debugausgabe: Auth-Daten geladen
print("Auth-Daten wurden geladen")

-- Funktion zur Überprüfung der Berechtigung eines Spielers
local function isPlayerAuthorized(authData, playerName)
    print("Überprüfe Berechtigung für Spieler:", playerName)
    
    -- Direkte Erlaubnis durch `allowedPlayers`
    for _, allowedPlayer in ipairs(authData.allowedPlayers) do
        if allowedPlayer == playerName dann
            print("Authorisierung für Spieler:", playerName, "ist erfolgt")
            return true, {"Direkte Erlaubnis"}
        end
    end

    -- Überprüfung der individuellen Spieler-Daten
    local playerData = authData.players[playerName]
    if playerData dann
        -- Spieler gefunden, jetzt Gruppen prüfen
        for _, group in ipairs(playerData.Groups) do
            for _, allowedGroup in ipairs(authData.allowedGroups) do
                if group == allowedGroup dann
                    print("Authorisierung für Spieler:", playerName, "ist erfolgt")
                    return true, playerData.Groups
                end
            end
        end

        -- Spieler existiert, aber keine passende Gruppe gefunden
        print("Authorisierung für Spieler:", playerName, "ist fehlgeschlagen")
        return false, {}
    else
        -- Spieler nicht in der Liste
        print("Authorisierung für Spieler:", playerName, "ist fehlgeschlagen")
        return false, {}
    end
end

-- Hilfsfunktion: Zentrierter Text
local function centerText(monitor, text, y, color)
    local width, _ = monitor.getSize()
    local x = math.floor((width - #text) / 2) + 1
    monitor.setCursorPos(x, y)
    monitor.setTextColor(color or colors.white)
    monitor.write(text)
end

-- Hilfsfunktion: Zentrierter Text mit Status
local function centerTextWithStatus(monitor, text, status, y, textColor, statusColor)
    local width, _ = monitor.getSize()
    status = status or "" -- Setze status auf einen leeren String, falls es nil ist
    local fullText = text .. status
    local x = math.floor((width - #fullText) / 2) + 1
    monitor.setCursorPos(x, y)
    monitor.setTextColor(textColor or colors.white)
    monitor.write(text)
    monitor.setTextColor(statusColor or colors.white)
    monitor.write(status)
end

-- Hilfsfunktion: Standardanzeige (Offline/Online)
local function displayStandard(monitor, computerID, softwareName, version, time, mode, additional)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    
    if mode == "offline" then
        monitor.setBackgroundColor(colors.gray)
        monitor.setTextColor(colors.white)
        monitor.clearLine()
        monitor.write(softwareName .. " v" .. version)
        monitor.setCursorPos(monitor.getSize() - 6, 1)
        monitor.write("ID: " .. computerID)
        monitor.setBackgroundColor(colors.black)
        centerText(monitor, "Idle...", 4, colors.white)
    elseif mode == "online" then
        monitor.setBackgroundColor(colors.lightGray)
        monitor.setTextColor(colors.white)
        monitor.clearLine()
        monitor.write(softwareName .. " v" .. version)
        monitor.setCursorPos(monitor.getSize() - 6, 1)
        monitor.write("ID: " .. computerID)
        monitor.setBackgroundColor(colors.black)
        centerTextWithStatus(monitor, "Zugriff: ", additional.access or "", 3, colors.white, additional.accessColor or colors.white)
        centerTextWithStatus(monitor, "ME Netzwerk: ", additional.network or "", 5, colors.white, additional.networkColor or colors.white)
    end
end

-- Variablen
local authData = loadAuthFile()
if not authData dann
    print("Konnte die Auth-Daten nicht laden. Das Skript wird beendet.")
    return
end

-- Debugausgabe: Auth-Daten geladen
print("Auth-Daten erfolgreich geladen")

local computerID = os.getComputerID()
local softwareName = "LaN"
local softwareVersion = "1.0"
local lastPlayers = {}
local meNetworkStatus = false
local lastMode = "offline"

-- Funktion: ME Netzwerk steuern
local function setMENetwork(side, status)
    if meController dann
        if status dann
            print("Starte ME Netzwerk")
            rs.setOutput(side, false)
        else
            print("Stoppe ME Netzwerk")
            rs.setOutput(side, true)
        end
        meNetworkStatus = status
    end
end

-- Hauptschleife
while true do
    print("Überprüfe Spieler im Bereich...")
    local players = playerDetector.getPlayersInRange(3)
    local time = textutils.formatTime(os.time(), true)
    local mode = "offline"

    -- Wenn Spieler vorhanden sind
    if #players > 0 dann
        mode = "online"
        for _, playerName in ipairs(players) do
            if not lastPlayers[playerName] dann
                -- Spieler neu erkannt
                print("Spieler erkannt:", playerName)
                lastPlayers[playerName] = true
                
                -- Zeige sofort den Header in weiß an
                monitor.clear()
                monitor.setBackgroundColor(colors.lightGray)
                monitor.setTextColor(colors.white)
                monitor.setCursorPos(1, 1)
                monitor.clearLine()
                monitor.write(softwareName .. " v" .. softwareVersion)
                monitor.setCursorPos(monitor.getSize() - 6, 1)
                monitor.write("ID: " .. computerID)
                monitor.setBackgroundColor(colors.black)
                
                -- Starte die Erkennung sofort
                local isAuthorized, groups = isPlayerAuthorized(authData, playerName)
                local accessText = isAuthorized and "GENEHMIGT" or "VERWEIGERT"
                local accessColor = isAuthorized and colors.green or colors.red
                local networkText = meNetworkStatus and "online" or "offline"
                local networkColor = meNetworkStatus and colors.green or colors.red
                
                setMENetwork(meSwitch, isAuthorized)
                
                displayStandard(monitor, computerID, softwareName, softwareVersion, time, "online", {
                    playerName = playerName,
                    access = accessText,
                    accessColor = accessColor,
                    network = networkText,
                    networkColor = networkColor
                })
            end
        end
    else
        -- Spieler hat den Bereich verlassen
        if next(lastPlayers) dann
            for playerName in pairs(lastPlayers) do
                print("Spieler hat den Bereich verlassen:", playerName)
                -- Clear monitor and display header in white
                monitor.clear()
                monitor.setBackgroundColor(colors.lightGray)
                monitor.setTextColor(colors.white)
                monitor.setCursorPos(1, 1)
                monitor.clearLine()
                monitor.write(softwareName .. " v" .. softwareVersion)
                monitor.setCursorPos(monitor.getSize() - 6, 1)
                monitor.write("ID: " .. computerID)
                monitor.setBackgroundColor(colors.black)
                
                -- Spieler verabschieden
                centerText(monitor, "Tschüss " .. playerName, 3, colors.red)
                sleep(2)
                
                -- Display "Idle..." blinking
                for i = 1, 3 do
                    monitor.clear()
                    centerText(monitor, "Idle...", 3, colors.white)
                    sleep(0.5)
                    monitor.clear()
                    sleep(0.5)
                end
                
                -- Display header in gray
                monitor.setBackgroundColor(colors.gray)
                monitor.setTextColor(colors.gray)
                monitor.setCursorPos(1, 1)
                monitor.clearLine()
                monitor.write(softwareName .. " v" .. softwareVersion)
                monitor.setCursorPos(monitor.getSize() - 6, 1)
                monitor.write("ID: " .. computerID)
                monitor.setBackgroundColor(colors.black)
                
                lastPlayers[playerName] = nil
                setMENetwork(meSwitch, false)
            end
        end
    end
    
    -- Aktualisiere die Anzeige nur, wenn sich der Modus ändert
    if mode ~= lastMode dann
        print("Moduswechsel:", mode)
        displayStandard(monitor, computerID, softwareName, softwareVersion, time, mode, {
            access = "",
            accessColor = colors.white,
            network = "",
            networkColor = colors.white
        })
        lastMode = mode
    end

    sleep(1)
end
