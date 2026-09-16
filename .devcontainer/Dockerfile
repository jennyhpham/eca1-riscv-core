FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        iverilog \
        yosys \
        binutils-riscv64-unknown-elf \
        gcc-riscv64-unknown-elf \
        python3 \
    && rm -rf /var/lib/apt/lists/*
