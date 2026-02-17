local util = require("util")

local default_color = app.preferences.slices.default_color -- Stores default on startup

------------------Dialogs Start------------------

local export_dialog = Dialog("Slice Export")
export_dialog
    :entry{ id="user_value",
        label="Export Location:"
    }
    :check{
        id="create_subfolder",
        label="Create Subfolder",
        selected=true
    }
    :check{
        id="create_subfolder_date",
        label="Create Subfolder with Date/Time",
        selected=false
    }
    :check{
        id="selection_only",
        label="Selection Only",
        selected=false
    }
    :combobox{
        id="resize",
        label="Resize:",
        option="100%",
        options={ "100%", "200%", "300%", "400%", "500%", "600%", "700%", "800%", "900%", "1000%" }
    }
    :separator{}
    :button{ id="export", text="Export", focus=true, onclick=function()
        Export()
    end }
    :button{ id="cancel", text="Cancel", onclick = function()
        export_dialog:close()
    end }

    -- Popup dialog for user data input, color, and clear button
local update_slices_dialog = Dialog("Set/Clear User Data & Color")
update_slices_dialog
    :color{
        id = "slice_color",
        label = "Slice Color:",
        color = default_color
    }
    :entry{
        id = "user_data",
        label = "User Data:",
        text = "",
        focus = true
    }
    :button{
        id = "ok",
        text = "Set Data",
        onclick = function()
            SetData()
        end
    }
    :button{
        id = "clear",
        text = "Clear Data",
        onclick = function()
            ClearData()
        end
    }
    :button{
        id = "cancel",
        text = "Cancel",
        onclick = function()
            update_slices_dialog:close()
        end
    }

------------------Dialogs End------------------

------------------Slice Utility Main Functions Start------------------

-- This function is called when the "Export" button is clicked in the export_dialog
-- It will loop through all slices in the current sprite and export them as individual PNG files
function Export()
    local data = export_dialog.data
    local spr = app.sprite
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

    folder = data.user_value

    -- Determine final export path
    local export_path = folder
    if data.create_subfolder then
        if data.create_subfolder_date then
            subfolder = sprite_name .. "-" .. datetime
        end
        export_path = app.fs.joinPath(folder, subfolder)
    end

    -- Get selection bounds if needed
    local sel_bounds = nil
    if data.selection_only then
        local sel = spr.selection
        if sel and not sel.isEmpty then
            sel_bounds = sel.bounds
        else
            local retry_dlg = Dialog{ title="No Selection", notitlebar=true, resizeable=false, parent=export_dialog }
            retry_dlg
                :label{label="No selection area was found."}
                :label{label="To use 'Selection Only', you must have an active selection."}
                :separator{}
                :label{label="Would you like to retry or cancel the export?"}
                :button{
                    id="retry",
                    text="Retry",
                    onclick=function()
                        retry_dlg:close()
                    end
                }
                :button{
                    id="cancel",
                    text="Cancel",
                    onclick=function()
                        retry_dlg:close()
                        export_dialog:close()
                    end
                }
                :show()
            return
        end
    end

    -- Check if export folder exists and prompt user TODO: extract to separate function
    if app.fs.isDirectory(export_path) then
        local dlg = Dialog("Folder Exists")
        dlg:label{label="The export folder already exists."}
        dlg:label{label="Do you want to overwrite its contents?"}
        dlg:separator{}
        dlg:button{id="yes", text="Yes"}
        dlg:button{id="no", text="No"}
        dlg:show()
        local result = dlg.data
        if not result.yes then
            app.alert("Export cancelled.")
            return
        end
    end

    -- Create export directory if it doesn't exist
    util.make_directory(export_path)

    -- Determine resize factor
    local resize_factor = tonumber(data.resize:sub(1, -2)) / 100

    -- Loop through slices and export
    local exported_count = 0
    local slice_table = {}
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
        local slice_subfolder = slice.data
        if slice_subfolder ~= "" then
            slice_export_path = app.fs.joinPath(export_path, slice_subfolder)
            util.make_directory(slice_export_path)
        end

        local slice_name = slice.name
        local slice_key = slice_name
        if slice_subfolder ~= "" then
            slice_key = slice_subfolder .. "/" .. slice.name
        end

        local export_data = util.get_export_data(slice_key)

        -- Ensure the value at this key is a list (array)
        if not slice_table[export_data.key] then
            slice_table[export_data.key] = {}
        end
        
        if util.export_is_unique(slice_table, export_data.key, export_data.path) then
            table.insert(slice_table[export_data.key], { path = export_data.path, increment = export_data.increment })
        else
            local lowest_increment = util.find_lowest_increment(slice_table, export_data.key)
            if lowest_increment > 0 then
                slice_name = slice_name .. "_" .. tostring(lowest_increment)
            end
            table.insert(slice_table[export_data.key], { path = export_data.path, increment = lowest_increment })
        end

        local file_path = app.fs.joinPath(slice_export_path, slice_name)

        local filename = file_path .. ".png"

        -- Create a new sprite from the source sprite
        local slice_spr = Sprite(spr)

        -- Crop new sprite to slice selection
        slice_spr:crop(bounds.x, bounds.y, bounds.width, bounds.height)

        -- Resize if needed
        if resize_factor ~= 1 then
            local new_width = math.max(1, math.floor(bounds.width * resize_factor + 0.5))
            local new_height = math.max(1, math.floor(bounds.height * resize_factor + 0.5))
            slice_spr:resize(new_width, new_height)
        end

        -- Save the new sprite
        slice_spr:saveAs(filename)

        -- Close the slice sprite
        slice_spr:close()

        exported_count = exported_count + 1

        ::continue::
    end

    -- Refocus on the original sprite
    app.sprite = spr

    -- Close the export dialog
    export_dialog:close()

    -- Show alert with export results
    app.alert("Exported " .. exported_count .. " slices to " .. export_path)
