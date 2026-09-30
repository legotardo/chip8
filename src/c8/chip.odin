package c8

import "../display"
import "core:fmt"
import "core:os"
import "core:time"

CHIP8_WIDTH :: 64
CHIP8_HEIGHT :: 32
DISPLAY_SCALE :: display.SCREEN_WIDTH / CHIP8_WIDTH
START_ADDR :: 0x200
FONT_ADDR :: 0x050
FREQUENCY_MS :: 1000.0 / 700
TIMERS_FREQUENCY_MS :: 1000.0 / 60

memory: [4096]byte
stack: [16]u16
display_memory: [2048]byte
I: u16 = 0
pc: u16 = START_ADDR
sp: u8 = 0
registers: [16]byte
last_tick: time.Tick
cpu_accumulator: f64
timers_accumulator: f64
delay_timer: byte
sound_timer: byte

load_rom_from_file :: proc(path: string) {
	data, err := os.read_entire_file(path, context.allocator)
	assert(err == nil, "Failed to read rom file")
	defer delete(data, context.allocator)

	load_rom_from_memory(data)
}

load_rom_from_memory :: proc(data: []byte) {
	pc = START_ADDR
	memory = {}
	display_memory = {}
	registers = {}
	last_tick = time.tick_now()

	copy(memory[START_ADDR:], data)
	copy(memory[FONT_ADDR:], FONT)
}

@(private = "file")
cycle :: proc() {
	opcode := cast(u16)(memory[pc]) << 8 | cast(u16)(memory[pc + 1])
	pc += 2

	instruction_found := false
	for instruction in instructions {
		if opcode & instruction.mask != instruction.addr do continue

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
	timers_accumulator += time.duration_milliseconds(elapsed)

	for cpu_accumulator >= FREQUENCY_MS {
		cpu_accumulator -= FREQUENCY_MS
		cycle()
	}

	for timers_accumulator >= TIMERS_FREQUENCY_MS {
		timers_accumulator -= TIMERS_FREQUENCY_MS

		if delay_timer > 0 do delay_timer -= 1
		if sound_timer > 0 do sound_timer -= 1
	}

	for idx := 0; idx < CHIP8_WIDTH * CHIP8_HEIGHT; idx += 1 {
		pixel := display_memory[idx]
		if (pixel == 1) {
			x := u16(idx % CHIP8_WIDTH)
			y := u16(idx / CHIP8_WIDTH)
			display.draw_pixel(x, y, DISPLAY_SCALE)
		}
	}

	if sound_timer > 0 {
		display.generate_beep()
	}
}

destroy :: proc() {
}

push_stack :: proc(data: u16) {
	assert(sp < size_of(u16) * 16)

	stack[sp] = data
	sp += 1
}

pop_stack :: proc() -> u16 {
	assert(sp > 0)

	val := stack[sp - 1]
	sp -= 1

	return val
}
