local Math = require(game.ReplicatedStorage.Shared.Math)

local TerrainGenerator = {}

local function GetIslandHeight(distance, config)
	if distance >= config.ISLAND_RADIUS then
		return 0
	end

	if distance < config.ISLAND_RADIUS - config.BEACH_WIDTH then
		local t = distance / (config.ISLAND_RADIUS - config.BEACH_WIDTH)
		return Math.Lerp(config.ISLAND_HEIGHT, config.BEACH_HEIGHT, Math.Smoothstep(t))
	end

	local t = (distance - (config.ISLAND_RADIUS - config.BEACH_WIDTH)) / config.BEACH_WIDTH
	return Math.Lerp(config.BEACH_HEIGHT, 0, Math.Smoothstep(t))
end

local function GenerateIsland(Terrain, config)
	local region = Region3.new(
		Vector3.new(
			-config.ISLAND_RADIUS,
			config.SEA_LEVEL - config.OCEAN_DEPTH,
			-config.ISLAND_RADIUS
		),
		Vector3.new(
			config.ISLAND_RADIUS,
			config.SEA_LEVEL + config.ISLAND_HEIGHT,
			config.ISLAND_RADIUS
		)
	)

	local resolution = config.TERRAIN_RESOLUTION
	local alignedRegion = region:ExpandToGrid(resolution)

	local materials, occupancy = Terrain:ReadVoxels(alignedRegion, resolution)

	local minPosition = alignedRegion.CFrame.Position - alignedRegion.Size / 2

	for x = 1, #materials do
		for z = 1, #materials[x][1] do
			local worldX = minPosition.X + (x - 0.5) * resolution
			local worldZ = minPosition.Z + (z - 0.5) * resolution

			local distance = math.sqrt(worldX ^ 2 + worldZ ^ 2)

			if distance < config.ISLAND_RADIUS then
				local surfaceHeight = GetIslandHeight(distance, config)
				local surfaceMaterial = config.LAND_MATERIAL

				if distance >= config.ISLAND_RADIUS - config.BEACH_WIDTH then
					surfaceMaterial = config.BEACH_MATERIAL
				end

				for y = 1, #materials[x] do
					local worldY = minPosition.Y + (y - 0.5) * resolution

					if worldY <= surfaceHeight then
						materials[x][y][z] = surfaceMaterial
						occupancy[x][y][z] = 1
					else
						materials[x][y][z] = Enum.Material.Air
						occupancy[x][y][z] = 0
					end
				end
			end
		end
	end

	Terrain:WriteVoxels(alignedRegion, resolution, materials, occupancy)
end

function TerrainGenerator.Generate(config)
	local Terrain = workspace.Terrain
	Terrain:Clear()

	Terrain.WaterColor = config.WATER_COLOR
	Terrain.WaterTransparency = config.WATER_TRANSPARENCY
	Terrain.WaterReflectance = config.WATER_REFLECTANCE
	Terrain.WaterWaveSize = config.WATER_WAVE_SIZE
	Terrain.WaterWaveSpeed = config.WATER_WAVE_SPEED

	Terrain:FillBlock(
		CFrame.new(0, config.SEA_LEVEL - config.OCEAN_DEPTH - config.SEABED_THICKNESS / 2, 0),
		Vector3.new(config.OCEAN_WIDTH, config.SEABED_THICKNESS, config.OCEAN_LENGTH),
		config.SEABED_MATERIAL
	)

	Terrain:FillBlock(
		CFrame.new(0, config.SEA_LEVEL - config.OCEAN_DEPTH / 2, 0),
		Vector3.new(config.OCEAN_WIDTH, config.OCEAN_DEPTH, config.OCEAN_LENGTH),
		config.WATER_MATERIAL
	)

	GenerateIsland(Terrain, config)
end

return TerrainGenerator
