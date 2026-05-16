package main

import rl "vendor:raylib"

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

Spacing: f32 = 5

populate_grid :: proc(grid: ^Grid) {
	start := Coord {
		x = (Width / 2) * -1,
		z = (Length / 2) * -1,
	}
	end := Coord {
		x = Width / 2,
		z = Length / 2,
	}
	for x := start.x; x < end.x; x += Spacing {
		for z := start.z; z < end.z; z += Spacing {
			coord := Coord {
				x = x,
				z = z,
			}
			grid[coord] = true
		}
	}
}

create_mesh :: proc(mesh: ^rl.Mesh, sphere: ^rl.Mesh, grid: ^Grid) {
	total := sphere.vertexCount * i32(len(grid))
	vertices := make([]f32, total * 3)

	i := 0
	for coord in grid {
		for v := 0; v < int(sphere.vertexCount); v += 1 {
			vertices[i * 3 + 0] = sphere.vertices[v * 3 + 0] + coord.x
			vertices[i * 3 + 1] = sphere.vertices[v * 3 + 1] + 1
			vertices[i * 3 + 2] = sphere.vertices[v * 3 + 2] + coord.z
			i += 1
		}
	}
	mesh.vertexCount = total
	mesh.triangleCount = sphere.triangleCount * i32(len(grid))
	mesh.vertices = raw_data(vertices)
	rl.UploadMesh(mesh, false)
}
