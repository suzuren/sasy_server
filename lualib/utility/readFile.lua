local skynet = require "skynet"
local tableConfigUrl = skynet.getenv("root_dir").."/lualib/config/tableConfig/"

function split(str, reps)  
    local resultStrsList = {};  
    string.gsub(str, '[^' .. reps ..']+', function(w) table.insert(resultStrsList, w) end );  
    return resultStrsList;  
end    
  
function loadCsvFile(fileName)   
    local tableConfig = {}  
    local f = io.open(tableConfigUrl..fileName, "r")
    if not f then
        skynet.error("----------------read--config--failed---fileName=%s--------",fileName)
    end  

    local data = f:read("*a")
    f:close()

    -- 按行划分
    local tableConfig = split(data, '\n\r');

    --[[ 从第2行开始保存（第一行是标题，后面的行才是内容） 用二维数组保存：arr[ID][属性标题字符串] ]]  
    local titles = split(tableConfig[1], ",")  

    local ID = 1  
    local returnTable = {}  
    for i = 2, #tableConfig, 1 do  
        local content = split(tableConfig[i], ",")  

        returnTable[ID] = {}  
        -- 以标题作为索引，保存每一列的内容，取值的时候这样取：returnTable[1].Title  
        for j = 1, #titles, 1 do
            returnTable[ID][titles[j]] = content[j] 
        end

        ID = ID + 1
    end  

    ID = ID - 1

    return returnTable,ID
end 


return {
    loadCsvFile = loadCsvFile,
}

