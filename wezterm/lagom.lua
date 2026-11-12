-- Lagom for WezTerm: applies what the `lagom` command wrote to lagom-state.json.
-- Loaded from .wezterm.lua (see the hook `lagom install` adds). Returns true when Lagom
-- owns the background, so the host config can switch its own wallpaper logic off.
local M = {}

function M.apply(config, wezterm)
  local path = wezterm.home_dir .. '/.config/wezterm/lagom-state.json'
  wezterm.add_to_config_reload_watch_list(path)
  local f = io.open(path, 'r')
  if not f then return false end
  local ok, state = pcall(wezterm.json_parse, f:read('*a'))
  f:close()
  if not ok or type(state) ~= 'table' or not state.scheme then return false end

  config.color_schemes = config.color_schemes or {}
  config.color_schemes['Lagom'] = state.scheme
  config.color_scheme = 'Lagom'
  config.colors = config.colors or {}
  config.colors.tab_bar = state.tab_bar
  config.window_frame = config.window_frame or {}
  for k, v in pairs(state.frame or {}) do config.window_frame[k] = v end

  local bg = state.background
  if bg == 'keep' then return false end -- colours only: the host config keeps its picture

  config.window_background_opacity = 1.0
  config.win32_system_backdrop = 'Disable'
  if type(bg) == 'table' then
    -- Herdr paints its panes with an explicit background colour, which WezTerm draws solid.
    -- Letting such cells through shows the picture inside the panes too.
    config.text_background_opacity = bg.cell_opacity or 1.0
    config.background = {
      { source = { Color = bg.color }, width = '100%', height = '100%' },
      { source = { File = bg.image }, width = 'Cover', height = 'Cover',
        horizontal_align = 'Center', vertical_align = 'Middle', attachment = 'Fixed' },
      -- the dimming that keeps every text colour at WCAG AA over the picture
      { source = { Color = bg.color }, width = '100%', height = '100%', opacity = bg.dim },
    }
  else
    config.background = nil
  end

  -- A per-window background override from the host config would win over the above: clear it.
  wezterm.on('update-right-status', function(window)
    local o = window:get_config_overrides()
    if o and o.background then
      o.background = nil
      window:set_config_overrides(o)
    end
  end)
  return true
end

return M
