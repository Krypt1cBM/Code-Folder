local Noise = {}

function Noise.GetWorley(worldX, worldZ, cellSize, seed)
	local cellX = math.floor(worldX / cellSize)
	local cellZ = math.floor(worldZ / cellSize)

	local nearestDistance = math.huge
	local secondNearestDistance = math.huge

	for offsetX = -2, 2 do
		for offsetZ = -2, 2 do
			local currentCellX = cellX + offsetX
			local currentCellZ = cellZ + offsetZ

			local hash = bit32.bxor(
				bit32.lrotate(bit32.bxor(currentCellX, seed), 13),
				bit32.lrotate(bit32.bxor(currentCellZ, seed), 17)
			)

			local random = Random.new(hash)

			local featureX = (currentCellX + random:NextNumber()) * cellSize
			local featureZ = (currentCellZ + random:NextNumber()) * cellSize

			local deltaX = worldX - featureX
			local deltaZ = worldZ - featureZ

			local distance = math.sqrt(deltaX * deltaX + deltaZ * deltaZ)

			if distance < nearestDistance then
				secondNearestDistance = nearestDistance
				nearestDistance = distance
			elseif distance < secondNearestDistance then
				secondNearestDistance = distance
			end
		end
	end

	return math.clamp((secondNearestDistance - nearestDistance) / cellSize, 0, 1)
end

return Noise
