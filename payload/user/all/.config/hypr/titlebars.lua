-- Official hyprbars, guarded so an unloaded plugin never breaks the config.
if hl.plugin and hl.plugin.hyprbars then
    hl.config({plugin = {hyprbars = {
        enabled = true, bar_height = 32, bar_color = "rgba(181818e8)", bar_blur = true,
        ["col.text"] = "rgb(999999)", bar_title_enabled = true,
        bar_text_size = 12, bar_text_weight = 400, bar_text_font = "Inter Variable",
        bar_text_align = "center", bar_buttons_alignment = "left",
        bar_part_of_window = true, bar_precedence_over_border = true,
        bar_padding = 12, bar_button_padding = 8, icon_on_hover = true,
        inactive_button_color = "rgb(666666)",
        on_double_click = "@HOME@/.local/bin/desktop-window maximize",
    }}})
    -- Barevná tlačítka zachovávají rozpoznatelné akce i v motivu Graphite.
    hl.plugin.hyprbars.add_button({bg_color="rgb(ff6058)", fg_color="rgb(652723)", size=14, icon="×", action="@HOME@/.local/bin/desktop-window close"})
    hl.plugin.hyprbars.add_button({bg_color="rgb(febc2e)", fg_color="rgb(705019)", size=14, icon="−", action="@HOME@/.local/bin/desktop-window minimize"})
    hl.plugin.hyprbars.add_button({bg_color="rgb(28c840)", fg_color="rgb(145923)", size=14, icon="+", action="@HOME@/.local/bin/desktop-window maximize"})
end
