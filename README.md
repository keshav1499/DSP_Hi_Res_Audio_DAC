# UART-to-I2S Audio Streamer on Tang Nano 9K

This project implements real-time audio streaming over UART to the UDA1334A I2S DAC using the Tang Nano 9K FPGA. The system receives 24-bit stereo audio samples via UART (from PC using PuTTY or any terminal) and streams them over I2S at 96kHz with a BCK of 4.8MHz.

## Features

- **I2S Protocol Support**: 24-bit stereo output with proper word select (WS) and bit clock (BCK).
- **UART Streaming**: Stream audio directly from PC over UART at 3 Mbps.
- **Real-Time Playback**: No buffer overflows thanks to UART FIFO management.
- **Test ROM**: Optionally load a simple beep or test waveform via ROM.

## Hardware Used

- **FPGA**: Tang Nano 9K (Gowin GW1NR-LV9QN88C6/I5)
- **DAC**: UDA1334A I2S Stereo DAC
- **Clock Source**: Internal 27 MHz clock PLL-ed to 4.8 MHz for BCK

## Baud Rate / Clock Requirements

- **UART Baud Rate**: 3,000,000 (3 Mbps)
- **System Clock**: 27 MHz
- **I2S BCK**: 4.8 MHz (generated using Gowin PLL IP)

## File Structure

```
/src
    driver.v          # Main I2S transmission module
    uart_receiver.v   # UART 24-bit packet receiver
    sine_wave_24bit.hex  # Optional waveform for test beep
/main_pc
    uart_sender.py    # Python script to stream audio from .wav file or live tone
README.md
```

## Usage Instructions

### FPGA

1. Flash the `driver.v` and `uart_receiver.v` to your Tang Nano 9K.
2. Ensure PLL is configured to generate 4.8 MHz BCK from 27 MHz input.

### PC Side (Putty or Python)

**Using PuTTY**:  
- Set baud rate to `3000000`  
- Send raw 24-bit audio samples packed as 3 bytes per sample, alternating L-R-L-R.

**Using Python (uart_sender.py)**:
```bash
python uart_sender.py --port COMx --file audio.wav
```

### Audio Format

- Each stereo sample is 6 bytes (3 for left + 3 for right)
- Signed 24-bit PCM (MSB first)

## Notes

- Ensure FPGA and PC serial port are both using 3 Mbps and 8-N-1 config.
- You may need a USB-to-UART module capable of 3 Mbps.

## Credits

Created by [Keshav Jha  github.com/keshav1499]  
License: MIT
