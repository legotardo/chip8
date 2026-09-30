// https://en.wikipedia.org/wiki/CHIP-8
package c8

import "core:math/rand"
import "../keyboard"

COSMAC_JUMP_OFFSET :: false
COSMAC_SHIFT :: false

Instruction :: struct {
	addr:   u16,
	mask:   u16,
	handle: proc(opcode: u16) -> bool,
}

Clear_Display :: Instruction {
	addr = 0x0000,
	mask = 0xFF0F,
	handle = proc(opcode: u16) -> bool {
		display_memory = {}

		return false
	},
}

Jump :: Instruction {
	addr = 0x1000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		pc = opcode & 0x0FFF

		return false
	},
}

Call_Subrotine :: Instruction {
	addr = 0x2000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		push_stack(pc)
		pc = opcode & 0x0FFF

		return false
	},
}

Return_Subrotine :: Instruction {
	addr = 0x00EE,
	mask = 0xFFFF,
	handle = proc(opcode: u16) -> bool {
		pc = pop_stack()

		return false
	},
}

Set_VX :: Instruction {
	addr = 0x6000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		idx := u8(opcode & 0x0F00 >> 8)
		registers[idx] = u8(opcode & 0x00FF)

		return false
	},
}

Set_I :: Instruction {
	addr = 0xA000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		I = opcode & 0x0FFF

		return false
	},
}

Jump_Offset :: Instruction {
	addr = 0xB000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		if COSMAC_JUMP_OFFSET {
			offset := opcode & 0x0FFF
			pc = offset + u16(registers[0])
		} else {
			x := u8((opcode & 0x0F00) >> 8)
			offset := opcode & 0x00FF
			pc = offset + u16(registers[x])
		}

		return false
	},
}

Display :: Instruction {
	addr = 0xD000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)
		n := u8(opcode & 0x000F)

		pos_x := registers[x]
		pos_y := registers[y]
		registers[15] = 0

		for row: u8 = 0; row < n; row += 1 {
			sprite := memory[I + u16(row)]
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
	mask = 0xF000,
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
	mask = 0xF000,
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
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		vx := registers[x]
		vy := registers[y]

		if vx == vy do return true

		return false
	},
}

Cond_Equals_3 :: Instruction {
	addr = 0x9000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		vx := registers[x]
		vy := registers[y]

		if vx != vy do return true

		return false
	},
}

Add_VX :: Instruction {
	addr = 0x7000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		n := u8(opcode & 0x00FF)

		registers[x] += n

		return false
	},
}

VX_EQ_VY :: Instruction {
	addr = 0x8000,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		registers[x] = registers[y]

		return false
	},
}

VX_OR_VY :: Instruction {
	addr = 0x8001,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		registers[x] |= registers[y]

		return false
	},
}

VX_AND_VY :: Instruction {
	addr = 0x8002,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		registers[x] &= registers[y]

		return false
	},
}

VX_XOR_VY :: Instruction {
	addr = 0x8003,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		registers[x] ~= registers[y]

		return false
	},
}

VX_PLUS_VY :: Instruction {
	addr = 0x8004,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		sum := u16(registers[x]) + u16(registers[y])
		carry := u8(sum > 0xFF)
		registers[x] = u8(sum)
		registers[15] = carry

		return false
	},
}

VX_MINUS_VY :: Instruction {
	addr = 0x8005,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		not_borrow := u8(registers[x] >= registers[y])
		registers[x] -= registers[y]
		// Fiquei muito tempo tentando entender o motivo pelo qual
		// essa flag estava errada, e era por causa que poderia existir
		// um overflow que acabava chegando no registrador VF
		// por conta disso, ele precisa sempre ser salvo por último.
		registers[15] = not_borrow

		return false
	},
}

VX_SHIFT_R :: Instruction {
	addr = 0x8006,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		if COSMAC_SHIFT {
			registers[x] = registers[y]
		}
		shifted := registers[x] & 1
		registers[x] >>= 1
		registers[15] = shifted

		return false
	},
}


