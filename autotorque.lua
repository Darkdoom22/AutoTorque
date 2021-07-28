_addon.name = "AutoTorque"
_addon.author = "Uwu/Darkdoom"
_addon.version = "1.0.4282021"
_addon.command = "at"

local packets = require('packets')
require('tables')
require('queues')
require('pack')
require('strings')
require('maths')
require('math')
require('coroutine')
local texts = require('texts')

local defaultSettings = {}
defaultSettings.flags = {}
defaultSettings.flags.draggable = false
defaultSettings.pos = {}
defaultSettings.pos.x = 400
defaultSettings.pos.y = 500
defaultSettings.text = {}
defaultSettings.text.font = 'Consolas'
defaultSettings.text.size = 11
defaultSettings.text.alpha = 255
defaultSettings.text.red = 249
defaultSettings.text.green = 236
defaultSettings.text.blue = 236
defaultSettings.text.stroke = {}
defaultSettings.text.stroke.alpha = 175
defaultSettings.text.stroke.red = 11
defaultSettings.text.stroke.green = 16
defaultSettings.text.stroke.blue = 15
defaultSettings.text.stroke.width = 2.0
defaultSettings.text.flags = {}
defaultSettings.text.flags.bold = true
defaultSettings.bg = {}
defaultSettings.bg.alpha = 160
defaultSettings.bg.red = 55
defaultSettings.bg.green = 50
defaultSettings.bg.blue = 50

local guessDisplay = texts.new(defaultSettings)
local display = {
    ["Timer"] = os.clock(),
    ["Delay"] = 0.5,
}

