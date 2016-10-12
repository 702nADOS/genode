# options: x86 arm
TOOLCHAIN_TARGET    ?= arm

# options: see tool/create_builddir
GENODE_TARGET       ?= foc_pbxa9

BUILD_DIR           ?= build
TOOLCHAIN_BUILD_DIR ?= $(BUILD_DIR)/toolchain-$(TOOLCHAIN_TARGET)
GENODE_BUILD_DIR    ?= $(BUILD_DIR)/genode-$(GENODE_TARGET)
BUILD_CONF           = $(GENODE_BUILD_DIR)/etc/build.conf

all: toolchain ports platform

# ================================================================
# Requiered packages for relaunched systems
packages:
	sudo apt-get update
	sudo apt-get install libncurses5-dev texinfo autogen autoconf2.64 g++ libexpat1-dev flex bison gperf cmake libXml2-dev libtool zlib1g-dev libglib2.0-dev
	sudo apt-get install make pkg-config gawk subversion expect git
	sudo apt-get install libxml2-utils syslinux
	sudo apt-get install xsltproc yasm iasl lynx

# ================================================================
# Genode toolchain. Only needs to be done once per target (x86/arm).
toolchain:
	mkdir -p $(TOOLCHAIN_BUILD_DIR)
	cd $(TOOLCHAIN_BUILD_DIR);\
	../../tool/tool_chain $(TOOLCHAIN_TARGET)
#
# ================================================================


# ================================================================
# Download Genode external sources. Only needs to be done once per system.
ports: foc libports

foc:
	$(MAKE) -C repos/base-foc prepare

libports:
	$(MAKE) -C repos/libports prepare
#
# ================================================================


# ================================================================
# Genode build process. Rebuild subtargets as needed.
platform: genode_build_dir tasksmanager

genode_build_dir:
	tool/create_builddir $(GENODE_TARGET) BUILD_DIR=$(GENODE_BUILD_DIR)
	printf 'REPOSITORIES += $$(GENODE_DIR)/repos/libports\n' >> $(BUILD_CONF)
	printf 'REPOSITORIES += $$(GENODE_DIR)/repos/taskmanager\n' >> $(BUILD_CONF)

taskmanager:
	$(MAKE) -j10 -C $(GENODE_BUILD_DIR) taskmanager

# Delete build directory for all target systems. In some cases, subfolders in the contrib directory might be corrupted. Remove manually and re-prepare if necessary.
clean:
	rm -rf $(BUILD_DIR)
#
# ================================================================


# ================================================================
# Run Genode with an active dom0 server.
run:
	$(MAKE) -j10 -C $(GENODE_BUILD_DIR) run/taskmanager
#
# ================================================================
