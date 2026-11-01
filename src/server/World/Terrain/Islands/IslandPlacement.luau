local IslandPlacement = {}

local function IsFarEnough(position, islands, candidateRadius, minGap)
	for _, island in ipairs(islands) do
		local existingRadius = math.max(island.RadiusX, island.RadiusZ)
		local minDistance = candidateRadius + existingRadius + minGap
		local actualDistance = (position - island.Position).Magnitude

		if actualDistance < minDistance then
			return false
		end
	end
	return true
end

return IslandPlacement
