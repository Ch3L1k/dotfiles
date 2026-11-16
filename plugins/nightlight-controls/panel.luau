--!nonstrict
local helper=noctalia.expandPath("~/.local/bin/noctalia-nightlight-control")
local prefs={nightlight={enabled=false,force=false,temperature_day=6500,temperature_night=4000},location={auto_locate=true,custom_schedule=false,address="",sunset="22:00",sunrise="07:00"}}
local busy=false
local shown=false
local loaded=false
local errorText=""
local dirty=false
local function mode()
 local l=prefs.location
 return l.custom_schedule and 0 or l.auto_locate and 1 or l.address~="" and 2 or 3
end
local function setMode(i)
 prefs.location.custom_schedule=i==0;prefs.location.auto_locate=i==1
 if i==0 then
  if prefs.location.sunset=="" then prefs.location.sunset="22:00" end
  if prefs.location.sunrise=="" then prefs.location.sunrise="07:00" end
 elseif i==2 then
  prefs.location.latitude=nil;prefs.location.longitude=nil
 elseif i==3 then prefs.location.address="" end
 dirty=true;render()
end
local function label(text) return ui.label({text=text,fontSize=13,color="on_surface_variant",maxLines=3}) end
local function field(title,key)
 return ui.row({gap=12,align="center"},{ui.label({text=title,flexGrow=1,fontSize=14}),ui.input({key=key,width=145,value=prefs.location[key] or "",placeholder="ЧЧ:ММ",onChange=function(v) prefs.location[key]=v;dirty=true end})})
end
local function slider(title,key)
 return ui.column({gap=6},{
  ui.row({gap=8},{ui.label({text=title,flexGrow=1,fontSize=14}),ui.label({text=tostring(prefs.nightlight[key]).." К",fontWeight="bold",color="primary"})}),
  ui.slider({key=key,min=1000,max=10000,step=100,value=prefs.nightlight[key],enabled=not busy,onChange=function(v)
   local n=math.floor((tonumber(v) or 6500)/100+.5)*100
   if key=="temperature_night" then n=math.min(n,prefs.nightlight.temperature_day-100)
   else n=math.max(n,prefs.nightlight.temperature_night+100) end
   prefs.nightlight[key]=n;dirty=true;render()
  end}),
 })
