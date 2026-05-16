package main

import "core:math"
import rl "vendor:raylib"

rodrigues :: proc(v, k: rl.Vector3, theta: f32) -> rl.Vector3 {
	// NOTE: v' = v·cos(θ) + (k × v)·sin(θ) + k·(k·v)·(1 - cos(θ))
	return(
		v * math.cos(theta) +
		rl.Vector3CrossProduct(k, v) * math.sin(theta) +
		k * rl.Vector3DotProduct(k, v) * (1 - math.cos(theta)) \
	)
}
