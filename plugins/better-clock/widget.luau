-- Local presentation refinement of yugaaank/better-clock (MIT).
function update()
  noctalia.setUpdateInterval(1000)
  local content = {
    ui.label({
      text = noctalia.formatTime(noctalia.getConfig("time_format") or "{:%H:%M}"),
      fontFamily = "Inter", fontSize = tonumber(noctalia.getConfig("font_size")) or 88,
      fontWeight = "light", color = "on_surface",
    }),
  }
  if noctalia.getConfig("show_date") ~= false then
    table.insert(content, ui.label({
      text = noctalia.formatTime(noctalia.getConfig("date_format") or "{:%d.%m.%Y}"),
      fontFamily = "Inter", fontSize = tonumber(noctalia.getConfig("date_font_size")) or 18,
      fontWeight = "medium", color = "on_surface_variant",
    }))
  end
  desktopWidget.render(ui.column({
    gap = 2, align = "center", paddingH = 28, paddingV = 14,
    fill = "surface_container/0.35", radius = 24,
  }, content))
end
update()
