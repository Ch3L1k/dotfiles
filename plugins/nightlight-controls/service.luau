--!nonstrict
-- Noctalia renders the declared settings; this service only applies their changes.
local helper=noctalia.expandPath("~/.local/bin/noctalia-nightlight-control")
local keys={"mode","warmth","temperature","day_temperature","start_time","end_time","city","latitude","longitude"}
local pending=true
local ticks=0
local busy=false
local lastPayload=""
local lastError=""
noctalia.setUpdateInterval(500)
local function payload()
 local values={}
 for _,key in ipairs(keys) do values[key]=noctalia.getConfig(key) end
 return noctalia.json.encode(values)
end
function onConfigChanged()
 if payload()~=lastPayload then pending=true;ticks=0 end
end
function update()
 if not pending or busy then return end
 ticks+=1
 if ticks<3 then return end
 pending=false;ticks=0;busy=true
 local data=payload();lastPayload=data
 noctalia.runAsync({helper,"apply-settings",data},function(r)
  busy=false
  if r.exitCode~=0 then
   local message=r.stderr or "Не удалось применить настройки."
   noctalia.log(message)
   if message~=lastError then
    noctalia.runAsync({"notify-send","-a","Ночной цвет","-u","normal","Настройки ночного цвета",message})
    lastError=message
   end
  else lastError="" end
  if payload()~=data then pending=true;ticks=0 end
 end,15000)
end
