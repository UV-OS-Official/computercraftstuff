--[[
Full Featured "Generic Linux" (single file)
- Auto-detects monitor (uses advanced monitor if present)
- Touch + keyboard (WASD) support
- Fancy boot logo & animation (paintutils-like drawing)
- Multiple video animations (longer/more detailed)
- Basic shell commands: ls, cat, help, neofetch, uptime
- All drawn in-code (no wget)
-- Paste into a CC:Tweaked computer and run
-- Controls:
   WASD = move selection, Enter = open, Backspace = return, Q = shutdown
   Touch: tap icon to launch
-- Enjoy :)
]]--

-- -------------- Helpers: surface abstraction --------------
local surface = {}
-- will be set to either monitor wrapper or term table
local SUR = nil
local SUR_NAME = "term"

-- try find a monitor peripheral (advanced) and use it
local function findMonitor()
  if peripheral then
    local names = peripheral.getNames and peripheral.getNames() or {}
    for _,n in ipairs(names) do
      local t = peripheral.getType and peripheral.getType(n) or nil
      if t == "monitor" then
        local mon = peripheral.wrap(n)
        if mon then
          return mon, n
        end
      end
    end
    -- fallback: peripheral.find if available
    if peripheral.find then
      local ok, mon = pcall(peripheral.find, "monitor")
      if ok and mon then return mon, "monitor" end
    end
  end
  return nil, nil
end

local mon, monName = findMonitor()
if mon then
  SUR = mon
  SUR_NAME = monName or "monitor"
else
  SUR = term
  SUR_NAME = "term"
end

-- unify API: clear(), setCursor(x,y), write(s), setBG(c), setFG(c), getSize()
function surface.clear()
  if SUR.clear then return SUR.clear() end
  term.clear()
end
function surface.setCursor(x,y)
  if SUR.setCursorPos then return SUR.setCursorPos(x,y) end
  term.setCursorPos(x,y)
end
function surface.write(s)
  if SUR.write then return SUR.write(s) end
  term.write(s)
end
function surface.setBG(c)
  if SUR.setBackgroundColor then return SUR.setBackgroundColor(c) end
  term.setBackgroundColor(c)
end
function surface.setFG(c)
  if SUR.setTextColor then return SUR.setTextColor(c) end
  term.setTextColor(c)
end
function surface.getSize()
  if SUR.getSize then return SUR.getSize() end
  return term.getSize()
end
function surface.clearLine(y)
  local w,h = surface.getSize()
  surface.setCursor(1,y)
  surface.setBG(colors.black)
  surface.setFG(colors.white)
  surface.write(string.rep(" ", w))
  surface.setCursor(1,y)
end

-- draw a filled rectangle with background color
local function rect(x,y,w,h,color)
  surface.setBG(color)
  for j=0,h-1 do
    surface.setCursor(x, y + j)
    surface.write(string.rep(" ", w))
  end
end

