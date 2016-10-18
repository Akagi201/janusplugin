##############################################################################
# Project janusplugin top level Makefile for installation. Requires GNU Make.
#
# Suitable for POSIX platforms (Linux, *BSD, OSX etc.)
#
# Copyright (C) 2015 - 2016, Bob Liu.
##############################################################################

include util/ver.cfg

ROOTDIR=$(shell pwd)

ifeq (dev,$(firstword $(MAKECMDGOALS)))
PREFIX= $(ROOTDIR)/build
DEV= 1
endif

ifndef PREFIX
PREFIX= /usr/local/janus
endif

ifeq ($(shell uname -s), Darwin)
PLAT=macosx
else
PLAT=linux
endif

################################ basic commands ######################################

RM= rm -f
CP= cp -f
MKDIR= mkdir -p
RMDIR= rmdir 2>/dev/null
INSTALL_F= install -m 0644
UNINSTALL= $(RM)

######################################## build plugin ################################
PLUGIN_NAME=janus-unix-dgram
INSTALL_HEADERDIR=$(PREFIX)/include/janus
INSTALL_LIBDIR=$(PREFIX)/lib/janus/libs

CC=gcc
CFLAGS=-std=c99 -fpic -I. -I$(PREFIX)/include `pkg-config --cflags glib-2.0 jansson` -D_POSIX_C_SOURCE=200112L -c -g

default all: unix_dgram
    @echo "==== Building Janus Plugin ===="
    ifeq (linux, $(PLAT))
        $(CC) -shared -o $(PLUGIN_NAME).so unix_dgram.o -lpthread `pkg-config --libs glib-2.0 jansson`
    else
        $(CC) -shared -dynamiclib -undefined suppress -flat_namespace -o $(PLUGIN_NAME).0.dylib unix_dgram.o -lpthread `pkg-config --libs glib-2.0 jansson`
    endif
    @echo "==== Successfully build Janus Plugin ===="

unix_dgram: src/unix_dgram.c
    $(CC) $(CFLAGS) src/unix_dgram.c

######################################## deps install ################################

install: deps_install
    $(CP) $(ROOTDIR)/conf/*.cfg $(PREFIX)/etc/janus/
    $(CP) $(PLUGIN_NAME).* $(PREFIX)/lib/janus/transports/

deps_install: deps install_janus_gateway_headers install_jansson install_glib
    @echo "==== Configuring Janus Plugin Environment ===="
    @echo "==== Successfully configure Janus Plugin Environment ===="

JANUS_GATEWAY_DIR=deps/janus-gateway-$(V_JANUS_GATEWAY)
install_janus_gateway_headers:
    @echo "==== Installing Janus Gateway $(V_JANUS_GATEWAY) headers ===="
    cd $(JANUS_GATEWAY_DIR) && $(CP) {.,plugins}/*.h $(INSTALL_HEADERDIR)
    @echo "==== Successfully install Janus Gateway $(V_JANUS_GATEWAY) headers ===="

install_jansson:
    @echo "==== Installing Jansson $(V_JANSSON) ===="
    cd $(JANSSON_DIR) && sudo $(MAKE) install
    @echo "==== Successfully install Jansson $(V_JANSSON) ===="

install_glib:
    @echo "==== Installing Glib $(V_GLIB) ===="
    cd $(GLIB_DIR) && sudo $(MAKE) install
    @echo "==== Successfully install Glib $(V_GLIB) ===="

#################################### deps build #################################

deps:
    ./util/deps

JANSSON_DIR=deps/jansson-$(V_JANSSON)
jansson:
    @echo "==== Building Jansson $(V_JANSSON) ===="
    cd $(JANSSON_DIR) && cmake -DCMAKE_INSTALL_PREFIX=$(PREFIX) && $(MAKE)
    @echo "==== Successfully build Jansson $(V_JANSSON) ===="

GLIB_DIR=deps/glib-$(V_GLIB)
glib:
    @echo "==== Building Glib $(V_GLIB) ===="
    cd $(GLIB_DIR) && sh autogen.sh && ./configure --prefix=$(PREFIX) && $(MAKE)
    @echo "==== Successfully build Glib $(V_GLIB) ===="

############################### development commands #############################

clean:
    cd $(JANSSON_DIR) && $(MAKE) clean
    cd $(GLIB_DIR) && $(MAKE) clean
    @rm -rf $(ROOTDIR)/*.so
    @rm -rf $(ROOTDIR)/*.o

.PHONY: clean
