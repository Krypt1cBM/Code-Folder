local OceanFloor = {}

function OceanFloor.GetElevation(worldX, worldZ, config)
	return -config.OCEAN_DEPTH
		+ math.noise(worldX * config.SEABED_NOISE_SCALE, 0, worldZ * config.SEABED_NOISE_SCALE)
			* config.SEABED_NOISE_AMPLITUDE
end

return OceanFloor
