#
# Makefile for OpenzWave Control Panel application
# Greg Satz

# GNU make only

.SUFFIXES:	.cpp .o .a .s

GCC_SUFFIX:=47

CC     := $(CROSS_COMPILE)gcc${GCC_SUFFIX}
CXX    := $(CROSS_COMPILE)g++${GCC_SUFFIX}
LD     := $(CROSS_COMPILE)g++${GCC_SUFFIX}
AR     := $(CROSS_COMPILE)gcc-ar${GCC_SUFFIX} rc
RANLIB := $(CROSS_COMPILE)gcc-ranlib${GCC_SUFFIX}

DEBUG_CFLAGS    := -Wall -Wno-unknown-pragmas -Wno-inline -Wno-format -g -DDEBUG -ggdb -O0
RELEASE_CFLAGS  := -Wall -Wno-unknown-pragmas -Werror -Wno-format -O3 -DNDEBUG

DEBUG_LDFLAGS	:= -g

# Change for DEBUG or RELEASE
CFLAGS	:= -c $(DEBUG_CFLAGS)
LDFLAGS	:= $(DEBUG_LDFLAGS) -Wl,-rpath=/usr/local/lib/gcc47

OPENZWAVE := ./open-zwave
LIBMICROHTTPD := -L/usr/local/lib -lmicrohttpd

INCLUDES := -I$(OPENZWAVE)/cpp/src -I$(OPENZWAVE)/cpp/src/command_classes \
	-I$(OPENZWAVE)/cpp/src/value_classes -I$(OPENZWAVE)/cpp/src/platform \
	-I$(OPENZWAVE)/cpp/src/platform/unix -I$(OPENZWAVE)/cpp/tinyxml \
	-I/usr/local/include -I$(OPENZWAVE)

# Remove comment below for gnutls support
#GNUTLS := -lgnutls

# OS Dependent flag settings
ifeq ($(OS),Windows_NT)
    uname_S := Windows
else
    uname_S := $(shell uname -s)
endif

# FreeBSD
ifeq ($(uname_S), FreeBSD)
        LIBZWAVE := $(OPENZWAVE)/libopenzwave.a
        LIBUSB := -ludev -lusb
        LIBS := $(LIBZWAVE) $(GNUTLS) $(LIBMICROHTTPD) -pthread $(LIBUSB)
endif

# Linux
ifeq ($(uname_S), Linux)
	LIBZWAVE := $(OPENZWAVE)/libopenzwave.a
	LIBUSB := -ludev
	LIBS := $(LIBZWAVE) $(GNUTLS) $(LIBMICROHTTPD) -pthread $(LIBUSB) -lresolv
endif
# OS X
ifeq ($(uname_S), Darwin)
	ARCH := -arch i386 -arch x86_64
	CFLAGS += $(ARCH)
	LIBZWAVE := $(wildcard $(OPENZWAVE)/cpp/lib/mac/libopenzwave.a)
	LIBUSB := -framework IOKit -framework CoreFoundation
	LIBS := $(LIBZWAVE) $(GNUTLS) $(LIBMICROHTTPD) -pthread $(LIBUSB) $(ARCH) -lresolv
endif
# Windows
ifeq ($(uname_S), Windows)
	@echo Windows builds not supported.
	@exit 1
endif

%.o : %.cpp
	$(CXX) $(CFLAGS) $(INCLUDES) -o $@ $<

%.o : %.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $<

all: ozwcp

open-zwave:
	git clone --depth=1 https://github.com/OpenZWave/open-zwave.git

$(LIBZWAVE): open-zwave
	$(MAKE) -C $(OPENZWAVE)

config: open-zwave
	cp -R open-zwave/config ./

ozwcp.o: ozwcp.h webserver.h $(OPENZWAVE)/cpp/src/Options.h $(OPENZWAVE)/cpp/src/Manager.h \
	$(OPENZWAVE)/cpp/src/Node.h $(OPENZWAVE)/cpp/src/Group.h \
	$(OPENZWAVE)/cpp/src/Notification.h $(OPENZWAVE)/cpp/src/platform/Log.h

webserver.o: webserver.h ozwcp.h $(OPENZWAVE)/cpp/src/Options.h $(OPENZWAVE)/cpp/src/Manager.h \
	$(OPENZWAVE)/cpp/src/Node.h $(OPENZWAVE)/cpp/src/Group.h \
	$(OPENZWAVE)/cpp/src/Notification.h $(OPENZWAVE)/cpp/src/platform/Log.h

ozwcp:	$(LIBZWAVE) ozwcp.o webserver.o zwavelib.o
	$(LD) -o $@ $(LDFLAGS) ozwcp.o webserver.o zwavelib.o $(LIBS)

ozwcp2:
	$(LD) -o $@ $(LDFLAGS) ozwcp.o webserver.o zwavelib.o $(LIBS)

dist: ozwcp
	rm -f ozwcp.tar.gz
	tar -c --exclude=".svn" --exclude=".git" -hvzf ozwcp.tar.gz ozwcp config/ cp.html cp.js openzwavetinyicon.png README

.PHONY: debian_deps
debian_deps: /usr/include/microhttpd.h /usr/include/libudev.h

/usr/include/microhttpd.h:
	sudo apt-get install -y libmicrohttpd-dev

/usr/include/libudev.h:
	sudo apt-get install -y libudev-dev

clean:
	rm -f ozwcp *.o
	rm -rf $(OPENZWAVE)

run: ozwcp
	./ozwcp -p 5555
