APPS := pacman_cmdserver
APPS += pacman_dataserver
APPS += pacman_units
APPS += zmq_test
APPS += zmq_loopback
APPS += pacman_push
APPS += pacman_counter

INCLUDE_DIR := include
SRC_DIR := src
OBJ_DIR := obj

INC := $(wildcard $(INCLUDE_DIR)/*.hh)

SRC_CC := $(wildcard $(SRC_DIR)/*.cc)
SRC_C  := $(wildcard $(SRC_DIR)/*.c)
SRC := $(SRC_CC) $(SRC_C)

OBJ_CC := $(SRC_CC:$(SRC_DIR)/%.cc=$(OBJ_DIR)/%.o)
OBJ_C  := $(SRC_C:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
OBJ := $(OBJ_CC) $(OBJ_C)

ABJ := $(filter-out $(APPS:%=$(OBJ_DIR)/%.o), $(OBJ))

CPPFLAGS += -I${INCLUDE_DIR}

LDLIBS += -lzmq -lstdc++

all: build

debug:
	echo $(OBJ)

build: $(APPS)

$(APPS): $(OBJ)
	$(CC) $(LDFLAGS) $(ABJ) $(OBJ_DIR)/$@.o $(LDLIBS) -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cc $(INC) | $(OBJ_DIR) 
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(INC) | $(OBJ_DIR) 
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJ_DIR):
	mkdir $@

.PHONY: all clean

clean:
	$(RM) -rf $(OBJ_DIR)
	$(RM) -f $(APP)
