package main

import rl "vendor:raylib"

Height: f32 = 36
Width: f32 = 100
Length: f32 = 100
Speed: f32 = 20

PressedFn :: proc "c" (key: rl.KeyboardKey) -> bool

GameState :: struct {
	camera: ^rl.Camera3D,
	mouse:  [2]f32,
	dir:    [2]f32,
}

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
	l := log_init(false)

	rl.SetConfigFlags({.FULLSCREEN_MODE})
	rl.InitWindow(1920, 1080, "terrain generation")
	defer rl.CloseWindow()

	camera := rl.Camera3D {
		position   = {-10, 50, 150},
		target     = {0, 0, 0},
		up         = {0, 1, 0},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}
	rl.SetTargetFPS(120)
	rl.SetMousePosition(1920 / 2, 1080 / 2)

	mesh := rl.LoadModel("apple.glb")

	for !rl.WindowShouldClose() && !rl.IsKeyPressed(.ESCAPE) {
		mouse := rl.GetMouseDelta()
		if rl.Vector2Length(mouse) < 50 {
			rotate(&l, &camera, mouse)
		}
		move(&l, &camera, rl.IsKeyDown, rl.GetFrameTime())

		rl.ClearBackground(World)
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.BeginMode3D(camera)
		rl.DrawModel(mesh, {0, 0, 0}, 100, rl.Color{180, 50, 220, 255})
		rl.EndMode3D()

		rl.DrawRectangle(5, 5, 500, 250, Overlay)
		draw_table(&camera, 6)
	}
}
