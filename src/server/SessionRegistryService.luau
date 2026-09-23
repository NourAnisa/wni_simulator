--!strict
local MemoryStoreService = game:GetService("MemoryStoreService")

local configModule = script.Parent:WaitForChild("ExperienceConfig", 5)
assert(configModule and configModule:IsA("ModuleScript"), "ExperienceConfig missing")
local Config = require(configModule)

export type SessionRoute = {
	matchId: string,
	matchPlaceId: number,
	accessCode: string,
	roster: {number},
	expiresAt: number,
}

local MAP_NAME = "WNI_Reconnect_v1"
local memoryMap: any = nil
local mapOK, mapResult = pcall(function()
	return MemoryStoreService:GetHashMap(MAP_NAME)
end)
if mapOK then
	memoryMap = mapResult
end

local SessionRegistryService = {}
SessionRegistryService.__index = SessionRegistryService

function SessionRegistryService.new()
	local self: any = setmetatable({}, SessionRegistryService)
	self.localFallback = {} :: {[number]: SessionRoute}
	return self
end

local function validRoute(route: any): boolean
	return typeof(route) == "table"
		and typeof(route.matchId) == "string"
		and #route.matchId >= 8
		and #route.matchId <= 80
		and typeof(route.matchPlaceId) == "number"
		and route.matchPlaceId > 0
		and route.matchPlaceId % 1 == 0
		and typeof(route.accessCode) == "string"
		and route.accessCode ~= ""
		and typeof(route.roster) == "table"
		and #route.roster == 4
		and typeof(route.expiresAt) == "number"
end

function SessionRegistryService.registerRoster(self: any, matchId: string, accessCode: string, rosterUserIds: {number}): boolean
	if matchId == "" or accessCode == "" or #rosterUserIds ~= 4 then return false end
	local expiresAt = os.time() + Config.SessionRouteSeconds
	local rosterCopy: {number} = table.clone(rosterUserIds)
	local route: SessionRoute = {
		matchId = matchId,
		matchPlaceId = Config.MatchPlaceId,
		accessCode = accessCode,
		roster = rosterCopy,
		expiresAt = expiresAt,
	}
	local allPersistent = memoryMap ~= nil and Config.MatchPlaceId > 0
	for _, userId in rosterUserIds do
		if typeof(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then return false end
		self.localFallback[userId] = table.clone(route)
		if allPersistent then
			local ok = pcall(function()
				memoryMap:SetAsync("u_" .. tostring(userId), route, Config.SessionRouteSeconds)
			end)
			if not ok then allPersistent = false end
		end
	end
	return true
end

function SessionRegistryService.get(self: any, userId: number): SessionRoute?
	if typeof(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then return nil end
	if memoryMap then
		local ok, raw = pcall(function()
			return memoryMap:GetAsync("u_" .. tostring(userId))
		end)
		if ok and validRoute(raw) then
			if raw.expiresAt > os.time() then
				return raw :: SessionRoute
			end
		end
	end
	local localRoute = self.localFallback[userId]
	if localRoute and localRoute.expiresAt > os.time() then
		return table.clone(localRoute)
	end
	self.localFallback[userId] = nil
	return nil
end

function SessionRegistryService.armReconnect(self: any, userId: number): boolean
	local route = self:get(userId)
	if not route then return false end
	route.expiresAt = os.time() + Config.ReconnectSeconds
	self.localFallback[userId] = table.clone(route)
	if memoryMap then
		local ok = pcall(function()
			memoryMap:SetAsync("u_" .. tostring(userId), route, Config.ReconnectSeconds)
		end)
		if not ok then return false end
	end
	return true
end

function SessionRegistryService.refreshSession(self: any, userId: number): boolean
	local route = self:get(userId)
	if not route then return false end
	route.expiresAt = os.time() + Config.SessionRouteSeconds
	self.localFallback[userId] = table.clone(route)
	if memoryMap then
		local ok = pcall(function()
			memoryMap:SetAsync("u_" .. tostring(userId), route, Config.SessionRouteSeconds)
		end)
		if not ok then return false end
	end
	return true
end

function SessionRegistryService.clear(self: any, userId: number)
	self.localFallback[userId] = nil
	if memoryMap then
		pcall(function()
			memoryMap:RemoveAsync("u_" .. tostring(userId))
		end)
	end
end

function SessionRegistryService.clearRoster(self: any, rosterUserIds: {number})
	for _, userId in rosterUserIds do
		self:clear(userId)
	end
end

return SessionRegistryService
