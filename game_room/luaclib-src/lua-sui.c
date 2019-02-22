#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>

struct VariationInfo {
	int64_t revenue;
	int64_t score;
	int64_t insure;
	int64_t grade;
	int64_t medal;
	int64_t gift;
	int64_t present;
	int64_t experience;
	int64_t loveliness;
	int64_t playTimeCount;
	int64_t winCount;
	int64_t lostCount;
	int64_t drawCount;
	int64_t fleeCount;
};

struct user_info { 
	int8_t isInit;
	int8_t isModified;
	
	struct VariationInfo variationInfo;
		
	int64_t grade;
	int64_t trusteeScore; //0
	int64_t frozenedScore;
	uint32_t deskPos;
	
	uint32_t kindID;
	uint32_t nodeID;
	uint32_t serverID;
	uint32_t tableID;
	uint32_t chairID;
	int32_t userStatus;
	
	int64_t restrictScore; //限制积分
	int32_t enListStatus;
	int8_t isAndroid;
	int32_t agent;
	char ipAddr[32];
	char machineID[40];
	int32_t deskCount;
	uint32_t userRule;
	uint32_t mobileUserRule;
	uint32_t logonTime;
	uint32_t inoutIndex;
	
	int8_t isClientReady;
		
	uint32_t userID;
	uint32_t gameID;
	uint32_t platformID;
	char nickName[128];
	char signature[256];
	uint8_t gender;
	uint16_t faceID;
	char platformFace[256];
	
	int32_t userRight;
	int32_t masterRight;
	int32_t memberOrder;
	int32_t masterOrder;
	
	int64_t siteDownScore;
	int64_t score;
	int64_t insure;
	int64_t present;
	int64_t loveliness;
	int64_t medal;
	int64_t gift;
	int64_t experience;
	
	int64_t winCount;
	int64_t lostCount;
	int64_t drawCount;
	int64_t fleeCount;
	int64_t contribution;
	int64_t dbStatus;
};