-- draw centered text on given row
local function centerText(row, text)
  local w, h = surface.getSize()
  local x = math.floor((w - #text)/2) + 1
  surface.setCursor(x, row)
  surface.write(text)
end

-- draw pixel-art frame from 2D color grid (frame[y][x])
local function drawFrameGrid(frame, startX, startY)
  local h = #frame
  local w = 0
  if h > 0 then w = #frame[1] end
  for y=1,h do
    for x=1,w do
      local c = frame[y][x]
      c = c or colors.black
      surface.setBG(c)
      surface.setCursor(startX + x - 1, startY + y - 1)
      surface.write(" ")
    end
  end
end

-- convenience clamp
local function clamp(v, a, b) if v < a then return a end if v > b then return b end return v end

-- -------------- Globals & Layout --------------
local W, H = surface.getSize()
local APPS_PER_ROW = 6
local ICON_W, ICON_H = 6, 4
local ICON_GAP_X, ICON_GAP_Y = 2, 3
local TOP_MARGIN = 4
local LEFT_MARGIN = 4

-- app list (we'll draw them programmatically)
local apps = {
  { id="terminal", name="Terminal", iconColor=colors.gray },
  { id="files",    name="Files",    iconColor=colors.orange },
  { id="video",    name="Video",    iconColor=colors.blue },
  { id="video2",   name="Video 2",  iconColor=colors.lightBlue },
  { id="video3",   name="Video 3",  iconColor=colors.purple },
  { id="settings", name="Settings", iconColor=colors.cyan },
  { id="about",    name="About",    iconColor=colors.lime },
}
local selected = 1

-- compute positions for apps (grid layout)
local function layoutApps()
  W,H = surface.getSize()
  local per_row = APPS_PER_ROW
  local positions = {}
  for i,app in ipairs(apps) do
    local row = math.floor((i-1) / per_row)
    local col = (i-1) % per_row
    local x = LEFT_MARGIN + col * (ICON_W + ICON_GAP_X)
    local y = TOP_MARGIN + row * (ICON_H + ICON_GAP_Y)
    positions[i] = { x=x, y=y }
  end
  return positions
end

local appPositions = layoutApps()

-- detect if surface supports touch events (i.e., monitor)
local function hasTouch()
  return SUR_NAME ~= "term"
end

-- -------------- Boot Animation + Logo --------------
local function drawLogoBig(startX, startY)
  -- mint-ish fancy logo (6x6 pixel art)
  local grid = {
    {0,0,colors.lime,colors.lime,0,0},
    {0,colors.lime,colors.green,colors.green,colors.lime,0},
    {colors.lime,colors.green,colors.lime,colors.lime,colors.green,colors.lime},
    {colors.lime,colors.green,colors.lime,colors.lime,colors.green,colors.lime},
    {0,colors.lime,colors.green,colors.green,colors.lime,0},
    {0,0,colors.lime,colors.lime,0,0},
  }
  local frame = {}
  for y=1,#grid do
    frame[y] = {}
    for x=1,#grid[y] do frame[y][x] = grid[y][x] end
  end
  drawFrameGrid(frame, startX, startY)
end

local function bootSequence()
  surface.clear()
  W,H = surface.getSize()
  -- progress bar animation across center
  local barY = math.floor(H/2)
  for i=1,W do
    rect(1, barY, W, 1, colors.black)
    rect(1, barY, i, 1, colors.green)
    centerText(barY - 2, "Initializing Generic Linux...")
    os.sleep(0.02)
  end

  -- show big logo centered
  local logoW, logoH = 6, 6
  local sx = math.floor((W - logoW)/2) + 1
  local sy = barY - 8
  drawLogoBig(sx, sy)
  centerText(sy + logoH + 1, "Generic Linux")
  centerText(sy + logoH + 2, "Mint-ish CC Edition")
  os.sleep(1.2)
end

-- -------------- Draw desktop, top/bottom bars, icons --------------
local function drawTopBar()
  surface.setBG(colors.black)
  surface.setFG(colors.white)
  surface.clearLine(1)
  surface.setCursor(2,1)
  surface.write(" Generic Linux (Lua) - "..(hasTouch() and "Touch+KB" or "KB only"))
  -- time on right
  local timeStr = os.date("%Y-%m-%d %H:%M:%S")
  surface.setCursor(W - #timeStr - 1, 1)
  surface.write(timeStr)
end

local function drawBottomBar()
  surface.setBG(colors.black)
  surface.setFG(colors.white)
  surface.clearLine(H)
  surface.setCursor(2, H)
  surface.write(" WASD Move | Enter Open | Backspace Return | Q Quit ")
end

local function drawAppIcon(i, isSelected)
  local pos = appPositions[i]
  local a = apps[i]
  local baseColor = a.iconColor or colors.gray
  local selColor = colors.lightGray
  local fg = colors.black
  -- draw icon box ICON_W x ICON_H
  rect(pos.x, pos.y, ICON_W, ICON_H, isSelected and selColor or baseColor)
  -- draw a simple inner pattern to look like an icon
  local innerX = pos.x + 1
  local innerY = pos.y + 1
  rect(innerX, innerY, ICON_W-2, ICON_H-2, colors.white)
  -- label (below icon)
  local label = a.name
  local lx = pos.x
  local ly = pos.y + ICON_H
  surface.setBG(colors.black)
  surface.setFG(isSelected and colors.green or colors.white)
  surface.setCursor(lx, ly)
  local pad = ICON_W + 1
  surface.write(label:sub(1, pad))
end

local function drawDesktop()
  W,H = surface.getSize()
  surface.clear()
  drawTopBar()
  drawBottomBar()
  appPositions = layoutApps()
  for i,_ in ipairs(apps) do
    drawAppIcon(i, i == selected)
  end
end

-- -------------- Video animations (multi-frame grids) --------------
-- We'll make three videos, each longer and more detailed.
-- Frames are 2D arrays of color numbers

-- Helper: generate gradient frame (for a "sunrise" effect)
local function sunriseFrame(width, height, phase)
  local frame = {}
  for y=1,height do
    frame[y] = {}
    for x=1,width do
      local t = (x + phase) / (width + 6)
      if y < height*0.4 then
        frame[y][x] = colors.lightBlue
      elseif y < height*0.6 then
        frame[y][x] = colors.blue
      elseif y < height*0.8 then
        frame[y][x] = colors.orange
      else
        frame[y][x] = colors.yellow
      end
    end
  end
  return frame
end

-- Video 1: sunrise animation (longer)
local function video_sunrise()
  local width = math.min(40, W - 10)
  local height = math.min(12, H - 8)
  for phase=0, 60 do
    local f = sunriseFrame(width, height, phase)
    local sx = math.floor((W - width)/2) + 1
    local sy = math.floor((H - height)/2) + 1
    drawFrameGrid(f, sx, sy)
    centerText(sy + height + 1, "Sunrise - Press Backspace to stop")
    local timer = os.startTimer(0.12)
    local loop = true
    while loop do
      local e, a, b, c = os.pullEvent()
      if e == "timer" and a == timer then loop = false end
      if e == "key" and a == keys.backspace then return end
      if e == "monitor_touch" or e == "mouse_click" then
        -- if touch, stop too
        if e == "monitor_touch" then
          local _,_,tx,ty = a, b, c -- fallback, won't be used
        end
      end
    end
  end
end

-- Video 2: bouncing block with colors (long, more frames)
local function video_bounce()
  local width = math.min(36, W - 10)
  local height = math.min(10, H - 8)
  local sx = math.floor((W - width)/2) + 1
  local sy = math.floor((H - height)/2) + 1
  local x, y = 1, 1
  local dx, dy = 1, 1
  for t=1, 200 do
    -- blank background
    rect(sx, sy, width, height, colors.black)
    -- draw a colorful blob
    local color = ({colors.red, colors.orange, colors.yellow, colors.lime, colors.green, colors.lightBlue, colors.purple})[(t % 7) + 1]
    rect(sx + x - 1, sy + y - 1, 4, 2, color)
    centerText(sy + height + 1, "Bounce - Press Backspace to stop")
    local timer = os.startTimer(0.07)
    local loop = true
    while loop do
      local e, a, b, c = os.pullEvent()
      if e == "timer" and a == timer then loop = false end
      if e == "key" and a == keys.backspace then return end
      if e == "monitor_touch" and a and b and c then -- monitor_touch returns (side,x,y)
        return
      end
    end
    x = x + dx
    y = y + dy
    if x <= 1 or x >= width-3 then dx = -dx end
    if y <= 1 or y >= height-1 then dy = -dy end
  end
end

-- Video 3: scrolling matrix-like effect (long)
local function video_matrix()
  local width = math.min(48, W - 8)
  local height = math.min(14, H - 6)
  local sx = math.floor((W - width)/2) + 1
  local sy = math.floor((H - height)/2) + 1
  local cols = {}
  for i=1,width do cols[i] = {pos = math.random(1,height), speed = 1 + math.random(2)} end
  for t=1, 300 do
    rect(sx, sy, width, height, colors.black)
    for i=1,width do
      local c = cols[i]
      c.pos = c.pos + c.speed
      if c.pos > height then c.pos = 1 end
      -- draw column
      for k=0,3 do
        local py = ((c.pos - k -1) % height) + 1
        local color = (k==0) and colors.lime or colors.green
        surface.setBG(color)
        surface.setCursor(sx + i - 1, sy + py - 1)
        surface.write(" ")
      end
    end
    centerText(sy + height + 1, "Matrix - Press Backspace to stop")
    local timer = os.startTimer(0.06)
    local loop = true
    while loop do
      local e, a, b, c = os.pullEvent()
      if e == "timer" and a == timer then loop = false end
      if e == "key" and a == keys.backspace then return end
      if e == "monitor_touch" and a and b and c then return end
    end
  end
end

-- wrapper that picks which video to play by id
local function playVideo(id)
  if id == "video" then video_sunrise()
  elseif id == "video2" then video_bounce()
  elseif id == "video3" then video_matrix()
  end
end

-- -------------- Simple shell app with basic commands --------------
local function runShell()
  surface.clear()
  surface.setFG(colors.white)
  surface.setBG(colors.black)
  centerText(2, "Generic Shell - type 'help' for commands. 'exit' to back.")
  local startTime = os.time()
  while true do
    surface.setFG(colors.green); surface.setBG(colors.black)
    surface.write("$ ")
    surface.setFG(colors.white)
    local line = read()
    if not line then break end
    line = line:match("^%s*(.-)%s*$")
    if line == "" then
      -- nothing
    elseif line == "exit" then break
    elseif line == "help" then
      print("Available: help, ls, cat <file>, neofetch, uptime, exit")
    elseif line == "ls" then
      for _,f in ipairs(fs.list("/")) do print(f) end
    elseif line:sub(1,4) == "cat " then
      local fname = line:sub(5)
      if fs.exists(fname) then
        local fh = fs.open(fname, "r")
        if fh then
          print(fh.readAll()); fh.close()
        else print("Unable to open "..fname) end
      else print("No such file: "..fname) end
    elseif line == "neofetch" then
      print("Generic Linux (Lua) - Neofetch-ish")
      print("Shell: generic-shell")
      print("Memory: not tracked")
      print("Uptime: "..(os.time() - startTime).."s")
    elseif line == "uptime" then
      print("Uptime: "..(os.time() - startTime).."s")
    else
      print("command not found: "..line)
    end
  end
end

-- -------------- App launching --------------
local function launchAppByIndex(i)
  local a = apps[i]
  if not a then return end
  surface.clear()
  if a.id == "terminal" then
    runShell()
  elseif a.id == "files" then
    surface.setBG(colors.black); surface.setFG(colors.white)
    centerText(2, "Files - Root listing (press Backspace to return)")
    local y = 4
    for _,f in ipairs(fs.list("/")) do
      surface.setCursor(4, y); surface.write(" - " .. f); y = y + 1
      if y >= H - 2 then break end
    end
    -- wait for backspace
    while true do
      local e, k = os.pullEvent("key")
      if k == keys.backspace then break end
    end
  elseif a.id:sub(1,5) == "video" then
    playVideo(a.id)
  elseif a.id == "settings" then
    surface.setBG(colors.black); surface.setFG(colors.white)
    centerText(2, "Settings (fake)")
    centerText(4, "Theme: Mint-ish")
    centerText(6, "Input: "..(hasTouch() and "Touch + Keyboard" or "Keyboard"))
    centerText(H-2, "Press Backspace to return")
    while true do
      local e, k = os.pullEvent("key")
      if k == keys.backspace then break end
    end
  elseif a.id == "about" then
    surface.setBG(colors.black); surface.setFG(colors.white)
    centerText(2, "About Generic Linux")
    centerText(4, "Lua-based demo OS for CC:Tweaked")
    centerText(6, "Made for vibes")
    centerText(H-2, "Press Backspace to return")
    while true do
      local e, k = os.pullEvent("key")
      if k == keys.backspace then break end
    end
  end
end

-- -------------- Input mapping for touch -> app index --------------
local function appAtPos(mx, my)
  for i,pos in ipairs(appPositions) do
    local x1,y1 = pos.x, pos.y
    local x2,y2 = x1 + ICON_W - 1, y1 + ICON_H - 1
    if mx >= x1 and mx <= x2 and my >= y1 and my <= y2 then
      return i
    end
    -- also allow tapping the label area (underneath)
    if my == y2 + 1 and mx >= x1 and mx <= x1 + ICON_W then
      return i
    end
  end
  return nil
end

-- -------------- Main desktop loop (keyboard + touch) --------------
local running = true
local function desktopLoop()
  drawDesktop()
  while running do
    -- listen for either key events or monitor touches
    local event, a, b, c, d = os.pullEvent()
    if event == "key" then
      local key = a
      if key == keys.q then
        running = false; break
      elseif key == keys.w then selected = clamp(selected - 1, 1, #apps)
      elseif key == keys.s then selected = clamp(selected + 1, 1, #apps)
      elseif key == keys.a then selected = clamp(selected - 1, 1, #apps)
      elseif key == keys.d then selected = clamp(selected + 1, 1, #apps)
      elseif key == keys.enter then
        launchAppByIndex(selected)
        drawDesktop()
      end
      -- redraw apps highlight
      for i,_ in ipairs(apps) do drawAppIcon(i, i==selected) end
    elseif event == "monitor_touch" then
      -- monitor_touch(side, x, y)
      local side, mx, my = a, b, c
      local idx = appAtPos(mx, my)
      if idx then
        launchAppByIndex(idx)
        drawDesktop()
      end
    elseif event == "mouse_click" then
      -- mouse_click(button, x, y)
      local button, mx, my = a, b, c
      local idx = appAtPos(mx, my)
      if idx then
        launchAppByIndex(idx)
        drawDesktop()
      end
    elseif event == "term_resize" or event == "monitor_resize" then
      -- update sizes and relayout
      W,H = surface.getSize()
      appPositions = layoutApps()
      drawDesktop()
    end
  end
end

-- -------------- Shutdown screen --------------
local function shutdown()
  surface.clear()
  centerText(math.floor(H/2), "Shutting down... cya")
  os.sleep(1)
  surface.clear()
end

-- -------------- Start OS --------------
bootSequence()
drawDesktop()
desktopLoop()
shutdown()
  -- Top bar
  term.setBackgroundColor(colors.black)
  term.setCursorPos(1,1)
  term.clearLine()
  term.write(" Generic Linux ")

  -- Bottom bar
  term.setCursorPos(1,H)
  term.clearLine()
  term.write(" WASD Move | Enter Open | Q Quit ")
end

-- ---------- Apps ----------
local apps = {
  { name="Terminal", x=6,  y=6 },
  { name="Files",    x=18, y=6 },
  { name="Video",    x=30, y=6 },
  { name="Settings", x=42, y=6 },
  { name="About",    x=54, y=6 },
}

local selected = 1

-- ---------- Draw App ----------
local function drawApp(app, sel)
  term.setBackgroundColor(sel and colors.lightGray or colors.gray)
  term.setTextColor(sel and colors.black or colors.white)

  for dy=0,2 do
    term.setCursorPos(app.x, app.y+dy)
    term.write("   ")
  end

  term.setCursorPos(app.x-1, app.y+4)
  term.write(" "..app.name.." ")
end

local function drawApps()
  for i,a in ipairs(apps) do
    drawApp(a, i==selected)
  end
end

-- ---------- Video Player ----------
local function videoPlayer()
  local frames = {
    {
      "  ███      ",
      " █   █     ",
      "█     █    ",
      " █   █     ",
      "  ███      "
    },
    {
      "     ███   ",
      "    █   █  ",
      "   █     █ ",
      "    █   █  ",
      "     ███   "
    },
    {
      "      ███  ",
      "     █   █ ",
      "    █     █",
      "     █   █ ",
      "      ███  "
    }
  }

  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.green)
  term.clear()

  while true do
    for _,frame in ipairs(frames) do
      term.clear()
      for i,line in ipairs(frame) do
        term.setCursorPos(math.floor(W/2)-5, math.floor(H/2)-2+i)
        term.write(line)
      end
      term.setCursorPos(2, H)
      term.write("Playing video... Backspace to exit")
      local timer = os.startTimer(0.15)

      while true do
        local e, p = os.pullEvent()
        if e=="key" and p==keys.backspace then return end
        if e=="timer" and p==timer then break end
      end
    end
  end
end

-- ---------- App Launcher ----------
local function launch(app)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(2,2)

  if app.name=="Terminal" then
    print("Generic Linux Terminal")
    print("type 'exit' to return")
    while true do
      write("$ ")
      local c = read()
      if c=="exit" then break end
      print("command not found")
    end

  elseif app.name=="Files" then
    print("Root filesystem:")
    for _,f in ipairs(fs.list("/")) do
      print(" - "..f)
    end
    print("\nPress Backspace to return")
    while os.pullEvent("key") ~= "key" do end

  elseif app.name=="Video" then
    videoPlayer()

  elseif app.name=="Settings" then
    print("Settings")
    print("Theme: Green")
    print("Input: Keyboard")
    print("\nPress Backspace to return")
    while true do
      local _,k = os.pullEvent("key")
      if k==keys.backspace then break end
    end

  elseif app.name=="About" then
    print("Generic Linux")
    print("Lua-based Desktop OS")
    print("Kernel: lua")
    print("Init: vibes")
    print("\nPress Backspace to return")
    while true do
      local _,k = os.pullEvent("key")
      if k==keys.backspace then break end
    end
  end
end

-- ---------- Desktop Loop ----------
local function desktop()
  drawDesktop()
  drawApps()

  while true do
    local _,k = os.pullEvent("key")

    if k==keys.q then break end
    if k==keys.w or k==keys.a then selected = math.max(1, selected-1) end
    if k==keys.s or k==keys.d then selected = math.min(#apps, selected+1) end
    if k==keys.enter then
      launch(apps[selected])
      drawDesktop()
    end

    drawApps()
  end
end

-- ---------- Shutdown ----------
local function shutdown()
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(2,2)
  print("Shutting down...")
  os.sleep(1)
end

-- ---------- MAIN ----------
bootAnimation()
desktop()
shutdown()
