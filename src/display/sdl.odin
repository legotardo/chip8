package display

import "core:fmt"
import "vendor:sdl3"

SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 320
SCREEN_HZ :: 60
SCREEN_DT :: 1_000_000_000 / SCREEN_HZ
SCREEN_TEXT_COLOR :: 0x00FF00

running := true
last_event: sdl3.Event
window: ^sdl3.Window
renderer: ^sdl3.Renderer

on_drop_event: proc(file_path: string)

start_display :: proc() {
	success := sdl3.Init({.VIDEO})
	assert(success, "Failed to init SDL3")

	window = sdl3.CreateWindow("CHIP-8", SCREEN_WIDTH, SCREEN_HEIGHT, {})
	assert(window != nil, "Failed to create SDL3 Window")

	renderer = sdl3.CreateRenderer(window, nil)
	assert(renderer != nil, "Failed to create SDL3 Renderer")

	success = sdl3.SetRenderVSync(renderer, 0)
	assert(success, "Failed to set SDL3 vsync")
}

begin :: proc() {
	for sdl3.PollEvent(&last_event) {
		if last_event.type == .QUIT {
			running = false
		}

		if last_event.type == .DROP_FILE {
			if on_drop_event != nil {
				on_drop_event(string(last_event.drop.data))
			}
		}
	}

	clear()
}

clear :: proc() {
	_ = sdl3.SetRenderDrawColor(renderer, 0, 0, 0, 0)
	sdl3.RenderClear(renderer)

	_ = sdl3.SetRenderDrawColor(
		renderer,
		u8((SCREEN_TEXT_COLOR >> 16) & 0xFF),
		u8((SCREEN_TEXT_COLOR >> 8) & 0xFF),
		u8(SCREEN_TEXT_COLOR & 0xFF),
		255,
	)
}

end :: proc() {
	sdl3.RenderPresent(renderer)
}

destroy :: proc() {
	sdl3.Quit()
	sdl3.DestroyWindow(window)
	sdl3.DestroyRenderer(renderer)
}

draw_pixel :: proc(x, y: u16, scale: u16 = 1) {
	for i: u16 = 0; i < scale * scale; i += 1 {
		sx := (x * scale) + (i / scale)
		sy := (y * scale) + (i % scale)
		sdl3.RenderPoint(renderer, f32(sx), f32(sy))
	}
}
