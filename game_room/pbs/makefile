
COMMON_SOURCE_FILES := $(shell ls ../protos/common/*.proto)
COMMON_TARGET_FILES := $(COMMON_SOURCE_FILES:../protos/common/%.proto=%.pb)

LOGINSERVER_SOURCE_FILES := $(shell ls ../protos/loginServer/*.proto)
LOGINSERVER_TARGET_FILES := $(LOGINSERVER_SOURCE_FILES:../protos/loginServer/%.proto=%.pb)

GAMESERVER_SOURCE_FILES := $(shell ls ../protos/gameServer/*.proto)
GAMESERVER_TARGET_FILES := $(GAMESERVER_SOURCE_FILES:../protos/gameServer/%.proto=%.pb)

TESTGAME_SOURCE_FILES := $(shell ls ../protos/testGame/*.proto)
TESTGAME_TARGET_FILES := $(TESTGAME_SOURCE_FILES:../protos/testGame/%.proto=%.pb)

.PHONY: all common loginserver gamerserver testgame

all: common loginserver gamerserver testgame

common: $(COMMON_TARGET_FILES)

loginserver: $(LOGINSERVER_TARGET_FILES)

gamerserver: $(GAMESERVER_TARGET_FILES)

testgame: $(TESTGAME_TARGET_FILES)

common%pb: ../protos/common/common%proto
	protoc --proto_path="../protos/common" -o$@ $<

loginServer%pb: ../protos/loginServer/loginServer%proto
	protoc --proto_path="../protos/loginServer" -o$@ $<

gameServer%pb: ../protos/gameServer/gameServer%proto
	protoc --proto_path="../protos/gameServer" -o$@ $<

testGame%pb: ../protos/testGame/testGame%proto
	protoc --proto_path="../protos/testGame" -o$@ $<

clean:
	-rm -rf *.pb