end

-- This function is called when the "Set Data" button is clicked in the update_slices_dialog
-- It will set the user data and/or color for all slices within the current selection
function SetData()
    local sprite = app.sprite
    local sel_bounds = sprite.selection.bounds

    local data = update_slices_dialog.data

    local user_data = data.user_data
    local slice_color = data.slice_color

    -- Check if color has been changed from default
    local color_changed = not util.equal_colors(slice_color, default_color)

    if (not user_data or user_data == "") and not color_changed then
        app.alert("Please enter User Data or select a Slice Color.")
        return
    end

    -- Loop through slices and set user data and/or color for those within selection
    local count = 0
    local updated_user_data = false
    local updated_color = false
    for i, slice in ipairs(sprite.slices) do
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
    update_slices_dialog:close() -- Close the dialog to apply changes
end

-- This function is called when the "Clear Data" button is clicked in the update_slices_dialog
-- It will reset the user data and color for all slices within the current selection
function ClearData()
    local sprite = app.sprite
    local sel_bounds = sprite.selection.bounds

    local count = 0
    for i, slice in ipairs(sprite.slices) do
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
    update_slices_dialog:close() -- Close the dialog to apply changes
    app.alert("Cleared user data and reset color for " .. count .. " slice(s) in selection.")
end

------------------Slice Utility Main Functions End------------------

------------------Slice Utility Command Functions------------------

local func = {}

function func.export_slices()
    local sprite = app.sprite
    if not sprite then return app.alert('No active sprite') end
    if #sprite.slices == 0 then return app.alert('No slices found in active sprite') end
    export_dialog:modify {
        id = "user_value",
        text = app.fs.filePath(sprite.filename) or ""
    }

    -- Check if there is a selection and enable/disable "Selection Only" option accordingly
    if sprite.selection and not sprite.selection.isEmpty then
        export_dialog:modify {
            id = "selection_only",
            label="Selection Only(*)",
            selected = true
        }
    else
        export_dialog:modify {
            id = "selection_only",
            label="Selection Only",
            selected = false
        }
    end
    
    export_dialog:show()
end

function func.update_slices()
    local sprite = app.sprite
    if not sprite then return app.alert('No active sprite') end

    -- Check if there is a selection and alert if not
    local sel = sprite.selection
    if not sel or sel.isEmpty then
        return app.alert("No selection area found.")
    end

    -- Checks if default color has changed since plugin loading/application start and updates dialog color if so
    local default_color_check = app.preferences.slices.default_color
    if not util.equal_colors(default_color_check, default_color) then
        default_color = default_color_check
        update_slices_dialog:modify {
            id = "slice_color",
            color = default_color
        }
    end

    update_slices_dialog:show()
end

return func