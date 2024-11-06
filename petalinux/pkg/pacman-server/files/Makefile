APPS := pacman_cmdserver
APPS += pacman_dataserver
APPS += pacman_units
APPS += pacman_menu
APPS += zmq_test
APPS += zmq_loopback
APPS += pacman_push
APPS += pacman_counter

INCLUDE_DIR := include
SRC_DIR := src
OBJ_DIR := obj

INC := $(wildcard $(INCLUDE_DIR)/*.hh)
SRC := $(wildcard $(SRC_DIR)/*.cc)
OBJ := $(SRC:$(SRC_DIR)/%.cc=$(OBJ_DIR)/%.o)
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

$(OBJ_DIR):
	mkdir $@

.PHONY: all clean

clean:
	$(RM) -rf $(OBJ_DIR)
	$(RM) -f $(APP)
