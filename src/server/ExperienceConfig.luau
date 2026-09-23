--!strict
-- Production routing configuration for WNI Simulator.
-- Keep reserved-server access codes out of replicated storage.
local Config = {
	SchemaVersion = 1,
	Environment = "development",
	LobbyPlaceId = 0,
	MatchPlaceId = 0,
	MatchMode = "Casual2v2",
	RulesVersion = "prototype-0.1",
	ReconnectSeconds = 90,
	SessionRouteSeconds = 7200,
	RosterArrivalSeconds = 45,
	TeleportRetryCount = 2,
}

function Config.isPublished(): boolean
	return game.PlaceId ~= 0 and game.GameId ~= 0
end

function Config.canTeleportToMatch(): boolean
	return Config.isPublished() and Config.MatchPlaceId > 0
end

function Config.canReturnToLobby(): boolean
	return Config.isPublished() and Config.LobbyPlaceId > 0
end

return table.freeze(Config)
