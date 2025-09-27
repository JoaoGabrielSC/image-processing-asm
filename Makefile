.PHONY: run
ASM = JGS

run:
	@echo "Running ASM program"
	dosbox -c "$(ASM).exe"


build-run:
	@echo "Building ASM program and running..."
	@bash run.sh $(ASM)

help:
	@echo "=============================================="
	@echo "    Photoshop Minimal in Assembly - Makefile"
	@echo "=============================================="
	@echo "Available targets:"
	@echo ""
	@echo "  run       - Run the pre-compiled ASM program in DOSBox"
	@echo "  build-run - Build the ASM source code and run the game"
	@echo "  clean     - Remove generated object and listing files"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make run    # Quick start - run existing executable"
	@echo "  make build-run   # Compile and run from source"
	@echo "  make clean       # Clean up build artifacts"
	@echo ""
	@echo "Requirements:"
	@echo "  - DOSBox installed and available in PATH"
	@echo "  - Bash shell for build-run target"
	@echo "  - NASM assembler (included: NASM16.exe)"
	@echo "=============================================="

clean:
	@echo "Cleaning up generated files..."
	@rm -f $(ASM).OBJ $(ASM).LST
	@echo "Cleanup complete."
