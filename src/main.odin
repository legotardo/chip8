package main

import "core:os"
import "c8"
import "display"

main :: proc() {
	display.start_display()
	defer display.destroy()

	display.on_drop_event = on_drop_event

	args := os.args
	if len(args) < 2 {
		default_program := #load("../examples/drag_a_file_here.ch8")
		c8.load_rom_from_memory(default_program)
	} else {
		program := args[1]
		c8.load_rom_from_file(program)
	}

	for display.running {
		display.begin()

		c8.run_cycles()

		display.end()
	}
}

@(private="file")
on_drop_event :: proc(file_path: string) {
	c8.load_rom_from_file(file_path)
}
