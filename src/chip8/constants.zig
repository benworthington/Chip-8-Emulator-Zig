pub const Constants = struct {
    pub const ROM_FOLDER = "src/roms";

    pub const RAM_SIZE = 4096;
    pub const PROGRAM_START: u16 = 0x200;
    pub const FONT_START: u16 = 0x050;

    pub const BASE_WIDTH = 64;
    pub const BASE_HEIGHT = 32;
    pub const SCREEN_SCALE = 20;

    pub const CLOCK_SPEED: u32 = 700; // CPU clock speed in Hz
    pub const TIMER_SPEED: u32 = 60; // Timer speed in Hz

    pub const FRAME_RATE: u32 = 60; // Target frame rate

    pub const NUM_REGISTERS = 16;
    pub const STACK_DEPTH = 16;
    pub const KEYPAD_SIZE = 16;
};
