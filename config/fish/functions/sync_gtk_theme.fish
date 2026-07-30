function sync_gtk_theme
    # Get GTK theme colors and apply to fish
    set gtk_theme (gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
    set color_scheme (gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")
    
    # Extract colors using Python GTK introspection
    set colors (python3 -c "
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
import sys

try:
    Gtk.init(None)
    style_ctx = Gtk.StyleContext()
    widget_path = Gtk.WidgetPath()
    widget_path.append_type(Gtk.Window)
    style_ctx.set_path(widget_path)
    
    # Get main colors
    fg_color = style_ctx.get_color(Gtk.StateFlags.NORMAL)
    bg_color = style_ctx.get_property('background-color', Gtk.StateFlags.NORMAL)
    
    # Get selection colors
    widget_path_entry = Gtk.WidgetPath()
    widget_path_entry.append_type(Gtk.Entry)
    style_ctx.set_path(widget_path_entry)
    selection_bg = style_ctx.get_property('background-color', Gtk.StateFlags.SELECTED)
    
    print(f'{int(fg_color.red*255):02x}{int(fg_color.green*255):02x}{int(fg_color.blue*255):02x}')
    print(f'{int(bg_color.red*255):02x}{int(bg_color.green*255):02x}{int(bg_color.blue*255):02x}')
    print(f'{int(selection_bg.red*255):02x}{int(selection_bg.green*255):02x}{int(selection_bg.blue*255):02x}')
except Exception as e:
    # Fallback colors for Kanagawa-Dark theme
    print('ffffff')
    print('1f1f28')
    print('2d4f67')
" 2>/dev/null)
    
    set fg_color $colors[1]
    set bg_color $colors[2]
    set selection_color $colors[3]
    
    # Apply colors to fish
    set -U fish_color_normal $fg_color
    set -U fish_color_command $fg_color
    set -U fish_color_quote 98bb6c
    set -U fish_color_redirection $fg_color
    set -U fish_color_end $fg_color
    set -U fish_color_error ff5d62
    set -U fish_color_param $fg_color
    set -U fish_color_comment 727169
    set -U fish_color_match $selection_color
    set -U fish_color_selection --background=$selection_color
    set -U fish_color_search_match --background=$selection_color
    set -U fish_color_history_current --background=$selection_color
    set -U fish_color_operator $fg_color
    set -U fish_color_escape 7fb4ca
    set -U fish_color_cwd 7e9cd8
    set -U fish_color_cwd_root ff5d62
    set -U fish_color_valid_path --underline
    set -U fish_color_autosuggestion 727169
    set -U fish_color_user 98bb6c
    set -U fish_color_host 7fb4ca
    set -U fish_color_cancel --reverse
    
    # Pager colors
    set -U fish_pager_color_background
    set -U fish_pager_color_prefix $fg_color --bold
    set -U fish_pager_color_progress brwhite --background=cyan
    set -U fish_pager_color_completion $fg_color
    set -U fish_pager_color_description 727169
    set -U fish_pager_color_selected_background --background=$selection_color
    set -U fish_pager_color_selected_prefix $fg_color --bold
    set -U fish_pager_color_selected_completion $fg_color
    set -U fish_pager_color_selected_description $fg_color
end
