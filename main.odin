package main

import rl "vendor:raylib"

Height: f32 = 36
Width: f32 = 200
Length: f32 = 100
Speed: f32 = 20

PressedFn :: proc "c" (key: rl.KeyboardKey) -> bool

GameState :: struct {
	camera: ^rl.Camera3D,
	mouse:  [2]f32,
	dir:    [2]f32,
}
Center: [3]f32 = {0, 0, 0}
Start: [3]f32 = {0, 170, 20}

get_direction :: proc(pressed: PressedFn) -> [2]f32 {
	direction := [2]f32{}
	if pressed(.W) {direction[0] += 1.0}
	if pressed(.S) {direction[0] -= 1.0}
	if pressed(.D) {direction[1] += 1.0}
	if pressed(.A) {direction[1] -= 1.0}
	return direction
}

move :: proc(l: ^Logger, camera: ^rl.Camera3D, pressed: PressedFn, frame_dt: f32) {
	dir := get_direction(pressed)

	eye := rl.Vector3Normalize(camera.target - camera.position)
	side := rl.Vector3Normalize(rl.Vector3CrossProduct(eye, camera.up))
	path := (eye * dir[0]) + (side * dir[1])

	dv := path * Speed * frame_dt
	camera.position += dv
	camera.target += dv
}

rotate :: proc(l: ^Logger, camera: ^rl.Camera3D, v2: [2]f32) {
	sensitivity: f32 = 0.002

	eye := rl.Vector3Normalize(camera.target - camera.position)
	side := rl.Vector3Normalize(rl.Vector3CrossProduct(eye, camera.up))

	theta := v2[0] * sensitivity * -1
	eye = rodrigues(eye, camera.up, theta)

	theta = v2[1] * sensitivity * -1
	pitched := rodrigues(eye, side, theta)

	if abs(rl.Vector3DotProduct(pitched, camera.up)) < 0.99 {
		eye = pitched
	}
	camera.target = camera.position + rl.Vector3Normalize(eye)
}

main :: proc() {
	l := log_init(true)

	rl.SetTraceLogLevel(.ALL)
	rl.SetConfigFlags({.FULLSCREEN_MODE})
	rl.InitWindow(1920, 1080, "terrain generation")
	defer rl.CloseWindow()

	camera := rl.Camera3D {
		position   = Start,
		target     = {0, 0, 0},
		up         = {0, 1, 0},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}
	rl.SetTargetFPS(120)
	rl.DisableCursor()
	rl.SetMousePosition(1920 / 2, 1080 / 2)

	mesh := rl.Mesh{}
	material := rl.LoadMaterialDefault()

	size := (Width / Spacing) * (Length / Spacing)
	points := size * 3
	palette := size * 4

	cells := ((Width / Spacing) - 1) * ((Length / Spacing) - 1)
	cells *= 6

	vertices := make([]f32, int(points))
	colors := make([]u8, int(palette))
	indices := make([]u16, int(cells))

	populate_vertices(vertices, colors)
	populate_indices(indices)
	summon_terrain(&mesh, vertices, indices, colors)

	rl.GenMeshTangents(&mesh)
	rl.UploadMesh(&mesh, false)

	for !rl.WindowShouldClose() && !rl.IsKeyPressed(.ESCAPE) {
		mouse := rl.GetMouseDelta()
		if rl.Vector2Length(mouse) < 50 {
			rotate(&l, &camera, mouse)
		}
		move(&l, &camera, rl.IsKeyDown, rl.GetFrameTime())

		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(World)

		rl.BeginMode3D(camera)
		rl.DrawMesh(mesh, material, rl.Matrix(1))

		rl.EndMode3D()
		rl.DrawRectangle(5, 5, 450, 200, Overlay)
		draw_hud(&camera, 6)
	}
}
