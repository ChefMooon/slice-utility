local func = {}

function func.export_slices()
    local spr = app.activeSprite
    if not spr then return print('No active sprite') end

    local full_path = spr.filename
    local folder = app.fs.filePath(spr.filename) or ""

    -- Get sprite name
    local sprite_name = app.fs.fileTitle(spr.filename) or "slice_utility_output"

    -- Get current datetime
    local datetime = os.date("%Y-%m-%d_%H-%M-%S")

    -- Create subfolder name
    local subfolder = sprite_name
    local export_folder = app.fs.joinPath(folder, subfolder)

    local function makeDirectory(path)
        if not app.fs.isDirectory(path) then
            app.fs.makeDirectory(path)
        end
    end

    local function setFolder(data)
        folder = data
    end

    local data =
    Dialog("Slice Export"):entry{ id="user_value",
            label="Export Location:",
            text=folder,
            focus=true}
            :check{
                id="create_subfolder",
                label="Create Subfolder",
                selected=true
            }
            :check{
                id="create_subfolder_date",
                label="Create Subfolder with Date/Time",
                selected=true
            }
            :check{
                id="selection_only",
                label="Selection Only",
                selected=false
            }
            :button{ id="export", text="Export" }
            :button{ id="cancel", text="Cancel" }
            :show().data

    if data.export then
        setFolder(data.user_value)
    else
        return
    end

    local export_path = folder
    if data.create_subfolder then
        if data.create_subfolder_date then
            subfolder = sprite_name .. "-" .. datetime
        end
        export_path = app.fs.joinPath(folder, subfolder)
    end
    makeDirectory(export_path)

    -- Get selection bounds if needed
    local sel_bounds = nil
    if data.selection_only then
        local sel = spr.selection
        if sel and not sel.isEmpty then
            sel_bounds = sel.bounds
        else
            app.alert("No selection area found. Exporting all slices.")
            sel_bounds = nil
        end
    end

    local exported_count = 0
    for i, slice in ipairs(spr.slices) do
        local bounds = slice.bounds

        -- If selection_only is true, skip slices outside selection
        if sel_bounds then
            if not (
                bounds.x >= sel_bounds.x and
                bounds.y >= sel_bounds.y and
                bounds.x + bounds.width <= sel_bounds.x + sel_bounds.width and
                bounds.y + bounds.height <= sel_bounds.y + sel_bounds.height
            ) then
                goto continue
            end
        end

        local slice_export_path = export_path
        if slice.data ~= "" then
            slice_export_path = app.fs.joinPath(export_path, slice.data)
            makeDirectory(slice_export_path)
        end

        local filename = app.fs.joinPath(slice_export_path, slice.name .. ".png")

        -- Create a new sprite from the source sprite
        local slice_spr = Sprite(spr)

        -- Crop new sprite to slice selection
        slice_spr:crop(bounds.x, bounds.y, bounds.width, bounds.height)

        -- Save the new sprite
        slice_spr:saveAs(filename)

        -- Close the slice sprite
        slice_spr:close()

        exported_count = exported_count + 1

        ::continue::
    end

    app.alert("Exported " .. exported_count .. " slices to " .. export_path)
end

function func.update_slices()
    local spr = app.activeSprite
    if not spr then return app.alert('No active sprite') end

    -- Get selection bounds
    local sel = spr.selection
    if not sel or sel.isEmpty then
        return app.alert("No selection area found.")
    end
    local sel_bounds = sel.bounds

    -- Default color for comparison
    local default_color = Color{ r=255, g=255, b=255, a=255 }

    -- Popup dialog for user data input, color, and clear button
    local dlg = Dialog("Set/Clear User Data & Color")
    dlg:color{
        id = "slice_color",
        label = "Slice Color:",
        color = default_color
    }
    dlg:entry{
        id = "user_data",
        label = "User Data:",
        text = "",
        focus = true
    }
    dlg:button{
        id = "ok",
        text = "Set Data",
        focus = true
    }
    dlg:button{
        id = "clear",
        text = "Clear Data"
    }
    dlg:button{
        id = "cancel",
        text = "Cancel"
    }
    dlg:show()

    local data = dlg.data

    if data.clear then
        -- Clear user data and color from all slices in selection
        local count = 0
        for i, slice in ipairs(spr.slices) do
            local bounds = slice.bounds
            if bounds.x >= sel_bounds.x and
               bounds.y >= sel_bounds.y and
               bounds.x + bounds.width <= sel_bounds.x + sel_bounds.width and
               bounds.y + bounds.height <= sel_bounds.y + sel_bounds.height then
                slice.data = ""
                slice.color = default_color
                count = count + 1
            end
        end
        app.alert("Cleared user data and reset color for " .. count .. " slice(s) in selection.")
        return
    end

    if not data.ok then
        return -- Cancelled
    end

    local user_data = data.user_data
    local slice_color = data.slice_color

    -- Check if color has been changed from default
    local color_changed = not (
        slice_color.red == default_color.red and
        slice_color.green == default_color.green and
        slice_color.blue == default_color.blue and
        slice_color.alpha == default_color.alpha
    )

    if (not user_data or user_data == "") and not color_changed then
        app.alert("Please enter User Data or select a Slice Color.")
        return
    end

    -- Loop through slices and set user data and/or color for those within selection
    local count = 0
    local updated_user_data = false
    local updated_color = false
    for i, slice in ipairs(spr.slices) do
        local bounds = slice.bounds
        if bounds.x >= sel_bounds.x and
           bounds.y >= sel_bounds.y and
           bounds.x + bounds.width <= sel_bounds.x + sel_bounds.width and
           bounds.y + bounds.height <= sel_bounds.y + sel_bounds.height then
            if user_data and user_data ~= "" then
                slice.data = user_data
                updated_user_data = true
            end
            if color_changed then
                slice.color = slice_color
                updated_color = true
            end
            count = count + 1
        end
    end

    local msg = "Updated "
    if updated_user_data and updated_color then
        msg = msg .. "user data and color"
    elseif updated_user_data then
        msg = msg .. "user data"
    elseif updated_color then
        msg = msg .. "color"
    end
    msg = msg .. " for " .. count .. " slice(s) in selection."
    app.alert(msg)
end

return func