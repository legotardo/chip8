// https://en.wikipedia.org/wiki/CHIP-8
package c8

import "../display"
import "core:fmt"

Instruction :: struct {
	addr:   u16,
	handle: proc(opcode: u16) -> bool,
}

Op :: Instruction {
	addr = 0x0000,
	handle = proc(opcode: u16) -> bool {
		if opcode & 0x0F00 != 0x0000 do return false

		switch (opcode) {
		case 0x0e0:
			{
				display.clear()
				break
			}
		case 0x0ee:
			{
				fmt.printfln("Returns from a subroutine")
				break
			}
		}

		return false
	},
}

Jump :: Instruction {
	addr = 0x1000,
	handle = proc(opcode: u16) -> bool {
		pc = opcode & 0x0FFF

		return false
	},
}

Set_VX :: Instruction {
	addr = 0x6000,
	handle = proc(opcode: u16) -> bool {
		idx := u8(opcode & 0x0F00 >> 8)
		registers[idx] = u8(opcode & 0x00FF)

		return false
	},
}

Set_I :: Instruction {
	addr = 0xa000,
	handle = proc(opcode: u16) -> bool {
		i^ = u16(opcode & 0x0FFF)

		return false
	},
}

Display :: Instruction {
	addr = 0xd000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)
		n := u8(opcode & 0x000F)

		pos_x := registers[x]
		pos_y := registers[y]
		registers[15] = 0

		for row: u8 = 0; row < n; row += 1 {
			sprite := memory[i^ + u16(row)]
			for bit: u8 = 0; bit < 8; bit += 1 {
				if sprite & (0x80 >> bit) == 0 do continue

				pixel_x := (pos_x + bit) % CHIP8_WIDTH
				pixel_y := (pos_y + row) % CHIP8_HEIGHT

				display_idx := u32(pixel_y) * u32(CHIP8_WIDTH) + u32(pixel_x)

				if memory[display_idx] == 1 do registers[15] = 1

				display_memory[display_idx] ~= 1
			}
		}

		return false
	},
}

Cond_Equals :: Instruction {
	addr = 0x3000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		n := u8(opcode & 0x00FF)

		vx := registers[x]

		if vx == n do return true

		return false
	},
}

Cond_Not_Equals :: Instruction {
	addr = 0x4000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		n := u8(opcode & 0x00FF)

		vx := registers[x]

		if vx != n do return true

		return false
	},
}

Cond_Equals_2 :: Instruction {
	addr = 0x5000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		vx := registers[x]
		vy := registers[y]

		if vx == vy do return true

		return false
	},
}

Add_VX :: Instruction {
	addr = 0x7000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		n := u8(opcode & 0x00FF)

		registers[x] += n

		return false
	},
}

instructions := [?]Instruction {
	Op,
	Jump,
	Set_VX,
	Set_I,
	Display,
	Cond_Equals,
	Cond_Not_Equals,
	Cond_Equals_2,
	Add_VX,
}
