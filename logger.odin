package main

import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

Logger :: struct {
	handle:  os.Handle,
	enabled: bool,
}
Path := "debug.log"

log_init :: proc(enabled: bool) -> Logger {
	if !enabled {return Logger{}}

	handle, err := os.open(Path, os.O_CREATE | os.O_WRONLY | os.O_TRUNC, 0o644)
	if err != 0 {
		return Logger{}
	}
	return Logger{handle = handle, enabled = true}
}

log :: proc(logger: ^Logger, msg: string) {
	if !logger.enabled {
		return
	}
	data := fmt.tprintf("%s\n", msg)
	os.write_string(logger.handle, data)
}

log_game_state :: proc(logger: ^Logger, state: GameState) {
	if !logger.enabled {return}
	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	if state.camera != nil {
		fmt.sbprintf(
			&b,
			"pos=[%.2f, %.2f, %.2f] target=[%.2f, %.2f, %.2f] fovy=%.2f ",
			state.camera.position.x,
			state.camera.position.y,
			state.camera.position.z,
			state.camera.target.x,
			state.camera.target.y,
			state.camera.target.z,
			state.camera.fovy,
		)
	}
	if state.dir[0] != 0 || state.dir[1] != 0 {
		fmt.sbprintf(&b, "dir=[%.2f, %.2f] ", state.dir[0], state.dir[1])
	}
	if state.mouse[0] != 0 || state.mouse[1] != 0 {
		fmt.sbprintf(&b, "mouse=[%.2f, %.2f]", state.mouse[0], state.mouse[1])
	}
	if len(strings.to_string(b)) == 0 {
		return
	}
	log(logger, strings.to_string(b))
}

draw_hud :: proc(cam: ^rl.Camera3D, y: i32) {
	col0: i32 = 15
	col1: i32 = 100
	col2: i32 = 220
	col3: i32 = 340

	rl.DrawText("   x", col1, y, 20, Text)
	rl.DrawText("   y", col2, y, 20, Text)
	rl.DrawText("   z", col3, y, 20, Text)

	rl.DrawText("pos", col0, y + 30, 20, Text)
	rl.DrawText(rl.TextFormat("% 8.2f", cam.position.x), col1, y + 30, 20, Text)
	rl.DrawText(rl.TextFormat("% 8.2f", cam.position.y), col2, y + 30, 20, Text)
	rl.DrawText(rl.TextFormat("% 8.2f", cam.position.z), col3, y + 30, 20, Text)

	rl.DrawText("target", col0, y + 60, 20, Text)
	rl.DrawText(rl.TextFormat("% 8.2f", cam.target.x), col1, y + 60, 20, Text)
	rl.DrawText(rl.TextFormat("% 8.2f", cam.target.y), col2, y + 60, 20, Text)
	rl.DrawText(rl.TextFormat("% 8.2f", cam.target.z), col3, y + 60, 20, Text)
}

log_close :: proc(logger: ^Logger) {
	if logger.enabled {
		os.close(logger.handle)
	}
}
