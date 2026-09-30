package keyboard

import "core:fmt"
import "vendor:sdl3"

State :: struct {
	keys: [16]bool,
}

state := State{}

handle_key_sdl :: proc(event: sdl3.KeyboardEvent) {
	key := -1

	// 1 2 3 4
	for num := 0; num < 4; num += 1 {
		if (event.key == sdl3.Keycode(sdl3.K_0 + num)) do key = num
	}

	switch (event.key) {
	case sdl3.K_Q: key = 0x4
	case sdl3.K_W: key = 0x5
	case sdl3.K_E: key = 0x6
	case sdl3.K_R: key = 0x7

	case sdl3.K_A: key = 0x8
	case sdl3.K_S: key = 0x9
	case sdl3.K_D: key = 0xA
	case sdl3.K_F: key = 0xB

	case sdl3.K_Z: key = 0xC
	case sdl3.K_X: key = 0xD
	case sdl3.K_C: key = 0xE
	case sdl3.K_V: key = 0xF
	}

	if (key == -1) do return

	state.keys[u8(key)] = event.down
}

is_key_down :: proc(key: u8) -> bool {
	return state.keys[key]
}

was_some_key_pressed :: proc() -> bool {
	for key in state.keys {
		if key do return true
	}

	return false
}