local autoTorque = {
    ["isAddonGuessing"] = false,
    ["isAddonGrabbingItem"] = false,
    ["Menu Id"] = 0,
    ["Detected Chests"] = Q{},
    ["Current Box"] = {
        ["Id"] = nil,
        ["BestGuess"] = nil,
        ["1st Digit"] = T{1, 2, 3, 4, 5, 6, 7, 8, 9},
        ["2nd Digit"] = T{0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
        ["Current Hint"] = {
            ["Message"] = "",
            ["Params"] = T{},
            ["Number"] = 0,
            ["Remaining"] = 0,
        },
        ["Permutations"] = T{},
        ["Blacklisted Perms"] = T{},
        ["Confidence"] = 0,
        
    },
    ["Correct Guesses"] = 0,
    ["Total Guesses"] = 0,
    ["Accuracy"] = 0,

    ["Debug"] = true,


    ["Zone Message Map"] = {
   [100] = 8078,
    [101] = 7509,
    [102] = 7929,
    [103] = 8104,
    [104] = 8669,
    [105] = 7720,
    [106] = 8094,
    [107] = 7555,
    [108] = 7624,
    [109] = 8487,
    [110] = 7611,
    [111] = 8588,
    [112] = 8190,
    [113] = 7932,
    [114] = 7789,
    [115] = 7885,
    [116] = 7581,
    [117] = 7588,
    [118] = 8130,
    [119] = 8367,
    [120] = 7527,
    [121] = 8107,
    [122] = 7438,
    [123] = 7890,
    [124] = 7841,
    [125] = 7651,
    [126] = 8074,
    [127] = 7355,
    [128] = 7510,
    [130] = 7574,
    [153] = 11400,
    [158] = 7386,
    [159] = 8449,
    [160] = 7413,
    [166] = 10582,
    [167] = 10596,
    [169] = 7543,
    [172] = 7416,
    [173] = 10521,
    [174] = 11399,
    [176] = 7608,
    [177] = 11223,
    [178] = 11403,
    [190] = 8257,
    [191] = 8377,
    [192] = 7413,
    [193] = 8389,
    [194] = 8269,
    [195] = 7600,
    [196] = 8309,
    [197] = 7354,
    [198] = 8275,
    [200] = 7531,
    [204] = 7519,
    [205] = 11486,
    [208] = 8288,
    [212] = 10642,
    [213] = 10452,
    },


    ["Default Message ID Map"] = {
       ["Offsets"] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
    },

    ["Current Zone Map"] = {
        --ipairs expects a table starting from index 1 with no holes
        --there are definitely real messages at dummy offsets, but I have yet to observe them (likely related to theif's tools)
        [1] = {
            ["Message"] = "dummy",
            ["Params"] = 0,
        },

        [2] = {
            ["Message"] = "Failed to Open",
            ["Params"] = 0,
        },

        [3] = {
            ["Message"] = "Correct Combination Was",
            ["Params"] = 1,
        },

        [4] = {
            ["Message"] = "Succeeded Opening",
            ["Params"] = 1,
        },

        [5] = {
            ["Message"] = "Second Digit Even/Odd",
            ["Params"] = 1,
        },

        [6] = {
            ["Message"] = "First Digit Even/Odd",
            ["Params"] = 1,
        },

        [7] = {
            ["Message"] = "Range",
            ["Params"] = 2,
        },
        
        [8] = {
            ["Message"] = "Less Than",
            ["Params"] = 1,
        },

        [9] = {
            ["Message"] = "Greater Than",
            ["Params"] = 1,
        },

        [10] = {
            ["Message"] = "Either Digit Equals",
            ["Params"] = 1,
        },

        [11] = {
            ["Message"] = "Second Digit Multi",
            ["Params"] = 3,
        },

        [12] = {
            ["Message"] = "First Digit Multi",
            ["Params"] = 3,
        },

        [13] = {
            ["Message"] = "dummy",
            ["Params"] = 0,
        },

        [14] = {
            ["Message"] = "dummy",
            ["Params"] = 0,
        },
        
        [15] = {
            ["Message"] = "Appearance",
            ["Params"] = 0,
        },


    },

}

local function GetMobById(id)

    local success, mob = pcall(windower.ffxi.get_mob_by_id,id)

    if(success)then

        return mob

    else
        return nil, success 

    end 

end

local function xiPrint(str)

    if(str and autoTorque["Debug"])then

	   windower.add_to_chat(22, str)

    end

end

local function FindPermutations(t1, t2)

    local perm = T{}

    for i = 1, #t1, 1 do

        for j = 1, #t2, 1 do

            if(t1[i] and t2[j])then

                if(autoTorque["Current Box"]["Blacklisted Perms"]:contains(tonumber(t1[i]..t2[j])) == false)then

                perm:insert(t1[i]..t2[j])

                end

            end

        end

    end

    return perm

end

packets.raw_fields.incoming[0x052] = L{
    {ctype='unsigned char',   label='Type'}, --04
    {ctype='unsigned short',  label='Menu ID'}, --05
  }

function autoTorque:Release()

    local startRelease = packets.new('incoming', 0x052, {
    ["Type"] = 2,
    ["Menu ID"] = self["Menu Id"],
    })

    local finishRelease = packets.new('incoming', 0x052, {
    ["Type"] = 1
    })

    xiPrint("Forcing event skip..")

    packets.inject(startRelease)
    packets.inject(finishRelease)

end

windower.register_event('addon command', function(...)

    local args = {...}

    if(#args == 1)then

        if(args[1]:lower() == "set")then

            if(Q(autoTorque["Detected Chests"]):length() == 0)then

            autoTorque["Current Box"]["Id"] = windower.ffxi.get_mob_by_target('t').id
            
            elseif(Q(autoTorque["Detected Chests"]):length() > 0)then

                Q(autoTorque["Detected Chests"]):push(autoTorque["Current Box"]["Id"])

            end

            windower.add_to_chat(22, 'Setting box!/Adding box to queue!')
           
        elseif(args[1]:lower() == "reset")then

            autoTorque:ResetBox()
            Q(autoTorque["Detected Chests"]):empty()

            xiPrint("[Debug reset] Resetting box table!")

        elseif(args[1]:lower() == "perms")then
        
            local possibleAnswers = FindPermutations(autoTorque["Current Box"]["1st Digit"], autoTorque["Current Box"]["2nd Digit"])
            local confidence = (1 / #possibleAnswers) * 100
            xiPrint(string.format("Possible Combinations Remaining : %s, solvable with confidence: %s%%", table.concat(possibleAnswers, ","), tostring(confidence)))
        
        elseif(args[1]:lower() == "testhint")then

            if(autoTorque["Current Box"]["Id"])then

                autoTorque:GetNextHint()
                xiPrint("Testing hint menu option injection..")

            end

        elseif(args[1]:lower() == "stuck")then

            autoTorque:Release()
            xiPrint("Trying to un packet lock you")


        elseif(args[1]:lower() == "solve")then

            xiPrint("Starting to solve..")
            autoTorque:RunSolver()

        elseif(args[1]:lower() == "debug")then

            autoTorque["Debug"] = not autoTorque["Debug"]

        end

    end

end)

local function pokeBox(id)

    if(id)then

        local box = GetMobById(id)

        if(not box or box and not box.valid_target)then
            xiPrint("No box to poke found")
            autoTorque:ResetBox()
            return
        end

        local poke = packets.new('outgoing', 0x01A, {
            ["Target"] = box.id,
            ["Target Index"] = box.index,
            ["Category"] = 0,
        })

        packets.inject(poke)

    end

end

function autoTorque:BuildZoneMessageMap()

    local zone = windower.ffxi.get_info().zone

    if(zone)then

        local zoneMessageBase = self["Zone Message Map"][zone] or nil

        if(zoneMessageBase)then

            for i,v in ipairs(self["Current Zone Map"]) do
                
                if(self["Current Zone Map"][i] and self["Default Message ID Map"]["Offsets"][i])then

                    local offset = zoneMessageBase + self["Default Message ID Map"]["Offsets"][i]
                    rawset(self["Current Zone Map"], offset, v)

                end

            end

        end

    end

end

function autoTorque:GetNextHint()

    self["isAddonGuessing"] = true
    local status = windower.ffxi.get_player().status
    local box = GetMobById(self["Current Box"]["Id"])
    local zone = windower.ffxi.get_info().zone

    if(box and (box.valid_target and box.distance:sqrt() < 6))then

        if(status ~= 4)then

            pokeBox(self["Current Box"]["Id"])

            xiPrint(string.format("Poking box [%s] [%s] yalms away", box.id, box.distance:sqrt()))
            coroutine.sleep(2)

            local menuOption = packets.new('outgoing', 0x05B, {
                ["Target"] = box.id,
                ["Option Index"] = 258,
                ["Target Index"] = box.index,
                ["Automated Message"] = false,
                ["Zone"] = zone,
                ["Menu ID"] = autoTorque["Menu Id"] 
        
            })
        
            xiPrint(string.format("injecting menu option to get next hint [id:%s] [index:%s] [option:258] [zone:%s] [menuId:%s]", box.id, box.index, zone, autoTorque["Menu Id"]))
            packets.inject(menuOption)
        
            self["isAddonGuessing"] = false

        end

    end

end

function autoTorque:UpdatePermutations()

    local potentialPerms = FindPermutations(self["Current Box"]["1st Digit"], self["Current Box"]["2nd Digit"])

    if(#self["Current Box"]["Blacklisted Perms"] > 0)then

        for i,v in ipairs(potentialPerms)do
            
            if(potentialPerms[i])then

                for k,v in pairs(self["Current Box"]["Blacklisted Perms"]) do

                    if(v == potentialPerms[i])then

                        potentialPerms:remove(i)                     

                    end

                end

            end

        end

    end

    self["Current Box"]["Permutations"] = potentialPerms
    self:PrintPermutations()

end

local _FirstDigitMulti = function(self)
    for i = #self["Current Box"]["1st Digit"],1,-1 do

        xiPrint(string.format("Current 1st digit {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))

        if(self["Current Box"]["Current Hint"]["Params"]:contains(self["Current Box"]["1st Digit"][i]) == false)then

            xiPrint(string.format("removing non matching number from (2nd digit table): {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))
            self["Current Box"]["1st Digit"]:remove(i)

        end

    end

    self:UpdatePermutations()
end

local _SecondDigitMulti = function(self)
    for i = #self["Current Box"]["2nd Digit"],1,-1 do

        xiPrint(string.format("Current 2nd digit %s at index %s", self["Current Box"]["2nd Digit"][i], i))

        if(self["Current Box"]["Current Hint"]["Params"]:contains(self["Current Box"]["2nd Digit"][i]) == false)then

            xiPrint(string.format("removing non matching number from (2nd digit table): {%s} at index [%s]", self["Current Box"]["2nd Digit"][i], i))
            self["Current Box"]["2nd Digit"]:remove(i)

        end

    end

    self:UpdatePermutations()  
end

local _FirstDigitEvenOdd = function(self)
    if(self["Current Box"]["Current Hint"]["Params"][1] and self["Current Box"]["Current Hint"]["Params"][1] % 2 == 0)then

        for i = #self["Current Box"]["1st Digit"], 1, -1 do
            xiPrint(string.format("Current 1st digit %s at index %s", self["Current Box"]["1st Digit"][i], i))

            if(self["Current Box"]["1st Digit"][i] and self["Current Box"]["1st Digit"][i] % 2 ~= 0)then

                xiPrint(string.format("removing odd number from (1st digit) table: {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))
                self["Current Box"]["1st Digit"]:remove(i)

            end

        end

        self:UpdatePermutations()
    else
        for i = #self["Current Box"]["1st Digit"], 1, -1 do
            xiPrint(string.format("Current 1st digit %s at index %s", self["Current Box"]["1st Digit"][i], i))

            if(self["Current Box"]["1st Digit"][i] and self["Current Box"]["1st Digit"][i] % 2 == 0)then

                xiPrint(string.format("removing even number from (1st digit) table: {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))
                self["Current Box"]["1st Digit"]:remove(i)

            end

        end

        self:UpdatePermutations()
    end

end

local _SecondDigitEvenOdd = function(self)
    if(self["Current Box"]["Current Hint"]["Params"][1] and self["Current Box"]["Current Hint"]["Params"][1] % 2 == 0)then

        for i = #self["Current Box"]["2nd Digit"], 1, -1 do
            xiPrint(string.format("Current 2nd digit {%s} at index [%s]", self["Current Box"]["2nd Digit"][i], i))

            if(self["Current Box"]["2nd Digit"][i] and self["Current Box"]["2nd Digit"][i] % 2 ~= 0)then

                xiPrint(string.format("removing odd number from 2nd digit table: {%s} at index [%s]", self["Current Box"]["2nd Digit"][i], i))
                self["Current Box"]["2nd Digit"]:remove(i)

            end

        end

        self:UpdatePermutations()
    else
        for i = #self["Current Box"]["2nd Digit"], 1, -1 do
            xiPrint(string.format("Current 2nd digit {%s} at index [%s]", self["Current Box"]["2nd Digit"][i], i))

            if(self["Current Box"]["2nd Digit"][i] and self["Current Box"]["2nd Digit"][i] % 2 == 0)then

                xiPrint(string.format("removing even number from 2nd digit table: {%s} at index [%s]", self["Current Box"]["2nd Digit"][i], i))
                self["Current Box"]["2nd Digit"]:remove(i)

            end

        end

        self:UpdatePermutations()
    end

end

local _Range = function(self)
    local lowerBound = self["Current Box"]["Current Hint"]["Params"][1]
    local upperBound = self["Current Box"]["Current Hint"]["Params"][2]

    local lowerBound1stDigit = tonumber(string.sub(tostring(lowerBound), 1, 1))
    local lowerBound2ndDigit = tonumber(string.sub(tostring(lowerBound), 2, 2))

    local upperBound1stDigit = tonumber(string.sub(tostring(upperBound), 1, 1))
    local upperBound2ndDigit = tonumber(string.sub(tostring(upperBound), 2, 2))

    for i = #self["Current Box"]["1st Digit"], 1, -1 do

        xiPrint(string.format("Current 1st digit {%s} at index [%s] checking against bounds [[L:%s U:%s]]", self["Current Box"]["1st Digit"][i], i, lowerBound1stDigit, upperBound1stDigit))
        if(self["Current Box"]["1st Digit"][i] and self["Current Box"]["1st Digit"][i] < lowerBound1stDigit)then
        
            xiPrint(string.format("Removing 1st digit below lower bound {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))
            self["Current Box"]["1st Digit"]:remove(i)

        elseif(self["Current Box"]["1st Digit"][i] and self["Current Box"]["1st Digit"][i] > upperBound1stDigit)then

            xiPrint(string.format("Removing 1st digit above upper bound {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))
            self["Current Box"]["1st Digit"]:remove(i)

        end

    end

    self:UpdatePermutations()
end

local _LessThan = function(self)
    local upperBound = self["Current Box"]["Current Hint"]["Params"][1]
    local upperBound1stDigit = tonumber(string.sub(tostring(upperBound), 1, 1))
        
    for i = #self["Current Box"]["1st Digit"], 1, -1 do

        if(self["Current Box"]["1st Digit"][i] and self["Current Box"]["1st Digit"][i] > upperBound1stDigit)then

            xiPrint(string.format("removing 1st digit higher than upper bound {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))

        end

    end

    self:UpdatePermutations()
end

local _GreaterThan = function(self)
    local lowerBound = self["Current Box"]["Current Hint"]["Params"][1]
    local lowerBound1stDigit = tonumber(string.sub(tostring(lowerBound), 1, 1))

    for i = #self["Current Box"]["1st Digit"], 1, -1 do

        if(self["Current Box"]["1st Digit"][i] and self["Current Box"]["1st Digit"][i] < lowerBound1stDigit)then
           
            xiPrint(string.format("removing 1st digit lower than upper bound {%s} at index [%s]", self["Current Box"]["1st Digit"][i], i))
            self["Current Box"]["1st Digit"]:remove(i)

        end

    end

    self:UpdatePermutations()
end

local _EitherDigit = function(self)
    local eitherNumber = self["Current Box"]["Current Hint"]["Params"][1]
    local curPerms = FindPermutations(self["Current Box"]["1st Digit"], self["Current Box"]["2nd Digit"])

    xiPrint(string.format("Adding %s as either digit possibility", self["Current Box"]["Current Hint"]["Params"][1]))

    for k,v in pairs(curPerms)do
        
        local doesPermContainNumber = tostring(v):contains(tostring(eitherNumber))
        xiPrint(string.format("Does perm contain number: %s %s", tostring(doesPermContainNumber), tostring(v)))
        
        if(doesPermContainNumber == false and v)then

            self["Current Box"]["Blacklisted Perms"]:insert(v)
            self["Current Box"]["Permutations"]:remove(k)
            self["Current Box"]["Permutations"]:sort()
            
            
        end

    end

    self:UpdatePermutations()
end

local HandleHintCase = {

    ["First Digit Multi"] = function(self)
        return pcall(_FirstDigitMulti,self)
    end,

    ["Second Digit Multi"] = function(self)
        return pcall(_SecondDigitMulti,self)
    end,

    ["First Digit Even/Odd"] = function(self)
        return pcall(_FirstDigitEvenOdd,self)
    end,

   ["Second Digit Even/Odd"] = function(self)
        return pcall(_SecondDigitEvenOdd,self)
    end,
 
    ["Range"] = function(self)
        return pcall(_Range,self)
    end,

    ["Less Than"] = function(self)
        return pcall(_LessThan,self)
    end,

    ["Greater Than"] = function(self)
        return pcall(_GreaterThan,self)
    end,

    ["Either Digit Equals"] = function(self)
        return pcall(_EitherDigit,self)
    end,

}

function autoTorque:InputGuess()

    local box = GetMobById(self["Current Box"]["Id"])  
    local zone = windower.ffxi.get_info().zone

    self["isAddonGuessing"] = true
    
    if(box)then

        pokeBox(box.id)

        coroutine.sleep(3)

        local guess = self["Current Box"]["Permutations"][math.random(1,#self["Current Box"]["Permutations"])]

        local menuOption = packets.new('outgoing', 0x05b, {
            ["Target"] = box.id,
            ["Option Index"] = 257,
            ["_unknown1"] = guess,
            ["Target Index"] = box.index,
            ["Automated Message"] = false,
            ["Zone"] = zone,
            ["Menu ID"] = self["Menu Id"],
        })

        packets.inject(menuOption)

        self["isAddonGuessing"] = false

        local accuracy = 0

        if(self["Total Guesses"] > 0)then
            accuracy = self["Correct Guesses"] / self["Total Guesses"] * 100
            self["Accuracy"] = accuracy
        end

        xiPrint(string.format("Inputting guess:%s accuracy:%s%% (%s/%s), id:%s menuOption:257 index:%s zone:%s menuId:%s", guess, accuracy, self["Correct Guesses"], self["Total Guesses"], box.id, box.index, zone, self["Menu Id"]))
    else
        xiPrint("Unable to generate guess")

    end
    
end

function autoTorque:RunSolver()

    while(Q(self["Detected Chests"]):length() > 0 or self["Current Box"]["Id"])do

        local box = GetMobById(self["Current Box"]["Id"]) or nil

        if(not self["Current Box"]["Id"])then

            self["Current Box"]["Id"] = Q(self["Detected Chests"]):pop()    

        end

        if(box and box.distance:sqrt() < 7)then

            if(self["Current Box"]["Current Hint"]["Remaining"] == 0)then

                pokeBox(self["Current Box"]["Id"])
                coroutine.sleep(2)
                autoTorque:Release()

            end

            while(self["Current Box"]["Current Hint"]["Remaining"] >= 1)do

                xiPrint(string.format("Remaining hints %s", self["Current Box"]["Current Hint"]["Remaining"]))

                if(self["Current Box"]["Current Hint"]["Remaining"] > 1)then

                    self:GetNextHint()
                
                else
                    xiPrint("Ready to solve!")
                    self["isAddonGuessing"] = false
                    self:InputGuess()
                    break

                end

                coroutine.sleep(3)

            end
        else
            xiPrint("Too far from next chest to solve!")

        end

        coroutine.sleep(1)

    end

end


function autoTorque:Solve()

    if(self["Current Box"] and self["Current Box"]["Current Hint"]["Remaining"] >= 1)then
       
       if(self["Current Box"]["Current Hint"]["Message"] and HandleHintCase[self["Current Box"]["Current Hint"]["Message"]])then

            HandleHintCase[self["Current Box"]["Current Hint"]["Message"]](self)

        end
               
    end

end

function autoTorque:PrintPermutations()


    local possibleAnswers = self["Current Box"]["Permutations"]
    local confidence = (1 / #possibleAnswers) * 100
    self["Current Box"]["Confidence"] = confidence

    xiPrint(string.format("Possible Combinations Remaining : %s, solvable with confidence: %s%%", table.concat(possibleAnswers, ","), tostring(confidence)))
    xiPrint(string.format("Possible first digits: %s", table.concat(self["Current Box"]["1st Digit"])))
    xiPrint(string.format("Possible second digits: %s", table.concat(self["Current Box"]["2nd Digit"])))

end

function autoTorque:ResetBox()

    autoTorque["Current Box"]["Id"] = nil
    autoTorque["Current Box"]["BestGuess"] = nil
    autoTorque["Current Box"]["1st Digit"] = T{1, 2, 3, 4, 5, 6, 7, 8, 9}
    autoTorque["Current Box"]["2nd Digit"] = T{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
    autoTorque["Current Box"]["Current Hint"] = {
        ["Message"] = "",
        ["Params"] = T{},
        ["Number"] = 0,
        ["Remaining"] = 0,
    }
    autoTorque["Current Box"]["Permutations"] = T{}
    autoTorque["Current Box"]["Blacklisted Perms"] = T{}
    autoTorque["Current Box"]["Confidence"] = 0


end

windower.register_event('incoming chunk', function (id, original, _, _)

    if(id == 0x038)then

        local entityAnimation = packets.parse('incoming', original)

        if(entityAnimation["Mob"] == autoTorque["Current Box"]["Id"])then

            if(entityAnimation["Type"] == "kesu")then

                xiPrint("Current targeted chest despawned!")

                local status = windower.ffxi.get_player().status

                if(status == 4)then

                    autoTorque:Release()

                end

                autoTorque:ResetBox()

                xiPrint("Resetting box table!")

            end

        end

    end


    if(id == 0x034)then

        local npcInteraction2 = packets.parse('incoming', original)
        local npc = GetMobById(npcInteraction2["NPC"]) 

        if(npc.name == "Treasure Casket" and npc.models[1] == 966 and npc.id == autoTorque["Current Box"]["Id"])then
            
            local hints = npcInteraction2["Menu Parameters"]:unpack("h")

            autoTorque["Current Box"]["Current Hint"]["Remaining"] = hints - 1 --total chances to solve, hints and guesses are shared
            autoTorque["Menu Id"] = npcInteraction2["Menu ID"] 

            if(autoTorque["isAddonGuessing"])then

                xiPrint("Blocking menu from appearing!")
                return true

            end

        end

    end


    if(id == 0x02A)then

        local zone = windower.ffxi.get_info().zone 
        local messagePacket = packets.parse('incoming', original)

        local currentMessage = autoTorque["Current Zone Map"][messagePacket["Message ID"] % 0x8000]--autoTorque["Zones"][zone]["Messages"][messagePacket["Message ID"]] or nil
        
        if(currentMessage)then
            --this packet can be received outside of 50 yalms which is fun
            local box = GetMobById(messagePacket["Player"])

            if(not box)then
                autoTorque["Current Box"]["Id"] = nil
            end

            if(box and box.models[1] == 966)then

                if(currentMessage["Message"] == "Appearance" and autoTorque["Current Box"]["Id"] == nil)then

                autoTorque["Current Box"]["Id"] = messagePacket["Player"] 

                windower.add_to_chat(22, string.format("Setting Current Box To : %s", autoTorque["Current Box"]["Id"]))

                autoTorque["Current Box"]["Current Hint"]["Number"] = 0
                autoTorque["Current Box"]["1st Digit"] = T{1, 2, 3, 4, 5, 6, 7, 8, 9}
                autoTorque["Current Box"]["2nd Digit"] = T{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
                
                elseif(autoTorque["Current Box"]["Id"] == messagePacket["Player"] and currentMessage["Message"] ~= "Correct Combination Was" and currentMessage["Message"] ~= "Succeeded Opening")then

                    local params = T{}

                    if(currentMessage["Params"] > 0)then

                        for i = 1,currentMessage["Params"],1 do

                            params:insert(messagePacket[string.format("Param %s", i)])

                        end

                    end

                    if(#params == 0)then

                        windower.add_to_chat(22, currentMessage["Message"])

                    elseif(#params == 1)then

                        windower.add_to_chat(22, string.format(currentMessage["Message"].." %s", params[1]))

                    elseif(#params == 2)then

                        windower.add_to_chat(22, string.format(currentMessage["Message"].." %s %s", params[1], params[2]))

                    elseif(#params == 3)then

                        windower.add_to_chat(22, string.format(currentMessage["Message"].." %s %s %s", params[1], params[2], params[3]))

                    end
                
                    autoTorque["Current Box"]["Current Hint"]["Message"] = currentMessage["Message"]
                    autoTorque["Current Box"]["Current Hint"]["Params"] = params
                    autoTorque["Current Box"]["Current Hint"]["Number"] = autoTorque["Current Box"]["Current Hint"]["Number"] + 1
                    autoTorque:Solve()

                end

                if(T(autoTorque["Detected Chests"]):contains(box.id) == false and currentMessage["Message"] == "Appearance" and box.id ~= autoTorque["Current Box"]["Id"])then

                    Q(autoTorque["Detected Chests"]):push(box.id)
                    xiPrint("Extra chest spawn detected, adding to queue!")

                end

                if(currentMessage["Message"] == "Correct Combination Was")then
                    windower.add_to_chat(22, string.format(currentMessage["Message"].." %s", messagePacket["Param 1"] or 0))

                    autoTorque:ResetBox()
                    autoTorque["Total Guesses"] = autoTorque["Total Guesses"] + 1

                    windower.add_to_chat(22, "Resetting box table!") 

                elseif(currentMessage["Message"] == "Succeeded Opening")then

                    windower.add_to_chat(22, string.format(currentMessage["Message"].." %s", messagePacket["Param 1"] or 0))

                    autoTorque:ResetBox()
                    autoTorque["Correct Guesses"] = autoTorque["Correct Guesses"] + 1 or 1
                    autoTorque["Total Guesses"] = autoTorque["Total Guesses"] + 1 or 1

                    windower.add_to_chat(22, "Resetting box table!")

                end

            end

        end

    end

end)


windower.register_event('load', function()

    guessDisplay:text("loading")
    guessDisplay:visible(true)
    autoTorque:BuildZoneMessageMap()
    xiPrint("building zone message map!")

end)

windower.register_event('zone change', function()

    autoTorque:BuildZoneMessageMap()
    xiPrint("Zone change detected, attempting to build message map")

end)

windower.register_event('prerender', function()

    if(os.clock() - display["Timer"] > display["Delay"])then

        --look upon my works and despair

        local displayString = "       _Available Permutations_       \\cs(233,106,32)\n"

        for i=1, #autoTorque["Current Box"]["Permutations"], 1 do

            if(i == 1 and #autoTorque["Current Box"]["Permutations"] > 1)then

                displayString = displayString .. string.format("[%s,", autoTorque["Current Box"]["Permutations"][i])

            elseif(i == 1 and #autoTorque["Current Box"]["Permutations"] == 1)then

                displayString = displayString .. string.format("[%s]\n", autoTorque["Current Box"]["Permutations"][i])

            end

            if(i % 12 ~= 0 and #autoTorque["Current Box"]["Permutations"] > 12 and i > 1 and i < #autoTorque["Current Box"]["Permutations"])then

                displayString = displayString .. string.format("%s,", autoTorque["Current Box"]["Permutations"][i])

            elseif(i % 12 ~= 0 and i < #autoTorque["Current Box"]["Permutations"] and #autoTorque["Current Box"]["Permutations"] <= 12 and i > 1)then

                 displayString = displayString .. string.format("%s,", autoTorque["Current Box"]["Permutations"][i])

            elseif(i % 12 == 0 and i < #autoTorque["Current Box"]["Permutations"] and i > 1)then

                displayString = displayString .. string.format("%s,\n", autoTorque["Current Box"]["Permutations"][i])

            end

            if(i == #autoTorque["Current Box"]["Permutations"] and i ~= 1)then

                displayString = displayString .. string.format("%s]\n", autoTorque["Current Box"]["Permutations"][i])

            end

        end

        displayString = displayString .. string.format("\\cs(249,236,236)\n    Current Box Id: " .. "[%s]":lpad(" ", 5) .. "\n", autoTorque["Current Box"]["Id"] or 0)

        if(autoTorque["Total Guesses"] > 0)then
            autoTorque["Accuracy"] = autoTorque["Correct Guesses"] / autoTorque["Total Guesses"] * 100
        end

        if(autoTorque["Current Box"]["Confidence"] and autoTorque["Current Box"]["Confidence"] >= 0 and autoTorque["Current Box"]["Confidence"] < 10)then

            displayString = displayString .. string.format("    Confidence    :" .. "[\\cs(220,33,33)%s%%\\cs(249,236,236)]":lpad(" ", 38) .. "\n", autoTorque["Current Box"]["Confidence"]:floor())

        elseif(autoTorque["Current Box"]["Confidence"] >= 10 and autoTorque["Current Box"]["Confidence"] < 50)then

            displayString = displayString .. string.format("    Confidence    :" .. "[\\cs(233,106,32)%s%%\\cs(249,236,236)]":lpad(" ", 39) .. "\n", autoTorque["Current Box"]["Confidence"]:floor())

        elseif(autoTorque["Current Box"]["Confidence"] >= 50 and autoTorque["Current Box"]["Confidence"] < 90)then

            displayString = displayString .. string.format("    Confidence    :" .. "[\\cs(226,226,49)%s%%\\cs(249,236,236)]":lpad(" ", 39) .. "\n", autoTorque["Current Box"]["Confidence"]:floor())

        elseif(autoTorque["Current Box"]["Confidence"] >= 90)then

            displayString = displayString .. string.format("    Confidence    :" .. "[\\cs(102,226,49)%s%%\\cs(249,236,236)]":lpad(" ", 40) .. "\n", autoTorque["Current Box"]["Confidence"]:floor())
               
        end

        if(autoTorque["Accuracy"] == 0)then

            displayString = displayString .. string.format("    Accuracy      :" .. "[\\cs(220,33,33)%s%%\\cs(249,236,236)]":lpad(" ", 38) .. "\n", autoTorque["Accuracy"]:floor())

        elseif(autoTorque["Accuracy"] < 10)then
                                                               
            displayString = displayString .. string.format("    Accuracy      : " .. "[\\cs(220,33,33)%s%%\\cs(249,236,236)]":lpad(" ", 38) .. "\n", autoTorque["Accuracy"]:floor())

        elseif(autoTorque["Accuracy"] > 10 and autoTorque["Accuracy"] < 75)then

            displayString = displayString .. string.format("    Accuracy      : " .. "[\\cs(253,116,75)%s%%\\cs(249,236,236)]":lpad(" ", 38) .. "\n", autoTorque["Accuracy"]:floor())

        elseif(autoTorque["Accuracy"] > 75)then

            displayString = displayString .. string.format("    Accuracy      : " .. "[\\cs(75,253,116)%s%%\\cs(249,236,236)]":lpad(" ", 38) .. "\n", autoTorque["Accuracy"]:floor())

        elseif(autoTorque["Accuracy"] == 100)then

            displayString = displayString .. string.format("    Accuracy      : " .. "[\\cs(75,253,116)%s%%\\cs(249,236,236)]":lpad(" ", 38) .. "\n", autoTorque["Accuracy"]:floor())
        end

        displayString = displayString .. string.format("    \\cs(249,236,236)Guesses       :" .. "[%sC/%sT]":lpad(" ", 11) .. "\n", autoTorque["Correct Guesses"], autoTorque["Total Guesses"])

        displayString = displayString .. string.format("    \\cs(249, 236, 236)Current Hint  : ".. "[%s]":lpad(" ", 5) .. "\n", autoTorque["Current Box"]["Current Hint"]["Message"])
        if(autoTorque["Current Box"]["Id"])then

            displayString = displayString .. string.format("    Box Distance  :" .. "[%s]":lpad(" ", 6), GetMobById(autoTorque["Current Box"]["Id"]).distance:sqrt():floor() or ">50")

        elseif(not autoTorque["Current Box"]["Id"])then

            displayString = displayString .. string.format("    Box Distance  :" .. "[%s]":lpad(" ", 6), "n/a")

        end

        guessDisplay:text(displayString)
        display["Timer"] = os.clock()

    end

end)