static void testGet(lua_State *L, struct user_info * p, const char * k)
{
	if(strcmp(k, "isModified")==0)
	{
		lua_pushstring(L, "isModified");
		lua_pushboolean(L, p->isModified);
		
		lua_settable(L, 3);
	}
	else if(strcmp(k, "variationInfo")==0)
	{
		lua_pushstring(L, "variationInfo");
		lua_newtable(L);
		lua_pushstring(L, "revenue");
		lua_pushinteger(L, p->variationInfo.revenue);
		lua_settable(L, -3);
		lua_pushstring(L, "score");
		lua_pushinteger(L, p->variationInfo.score);
		lua_settable(L, -3);
		lua_pushstring(L, "insure");
		lua_pushinteger(L, p->variationInfo.insure);
		lua_settable(L, -3);
		lua_pushstring(L, "grade");
		lua_pushinteger(L, p->variationInfo.grade);
		lua_settable(L, -3);
		lua_pushstring(L, "medal");
		lua_pushinteger(L, p->variationInfo.medal);
		lua_settable(L, -3);
		lua_pushstring(L, "gift");
		lua_pushinteger(L, p->variationInfo.gift);
		lua_settable(L, -3);
		lua_pushstring(L, "present");
		lua_pushinteger(L, p->variationInfo.present);
		lua_settable(L, -3);
		lua_pushstring(L, "experience");
		lua_pushinteger(L, p->variationInfo.experience);
		lua_settable(L, -3);
		lua_pushstring(L, "playTimeCount");
		lua_pushinteger(L, p->variationInfo.playTimeCount);
		lua_settable(L, -3);
		lua_pushstring(L, "winCount");
		lua_pushinteger(L, p->variationInfo.winCount);
		lua_settable(L, -3);
		lua_pushstring(L, "lostCount");
		lua_pushinteger(L, p->variationInfo.lostCount);
		lua_settable(L, -3);
		lua_pushstring(L, "drawCount");
		lua_pushinteger(L, p->variationInfo.drawCount);
		lua_settable(L, -3);
		lua_pushstring(L, "fleeCount");
		lua_pushinteger(L, p->variationInfo.fleeCount);
		lua_settable(L, -3);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "grade")==0)
	{
		lua_pushstring(L, "grade");
		lua_pushinteger(L, p->grade);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "trusteeScore")==0)
	{
		lua_pushstring(L, "trusteeScore");
		lua_pushinteger(L, p->trusteeScore);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "frozenedScore")==0)
	{
		lua_pushstring(L, "frozenedScore");
		lua_pushinteger(L, p->frozenedScore);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "deskPos")==0)
	{
		lua_pushstring(L, "deskPos");
		lua_pushinteger(L, p->deskPos);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "kindID")==0)
	{
		lua_pushstring(L, "kindID");
		lua_pushinteger(L, p->kindID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "nodeID")==0)
	{
		lua_pushstring(L, "nodeID");
		lua_pushinteger(L, p->nodeID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "serverID")==0)
	{
		lua_pushstring(L, "serverID");
		lua_pushinteger(L, p->serverID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "tableID")==0)
	{
		lua_pushstring(L, "tableID");
		lua_pushinteger(L, p->tableID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "chairID")==0)
	{
		lua_pushstring(L, "chairID");
		lua_pushinteger(L, p->chairID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "userStatus")==0)
	{
		lua_pushstring(L, "userStatus");
		lua_pushinteger(L, p->userStatus);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "restrictScore")==0)
	{
		lua_pushstring(L, "restrictScore");
		lua_pushinteger(L, p->restrictScore);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "enListStatus")==0)
	{
		lua_pushstring(L, "enListStatus");
		lua_pushinteger(L, p->enListStatus);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "isAndroid")==0)
	{
		lua_pushstring(L, "isAndroid");
		lua_pushboolean(L, p->isAndroid);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "agent")==0)
	{
		lua_pushstring(L, "agent");
		lua_pushinteger(L, p->agent);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "ipAddr")==0)
	{
		lua_pushstring(L, "ipAddr");
		lua_pushlstring(L, p->ipAddr, strlen(p->ipAddr));
		lua_settable(L, 3);
	}
	else if(strcmp(k, "machineID")==0)
	{
		lua_pushstring(L, "machineID");
		lua_pushlstring(L, p->machineID, strlen(p->machineID));
		lua_settable(L, 3);
	}
	else if(strcmp(k, "deskCount")==0)
	{
		lua_pushstring(L, "deskCount");
		lua_pushinteger(L, p->deskCount);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "userRule")==0)
	{
		lua_pushstring(L, "userRule");
		lua_pushinteger(L, p->userRule);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "mobileUserRule")==0)
	{
		lua_pushstring(L, "mobileUserRule");
		lua_pushinteger(L, p->mobileUserRule);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "logonTime")==0)
	{
		lua_pushstring(L, "logonTime");
		lua_pushinteger(L, p->logonTime);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "inoutIndex")==0)
	{
		lua_pushstring(L, "inoutIndex");
		lua_pushinteger(L, p->inoutIndex);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "isClientReady")==0)
	{
		lua_pushstring(L, "isClientReady");
		lua_pushboolean(L, p->isClientReady);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "userID")==0)
	{
		lua_pushstring(L, "userID");
		lua_pushinteger(L, p->userID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "gameID")==0)
	{
		lua_pushstring(L, "gameID");
		lua_pushinteger(L, p->gameID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "platformID")==0)
	{
		lua_pushstring(L, "platformID");
		lua_pushinteger(L, p->platformID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "nickName")==0)
	{
		lua_pushstring(L, "nickName");
		lua_pushlstring(L, p->nickName, strlen(p->nickName));
		lua_settable(L, 3);
	}
	else if(strcmp(k, "signature")==0)
	{
		lua_pushstring(L, "signature");
		lua_pushlstring(L, p->signature, strlen(p->signature));
		lua_settable(L, 3);
	}
	else if(strcmp(k, "gender")==0)
	{
		lua_pushstring(L, "gender");
		lua_pushinteger(L, p->gender);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "faceID")==0)
	{
		lua_pushstring(L, "faceID");
		lua_pushinteger(L, p->faceID);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "platformFace")==0)
	{
		lua_pushstring(L, "platformFace");
		lua_pushlstring(L, p->platformFace, strlen(p->platformFace));
		lua_settable(L, 3);
	}
	else if(strcmp(k, "userRight")==0)
	{
		lua_pushstring(L, "userRight");
		lua_pushinteger(L, p->userRight);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "masterRight")==0)
	{
		lua_pushstring(L, "masterRight");
		lua_pushinteger(L, p->masterRight);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "memberOrder")==0)
	{
		lua_pushstring(L, "memberOrder");
		lua_pushinteger(L, p->memberOrder);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "masterOrder")==0)
	{
		lua_pushstring(L, "masterOrder");
		lua_pushinteger(L, p->masterOrder);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "siteDownScore")==0)
	{
		lua_pushstring(L, "siteDownScore");
		lua_pushinteger(L, p->siteDownScore);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "score")==0)
	{
		lua_pushstring(L, "score");
		lua_pushinteger(L, p->score);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "insure")==0)
	{
		lua_pushstring(L, "insure");
		lua_pushinteger(L, p->insure);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "present")==0)
	{
		lua_pushstring(L, "present");
		lua_pushinteger(L, p->present);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "loveliness")==0)
	{
		lua_pushstring(L, "loveliness");
		lua_pushinteger(L, p->loveliness);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "medal")==0)
	{
		lua_pushstring(L, "medal");
		lua_pushinteger(L, p->medal);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "gift")==0)
	{
		lua_pushstring(L, "gift");
		lua_pushinteger(L, p->gift);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "experience")==0)
	{
		lua_pushstring(L, "experience");
		lua_pushinteger(L, p->experience);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "winCount")==0)
	{
		lua_pushstring(L, "winCount");
		lua_pushinteger(L, p->winCount);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "lostCount")==0)
	{
		lua_pushstring(L, "lostCount");
		lua_pushinteger(L, p->lostCount);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "drawCount")==0)
	{
		lua_pushstring(L, "drawCount");
		lua_pushinteger(L, p->drawCount);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "fleeCount")==0)
	{
		lua_pushstring(L, "fleeCount");
		lua_pushinteger(L, p->fleeCount);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "contribution")==0)
	{
		lua_pushstring(L, "contribution");
		lua_pushinteger(L, p->contribution);
		lua_settable(L, 3);
	}
	else if(strcmp(k, "dbStatus")==0)
	{
		lua_pushstring(L, "dbStatus");
		lua_pushinteger(L, p->dbStatus);
		lua_settable(L, 3);
	}
}

