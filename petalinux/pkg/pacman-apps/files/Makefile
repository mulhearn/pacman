# Makefile for pacman apps

# apps and supporting library
APPS     := pacman_menu pacman_units pacman_cmdserver pacman_dataserver pacman_counter pacman_push
LIB_NAME := libdrivers.a

# directories
SRC_DIR := src
LIB_DIR := lib
OBJ_DIR := obj
BIN_DIR := bin

# include directories:
INCLUDE_DIRS := -Iinclude -I$(SRC_DIR)/drivers-common -I$(SRC_DIR)/drivers-linux -I$(SRC_DIR)/platform

# library sources
COMMON_SRCS := $(wildcard $(SRC_DIR)/drivers-common/*.c) $(wildcard $(SRC_DIR)/platform/*.c)
LINUX_SRCS  := $(wildcard $(SRC_DIR)/drivers-linux/*.cc)
LIB_OBJS    := $(COMMON_SRCS:$(SRC_DIR)/drivers-common/%.c=$(OBJ_DIR)/%.o) \
$(COMMON_SRCS:$(SRC_DIR)/platform/%.c=$(OBJ_DIR)/%.o) \
$(LINUX_SRCS:$(SRC_DIR)/drivers-linux/%.cc=$(OBJ_DIR)/%.o)

# Flags
CPPFLAGS := $(INCLUDE_DIRS) -D_LINUX
CXXFLAGS := -Wall -O2
CFLAGS   := -Wall -O2
#LDLIBS   := $(LIB_DIR)/$(LIB_NAME) -lzmq -lstdc++
LDLIBS   := -lzmq -lstdc++

# default targets
APP_ELFS := $(addprefix $(BIN_DIR)/,$(addsuffix .elf,$(APPS)))

all: $(LIB_DIR)/$(LIB_NAME) $(APP_ELFS)

#-----------------------------------
# --- BUILD LIBRARY
#-----------------------------------

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

# build static library
$(LIB_DIR)/$(LIB_NAME): $(LIB_OBJS)
	@mkdir -p $(LIB_DIR)
	$(AR) rcs $@ $^

#-----------------------------------
# --- BUIlD APPLICATIONS
#-----------------------------------

# App objects:
APP_OBJS := $(addprefix $(OBJ_DIR)/,$(addsuffix .o,$(APPS)))

# build each app object from its main.cc
$(OBJ_DIR)/%.o: $(SRC_DIR)/apps/%/main.cc
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# link each ELF
$(BIN_DIR)/%.elf: $(OBJ_DIR)/%.o $(LIB_DIR)/$(LIB_NAME)
	@mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $@

#-----------------------------------
# --- CLEAN
#-----------------------------------

clean:
	rm -rf $(OBJ_DIR) $(LIB_DIR) $(BIN_DIR) __pycache__ pylib/__pycache__

simulated-pacman:
	echo "WARNING:  building with SIMULATED PACMAN HARDWARE"
	$(MAKE) CXXFLAGS+=" -DSIMULATED_PACMAN"
