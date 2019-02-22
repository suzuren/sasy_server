
COMMON_SOURCE_FILES := $(shell ls ../protos/common/*.proto)
COMMON_TARGET_FILES := $(COMMON_SOURCE_FILES:../protos/common/%.proto=%.pb)

LOGINSERVER_SOURCE_FILES := $(shell ls ../protos/loginServer/*.proto)
LOGINSERVER_TARGET_FILES := $(LOGINSERVER_SOURCE_FILES:../protos/loginServer/%.proto=%.pb)


.PHONY: all loginserver

all: common loginserver

common: $(COMMON_TARGET_FILES)

loginserver: $(LOGINSERVER_TARGET_FILES)

common%pb: ../protos/common/common%proto
	protoc --proto_path="../protos/common" -o$@ $<

loginServer%pb: ../protos/loginServer/loginServer%proto
	protoc --proto_path="../protos/loginServer" -o$@ $<

clean:
	-rm -rf *.pb