static void testSet(lua_State *L, struct user_info* p, const char * k)
{
	if(strcmp(k, "isModified")==0)
	{
		p->isModified = lua_toboolean(L, -1);
	}
	else if(strcmp(k, "variationInfo")==0)
	{
		lua_pushnil(L);
		while(lua_next(L, -2) != 0) {
			if(strcmp(lua_tostring(L, -2), "revenue")==0)
				p->variationInfo.revenue = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "score")==0)
				p->variationInfo.score = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "insure")==0)
				p->variationInfo.insure = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "grade")==0)
				p->variationInfo.grade = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "medal")==0)
				p->variationInfo.medal = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "gift")==0)
				p->variationInfo.gift = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "present")==0)
				p->variationInfo.present = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "experience")==0)
				p->variationInfo.experience = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "loveliness")==0)
				p->variationInfo.loveliness = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "playTimeCount")==0)
				p->variationInfo.playTimeCount = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "winCount")==0)
				p->variationInfo.winCount = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "lostCount")==0)
				p->variationInfo.lostCount = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "drawCount")==0)
				p->variationInfo.drawCount = lua_tointeger(L, -1);
			else if(strcmp(lua_tostring(L, -2), "fleeCount")==0)
				p->variationInfo.fleeCount = lua_tointeger(L, -1);
			lua_pop(L, 1);
		}
	}
	else if(strcmp(k, "grade")==0)
	{
		p->grade = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "trusteeScore")==0)
	{
		p->trusteeScore = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "frozenedScore")==0)
	{
		p->frozenedScore = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "deskPos")==0)
	{
		p->deskPos = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "kindID")==0)
	{
		p->kindID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "nodeID")==0)
	{
		p->nodeID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "serverID")==0)
	{
		p->serverID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "tableID")==0)
	{
		p->tableID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "chairID")==0)
	{
		p->chairID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "userStatus")==0)
	{
		p->userStatus = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "restrictScore")==0)
	{
		p->restrictScore = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "enListStatus")==0)
	{
		p->enListStatus = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "isAndroid")==0)
	{
		p->isAndroid = lua_toboolean(L, -1);
	}
	else if(strcmp(k, "agent")==0)
	{
		p->agent = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "ipAddr")==0)
	{
		strcpy(p->ipAddr, lua_tostring(L, -1));
	}
	else if(strcmp(k, "machineID")==0)
	{
		strcpy(p->machineID, lua_tostring(L, -1));
	}
	else if(strcmp(k, "deskCount")==0)
	{
		p->deskCount = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "userRule")==0)
	{
		p->userRule = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "mobileUserRule")==0)
	{
		p->mobileUserRule = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "logonTime")==0)
	{
		p->logonTime = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "inoutIndex")==0)
	{
		p->inoutIndex = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "isClientReady")==0)
	{
		p->isClientReady = lua_toboolean(L, -1);
	}
	else if(strcmp(k, "userID")==0)
	{
		p->userID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "gameID")==0)
	{
		p->gameID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "platformID")==0)
	{
		p->platformID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "nickName")==0)
	{
		strcpy(p->nickName, lua_tostring(L, -1));
	}
	else if(strcmp(k, "signature")==0)
	{
		strcpy(p->signature, lua_tostring(L, -1));
	}
	else if(strcmp(k, "gender")==0)
	{
		p->gender = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "faceID")==0)
	{
		p->faceID = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "platformFace")==0)
	{
		strcpy(p->platformFace, lua_tostring(L, -1));
	}
	else if(strcmp(k, "userRight")==0)
	{
		p->userRight = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "masterRight")==0)
	{
		p->masterRight = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "memberOrder")==0)
	{
		p->memberOrder = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "masterOrder")==0)
	{
		p->masterOrder = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "siteDownScore")==0)
	{
		p->siteDownScore = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "score")==0)
	{
		p->score = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "insure")==0)
	{
		p->insure = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "present")==0)
	{
		p->present = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "loveliness")==0)
	{
		p->loveliness = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "medal")==0)
	{
		p->medal = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "gift")==0)
	{
		p->gift = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "experience")==0)
	{
		p->experience = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "winCount")==0)
	{
		p->winCount = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "lostCount")==0)
	{
		p->lostCount = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "drawCount")==0)
	{
		p->drawCount = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "fleeCount")==0)
	{
		p->fleeCount = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "contribution")==0)
	{
		p->contribution = lua_tointeger(L, -1);
	}
	else if(strcmp(k, "dbStatus")==0)
	{
		p->dbStatus = lua_tointeger(L, -1);
	}
}

