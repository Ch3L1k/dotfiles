--!nonstrict
-- Local UI; recording itself belongs to the official Noctalia service.
local helper=noctalia.expandPath("~/.local/bin/noctalia-record-control")
local sources={"portal","region","focused"}
local qualities={28,21,16}
local rates={30,60,120}
local sizes={"original","1920x1080","1280x720"}
local audio={"none","default_output","default_input","both"}
local delays={0,3,5}
local prefs={source="portal",quality=21,fps=60,resolution="original",audio="default_output",delay=3,cursor=true}
local info={recording=false,pending=false,available=true,folder=noctalia.expandPath("~/Videos/Recordings")}
local busy=false
local checking=false
local shown=false
local errorText=""
local ticks=0
local function index(values,value)
  for i,v in ipairs(values) do if v==value then return i-1 end end
  return 0
end
local function active() return info.recording or info.pending end
local function field(label,options,values,key)
  return ui.row({gap=16,align="center"},{
    ui.label({text=label,width=138,color="on_surface_variant",fontSize=14}),
    ui.select({key=key,options=options,selectedIndex=index(values,prefs[key]),flexGrow=1,enabled=not active() and not busy,
      onChange=function(value)
        local n=tonumber(value)
        if n and values[n+1]~=nil then prefs[key]=values[n+1] end
      end}),
  })
end
function render()
  local status=info.recording and "Идёт запись" or (info.pending and "Подготовка записи…" or "Готово к записи")
  panel.render(ui.column({padding=24,gap=14,flexGrow=1},{
    ui.row({gap=12,align="center"},{
      ui.glyph({name="video",size=28,color=info.recording and "error" or "primary"}),
      ui.column({gap=3,flexGrow=1},{ui.label({text="Запись экрана",fontSize=24,fontWeight="bold"}),
        ui.label({text="Аппаратная запись · MP4",fontSize=12,color="on_surface_variant"})}),
      ui.button({glyph="x",variant="ghost",onClick=function() panel.close() end}),
    }),
    ui.row({fill=info.recording and "error_container" or "surface_container_high",radius=14,padding=12,gap=8,align="center"},{
      ui.glyph({name=info.recording and "circle-filled" or "circle-check",size=15,color=info.recording and "error" or "primary"}),
      ui.label({text=status,fontSize=14,color=info.recording and "on_error_container" or "on_surface"}),
    }),
    ui.scroll({flexGrow=1,gap=12},{
      field("Что записывать",{"Экран или окно…","Область экрана…","Текущий монитор"},sources,"source"),
      field("Качество",{"Хорошее · меньше файл","Высокое","Максимальное"},qualities,"quality"),
      field("Частота кадров",{"30 FPS","60 FPS","120 FPS"},rates,"fps"),
      field("Размер кадра",{"Как на экране","1920 × 1080","1280 × 720"},sizes,"resolution"),
      field("Звук",{"Без звука","Звук компьютера","Микрофон","Компьютер + микрофон"},audio,"audio"),
      field("Задержка",{"Без задержки","3 секунды","5 секунд"},delays,"delay"),
      ui.row({gap=16,align="center"},{ui.label({text="Показывать курсор",flexGrow=1,color="on_surface_variant",fontSize=14}),
        ui.toggle({checked=prefs.cursor,enabled=not active() and not busy,onChange=function(value) prefs.cursor=value=="true" end})}),
      ui.label({text=errorText~="" and errorText or (info.error or ""),color="error",fontSize=12,maxLines=3,visible=errorText~="" or (info.error or "")~=""}),
    }),
    ui.row({gap=8,align="center"},{
      ui.label({text="Videos / Recordings",fontSize=12,color="on_surface_variant",flexGrow=1}),
      ui.button({text="Папка записей",glyph="folder-open",variant="ghost",controlSize="sm",onClick="openFolder"}),
    }),
    ui.row({gap=10},{
      ui.button({text=active() and "Остановить и сохранить" or (busy and "Подготовка…" or "Начать запись"),
        glyph=active() and "player-stop-filled" or "player-record",variant=active() and "destructive" or "primary",
        flexGrow=1,enabled=not busy and info.available,onClick="record"}),
    }),
  }))
end
local function refresh(loadPrefs)
  if checking then return end
  checking=true
  noctalia.runAsync({helper,"get"},function(result)
    checking=false
    if result.exitCode==0 then
      local data=noctalia.json.decode(result.stdout)
      if type(data)=="table" then
        info=data
        if loadPrefs and type(data.prefs)=="table" then prefs=data.prefs end
      end
    else errorText=result.stderr end
    if shown then render() end
  end,5000)
end
function record()
  if busy then return end
  busy=true;errorText="";render()
  if active() then
    noctalia.runAsync({helper,"stop"},function(result)
      busy=false
      if result.exitCode~=0 then errorText=result.stderr end
      refresh(false)
    end,10000)
  else
    local data=noctalia.json.encode(prefs)
    local ok=noctalia.runAsync({"systemd-run","--user","--collect","--quiet","--unit=noctalia-record-start",helper,"start",data},function(result)
      busy=false
      if result.exitCode==0 then panel.close()
      else errorText=result.stderr;render() end
    end,10000)
    if not ok then busy=false;errorText="Не удалось запустить запись";render() end
  end
end
function openFolder() noctalia.runAsync({"xdg-open",info.folder}) end
function advanced()
  panel.close()
  noctalia.runAsync({"noctalia","msg","settings-open-plugin","noctalia/screen_recorder"})
end
function onOpen()
  shown=true;busy=false;ticks=0
  render();refresh(true)
  panel.setWantsSecondTicks(true)
end
function onClose()
  shown=false
  noctalia.runAsync({helper,"save",noctalia.json.encode(prefs)})
end
function update()
  if not shown then return end
  ticks+=1
  if ticks%2==0 then refresh(false) end
end
