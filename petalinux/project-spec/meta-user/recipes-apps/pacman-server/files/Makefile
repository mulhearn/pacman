APPS =  pacman-cmdserver
APPS += pacman-dataserver

# Add any other object files to this list below
 APP_OBJS =  pacman-cmdserver.o
 APP_OBJS += pacman-dataserver.o

all: build

build: $(APPS)

$(APPS): $(APP_OBJS)
	$(CC) $(LDFLAGS) -o $@ $@.o $(LDLIBS) -lzmq

clean:
	$(RM) $(APP_OBJS) $(APPS)