static void testAdd(lua_State *L, struct user_info* p, const char * k)
{
	if(strcmp(k, "siteDownScore")==0)
	{
		p->siteDownScore += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "score")==0)
	{
		p->score += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "insure")==0)
	{
		p->insure += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "present")==0)
	{
		p->present += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "loveliness")==0)
	{
		p->loveliness += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "medal")==0)
	{
		p->medal += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "gift")==0)
	{
		p->gift += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "experience")==0)
	{
		p->experience += lua_tointeger(L, -1);
	}
	else if(strcmp(k, "contribution")==0)
	{
		p->contribution += lua_tointeger(L, -1);
	}
}

static int l_new(lua_State *L) {
	struct user_info * copy = malloc(sizeof(*copy));
	memset(copy,0,sizeof(struct user_info));
	lua_pushlightuserdata(L, (void*)copy);
	return 1;
}

static int l_initialize(lua_State *L) {
	if(!lua_isuserdata(L,1))
	{
		return luaL_error(L, "not an userdata");
	}
	struct user_info* p = (struct user_info*)lua_touserdata(L,1);
	if(p->isInit)
		return luaL_error(L, "is already initialized");
	p->isInit = 1;
	lua_pushnil(L);
	while(lua_next(L, 2) != 0) {
		testSet(L, p, lua_tostring(L, -2));
		lua_pop(L, 1);
	}
	lua_pushnil(L);
	while(lua_next(L, 3) != 0) {
		testSet(L, p, lua_tostring(L, -2));
		lua_pop(L, 1);
	}
	return 0;
}

