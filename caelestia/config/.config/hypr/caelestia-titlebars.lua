-- Traffic lights complement Caelestia's panels using the official hyprbars plugin.
if hl.plugin and hl.plugin.hyprbars then
    local command = os.getenv("HOME") .. "/.local/bin/caelestia-window "
    hl.config({plugin = {hyprbars = {
        enabled = true, bar_height = 30, bar_color = "rgba(191820ee)", bar_blur = true,
        ["col.text"] = "rgb(cac4d0)",
        bar_title_enabled = true, bar_text_size = 12, bar_text_weight = 400,
        bar_text_font = "Rubik", bar_text_align = "center",
        bar_buttons_alignment = "left", bar_part_of_window = true,
        bar_precedence_over_border = true, bar_padding = 12, bar_button_padding = 8,
        icon_on_hover = true, on_double_click = command .. "maximize",
    }}})
    hl.plugin.hyprbars.add_button({bg_color="rgb(ff6058)", fg_color="rgb(652723)", size=14, icon="×", action=command .. "close"})
    hl.plugin.hyprbars.add_button({bg_color="rgb(febc2e)", fg_color="rgb(705019)", size=14, icon="−", action=command .. "minimize"})
    hl.plugin.hyprbars.add_button({bg_color="rgb(28c840)", fg_color="rgb(145923)", size=14, icon="+", action=command .. "maximize"})
end
