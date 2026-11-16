--!nonstrict
local helper=noctalia.expandPath("~/.local/bin/system-controls")
local shown=false
local busy=false
local checking=false
local ticks=0
local info={summary="Проверка состояния…",eco=false,actions={}}
local errorText=""
local messageText=""
local selected="Все"
local tabs={"Все","Питание","Мониторы","Инструменты"}
local function execute(id)
  if busy then return end
  busy=true;errorText="";messageText="";render()
  noctalia.runAsync({helper,"run",id},function(result)
    busy=false
    if result.exitCode~=0 then errorText=result.stderr else errorText="";messageText=result.stdout or "" end
    refresh()
  end,180000)
end
function render()
  local children={}
  for _,a in ipairs(info.actions) do
    if selected=="Все" or selected==a.group then
      local id=a.id
      table.insert(children,ui.row({gap=14,padding=14,radius=16,fill="surface_container_high",align="center"},{
        ui.glyph({name=a.icon,size=25,color="primary"}),
        ui.column({gap=5,flexGrow=1},{
          ui.label({text=a.title,fontSize=15,fontWeight="bold"}),
          ui.label({text=a.description,fontSize=12,color="on_surface_variant",maxLines=2}),
        }),
        ui.button({text=a.button or "Открыть",variant=a.id=="eco" and info.eco and "primary" or "secondary",enabled=not busy and a.enabled~=false,onClick=function() execute(id) end}),
      }))
    end
  end
  local tabButtons={}
  for _,t in ipairs(tabs) do
    local name=t
    table.insert(tabButtons,ui.button({text=t,flexGrow=1,variant=selected==t and "primary" or "ghost",onClick=function() selected=name;render() end}))
  end
  panel.render(ui.column({padding=24,gap=16,flexGrow=1},{
    ui.row({gap=12,align="center"},{
      ui.glyph({name="adjustments",size=30,color="primary"}),
      ui.column({gap=4,flexGrow=1},{ui.label({text="Скрипты системы",fontSize=25,fontWeight="bold"}),ui.label({text="Управление ноутбуком · Alt + Shift + S",fontSize=12,color="on_surface_variant"})}),
      ui.button({glyph="x",variant="ghost",onClick=function() panel.close() end}),
    }),
    ui.row({padding=14,radius=16,fill="secondary_container",gap=10,align="center"},{
      ui.glyph({name=info.eco and "battery-eco" or "cpu",size=22,color="on_secondary_container"}),
      ui.label({text=info.summary,fontSize=13,color="on_secondary_container",maxLines=3,flexGrow=1}),
    }),
    ui.row({gap=4},tabButtons),
    ui.scroll({flexGrow=1,gap=10},children),
    ui.label({text=messageText,color="primary",fontSize=12,maxLines=6,visible=messageText~=""}),
    ui.label({text=errorText,color="error",fontSize=12,maxLines=3,visible=errorText~=""}),
    ui.label({text=busy and "Применение…" or "Настройки и состояние обновляются автоматически",fontSize=12,color="on_surface_variant"}),
  }))
end
function refresh()
  if checking then return end
  checking=true
  noctalia.runAsync({helper,"status"},function(result)
    checking=false
    if result.exitCode==0 then
      local data=noctalia.json.decode(result.stdout)
      if type(data)=="table" then info=data end
    else errorText=result.stderr end
    if shown then render() end
  end,7000)
end
function onOpen() shown=true;errorText="";messageText="";ticks=0;render();refresh();panel.setWantsSecondTicks(true) end
function onClose() shown=false end
function update() if shown then ticks+=1;if ticks%4==0 then refresh() end end end
