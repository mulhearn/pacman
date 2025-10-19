# ===========================
# Makefile for pacman apps
# ===========================

# Apps
APPS     := pacman_menu pacman_units
LIB_NAME := libdrivers.a

# Compiler / tools
#CXX := g++
#CC  := gcc
#AR  := ar

# Directories
SRC_DIR := src
LIB_DIR := lib
OBJ_DIR := obj
BIN_DIR := bin

# Include directories:
INCLUDE_DIRS := -Iinclude -I$(SRC_DIR)/drivers-common -I$(SRC_DIR)/drivers-linux -I$(SRC_DIR)/platform

# Library sources
COMMON_SRCS := $(wildcard $(SRC_DIR)/drivers-common/*.c) $(wildcard $(SRC_DIR)/platform/*.c)
LINUX_SRCS  := $(wildcard $(SRC_DIR)/drivers-linux/*.cc)
LIB_OBJS    := $(COMMON_SRCS:$(SRC_DIR)/drivers-common/%.c=$(OBJ_DIR)/%.o) \
$(COMMON_SRCS:$(SRC_DIR)/platform/%.c=$(OBJ_DIR)/%.o) \
$(LINUX_SRCS:$(SRC_DIR)/drivers-linux/%.cc=$(OBJ_DIR)/%.o)

# Flags
CPPFLAGS := $(INCLUDE_DIRS)
CXXFLAGS := -Wall -O2
CFLAGS   := -Wall -O2
LDLIBS   := $(LIB_DIR)/$(LIB_NAME) -lstdc++

# ===========================
# Default target
# ===========================
all: $(LIB_DIR)/$(LIB_NAME) $(BIN_DIR)/pacman_menu.elf $(BIN_DIR)/pacman_units.elf

# ===========================
# Library build
# ===========================

# C files (drivers-common + platform)
$(OBJ_DIR)/%.o: $(SRC_DIR)/drivers-common/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/platform/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# C++ files (drivers-linux)
$(OBJ_DIR)/%.o: $(SRC_DIR)/drivers-linux/%.cc
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# Build static library
$(LIB_DIR)/$(LIB_NAME): $(LIB_OBJS)
	@mkdir -p $(LIB_DIR)
	$(AR) rcs $@ $^

# ===========================
# App object rules (C++ only)
# ===========================

# Example for pacman_menu
$(OBJ_DIR)/pacman_menu.o: $(SRC_DIR)/apps/pacman_menu/main.cc
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# Example for pacman_units
$(OBJ_DIR)/pacman_units.o: $(SRC_DIR)/apps/pacman_units/main.cc
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(BIN_DIR)/pacman_menu.elf: $(OBJ_DIR)/pacman_menu.o $(LIB_DIR)/$(LIB_NAME)
	@mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(BIN_DIR)/pacman_units.elf: $(OBJ_DIR)/pacman_units.o $(LIB_DIR)/$(LIB_NAME)
	@mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $@


# ===========================
# Clean
# ===========================
.PHONY: all clean

clean:
	$(RM) -rf $(OBJ_DIR) $(LIB_DIR) $(APPS)