static int l_getAttribute(lua_State *L) {
	if(!lua_isuserdata(L,1))
	{
		return luaL_error(L, "not an userdata");
	}
	struct user_info* p = (struct user_info*)lua_touserdata(L,1);
	if(!p->isInit)
		return luaL_error(L, "operate an unused object");
	lua_newtable(L); //3是返回值table
	lua_pushnil(L);
	while(lua_next(L, 2) != 0) {
		testGet(L, p, lua_tostring(L, -1));
		lua_pop(L, 1);
	}
	return 1;
}

static int l_setAttribute(lua_State *L) {
	if(!lua_isuserdata(L,1))
	{
		return luaL_error(L, "not an userdata");
	}
	struct user_info* p = (struct user_info*)lua_touserdata(L,1);
	if(!p->isInit)
		return luaL_error(L, "operate an unused object");
	lua_pushnil(L);
	while(lua_next(L, 2) != 0) {
		testSet(L, p, lua_tostring(L, -2));
		lua_pop(L, 1);
	}
	return 0;
}

static int l_addAttribute(lua_State *L) {
	if(!lua_isuserdata(L,1))
	{
		return luaL_error(L, "not an userdata");
	}
	struct user_info* p = (struct user_info*)lua_touserdata(L,1);
	if(!p->isInit)
		return luaL_error(L, "operate an unused object");
	lua_pushnil(L);
	while(lua_next(L, 2) != 0) {
		testAdd(L, p, lua_tostring(L, -2));
		lua_pop(L, 1);
	}
	return 0;
}

static int l_distillVariation(lua_State *L) {
	if(!lua_isuserdata(L,1))
	{
		return luaL_error(L, "not an userdata");
	}
	struct user_info* p = (struct user_info*)lua_touserdata(L,1);
	if(!p->isInit)
		return luaL_error(L, "operate an unused object");
	lua_pushboolean(L, p->isModified);
	if(p->isModified)
	{
		p->isModified = 0;
		
		lua_newtable(L);
		lua_pushstring(L, "variationInfo");
		lua_newtable(L);
		
		lua_pushstring(L, "revenue");
		lua_pushinteger(L, p->variationInfo.revenue);
		lua_settable(L, -3);
		lua_pushstring(L, "score");
		lua_pushinteger(L, p->variationInfo.score);
		lua_settable(L, -3);
		lua_pushstring(L, "insure");
		lua_pushinteger(L, p->variationInfo.insure);
		lua_settable(L, -3);
		lua_pushstring(L, "grade");
		lua_pushinteger(L, p->variationInfo.grade);
		lua_settable(L, -3);
		lua_pushstring(L, "medal");
		lua_pushinteger(L, p->variationInfo.medal);
		lua_settable(L, -3);
		lua_pushstring(L, "gift");
		lua_pushinteger(L, p->variationInfo.gift);
		lua_settable(L, -3);
		lua_pushstring(L, "present");
		lua_pushinteger(L, p->variationInfo.present);
		lua_settable(L, -3);
		lua_pushstring(L, "experience");
		lua_pushinteger(L, p->variationInfo.experience);
		lua_settable(L, -3);
		lua_pushstring(L, "loveliness");
		lua_pushinteger(L, p->variationInfo.loveliness);
		lua_settable(L, -3);
		lua_pushstring(L, "playTimeCount");
		lua_pushinteger(L, p->variationInfo.playTimeCount);
		lua_settable(L, -3);
		lua_pushstring(L, "winCount");
		lua_pushinteger(L, p->variationInfo.winCount);
		lua_settable(L, -3);
		lua_pushstring(L, "lostCount");
		lua_pushinteger(L, p->variationInfo.lostCount);
		lua_settable(L, -3);
		lua_pushstring(L, "drawCount");
		lua_pushinteger(L, p->variationInfo.drawCount);
		lua_settable(L, -3);
		lua_pushstring(L, "fleeCount");
		lua_pushinteger(L, p->variationInfo.fleeCount);
		lua_settable(L, -3);
		lua_settable(L, -3);
		lua_pushstring(L, "userID");
		lua_pushinteger(L, p->userID);
		lua_settable(L, -3);
		lua_pushstring(L, "inoutIndex");
		lua_pushinteger(L, p->inoutIndex);
		lua_settable(L, -3);
		
		memset(&(p->variationInfo),0,sizeof(struct VariationInfo));
		return 2;
	}
	return 1;
}

