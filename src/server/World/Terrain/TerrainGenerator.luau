local OceanFloor = require(script.Parent.OceanFloor)
local IslandShape = require(script.Parent.Islands.IslandShape)
local IslandTerrain = require(script.Parent.Islands.IslandTerrain)

local TerrainGenerator = {}

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

	local island = IslandShape.Generate(config, math.random(0, 10000))
	IslandTerrain.Generate(Terrain, island, config)
end

return TerrainGenerator