end
function render()
 local state="Параметры сохраняются кнопкой «Применить»"
 local children={
  ui.row({gap=12,align="center"},{ui.label({text="Включать по расписанию",flexGrow=1,fontSize=15}),ui.toggle({key="enabled",checked=prefs.nightlight.enabled,enabled=not busy,onChange=function(v) prefs.nightlight.enabled=v=="true";dirty=true;render() end})}),
  ui.row({gap=12,align="center"},{ui.label({text="Всегда тёплый цвет",flexGrow=1,fontSize=15}),ui.toggle({key="force",checked=prefs.nightlight.force,enabled=not busy,onChange=function(v) prefs.nightlight.force=v=="true";dirty=true;render() end})}),
  slider("Ночью · меньше К — теплее", "temperature_night"),
  slider("Днём · 6500 К — обычный белый", "temperature_day"),
  ui.row({gap=8},{
   ui.button({text="Мягкий · 4500",variant="ghost",flexGrow=1,onClick=function() prefs.nightlight.temperature_night=4500;prefs.nightlight.temperature_day=math.max(4600,prefs.nightlight.temperature_day);dirty=true;render() end}),
   ui.button({text="Тёплый · 3500",variant="ghost",flexGrow=1,onClick=function() prefs.nightlight.temperature_night=3500;prefs.nightlight.temperature_day=math.max(3600,prefs.nightlight.temperature_day);dirty=true;render() end}),
   ui.button({text="Янтарный · 2500",variant="ghost",flexGrow=1,onClick=function() prefs.nightlight.temperature_night=2500;prefs.nightlight.temperature_day=math.max(2600,prefs.nightlight.temperature_day);dirty=true;render() end}),
  }),
  ui.label({text="Расписание",fontSize=17,fontWeight="bold"}),
  ui.select({key="schedule",options={"По часам","Закат и рассвет · автоматически","Закат и рассвет · город","Закат и рассвет · координаты"},selectedIndex=mode(),enabled=not busy,onChange=function(v) setMode(tonumber(v) or 0) end}),
 }
 if mode()==0 then
  table.insert(children,field("Включать вечером","sunset"));table.insert(children,field("Выключать утром","sunrise"))
 elseif mode()==1 then table.insert(children,label("Местоположение определяется Noctalia по IP. Часовой пояс — системный."))
 elseif mode()==2 then
  table.insert(children,ui.input({key="address",value=prefs.location.address or "",placeholder="Город, страна",onChange=function(v) prefs.location.address=v;dirty=true end}))
 else
  for _,k in ipairs({"latitude","longitude"}) do
   local key=k
   table.insert(children,ui.row({gap=12},{ui.label({text=k=="latitude" and "Широта" or "Долгота",flexGrow=1}),ui.input({key=k,width=170,value=tostring(prefs.location[k] or ""),placeholder=k=="latitude" and "−90 … 90" or "−180 … 180",onChange=function(v) prefs.location[key]=tonumber(v);dirty=true end})}))
  end
 end
 table.insert(children,label("Временное включение действует до повторного нажатия или перезапуска оболочки; сохранённое расписание не меняет."))
 table.insert(children,label("Местоположение и время заката/рассвета общие для ночного света и автоматической темы Noctalia."))
 table.insert(children,ui.label({text="Переход и экраны",fontSize=17,fontWeight="bold"}))
 table.insert(children,label("Штатный плавный переход: 60 минут вокруг заката и рассвета. В Noctalia 5.4 длительность фиксирована. Цвет применяется ко всем экранам, включая подключённые позже."))
 table.insert(children,ui.button({text="Открыть общие настройки Noctalia",variant="ghost",onClick=function() panel.close();noctalia.runAsync({"noctalia","msg","settings-open","nightlight"}) end}))
 panel.render(ui.column({padding=24,gap=14,flexGrow=1,fill="surface",radius=20},{
  ui.row({gap=12,align="center"},{ui.glyph({name="moon-stars",size=30,color="primary"}),ui.column({gap=3,flexGrow=1},{ui.label({text="Ночной цвет",fontSize=25,fontWeight="bold"}),label("Меньше синего света вечером")}),ui.button({glyph="x",variant="ghost",onClick=function() panel.close() end})}),
  ui.row({padding=12,radius=14,fill="secondary_container"},{ui.label({text=state,fontSize=13,color="on_secondary_container",maxLines=2,flexGrow=1})}),
  ui.scroll({flexGrow=1,gap=15},children),
  ui.label({text=errorText,color="error",fontSize=12,maxLines=3,visible=errorText~=""}),
  ui.row({gap=10},{ui.button({text="Временно включить / выключить",variant="secondary",flexGrow=1,enabled=not busy,onClick=function()
   noctalia.runAsync({helper,"temporary"},function(r)
    if r.exitCode~=0 then errorText=r.stderr else errorText="" end
    if shown then render() end
   end,10000)
   render()
  end}),ui.button({text=busy and "Сохранение…" or "Применить",variant="primary",enabled=loaded and not busy and dirty,onClick="apply"})}),
 }))
end
function apply()
 if busy then return end
 busy=true;errorText="";render()
 noctalia.runAsync({helper,"save",noctalia.json.encode(prefs)},function(r)
  busy=false
  if r.exitCode==0 then
   prefs=noctalia.json.decode(r.stdout);dirty=false
  else errorText=r.stderr end
  if shown then render() end
 end,15000)
end
function onOpen()
 shown=true;loaded=false;dirty=false;errorText=""
 render()
 noctalia.runAsync({helper,"get"},function(r)
  if r.exitCode==0 then prefs=noctalia.json.decode(r.stdout);loaded=true else errorText=r.stderr end
  if shown then render() end
 end,10000)
end
function onClose() shown=false end
