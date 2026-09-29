package main

import "core:fmt"
import "core:os"
import "c8"
import "display"

main :: proc() {
	display.start_display()
	defer display.destroy()

	args := os.args
	if len(args) < 2 {
		fmt.printfln("Usage: ./chip8 <program path>")
		os.exit(0)
	}
	program := args[1]

	c8.load_rom(program)

	for display.running {
		display.begin()

		c8.run_cycles()

		display.end()
	}
}
