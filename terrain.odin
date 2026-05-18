package main

import "core:math"
import rl "vendor:raylib"


Frequency: f32 = 0.2
Amplitude: f32 = 5
Vector3 :: struct {
	x: f32,
	y: f32,
	z: f32,
}
Coord :: struct {
	x: f32,
	z: f32,
}
Grid :: map[Coord]bool

concentric_circles :: proc(x, z: f32) -> f32 {
	// -1..1 -> 0..2
	n := math.sin(Frequency * math.sqrt((x * x) + (z * z))) + 1
	return n * Amplitude
}

populate_vertices :: proc(vertices: []f32, colors: []u8) {
	offset := Vector3 {
		x = Width / 2,
		z = Length / 2,
	}
	rows := u32(Length / Spacing)
	cols := u32(Width / Spacing)

	for i in 0 ..< rows {
		for j in 0 ..< cols {
			x := (f32(j) * Spacing) - offset.x + (Spacing / 2)
			z := (f32(i) * Spacing) - offset.z + (Spacing / 2)
			y: f32 = concentric_circles(x, z)

			idx := (i * cols) + j
			v := idx * 3
			c := idx * 4

			vertices[v] = x
			vertices[v + 1] = y
			vertices[v + 2] = z

			// RGBA
			ceiling := Amplitude * 2
			gradient := y / ceiling
			brightness := 255 * gradient

			colors[c] = u8(101 + (brightness * 0.5))
			colors[c + 1] = u8(67 + u32(brightness * 0.3))
			colors[c + 2] = u8(33 + u32(brightness * 0.1))
			colors[c + 3] = u8(255)
		}
	}
}

populate_indices :: proc(indices: []u16) {
	rows := u16(Length / Spacing)
	cols := u16(Width / Spacing)

	for i in 0 ..< rows - 1 {
		for j in 0 ..< cols - 1 {
			cell := (i * (cols - 1)) + j
			a := (i * cols) + j
			b := a + 1
			c := a + cols
			d := c + 1

			idx := cell * 6
			indices[idx] = a
			indices[idx + 1] = c
			indices[idx + 2] = b
			indices[idx + 3] = b
			indices[idx + 4] = c
			indices[idx + 5] = d
		}
	}
}

summon_terrain :: proc(terrain: ^rl.Mesh, vertices: []f32, indices: []u16, colors: []u8) {
	terrain.vertexCount = i32(len(vertices) / 3)
	terrain.triangleCount = i32(len(indices) / 3)
	terrain.vertices = raw_data(vertices)
	terrain.indices = raw_data(indices)
	terrain.colors = raw_data(colors)
}
