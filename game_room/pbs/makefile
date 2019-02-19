
LOGINSERVER_SOURCE_FILES := $(shell ls ../protos/loginServer/*.proto)
LOGINSERVER_TARGET_FILES := $(LOGINSERVER_SOURCE_FILES:../protos/loginServer/%.proto=%.pb)


.PHONY: all loginserver

all: loginserver

loginserver: $(LOGINSERVER_TARGET_FILES)

loginServer%pb: ../protos/loginServer/loginServer%proto
	protoc --proto_path="../protos/loginServer" -o$@ $<

clean:
	-rm -rf *.pb
