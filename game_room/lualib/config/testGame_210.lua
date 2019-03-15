return {
	volcano = {
		isEnable = false,
		activePoolThreshold = 20000000,
		activeFishMultiple = 20,
		giveRate = 0.4,
	},
	hdDropBox = {
		isEnable = true,
		openNeedScore = 300000,
	},
	boxSceneInterval = 6,							-- 每多少次鱼阵有一次宝箱鱼阵, nil不出宝箱鱼阵
	tryScore = 1000000,								-- 试玩场坐下给多少钱
	minBroadCastPresent = 10000,					-- 播报最低牌子数
	scorePerPresent = 1,							-- 奖牌价值
	scorePerPresentTry = 0.1,							-- 试玩场牌子转换为金币系数
	presentName = "礼券",
	cannonMultiple = {
		min = 100,
		max = 500,
	},
	bombRange = {									-- 局部炸弹的范围
		width = 400,
		height = 400,
	},
	jieRiTime = {									--节日时间
		startTime = 20170213000000,
		endTime = 20170221000000,
	},
	redPacketTime = {								--红包鱼阵时间
		startTime = 20170120000000,
		endTime = 20170205000000,
	},
	fishHash = {
		[0]={name="fish1", speed=9, multiple=2, boundingBox={55,15}, probability=0.495},
		[1]={name="fish2", speed=9, multiple=2, boundingBox={60,25}, probability=0.495},
		[2]={name="fish3", speed=9, multiple=3, boundingBox={80,32}, probability=0.33},
		[3]={name="fish4", speed=7, multiple=4, boundingBox={70,43}, probability=0.2475},		
		[4]={name="fish5", speed=7, multiple=5, boundingBox={80,54}, probability=0.198},
		[5]={name="fish6", speed=6, multiple=6, boundingBox={90,70}, probability=0.165},
		[6]={name="fish7", speed=6, multiple=7, boundingBox={90,40}, probability=0.141428571},
		[7]={name="fish8", speed=5, multiple=8, boundingBox={120,55}, probability=0.12375},
		[8]={name="fish9", speed=5, multiple=9, boundingBox={150,47}, probability=0.11},
		[9]={name="fish10", speed=5, multiple=10, boundingBox={110,112}, probability=0.099},
		[10]={name="fish11", speed=4, multiple=12, boundingBox={145,80}, probability=0.0825},
		[11]={name="fish12", speed=4, multiple=15, boundingBox={120,150}, probability=0.066},
		[12]={name="fish13", speed=4, multiple=20, boundingBox={180,70}, probability=0.0495},
		[13]={name="fish14", speed=4, multiple=25, boundingBox={255,88}, probability=0.0396},
		[14]={name="蝙蝠鱼", speed=4, multiple=30, boundingBox={180,180}, probability=0.033},
		[15]={name="银鲨", speed=3, multiple=35, boundingBox={270,80}, probability=0.028285714},
		[16]={name="金鲨", speed=3, multiple=100, boundingBox={290,90}, probability=0.0099},
		[17]={name="美人鱼", speed=3, multiple={40,120}, boundingBox={500,170}, probability=0.012375},
		[18]={name="金蝙蝠鱼", speed=2, multiple={120,300}, boundingBox={400,100}, probability=0.004714286},
		[19]={name="机械鱼", speed=1, multiple=320, boundingBox={404,100}, probability=0.0030625},
		[20]={name="金猪", speed=2, multiple={300,500}, boundingBox={200,245}, probability=0.002462687},
		[21]={name="电鳗", speed=3, multiple=200, boundingBox={180,100}, probability=0.00666667},
		[22]={name="全屏炸弹", speed=3, multiple=1000, boundingBox={140,140}, probability=0.001},
		[23]={name="定屏炸弹", speed=3, multiple=20, boundingBox={130,130}, probability=0.0495},
		[24]={name="小话费", speed=4, multiple=22, boundingBox={340,130}, probability=0.005},
		[25]={name="大话费", speed=4, multiple=32, boundingBox={340,130}, probability=0.001},
		[26]={name="小金龙", speed=4, multiple=200, boundingBox={340,130}, probability=0.00495},
		[27]={name="骨鱼", speed=4, multiple=500, boundingBox={460,130}, probability=0.00198},
		[28]={name="机械虾", speed=4, multiple=600, boundingBox={460,130}, probability=0.00165},
		[29]={name="波塞冬", speed=4, multiple=800, boundingBox={460,130}, probability=0.0001},
		[30]={name="凤凰", speed=4, multiple=0, boundingBox={460,130}, probability=0.001667},
		[31]={name="南瓜鱼1", speed=4, multiple=15, boundingBox={460,130}, probability=0.06533333},
		[32]={name="南瓜鱼2", speed=4, multiple=200, boundingBox={460,130}, probability=0.0049},
		[33]={name="波塞冬的宝藏", speed=4, multiple=800, boundingBox={460,130}, probability=0.0005},
		[34]={name="大红包", speed=4, multiple=100, boundingBox={460,130}, probability=0.0098},
		[35]={name="小红包", speed=4, multiple=10, boundingBox={460,130}, probability=0.098},
		[36]={name="亲嘴鱼1", speed=4, multiple=15, boundingBox={460,130}, probability=0.06533333},
		[37]={name="亲嘴鱼2", speed=4, multiple=200, boundingBox={460,130}, probability=0.0049},
--[[		
		[30]={name="鱼王1", speed=5, multiple=0, boundingBox={150,150}, probability=0.08},
		[31]={name="鱼王2", speed=5, multiple=0, boundingBox={150,150}, probability=0.08},	
		[32]={name="鱼王3", speed=5, multiple=0, boundingBox={150,150}, probability=0.06},
		[33]={name="鱼王4", speed=5, multiple=2, boundingBox={150,150}, probability=0.05},
		[34]={name="鱼王5", speed=5, multiple=2, boundingBox={150,150}, probability=0.04},
		[35]={name="鱼王6", speed=5, multiple=0, boundingBox={150,150}, probability=0.04},
		[36]={name="鱼王7", speed=5, multiple=0, boundingBox={150,150}, probability=0.03},
		[37]={name="鱼王8", speed=5, multiple=0, boundingBox={150,150}, probability=0.02},
		[38]={name="鱼王9", speed=5, multiple=0, boundingBox={150,150}, probability=0.01},
		[39]={name="鱼王10", speed=5, multiple=0, boundingBox={150,150}, probability=0.008},
--]]
		[40]={name="美人鱼", speed=1, multiple=200, boundingBox={150,150}, probability=0.00495},
		-- [41]={name="金宝箱", speed=2, multiple={40,60}, boundingBox={150,150}, probability=0.006},
		-- [42]={name="银宝箱", speed=2, multiple={10,30}, boundingBox={150,150}, probability=0.015},
		-- [43]={name="铜宝箱", speed=2, multiple=10, boundingBox={150,150}, probability=0.03},
		-- [44]={name="小宝箱", speed=2, multiple=5, boundingBox={150,150}, probability=0.12},
		-- [45]={name="大宝箱", speed=2, multiple=20, boundingBox={150,150}, probability=0.03},
		[99]={name="扑克10", speed=3, multiple=10, boundingBox={270,80}, probability=0.1},
		[100]={name="扑克J", speed=3, multiple=10, boundingBox={270,80}, probability=0.1},
		[101]={name="扑克Q", speed=3, multiple=10, boundingBox={270,80}, probability=0.1},
		[102]={name="扑克K", speed=3, multiple=10, boundingBox={270,80}, probability=0.1},
		[103]={name="扑克A", speed=3, multiple=10, boundingBox={270,80}, probability=0.1},
	},
	bulletHash = {								-- kind:对应BulletKind name:描述 speed:子弹速度 netRadius:渔网的半径
		[0]={name="1炮筒", speed=20},
		[1]={name="2炮筒", speed=20},
		[2]={name="3炮筒", speed=20},
		[3]={name="4炮筒", speed=20},
		[4]={name="1炮筒能量炮", speed=30},
		[5]={name="2炮筒能量炮", speed=30},
		[6]={name="3炮筒能量炮", speed=30},
		[7]={name="4炮筒能量炮", speed=30},
	},
	
	-- 游戏人数对应的生成时间间隔(秒)
	singleBuildInterval = {
		smallFish={3,2,1,1,2,2,2,2},							-- 0-9
		mediumFish={10,10,10,10,3,3,3,3},						-- 10-13
		goldFish={12,12,12,12,3,3,3,3},							-- 14-15
		fish16={35,35,35,35,43,43,43,43},						-- 16 
		fish17={57,57,57,57,43,43,43,43},						-- 17
		fish18={119,119,119,119,93,93,93,93},					-- 18
		fish19={129,129,129,129,181,181,181,181},				-- 19
		fish20={150,150,150,150,91,91,91,91},					-- 20--新手场boss
		lockBomb={134,134,124,124,114,114,114,114},				-- 21
		bomb={143,143,139,139,139,139,131,131},					-- 22 
		superBomb={153,153,151,151,151,151,149,149},			-- 23
		tripleDouble={148,148,138,138,128,128,128,128},			-- 24-25
		xiaojinglong={84,84,84,84,93,93,93,93},					-- 26
		guyu={107,107,97,97,91,91,91,91},						-- 27--千炮场boss
		jixiexia={107,107,97,97,91,91,91,91},					-- 28--玩炮场boss
		big4={197,197,187,187,177,177,177,177},					-- 29
		nanGuaYu_1={10,10,10,10,3,3,3,3},						-- 31 36
		nanGuaYu_2={84,84,84,84,93,93,93,93},					-- 32 37
		fishKing={3400,3400,2900,2900,2300,2300,2300,2300},		-- 30-39
		goldBox={2110,2110,2110,2110,2110,2110,2110,2110},		-- 41
		silverBox={990,990,990,990,990,990,990,990},			-- 42
		copperBox={430,430,430,430,430,430,430,430},			-- 43	
		smallBox={60,55,50,45,60,60,60,60},						-- 44
		BigBox={150,140,130,120,180,180,180,180},				-- 45	
		PokerFish={20,20,15,15,3,3,3,3},						-- 100-104	
	},
	pipelineBuildInterval = {
		pipeline1={18,18,18,18,43,43,43,43},
		pipeline2={20,18,18,18,91,91,91,91},
		pipeline3={20,20,20,20,43,43,43,43},
		pipeline4={20,20,20,20,91,91,91,91},
		pipeline5={20,20,20,20,43,43,43,43},
	},
	contributionRatio = {		-- 贡献度控制概率
		{value=-500, ratio=0.5},
		{value=-400, ratio=0.6},
		{value=-300, ratio=0.7},
		{value=-200, ratio=0.8},
		{value=-100, ratio=0.9},
		{value=-50, ratio=0.95},
	},

	telephoneFishRate = {		--话费鱼概率动态调整--根据vip玩家的充值亏损情况
		{minValue=50, maxValue=100,ratio=1},
		{minValue=100, maxValue=200,ratio=1},
		{minValue=200, maxValue=300,ratio=1},
		{minValue=300, maxValue=500,ratio=1},
		{minValue=500, maxValue=0,ratio=1},
	},

	pathType = {
		pt_single={min=1, max=80, intervalTicks=100},
		pt_pipeline={min=1, max=80, intervalTicks=2000},
	},

	punishmentList = {
		[0] = {userId = 0},--惩罚的玩家id
		[1] = {userId = 0},	
		[2] = {userId = 0},
	},

	upRateUserList = {
		[0] = {userId = 33956, rate = 0.05},--提升玩家概率
	},

	fengHuangAddRate = {
		[0] = {gunCount = 150, 	addRate = 60},
		[1] = {gunCount = 100, 	addRate = 40},
		[2] = {gunCount = 50, 	addRate = 20},
	},

	--控制玩家暴击概率--crit暴击，miss闪避，hit打中
	controlCritRate = {
		normalRate = {crit = 10, miss = 20}, --1-10暴击，11-20闪避，21-100打中
		controlRate = {
			[0] = {userId = 0, crit = 100, miss = 20}, 
		},
	},

	notifyUserRate = {
		[0] = {userId = 0},
	},
}