static void testWrite(lua_State *L, struct VariationInfo* p, const char * k, struct user_info* p1)
{
	int64_t temp = lua_tointeger(L, -1);
	if(strcmp(k, "revenue")==0)
	{
		p->revenue += temp;
	}
	else if(strcmp(k, "score")==0)
	{
		p->score += temp;
		p1->score += temp;
	}
	else if(strcmp(k, "insure")==0)
	{
		p->insure += temp;
		p1->insure += temp;
	}
	else if(strcmp(k, "grade")==0)
	{
		p->grade += temp;
		p1->grade += temp;
	}
	else if(strcmp(k, "medal")==0)
	{
		p->medal += temp;
		p1->medal += temp;
	}
	else if(strcmp(k, "gift")==0)
	{
		p->gift += temp;
		p1->gift += temp;
	}
	else if(strcmp(k, "present")==0)
	{
		p->present += temp;
		p1->present += temp;
	}
	else if(strcmp(k, "experience")==0)
	{
		p->experience += temp;
		p1->experience += temp;
	}
	else if(strcmp(k, "loveliness")==0)
	{
		p->loveliness += temp;
		p1->loveliness += temp;
	}
}

static int l_writeUserScore(lua_State *L)
{
	if(!lua_isuserdata(L,1))
	{
		return luaL_error(L, "not an userdata");
	}
	struct user_info* p = (struct user_info*)lua_touserdata(L,1);
	if(!p->isInit)
		return luaL_error(L, "operate an unused object");
	struct VariationInfo *temp = &(p->variationInfo);
	temp->playTimeCount += lua_tointeger(L, -1);
	int t = lua_tointeger(L, -2);
	if(t == 1)
	{
		temp->winCount ++;
		p->winCount ++;
	}
	else if(t == 2)
	{
		temp->lostCount ++;
		p->lostCount ++;
	}
	else if(t == 3)
	{
		temp->drawCount ++;
		p->drawCount ++;
	}
	else if(t == 4)
	{
		temp->fleeCount ++;
		p->fleeCount ++;
	}
		
	p->isModified = 1;
	if(p->isAndroid)
	{
		return 0;
	}
	lua_pushnil(L);
	while(lua_next(L, 2) != 0) {
		testWrite(L, temp, lua_tostring(L, -2), p);
		lua_pop(L, 1);
	}
	return 0;
}

static int l_destroy(lua_State *L)
{
	if(lua_isuserdata(L,1))
	{
		struct user_info* p = (struct user_info*)lua_touserdata(L,1);
		memset(p,0,sizeof(struct user_info));
		free(p);
	}
	return 0;
}

static int l_reset(lua_State *L)
{
	if(lua_isuserdata(L,1))
	{
		struct user_info* p = (struct user_info*)lua_touserdata(L,1);
		memset(p,0,sizeof(struct user_info));
	}
	return 0;
}

int luaopen_sui(lua_State *L) {
	luaL_checkversion(L);
	
	luaL_Reg l[] = {
		{ "addAttribute", l_addAttribute },
		{ "setAttribute", l_setAttribute },
		{ "getAttribute", l_getAttribute },
		{ "writeUserScore", l_writeUserScore },
		{ "distillVariation", l_distillVariation },
		{ "destroy", l_destroy },
		{ "initialize", l_initialize },
		{ "reset", l_reset },
		{ "new", l_new },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);

	return 1;
}
