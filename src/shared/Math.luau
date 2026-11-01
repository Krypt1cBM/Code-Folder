local Math = {}

function Math.Lerp(a, b, t)
	return a + (b - a) * t
end

function Math.Smoothstep(t)
	return 3 * t ^ 2 - 2 * t ^ 3
end

return Math
