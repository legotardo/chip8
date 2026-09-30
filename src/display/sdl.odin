package display

import "core:fmt"
import "vendor:sdl3"
import "../keyboard"

SCREEN_WIDTH :: 640
SCREEN_HEIGHT :: 320
SCREEN_HZ :: 60
SCREEN_DT :: 1_000_000_000 / SCREEN_HZ
SCREEN_TEXT_COLORS := []u32{0x00FF00, 0xFF0000, 0x0000FF, 0xFFFFFF, 0x404040}

running := true
last_event: sdl3.Event
window: ^sdl3.Window
renderer: ^sdl3.Renderer
stream: ^sdl3.AudioStream
current_screen_color := SCREEN_TEXT_COLORS[0]
screen_color_idx := 0

on_drop_event: proc(file_path: string)

start_display :: proc() {
	success := sdl3.Init({.VIDEO, .AUDIO})
	assert(success, "Failed to init SDL3")

	window = sdl3.CreateWindow("CHIP-8", SCREEN_WIDTH, SCREEN_HEIGHT, {})
	assert(window != nil, "Failed to create SDL3 Window")

	renderer = sdl3.CreateRenderer(window, nil)
	assert(renderer != nil, "Failed to create SDL3 Renderer")

	success = sdl3.SetRenderVSync(renderer, 0)
	assert(success, "Failed to set SDL3 vsync")

	audio_spec := sdl3.AudioSpec{
		channels = 1,
		format = .F32,
		freq = 48000,
	}

	stream = sdl3.OpenAudioDeviceStream(sdl3.AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio_spec, nil, nil)
	assert(stream != nil, "Failed to create SDL3 Audio Stream")

	sdl3.ResumeAudioStreamDevice(stream)
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

		if last_event.type == .KEY_DOWN {
			keyboard.handle_key_sdl(last_event.key)

			if last_event.key.key == sdl3.K_P && !last_event.key.repeat {
				screen_color_idx = (screen_color_idx + 1) % len(SCREEN_TEXT_COLORS)
				current_screen_color = SCREEN_TEXT_COLORS[screen_color_idx]
			}
		}
		if last_event.type == .KEY_UP {
			keyboard.handle_key_sdl(last_event.key)
		}
	}

	clear()
}

clear :: proc() {
	_ = sdl3.SetRenderDrawColor(renderer, 0, 0, 0, 0)
	sdl3.RenderClear(renderer)

	_ = sdl3.SetRenderDrawColor(
		renderer,
		u8((current_screen_color >> 16) & 0xFF),
		u8((current_screen_color >> 8) & 0xFF),
		u8(current_screen_color & 0xFF),
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

audio_phase: f32 = 0.0

generate_beep :: proc() {
	sample_count := 480

	samples := make([]f32, sample_count)
	defer delete(samples)

	frequency: f32 = 440.0
	sample_rate: f32 = 48000.0
	phase_step := frequency / sample_rate

	for i in 0..<sample_count {
		if audio_phase < 0.5 {
			samples[i] = 0.15
		} else {
			samples[i] = -0.15
		}

		audio_phase += phase_step

		if audio_phase >= 1.0 {
			audio_phase -= 1.0
		}
	}

	sdl3.PutAudioStreamData(
		stream,
		raw_data(samples),
		i32(len(samples) * size_of(f32)),
	)
}
