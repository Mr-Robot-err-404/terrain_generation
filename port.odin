package main

import rl "vendor:raylib"
import rg "vendor:raylib/rlgl"

draw_instanced :: proc(mesh: rl.Mesh, transforms: []rl.Matrix) {
	floats := make([][16]f32, len(transforms), context.temp_allocator)
	for t, i in transforms {
		floats[i] = rl.MatrixToFloatV(t)
	}

	vbo := rg.LoadVertexBuffer(raw_data(floats), i32(len(floats) * size_of([16]f32)), false)
	rg.EnableVertexArray(mesh.vaoId)
	for i in 0 ..< 4 {
		loc := u32(12) + u32(i) // SHADER_LOC_MATRIX_MODEL starts at 12
		rg.EnableVertexAttribute(loc)
		rg.SetVertexAttribute(
			loc,
			4,
			rg.FLOAT,
			false,
			size_of(rl.Matrix),
			i32(i * size_of([4]f32)),
		)
		rg.SetVertexAttributeDivisor(loc, 1)
	}
	rg.DisableVertexBuffer()
	rg.DrawVertexArrayElementsInstanced(0, mesh.triangleCount * 3, nil, i32(len(transforms)))
	rg.DisableVertexArray()
	rg.UnloadVertexBuffer(vbo)
}
