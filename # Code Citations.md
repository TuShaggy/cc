# Code Citations

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if ri.status == "online" or ri.status == "charged
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if ri.status == "online" or ri.status == "charged" then
      statusColor = colors.green
    elseif ri.status == "offline" then
      statusColor = colors.gray
    elseif ri.status == "charging" then
      statusColor = colors.orange
    end

    f.draw_text_lr(mon, 
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if ri.status == "online" or ri.status == "charged" then
      statusColor = colors.green
    elseif ri.status == "offline" then
      statusColor = colors.gray
    elseif ri.status == "charging" then
      statusColor = colors.orange
    end

    f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)
    f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(ri.generation
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if ri.status == "online" or ri.status == "charged" then
      statusColor = colors.green
    elseif ri.status == "offline" then
      statusColor = colors.gray
    elseif ri.status == "charging" then
      statusColor = colors.orange
    end

    f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)
    f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(ri.generationRate) .. " rf/t", colors.white, colors.lime, colors.black)

    local tempColor = colors.red
    if ri.temperature <= 5000 then tempColor = colors.green end
    if ri.temperature >= 5000 and ri.
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if ri.status == "online" or ri.status == "charged" then
      statusColor = colors.green
    elseif ri.status == "offline" then
      statusColor = colors.gray
    elseif ri.status == "charging" then
      statusColor = colors.orange
    end

    f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)
    f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(ri.generationRate) .. " rf/t", colors.white, colors.lime, colors.black)

    local tempColor = colors.red
    if ri.temperature <= 5000 then tempColor = colors.green end
    if ri.temperature >= 5000 and ri.temperature <= 6500 then tempColor = colors.orange end
    f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(ri.temperature) .. "C", colors.white, tempColor, colors.black)
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
(8)
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
(8)
    f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputfluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)

    if autoInputGate
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
(8)
    f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputfluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)

    if autoInputGate == 1 then
      f.draw_text(mon, 14, 10, "AU", colors.white, colors.gray)
    else
      f.draw_text(mon, 14, 10, "MA", colors.white, colors.gray
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.0
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
    f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercent .. "%", colors.white, colors.white, colors.black)
    f.progress_bar(mon,
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if fieldPercent
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if fieldPercent >= 50 then fieldColor = colors.green end
    if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end

    if autoInputGate == 1 then 
      f.draw_text_lr(mon, 2, 1
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if fieldPercent >= 50 then fieldColor = colors.green end
    if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end

    if autoInputGate == 1 then 
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
    else
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent .. "%",
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
if fieldPercent >= 50 then fieldColor = colors.green end
    if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end

    if autoInputGate == 1 then 
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
    else
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
    end
    f.progress_bar(
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
.red
    if fuelPercent >= 70 then fuelColor = colors.green end
    if fuelPercent < 70 and fuelPercent > 3
```

## License: unknown
https://github.com/HollowWaka/idk/blob/d951d42e23cd38a15f457d9807ce40b5d81d360d/drmon.lua

```
.red
    if fuelPercent >= 70 then fuelColor = colors.green end
    if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end

    f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
```

## License: MIT
https://github.com/acidjazz/drmon/blob/master/drmon.lua

```
-- Layout functions
function ui.center(x)
  return math.floor(monX / 2 - x / 2)
end
```
    if fuelPercent >= 70 then fuelColor = colors.green end
    if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end

    f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
````

