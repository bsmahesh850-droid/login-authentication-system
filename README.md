# Hardware-Assisted Login Authentication System (Verilog + ESP32)

Educational prototype: a 4-bit demonstration credential (`1010` = `0xA`) is **not** production-grade security.

* `rtl/` - synthesizable Verilog-2001 authentication controller (simulated and synthesized).
* `esp32/` - Arduino sketch: an independent software model of the same login behaviour. **The ESP32 does not run the Verilog.**
* No FPGA, keypad or other hardware is required.

## Structure
```
login-authentication-system/
├── rtl/            authentication_fsm.v  credential_checker.v  attempt_counter.v  login_controller.v
├── testbench/      tb_login_controller.v
├── esp32/          esp32_login.ino
├── docs/           architecture.md  project_report.md
├── synthesis/      yosys_commands.txt
└── README.md
```

## 1. Simulate the Verilog (Icarus Verilog)
```
sudo apt install iverilog        # Linux; macOS: brew install icarus-verilog
iverilog -g2012 -o login_sim rtl/*.v testbench/*.v
vvp login_sim
```
Expected last lines: `SUMMARY: 16 passed, 0 failed` and `OVERALL: PASS`. Optional waveform: `gtkwave login_sim.vcd`.

## 2. Synthesize (Yosys)
```
sudo apt install yosys
yosys -s synthesis/yosys_commands.txt
```
The `stat` section lists flip-flops and gates. Reference run (Yosys 0.33): 9 flip-flops, 38 generic combinational cells, no latches. Generic counts, not silicon figures.

## 3. Run the ESP32 demo
1. Arduino IDE -> Boards Manager -> install "esp32 by Espressif Systems".
2. Select your board (for example "ESP32 Dev Module"), open `esp32/esp32_login.ino`, upload.
3. Serial Monitor: **115200 baud**, line ending **Newline**.
4. Type credentials. The valid one is `A` (or `000A`).

| Input | Effect |
|-------|--------|
| `A` / `000A` | Access granted |
| any other 1-4 hex chars | Denied; 3 failures lock the interface |
| `#STATUS` | Show state and failed attempts |
| `#LOGOUT` | End a granted session |
| `#RESET` then `CONFIRM` | Administrative reset (unlock, clear counter) |

Optional LEDs and buzzer: see the pin table in `docs/architecture.md` (GPIO25 green LED, GPIO26 red LED, GPIO27 active buzzer, 220-330 ohm resistors on LEDs). Set `USE_INDICATORS 0` in the sketch if nothing is wired.

## Notes
* The spec asks for "four-digit hexadecimal-style input" but a credential of `0xA`; the sketch accepts 1 to 4 hex characters and compares the value to `0xA`.
* Status of verification: RTL simulation and Yosys run were executed; the ESP32 sketch was checked on a PC with an Arduino shim, not flashed to a board.
* Future UART link to an FPGA is a design only (see `docs/architecture.md`, section 5).
