APP := pacman-cmdserver
APP += pacman-dataserver

INCLUDE_DIR := include
SRC_DIR := src
OBJ_DIR := obj

SRC := $(wildcard $(SRC_DIR)/*.cc)
OBJ := $(SRC:$(SRC_DIR)/%.cc=$(OBJ_DIR)/%.o)

CPPFLAGS += -I${INCLUDE_DIR}

LDLIBS += -lzmq -lstdc++

all: build

build: $(APP)

$(APP): $(OBJ)
	$(CC) $(LDFLAGS) $(filter-out $(OBJ_DIR)/$(filter-out $@, $(APP)).o, $^) $(LDLIBS) -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cc | $(OBJ_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJ_DIR):
	mkdir $@

.PHONY: all clean

clean:
	$(RM) -rf $(OBJ_DIR)
	$(RM) -f $(APP)
