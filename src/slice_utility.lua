local util = require("util")

local default_color = app.preferences.slices.default_color -- Stores default on startup

------------------Dialogs Start------------------

local export_dialog = Dialog("Slice Export")
export_dialog
    :file{
        id="export_location",
        label="Export Location:",
        title="Select Export Folder",
        open=true,
        save=false,
        entry=true
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
    :button{ id="export", text="   Export   ", focus=true, onclick=function()
        Export()
    end }
    :button{ id="cancel", text="   Cancel   ", onclick = function()
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

-- Helper function to show export report with optional details
-- Displays summary stats and provides button to show detailed report
function show_export_report(export_path, total_sprite_slices, export_details, export_duration_ms)
    local local_export_details = export_details  -- Capture for closure
    local local_export_duration = export_duration_ms
    local local_total_slices = total_sprite_slices
    
    -- Calculate summary stats (lazy evaluation - only when needed)
    local summary_stats = nil
    
    -- Create main export report dialog
    local export_report_dialog = Dialog("Export Report")
    export_report_dialog
        :label{ label="Exported to: " .. export_path }
        :separator{}
    
    -- Add summary counters dynamically
    local exported_count = 0
    local unique_count = 0
    local duplicates_count = 0
    local skipped_count = 0
    
    for _, entry in ipairs(export_details) do
        if entry.action == "exported" then
            exported_count = exported_count + 1
            unique_count = unique_count + 1
        elseif entry.action == "duplicate_renamed" then
            exported_count = exported_count + 1
            duplicates_count = duplicates_count + 1
        elseif entry.action == "skipped_export_false" or entry.action == "skipped_exists" then
            skipped_count = skipped_count + 1
        end
    end
    
    export_report_dialog
        :label{ label="Total exported: " .. exported_count }
    
    if unique_count > 0 then
        export_report_dialog:label{ label="  Unique: " .. unique_count }
    end
    if duplicates_count > 0 then
        export_report_dialog:label{ label="  Duplicates (renamed): " .. duplicates_count }
    end
    if skipped_count > 0 then
        export_report_dialog:label{ label="Total skipped: " .. skipped_count }
    end
    
    export_report_dialog:separator{}
    
    -- Add buttons
    export_report_dialog:button{
        id = "show_details",
        text = "Show Details",
        onclick = function()
            -- Lazy-load summary stats only when details are requested
            if not summary_stats then
                summary_stats = util.calculate_export_summary(local_export_details, local_total_slices, local_export_duration)
            end
            
            -- Print full report to console
            local formatter = util.ReportFormatter:new()
            local full_report = formatter:build_full_report(summary_stats, local_export_details)
            print(full_report)
        end
    }
    
    export_report_dialog:button{
        id = "ok",
        text = "     OK     ",
        onclick = function()
            export_report_dialog:close()
        end
    }
    
    export_report_dialog:show()
end

-- This function is called when the "Export" button is clicked in the export_dialog
-- It will loop through all slices in the current sprite and export them as individual PNG files
function Export()
    local export_start_time = os.time() * 1000 + (os.clock() % 1) * 1000  -- Approximate milliseconds
    
    local data = export_dialog.data
    local spr = app.sprite
    if not spr then return print('No active sprite') end

    -- Get sprite name
    local sprite_name = app.fs.fileTitle(spr.filename) or "slice_utility_output"

    -- Get current datetime
    local datetime = os.date("%Y-%m-%d_%H-%M-%S")

    -- Get export base folder from user input
    local folder = data.export_location

    -- Determine subfolder name (if needed)
    local subfolder = sprite_name
    if data.create_subfolder and data.create_subfolder_date then
        subfolder = sprite_name .. "-" .. datetime
    end

    -- Determine final export path
    local export_path = folder
    if data.create_subfolder then
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
    local folder_action = "Overwrite"  -- Default action
    if app.fs.isDirectory(export_path) then
        local dlg = Dialog("Folder Exists")
        dlg:label{label="The export folder already exists."}
        dlg:separator{}
        dlg:radio{
            id="overwrite",
            text="Overwrite (merge files, keep existing)",
            selected=true,
            onclick=function()
                folder_action = "Overwrite"
            end
        }
        dlg:radio{
            id="new_only",
            text="New Only (skip existing files)",
            selected=false,
            onclick=function()
                folder_action = "New Only"
            end
        }
        dlg:radio{
            id="delete_replace",
            text="Delete & Replace (clear folder first)",
            selected=false,
            onclick=function()
                folder_action = "Delete & Replace"
            end
        }
        dlg:separator{}
        dlg:button{id="ok", text="   OK   "}
        dlg:button{id="cancel", text="   Cancel   "}
        dlg:show()
        local result = dlg.data
        if result.cancel then
            return
        end
        
        -- If user selected "Delete & Replace", delete directory contents first
        if folder_action == "Delete & Replace" then
            local ok, err = util.delete_directory_contents(export_path)
            if not ok then
                app.alert("Failed to delete folder contents: " .. (err or "Unknown error"))
                return
            end
        end
    end

    -- If "New Only" mode, get list of existing files to skip during export
    local existing_files = {}
    if folder_action == "New Only" then
        existing_files = util.get_existing_files(export_path)
    end

    -- Create export directory if it doesn't exist
    local ok, err = util.make_directory(export_path)
    if not ok then
        app.alert("Failed to create export directory: " .. (err or "Unknown error"))
        return
    end

    -- Determine resize factor
    local resize_factor = tonumber(data.resize:sub(1, -2)) / 100

    -- Initialize export details collection
    local export_details = {}
    local total_sprite_slices = #spr.slices

    -- Loop through slices and export
    local exported_count = 0
    local exported_duplicates = 0
    local exported_unique = 0
    local skipped_count = 0
    local skipped_by_existing_count = 0
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
        local slice_data = util.parse_slice_data(slice.data)
        local slice_subfolder = ""
        local should_export = true
        if type(slice_data) == "table" then
            slice_subfolder = slice_data.folder or ""
            should_export = slice_data.export ~= false
        elseif type(slice_data) == "string" then
            slice_subfolder = slice_data
        end

        if not should_export then
            skipped_count = skipped_count + 1
            table.insert(export_details, {
                slice_name = slice.name,
                action = "skipped_export_false",
                file_path = "",
                file_size = 0
            })
            goto continue
        end

        if slice_subfolder ~= "" then
            slice_export_path = app.fs.joinPath(export_path, slice_subfolder)
            util.make_directory(slice_export_path)
        end

        local slice_name = slice.name
        local slice_key = slice_name
        if slice_subfolder ~= "" then
            slice_key = slice_subfolder .. "/" .. slice.name
        end

        -- If "New Only" mode, check if file already exists using slice_key
        if folder_action == "New Only" then
            if existing_files[slice_key .. ".png"] then
                skipped_by_existing_count = skipped_by_existing_count + 1
                table.insert(export_details, {
                    slice_name = slice.name,
                    action = "skipped_exists",
                    file_path = app.fs.joinPath(slice_subfolder ~= "" and slice_subfolder or ".", slice_name .. ".png"),
                    file_size = 0
                })
                goto continue
            end
        end

        local export_data = util.get_export_data(slice_key)
        local original_name = nil

        -- Ensure the value at this key is a list (array)
        if not slice_table[export_data.key] then
            slice_table[export_data.key] = {}
        end
        
        if util.export_is_unique(slice_table, export_data.key, export_data.path) then
            table.insert(slice_table[export_data.key], { path = export_data.path, increment = export_data.increment })
            exported_unique = exported_unique + 1
        else
            local lowest_increment = util.find_lowest_increment(slice_table, export_data.key)
            if lowest_increment > 0 then
                slice_name = slice_name .. "_" .. tostring(lowest_increment)
            end
            table.insert(slice_table[export_data.key], { path = export_data.path, increment = lowest_increment })
            exported_duplicates = exported_duplicates + 1
            original_name = slice.name  -- Track original name for duplicate rename
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

        -- Collect export details
        local action = original_name and "duplicate_renamed" or "exported"
        local relative_path = slice_subfolder ~= "" and slice_subfolder .. "/" .. slice_name or slice_name
        local file_size = util.get_file_size(filename)
        
        table.insert(export_details, {
            slice_name = slice.name,
            action = action,
            file_path = relative_path .. ".png",
            file_size = file_size,
            original_name = original_name
        })

        ::continue::
    end

    -- Refocus on the original sprite
    app.sprite = spr

    -- Close the export dialog
    export_dialog:close()

    -- Calculate export duration
    local export_end_time = os.time() * 1000 + (os.clock() % 1) * 1000
    local export_duration_ms = math.max(0, export_end_time - export_start_time)

    -- Show export report with details support
    show_export_report(export_path, total_sprite_slices, export_details, export_duration_ms)
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
    local sprite_path = app.fs.filePath(sprite.filename) or ""
    export_dialog:modify {
        id = "export_location",
        basepath = sprite_path,
        filename = sprite_path
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
    
    local dialogWidth, dialogHeight = 350, 135
    local xPos = app.window.width / 2 - dialogWidth / 2
    local yPos = app.window.height / 2 - dialogHeight / 2
    export_dialog:show{
        bounds=Rectangle(xPos, yPos, dialogWidth, dialogHeight)
    }
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