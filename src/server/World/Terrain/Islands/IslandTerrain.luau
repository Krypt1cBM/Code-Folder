local IslandShape = require(script.Parent.IslandShape)
local IslandTerrain = {}

function IslandTerrain.Generate(terrain, island, config)
	local generationRadius = config.ISLAND_MAX_GENERATION_RADIUS

	local minX = -generationRadius
	local maxX = generationRadius
	local minZ = -generationRadius
	local maxZ = generationRadius

	local resolution = config.TERRAIN_RESOLUTION
	local chunkSize = config.ISLAND_CHUNK_SIZE

	local minY = config.SEA_LEVEL
		- config.OCEAN_DEPTH
		- math.abs(config.SEABED_NOISE_AMPLITUDE)
		- config.SEABED_THICKNESS

	local maxY = config.SEA_LEVEL

	local startX = math.floor(minX / resolution) * resolution
	local startZ = math.floor(minZ / resolution) * resolution

	local endX = math.ceil(maxX / resolution) * resolution
	local endZ = math.ceil(maxZ / resolution) * resolution

	for chunkX = startX, endX - 1, chunkSize do
		local chunkMaxX = math.min(chunkX + chunkSize, endX)

		for chunkZ = startZ, endZ - 1, chunkSize do
			local chunkMaxZ = math.min(chunkZ + chunkSize, endZ)

			local region = Region3.new(
				Vector3.new(chunkX, minY, chunkZ),
				Vector3.new(chunkMaxX, maxY, chunkMaxZ)
			)

			region = region:ExpandToGrid(resolution)

			local materials, occupancy = terrain:ReadVoxels(region, resolution)
			local minPosition = region.CFrame.Position - region.Size / 2
			local voxelsPerAxis = region.Size / resolution

			for x = 1, voxelsPerAxis.X do
				local worldX = minPosition.X + (x - 0.5) * resolution

				for z = 1, voxelsPerAxis.Z do
					local worldZ = minPosition.Z + (z - 0.5) * resolution
					local field = IslandShape.GetBaseField(island, worldX, worldZ, config)

					for y = 1, voxelsPerAxis.Y do
						local worldY = minPosition.Y + (y - 0.5) * resolution

						if field < 1 and worldY <= config.SEA_LEVEL then
							materials[x][y][z] = config.ISLAND_MATERIAL
							occupancy[x][y][z] = 1
						elseif materials[x][y][z] ~= config.SEABED_MATERIAL then
							materials[x][y][z] = Enum.Material.Air
							occupancy[x][y][z] = 0
						end
					end
				end
			end

			terrain:WriteVoxels(region, resolution, materials, occupancy)
		end
	end
end

return IslandTerrain
