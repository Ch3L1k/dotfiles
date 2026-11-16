--!nonstrict
barWidget.setGlyph("adjustments")
barWidget.setTooltip("Скрипты системы · Alt + Shift + S")
function onClick()
 noctalia.runAsync({"noctalia","msg","panel-toggle","ch3l1k/system-controls:main"})
end
