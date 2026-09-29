package c8

import "../display"
import "core:fmt"
import "core:os"
import "core:time"

CHIP8_WIDTH :: 64
CHIP8_HEIGHT :: 32
DISPLAY_SCALE :: display.SCREEN_WIDTH / CHIP8_WIDTH
START_ADDR :: 0x200
I_ADDR :: 0x000
FONT_ADDR :: 0x050
FREQUENCY_MS :: 1000.0 / 700

memory: [4096]byte
display_memory: [2048]byte
i := cast(^u16)&memory[I_ADDR]
pc: u16 = START_ADDR
registers: [16]byte
last_tick: time.Tick
cpu_accumulator: f64

load_rom :: proc(path: string) {
	last_tick = time.tick_now()

	data, err := os.read_entire_file(path, context.allocator)
	assert(err == nil, "Failed to read rom file")
	defer delete(data, context.allocator)

	copy(memory[START_ADDR:], data)
}

@(private = "file")
cycle :: proc() {
	opcode := cast(u16)(memory[pc]) << 8 | cast(u16)(memory[pc + 1])
	pc += 2

	instruction_found := false
	for instruction in instructions {
		if opcode & 0xF000 != instruction.addr do continue

		instruction_found = true
		skip_next := instruction.handle(opcode)

		if skip_next do pc += 2

		// fmt.printfln("[C8] Executed instruction for opcode %04x", opcode)
	}

	if !instruction_found {
		fmt.printfln("[C8] Instruction not found for opcode %04x", opcode)
	}
}

run_cycles :: proc() {
	now := time.tick_now()
	elapsed := time.tick_since(last_tick)
	last_tick = now
	cpu_accumulator += time.duration_milliseconds(elapsed)

	for cpu_accumulator >= FREQUENCY_MS {
		cpu_accumulator -= FREQUENCY_MS
		cycle()
	}

	for idx := 0; idx < CHIP8_WIDTH * CHIP8_HEIGHT; idx += 1 {
		pixel := display_memory[idx]
		if (pixel == 1) {
			x := u16(idx % CHIP8_WIDTH)
			y := u16(idx / CHIP8_WIDTH)
			display.draw_pixel(x, y, DISPLAY_SCALE)
		}
	}
}

destroy :: proc() {
}
