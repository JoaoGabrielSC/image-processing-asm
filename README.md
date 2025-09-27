# Photoshop Minimal - Assembly x86

A basic photoshop implementation written in x86 Assembly language for the Embedded Systems course project (2025/1).

<img width="1000" height="774" alt="image" src="https://github.com/user-attachments/assets/b3726fe2-6e10-4fb6-9832-a226d2c7da9e" />
<img width="1007" height="783" alt="image" src="https://github.com/user-attachments/assets/1570aabc-7aa1-4544-b76b-4b087ba9aac7" />
<img width="1004" height="779" alt="image" src="https://github.com/user-attachments/assets/85f12166-0a07-4258-b7e9-89f3c7b4600f" />
<img width="1004" height="782" alt="image" src="https://github.com/user-attachments/assets/d28441b4-14cc-48f6-89e1-e081562213d8" />
<img width="1007" height="775" alt="image" src="https://github.com/user-attachments/assets/c5c6c4be-5864-4d80-a5a8-b2e3dec14ddf" />


## Author

**João Gabriel Santos Custódio**  
Embedded Systems Laboratory Project - 2025/1

## Description

This project implements a digital image processing program in 16-bit x86 Assembly language. The application features a graphical user interface with mouse support and allows users to open and visualize images, as well as apply several classic filters:

- **Open Image**: Load and display images from text files
- **Low-Pass Filter**: Smooths the image using a 3x3 neighborhood average
- **High-Pass Filter**: Highlights edges and details using a 3x3 kernel
- **Gradient Filter**: Applies a gradient operation for edge detection
- **Interactive UI**: Mouse-driven interface with buttons for each operation
- **VGA Graphics**: 640x480 resolution, 16-color mode

All image processing and UI rendering are performed directly in Assembly, demonstrating low-level graphics and file handling techniques for DOS environments.

### Graphics

- Resolution: 640x480 pixels
- Color mode: 16 colors
- Real-time rendering with collision detection
- Smooth ball and paddle animations

## Requirements

- **DOSBox**: Installed and configured
- **Bash**: Linux/macOS or WSL on Windows to execute scripts
- **Make**: Build automation tool
- **NASM**: Netwide Assembler (included in project)

## Installation & Setup

1. Clone the repository:

```bash
git clone https://github.com/JoaoGabrielSC/image-processing-asm.git
cd image-processing-asm
```

2. Ensure DOSBox is installed on your system

3. Make the run script executable:

```bash
chmod +x run.sh
```

## Usage

The project includes a Makefile with several convenient targets:

### `make run`

Runs the pre-compiled code executable in DOSBox:

```bash
make run
```

### `make build-run`

Builds the assembly source code and runs the game:

```bash
make build-run
```

### `make clean`

Removes generated object and listing files:

```bash
make clean
```

### `make help`

Shows all available commands:

```bash
make help
```

## Manual Compilation

If you prefer to compile manually:

1. Start DOSBox
2. Mount the project directory
3. Use the included NASM assembler:

```
nasm16.exe JGS.asm
freelink.exe JGS.obj
JGS.exe
```

## Project Structure

```
├── JGS.asm           # Main assembly source code
├── JGS.exe           # Compiled executable
├── Makefile          # Build automation
├── run.sh            # DOSBox execution script
├── DOSBox.conf       # DOSBox configuration
├── NASM16.exe        # 16-bit NASM assembler
├── FREELINK.exe      # Linker for DOS
├── asm/              # Additional assembly modules
│   └── MODE13H/      # Graphics mode utilities
└── dosbox.app/       # DOSBox application (macOS)
```

## Technical Details

### Assembly Implementation

- **Segment Architecture**: Uses classic DOS segment model
- **Interrupt Handling**: Custom keyboard interrupt (INT 9h)
- **Graphics**: VGA mode 12h (640x480, 16 colors)
- **Memory Management**: Stack and data segment organization

### Performance Optimizations

- Efficient memory usage with segment registers
- Optimized drawing routines
- Minimal interrupt overhead
- Direct VGA memory access

**DOSBox not found**: Ensure DOSBox is installed and in your PATH

```bash
# macOS with Homebrew
brew install dosbox

# Ubuntu/Debian
sudo apt-get install dosbox
```

**Permission denied on run.sh**: Make the script executable

```bash
chmod +x run.sh
```

**Assembly errors**: Ensure you're using the included NASM16.exe for 16-bit compatibility

## Learning Outcomes

This project demonstrates:

- Low-level programming concepts
- Graphics programming fundamentals  
- Interrupt handling and system programming
- Assembly language optimization techniques
- Real-time game development principles

## License

This project is part of an academic assignment for the Embedded Systems course. Feel free to study and learn from the implementation.

## Contributing

This is an academic project, but suggestions and improvements are welcome! Please feel free to:

- Report bugs
- Suggest optimizations
- Share learning insights

---

**Note**: This code runs in a DOS environment through DOSBox. For the best experience, ensure DOSBox is properly configured with appropriate CPU cycles.`