VX_VY_MINUS_VX :: Instruction {
	addr = 0x8007,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		not_borrow := u8(registers[y] >= registers[x])
		registers[x] = registers[y] - registers[x]
		registers[15] = not_borrow

		return false
	},
}

VX_SHIFT_L :: Instruction {
	addr = 0x800E,
	mask = 0xF00F,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		y := u8((opcode & 0x00F0) >> 4)

		if COSMAC_SHIFT {
			registers[x] = registers[y]
		}
		// Bit mais significativo, diferente
		// do shift_r
		shifted := (registers[x] >> 7) & 1
		registers[x] <<= 1
		registers[15] = shifted

		return false
	},
}

Set_VX_From_Delay_Timer :: Instruction {
	addr = 0xF007,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)

		registers[x] = delay_timer

		return false
	},
}

Set_Delay_Timer :: Instruction {
	addr = 0xF015,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)

		delay_timer = registers[x]

		return false
	},
}

Set_Sound_Timer :: Instruction {
	addr = 0xF018,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)

		sound_timer = registers[x]

		return false
	},
}

Store_Value :: Instruction {
	addr = 0xF055,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := (opcode & 0x0F00) >> 8

		for count: u16 = 0; count <= x; count += 1 {
			memory[I + count] = registers[count]
		}

		return false
	},
}

Load_Value :: Instruction {
	addr = 0xF065,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := (opcode & 0xF00) >> 8

		for count: u16 = 0; count <= x; count += 1 {
			registers[count] = memory[I + count]
		}

		return false
	},
}

Binary_Decimal_Conversion :: Instruction {
	addr = 0xF033,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0xF00) >> 8)
		vx := registers[x]

		val1 := vx / 100
		val2 := vx % 100 / 10
		val3 := vx % 10

		memory[I] = val1
		memory[I + 1] = val2
		memory[I + 2] = val3

		return false
	},
}

Add_To_Index :: Instruction {
	addr = 0xF01E,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0xF00) >> 8)
		vx := registers[x]

		I += u16(vx)

		return false
	},
}

Skip_Key_N_Pressed :: Instruction {
	addr = 0xE0A1,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0xF00) >> 8)
		vx := registers[x]
		is_pressed := keyboard.is_key_down(vx)

		return !is_pressed
	},
}

Skip_Key_Pressed :: Instruction {
	addr = 0xE09E,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0xF00) >> 8)
		vx := registers[x]
		is_pressed := keyboard.is_key_down(vx)

		return is_pressed
	},
}

Get_Key :: Instruction {
	addr = 0xF00A,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0xF00) >> 8)
		vx := registers[x]

		if !keyboard.was_some_key_pressed() do pc -= 2

		return false
	},
}

Random :: Instruction {
	addr = 0xC000,
	mask = 0xF000,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		n := u8(opcode & 0x00FF)

		registers[x] = u8(rand.int_range(0, int(n))) & n

		return false
	},
}

Font_Char :: Instruction {
	addr = 0xF029,
	mask = 0xF0FF,
	handle = proc(opcode: u16) -> bool {
		x := u8((opcode & 0x0F00) >> 8)
		vx := registers[x]

		I = FONT_ADDR + u16(vx * 5)

		return false
	},
}

instructions := [?]Instruction {
	Clear_Display,
	Jump,
	Set_VX,
	Set_I,
	Display,
	Cond_Equals,
	Cond_Not_Equals,
	Cond_Equals_2,
	Cond_Equals_3,
	Add_VX,
	VX_EQ_VY,
	VX_OR_VY,
	VX_AND_VY,
	VX_XOR_VY,
	VX_PLUS_VY,
	VX_MINUS_VY,
	VX_SHIFT_R,
	VX_VY_MINUS_VX,
	VX_SHIFT_L,
	Set_VX_From_Delay_Timer,
	Set_Delay_Timer,
	Set_Sound_Timer,
	Call_Subrotine,
	Return_Subrotine,
	Store_Value,
	Load_Value,
	Binary_Decimal_Conversion,
	Add_To_Index,
	Skip_Key_N_Pressed,
	Skip_Key_Pressed,
	Jump_Offset,
	Get_Key,
	Random,
	Font_Char,
}
