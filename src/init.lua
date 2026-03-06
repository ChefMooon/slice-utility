local slice_utility = require("slice_utility")

function init(plugin)
  -- "plugin.preferences" as a table with fields for the plugin
  -- (these fields are saved between sessions)
  if plugin.preferences.count == nil then
    plugin.preferences.count = 0
  end

  -- Custom menu group in the "Sprite" dropdown
  plugin:newMenuGroup{
    id="slice_utility",
    title="Slice Utility",
    group="sprite_properties"
  }

  -- Export slice command, opens popup
  plugin:newCommand{
    id="export_slices",
    title="Export Slices...",
    group="slice_utility",
    onclick=function()
      slice_utility.export_slices()
    end,
    onenabled=function() -- Enabled only if there's a sprite
      return app.sprite
    end
  }

  plugin:newCommand{
    id="update_slice_data",
    title="Update Slice Data...",
    group="slice_utility",
    onclick=function()
      slice_utility.update_slices()
    end,
    onenabled=function() -- Enabled only if there's a sprite and a selection
      return app.sprite and app.sprite.selection and not app.sprite.selection.isEmpty
    end
  }
end

--- This function is called when the plugin is removed/unloaded. Use in the future for cleanup if needed.
-- function exit(plugin)
--   print("Slice Utility successfully removed")
-- end