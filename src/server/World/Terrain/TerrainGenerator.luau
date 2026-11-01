local Math = require(game.ReplicatedStorage.Scripts.Math)
local OceanFloor = require(script.Parent.OceanFloor)

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

	local alignedRegion = region:ExpandToGrid(config.TERRAIN_RESOLUTION)

	local materials, occupancy = Terrain:ReadVoxels(alignedRegion, config.TERRAIN_RESOLUTION)

	local minPosition = alignedRegion.CFrame.Position - alignedRegion.Size / 2

	for x = 1, #materials do
		for z = 1, #materials[x][1] do
			local worldX = minPosition.X + (x - 0.5) * config.TERRAIN_RESOLUTION
			local worldZ = minPosition.Z + (z - 0.5) * config.TERRAIN_RESOLUTION

			local distance = math.sqrt(worldX ^ 2 + worldZ ^ 2)

			if distance < config.ISLAND_RADIUS then
				local surfaceHeight = GetIslandHeight(distance, config)
				local surfaceMaterial = config.LAND_MATERIAL

				if distance >= config.ISLAND_RADIUS - config.BEACH_WIDTH then
					surfaceMaterial = config.BEACH_MATERIAL
				end

				for y = 1, #materials[x] do
					local worldY = minPosition.Y + (y - 0.5) * config.TERRAIN_RESOLUTION

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

	Terrain:WriteVoxels(alignedRegion, config.TERRAIN_RESOLUTION, materials, occupancy)
end

local function GenerateSeabedChunk(terrain, originX, originZ, config)
	local chunkRegion = Region3.new(
		Vector3.new(
			originX,
			config.SEA_LEVEL
				- config.OCEAN_DEPTH
				- config.SEABED_NOISE_AMPLITUDE
				- config.SEABED_THICKNESS,
			originZ
		),
		Vector3.new(
			originX + config.SEABED_CHUNK_SIZE,
			config.SEA_LEVEL,
			originZ + config.SEABED_CHUNK_SIZE
		)
	)

	chunkRegion = chunkRegion:ExpandToGrid(config.TERRAIN_RESOLUTION)
	local regionMin = chunkRegion.CFrame.Position - chunkRegion.Size / 2

	local voxelsPerAxis = chunkRegion.Size / config.TERRAIN_RESOLUTION
	local materials = table.create(voxelsPerAxis.X)
	local occupancy = table.create(voxelsPerAxis.X)

	for x = 1, voxelsPerAxis.X do
		local worldX = regionMin.X + (x - 0.5) * config.TERRAIN_RESOLUTION
		materials[x] = table.create(voxelsPerAxis.Y)
		occupancy[x] = table.create(voxelsPerAxis.Y)

		for y = 1, voxelsPerAxis.Y do
			local worldY = regionMin.Y + (y - 0.5) * config.TERRAIN_RESOLUTION
			materials[x][y] = table.create(voxelsPerAxis.Z)
			occupancy[x][y] = table.create(voxelsPerAxis.Z)

			for z = 1, voxelsPerAxis.Z do
				local worldZ = regionMin.Z + (z - 0.5) * config.TERRAIN_RESOLUTION

				local surfaceHeight = OceanFloor.GetElevation(worldX, worldZ, config)
				local voxelBottomY = worldY - config.TERRAIN_RESOLUTION / 2

				local fillAmount =
					math.clamp((surfaceHeight - voxelBottomY) / config.TERRAIN_RESOLUTION, 0, 1)

				occupancy[x][y][z] = fillAmount
				if fillAmount > 0 then
					materials[x][y][z] = config.SEABED_MATERIAL
				else
					materials[x][y][z] = Enum.Material.Air
				end
			end
		end
	end

	terrain:WriteVoxels(chunkRegion, config.TERRAIN_RESOLUTION, materials, occupancy)
end

function TerrainGenerator.Generate(config)
	local Terrain = workspace.Terrain
	Terrain:Clear()

	Terrain.WaterColor = config.WATER_COLOR
	Terrain.WaterTransparency = config.WATER_TRANSPARENCY
	Terrain.WaterReflectance = config.WATER_REFLECTANCE
	Terrain.WaterWaveSize = config.WATER_WAVE_SIZE
	Terrain.WaterWaveSpeed = config.WATER_WAVE_SPEED

	local startPosition = -config.SEABED_TEST_SIZE / 2
	local chunksPerAxis = config.SEABED_TEST_SIZE / config.SEABED_CHUNK_SIZE

	for x = 0, chunksPerAxis - 1 do
		local originX = startPosition + x * config.SEABED_CHUNK_SIZE
		for z = 0, chunksPerAxis - 1 do
			local originZ = startPosition + z * config.SEABED_CHUNK_SIZE
			GenerateSeabedChunk(Terrain, originX, originZ, config)
		end
	end
end

return TerrainGenerator
