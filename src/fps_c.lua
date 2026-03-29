-- gtasa v2.00

local imgui = require("mimgui")
local ffi = require("ffi")
local jsoncfg = require("jsoncfg")

local gta = ffi.load("GTASA")

ffi.cdef([[
    extern float _ZN6CTimer8game_FPSE;
]])

local default_cfg = {
    pos   = "top_left",
    scale = 1,
}

local cfg = jsoncfg.load(default_cfg, "fps_c")

local scale_map = { [1]=0.4, [2]=0.6, [3]=0.8, [4]=1.0 }

local valid_pos = { top_left=true, top_right=true, bottom_left=true, bottom_right=true, center=true }

local pivot_map = {
    top_left     = imgui.ImVec2(0,   0),
    top_right    = imgui.ImVec2(1,   0),
    bottom_left  = imgui.ImVec2(0,   1),
    bottom_right = imgui.ImVec2(1,   1),
    center       = imgui.ImVec2(0.5, 0.5),
}

local anchor_cache = {}
local last_sx, last_sy, last_dpi

local function get_anchor()
    local dpi = MONET_DPI_SCALE or 1
    local sx, sy = getScreenResolution()
    if sx ~= last_sx or sy ~= last_sy or dpi ~= last_dpi then
        last_sx, last_sy, last_dpi = sx, sy, dpi
        anchor_cache = {
            top_left     = imgui.ImVec2(10 * dpi,      10 * dpi),
            top_right    = imgui.ImVec2(sx - 10 * dpi, 10 * dpi),
            bottom_left  = imgui.ImVec2(10 * dpi,      sy - 10 * dpi),
            bottom_right = imgui.ImVec2(sx - 10 * dpi, sy - 10 * dpi),
            center       = imgui.ImVec2(sx / 2,        sy / 2),
        }
    end
    return anchor_cache, dpi
end

imgui.OnFrame(
    function() return not isGamePaused() end,
    function()
        local anchor, dpi = get_anchor()
        local pos = valid_pos[cfg.pos] and cfg.pos or "top_left"

        imgui.SetNextWindowPos(anchor[pos], imgui.Cond.Always, pivot_map[pos])
        imgui.SetNextWindowBgAlpha(0.4)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(6 * dpi, 4 * dpi))
        imgui.Begin("##fps", nil, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoInputs + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoMove)
        imgui.SetWindowFontScale((scale_map[cfg.scale] or 0.4) * dpi)
        imgui.Text(string.format("FPS: %.0f", gta._ZN6CTimer8game_FPSE))
        imgui.End()
        imgui.PopStyleVar(2)
    end
)

function main()
    sampRegisterChatCommand("fps", function(args)
        local p, s = args:match("^(%S+)%s*(%S*)$")
        local changed = false

        if p and valid_pos[p] then
            cfg.pos = p
            changed = true
        end
        if s and tonumber(s) then
            cfg.scale = math.max(1, math.min(4, tonumber(s)))
            changed = true
        end

        if not changed then
            sampAddChatMessage("fps: top_left | top_right | bottom_left | bottom_right | center  [scale 1-4]", -1)
        else
            jsoncfg.save(cfg, "fps_c")
        end
    end)
    wait(-1)
end
