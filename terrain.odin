package main

import "core:math"
import rl "vendor:raylib"


Frequency: f32 = 0.5
Amplitude: f32 = 10
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

waves :: proc(x, z: f32) -> f32 {
	x_offset := math.sin(Frequency * math.sin(x))
	z_offset := math.sin(Frequency * math.sin(z))
	n := x_offset + z_offset + 1

	// -1..1 -> 0..2
	n += 1
	return n * Amplitude
}

populate_vertices :: proc(vertices: []f32) {
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
			y: f32 = waves(x, z)

			idx := (i * cols) + j
			v := idx * 3
			vertices[v] = x
			vertices[v + 1] = y
			vertices[v + 2] = z
		}
	}
}

populate_colors :: proc(colors: []u8, normals: []f32) {
	offset := Vector3 {
		x = Width / 2,
		z = Length / 2,
	}
	rows := u32(Length / Spacing)
	cols := u32(Width / Spacing)
	light_source := normalize(Vector3{1, -1, 1})

	for i in 0 ..< rows {
		for j in 0 ..< cols {
			x := (f32(j) * Spacing) - offset.x + (Spacing / 2)
			z := (f32(i) * Spacing) - offset.z + (Spacing / 2)
			y: f32 = waves(x, z)

			idx := (i * cols) + j
			c := idx * 4

			height_factor := clamp(y / (Amplitude * 2), 0, 1)
			diffuse := dot_product(vector_at_idx(u16(idx), normals), light_source)
			ratio := (diffuse * 0.7) + (height_factor * 0.3)
			brightness := clamp(diffuse, 0.1, 1)

			colors[c] = u8(101 * brightness)
			colors[c + 1] = u8(67 * brightness)
			colors[c + 2] = u8(33 * brightness)
			colors[c + 3] = 255

			// final pass to normalize again after accumulation
			n := vector_at_idx(u16(idx), normals)
			i := idx * 3
			normals[i] = n.x
			normals[i] = n.y
			normals[i] = n.y
		}
	}

}

populate_indices :: proc(indices: []u16, vertices: []f32, normals: []f32) {
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
			summon_triangle(a, c, b, vertices, indices, normals, idx)
			summon_triangle(b, c, d, vertices, indices, normals, idx + 3)
		}
	}
}

summon_triangle :: proc(a, c, b: u16, vertices: []f32, indices: []u16, normals: []f32, idx: u16) {
	n := calc_face_normal(a, c, b, vertices)
	assign_normal(a, n, normals)
	assign_normal(c, n, normals)
	assign_normal(b, n, normals)

	indices[idx] = a
	indices[idx + 1] = c
	indices[idx + 2] = b
}

assign_normal :: proc(a: u16, n: Vector3, normals: []f32) {
	i := a * 3
	normals[i] += n.x
	normals[i + 1] += n.y
	normals[i + 2] += n.z
}

calc_face_normal :: proc(a, c, b: u16, vertices: []f32) -> Vector3 {
	va := vector_at_idx(a, vertices)
	vb := vector_at_idx(b, vertices)
	vc := vector_at_idx(c, vertices)
	ab := diff(vb, va)
	ac := diff(vc, va)
	prod := cross_product(ab, ac)
	return normalize(prod)
}

diff :: proc(a, b: Vector3) -> Vector3 {
	return Vector3{x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}
}
vector_at_idx :: proc(vertex_idx: u16, buffer: []f32) -> Vector3 {
	idx := vertex_idx * 3
	return Vector3{x = buffer[idx], y = buffer[idx + 1], z = buffer[idx + 2]}
}

dot_product :: proc(va, vb: Vector3) -> f32 {
	return (va.x * vb.x) + (va.y * vb.y) + (va.z * vb.z)
}

cross_product :: proc(ab: Vector3, ac: Vector3) -> Vector3 {
	return Vector3 {
		x = (ab.y * ac.z) - (ab.z * ac.y),
		y = (ab.z * ac.x) - (ab.x * ac.z),
		z = (ab.x * ac.y) - (ab.y * ac.x),
	}
}
normalize :: proc(v: Vector3) -> Vector3 {
	size := math.sqrt_f32((v.x * v.x) + (v.y * v.y) + (v.z * v.z))
	return Vector3{x = v.x / size, y = v.y / size, z = v.z / size}
}

summon_terrain :: proc(
	terrain: ^rl.Mesh,
	vertices: []f32,
	indices: []u16,
	colors: []u8,
	normals: []f32,
) {
	terrain.vertexCount = i32(len(vertices) / 3)
	terrain.triangleCount = i32(len(indices) / 3)
	terrain.vertices = raw_data(vertices)
	terrain.indices = raw_data(indices)
	terrain.colors = raw_data(colors)
	terrain.normals = raw_data(normals)
}
