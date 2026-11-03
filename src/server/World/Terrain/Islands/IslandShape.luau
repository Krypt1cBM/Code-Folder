local Noise = require(game.ReplicatedStorage.Scripts.Noise)

local IslandShape = {}

local SMOOTH_UNION_BLEND = 0.3

function IslandShape.Generate(config, seed)
	local random = Random.new(seed)

	local radius = random:NextNumber(config.ISLAND_MIN_RADIUS, config.ISLAND_MAX_RADIUS)

	local ellipticity =
		random:NextNumber(config.ISLAND_MIN_ELLIPTICITY, config.ISLAND_MAX_ELLIPTICITY)

	local rotation = random:NextNumber(0, math.pi * 2)

	local noiseOffsetX = random:NextNumber(-10000, 10000)
	local noiseOffsetZ = random:NextNumber(-10000, 10000)

	local radiusX = radius * math.sqrt(ellipticity)
	local radiusZ = radius / math.sqrt(ellipticity)

	local ellipses = {
		{
			Position = Vector2.new(0, 0),
			RadiusX = radiusX,
			RadiusZ = radiusZ,
			Rotation = rotation,
		},
	}

	for _ = 1, 2 do
		local angle = random:NextNumber(0, math.pi * 2)

		local directionX = math.cos(angle)
		local directionZ = math.sin(angle)

		local localX = directionX * math.cos(rotation) + directionZ * math.sin(rotation)

		local localZ = -directionX * math.sin(rotation) + directionZ * math.cos(rotation)

		local boundaryDistance = 1 / math.sqrt((localX / radiusX) ^ 2 + (localZ / radiusZ) ^ 2)

		local distance = boundaryDistance * random:NextNumber(0.75, 0.95)
		local size = random:NextNumber(0.3, 0.8)
		local secondaryRadius = radius * size
		local secondaryEllipticity = random:NextNumber(1.5, 2.5)

		table.insert(ellipses, {
			Position = Vector2.new(directionX * distance, directionZ * distance),
			RadiusX = secondaryRadius * math.sqrt(secondaryEllipticity),
			RadiusZ = secondaryRadius / math.sqrt(secondaryEllipticity),
			Rotation = random:NextNumber(0, math.pi * 2),
		})
	end

	return {
		Ellipses = ellipses,
		NoiseOffsetX = noiseOffsetX,
		NoiseOffsetZ = noiseOffsetZ,
		Seed = seed,
	}
end

function IslandShape.GetBaseField(island, worldX, worldZ, config)
	local field = math.huge
	local primary = island.Ellipses[1]

	for _, ellipse in ipairs(island.Ellipses) do
		local offsetX = worldX - ellipse.Position.X
		local offsetZ = worldZ - ellipse.Position.Y

		local rotatedX = offsetX * math.cos(ellipse.Rotation) + offsetZ * math.sin(ellipse.Rotation)

		local rotatedZ = -offsetX * math.sin(ellipse.Rotation)
			+ offsetZ * math.cos(ellipse.Rotation)

		local normalizedX = rotatedX / ellipse.RadiusX
		local normalizedZ = rotatedZ / ellipse.RadiusZ

		local distance = math.sqrt(normalizedX ^ 2 + normalizedZ ^ 2)

		local blend = SMOOTH_UNION_BLEND
		local h = math.max(blend - math.abs(field - distance), 0) / blend

		field = math.min(field, distance) - h * h * blend * 0.25
	end

	local radius = math.sqrt(primary.RadiusX * primary.RadiusZ)

	local normalizedX = (worldX - primary.Position.X) / radius
	local normalizedZ = (worldZ - primary.Position.Y) / radius

	local baseNoise = math.noise(
		normalizedX * config.ISLAND_BASE_NOISE_SCALE + island.NoiseOffsetX,
		normalizedZ * config.ISLAND_BASE_NOISE_SCALE + island.NoiseOffsetZ
	)

	local baseField = field + baseNoise * config.ISLAND_BASE_NOISE_AMPLITUDE

	local distanceFromCoast = baseField - 1
	local fadeDistance = config.ISLAND_COAST_NOISE_FADE_DISTANCE

	if math.abs(distanceFromCoast) >= fadeDistance then
		return baseField
	end

	local sizeFade = math.clamp(-distanceFromCoast / fadeDistance, 0, 1)

	local cellSize = config.ISLAND_COASTLINE_CELL_SIZE
		+ (config.ISLAND_COASTLINE_MIN_CELL_SIZE - config.ISLAND_COASTLINE_CELL_SIZE) * sizeFade

	local coastlineNoise = Noise.GetWorley(normalizedX, normalizedZ, cellSize / radius, island.Seed)

	local coastlineInfluence = math.clamp(1 - math.abs(distanceFromCoast) / fadeDistance, 0, 1)

	local coastlineDisplacement = math.max(0, 0.5 - coastlineNoise)
		* config.ISLAND_COASTLINE_AMPLITUDE
		* coastlineInfluence

	return baseField - coastlineDisplacement
end

return IslandShape
