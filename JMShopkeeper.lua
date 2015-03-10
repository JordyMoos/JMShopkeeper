
---
--- JMShopkeeper
---

--[[

    Variable declaration

 ]]

---
-- @field name
-- @field savedVariablesName
--
local Config = {
    name = 'JMShopkeeper',
    savedVariablesName = 'JMShopkeeperSavedVariables',
}

---
-- Parser object
--
local Parser = {
}

--[[

    Result table

 ]]

---
--
local ResultTable = {
    position = 1,
    rowList = {},
    rowCount = 20
}

local ParsedData = {
    saleList = {},
    guildList = {},
}

---
--
function ResultTable:initialize()
    -- Create the result rows
    for rowIndex = 1, self.rowCount do
        local row = CreateControlFromVirtual(
            'JMShopkeeperResultRow',
            JMShopkeeperGuiMainWindowResultBackground,
            'JMShopkeeperResultRow',
            rowIndex
        );
        row:SetSimpleAnchorParent(5, (row:GetHeight() + 2) * (rowIndex - 1))
        row:SetHidden(false)

        self.rowList[rowIndex] = row
    end

    -- Enable scrolling over the result rows
    JMShopkeeperGuiMainWindowResultBackground:SetMouseEnabled(true)
    JMShopkeeperGuiMainWindowResultBackground:SetHandler("OnMouseWheel", function(_, direction)
        ResultTable:onScrolled(direction)
    end)

    -- Let the fetch button work
    JMShopkeeperGuiMainWindowFetchButton:SetHandler('OnClicked', function()
        Parser:parse()
    end)

    local saleList = JMGuildSaleHistoryTracker.getSalesFromUser("@Player")
end

---
--
function ResultTable:resetPosition()
    self.position = 0
end

---
--
function ResultTable:onScrolled(direction)
    self:adjustPosition(direction)
    self:draw()
end

---
-- @param direction
--
function ResultTable:adjustPosition(direction)
    local newPosition = self.position + direction;

    if (newPosition > #ParsedData.saleList - self.rowCount) then
        newPosition = #ParsedData.saleList - self.rowCount
    end

    if (newPosition < 1) then
        newPosition = 0
    end

    self.position = newPosition;
end

---
--
function ResultTable:draw()
    for rowIndex = 1, self.rowCount do
        local sale = ParsedData.saleList[rowIndex + self.position]
        if (sale == nil) then
            return
        end

        local icon = GetItemLinkInfo(sale.itemLink)
        local resultRow = self.rowList[rowIndex]
        resultRow:GetNamedChild('ID'):SetText((rowIndex + self.position))
        resultRow:GetNamedChild('Buyer'):SetText(sale.buyer)
        resultRow:GetNamedChild('Guild'):SetText(sale.guildName)
        resultRow:GetNamedChild('Icon'):SetTexture(icon)
        resultRow:GetNamedChild('Item'):SetText(zo_strformat('<<t:1>>', sale.itemLink))
        resultRow:GetNamedChild('Price'):SetText(sale.price)
        resultRow:GetNamedChild('Quantity'):SetText(sale.quantity)
        resultRow:GetNamedChild('Time'):SetText(ZO_FormatDurationAgo(GetTimeStamp() - sale.saleTimestamp))
    end

    JMShopkeeperResultPaginationSummary:SetText((self.position + 1) .. ' - ' .. (self.position + self.rowCount) .. ' of ' .. #ParsedData.saleList)
end

--[[

    Parser

 ]]

function Parser:parse()
    d('Parsing')

    local salesList = JMGuildSaleHistoryTracker.getSalesFromUser(GetDisplayName())
    table.sort(salesList, function(a, b)
        return a.saleTimestamp > b.saleTimestamp
    end)

    local guildList = {}

    for _, sale in pairs(salesList) do
        if not guildList[sale.guildName] then
            guildList[sale.guildName] = 0
        end

        guildList[sale.guildName] = guildList[sale.guildName] + 1
    end

    ParsedData.guildList = guildList
    ParsedData.saleList = salesList

    ResultTable:resetPosition()
    ResultTable:draw()
end

--[[

    Initialize

 ]]

---
-- Start of the addon
--
local function Initialize()
    ResultTable:initialize()
end

--[[

    Events

 ]]

--- Adding the initialize handler
EVENT_MANAGER:RegisterForEvent(
    Config.name,
    EVENT_ADD_ON_LOADED,
    function (event, addonName)
        if addonName ~= Config.name then
            return
        end

        Initialize()
        EVENT_MANAGER:UnregisterForEvent(Config.name, EVENT_ADD_ON_LOADED)
    end
)

---
--
SLASH_COMMANDS['/jm_sk'] = function()
    JMShopkeeperGuiMainWindow:ToggleHidden()
    JMShopkeeperGuiMainWindow:BringWindowToTop()
end
