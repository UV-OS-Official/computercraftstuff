-- ==========================================
-- Generic Linux Base - Full Featured
-- CC:Tweaked Single File OS
-- ==========================================

-- ---------- Setup ----------
term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)
term.clear()

local W, H = term.getSize()

-- ---------- Boot Animation ----------
local function bootAnimation()
  term.clear()
  term.setCursorPos(1,1)

  for i = 1, W do
    term.setCursorPos(i, math.floor(H/2))
    term.setBackgroundColor(colors.green)
    term.write(" ")
    os.sleep(0.02)
  end

  term.setBackgroundColor(colors.black)
  term.setCursorPos(math.floor(W/2)-6, math.floor(H/2)+2)
  term.write("Generic Linux")
  term.setCursorPos(math.floor(W/2)-8, math.floor(H/2)+3)
  term.write("Loading system...")
  os.sleep(1)
end

-- ---------- Desktop ----------
local function drawDesktop()
  term.setBackgroundColor(colors.green)
  term.clear()

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
