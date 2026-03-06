
local util = {}

--- Creates a directory at the specified path if it does not already exist.
-- Checks for empty/nil path, handles errors, and returns success/failure.
-- Uses app.fs.isDirectory to check existence and app.fs.makeDirectory to create.
-- Returns true if directory exists or is created successfully, false and error message otherwise.
--
-- @param path The directory path to create (string).
-- @return success (boolean): true if directory exists or was created, false otherwise.
-- @return err (string|nil): error message if failed, nil if successful.
function util.make_directory(path)
    -- Check for empty or nil path
    if not path or path == "" then
        return false, "Path is empty or nil"
    end
    local ok, err = pcall(function()
        if app.fs.isDirectory(path) then
            return true
        else
            app.fs.makeDirectory(path)
            return app.fs.isDirectory(path)
        end
    end)
    if ok then
        -- If directory exists after attempt, success
        if app.fs.isDirectory(path) then
            return true
        else
            return false, "Directory creation failed"
        end
    else
        return false, err or "Unknown error"
    end
end

--- Checks if a path ends with an underscore followed by a number and extracts the increment.
-- Matches the pattern "_<number>" at the end of the string.
--
-- @param path The string to check (e.g., "block/yellow_1").
-- @return true, increment (number) if the pattern is found; false, 0 otherwise.
function util.check_increment(path)
  -- Match pattern: underscore followed by one or more digits at the end of the string
  local increment = path:match("_(%d+)$")
  if increment then
    return true, tonumber(increment)
  else
    return false, 0
  end
end

--- Parses an export path and returns its key, original path, and increment.
-- For example, given "block/yellow_1", returns:
--   { key = "block/yellow", path = "block/yellow_1", increment = 1 }
-- If no increment is found, increment will be 0 and key will be the path.
--
-- @param path The export path string to parse.
-- @return Table with fields: key (string), path (string), increment (number).
function util.get_export_data(path)
    local has_inc, inc = util.check_increment(path)
    if has_inc then
        local key = path:gsub("_(%d+)$", "")
        return { key = key, path = path, increment = inc }
    else
        return { key = path, path = path, increment = 0 }
    end
end

--- Checks if a given path is unique within the entries for a key.
-- Iterates over t[key] (a list of tables with a 'path' field) and returns false
-- if any entry has a 'path' equal to the provided path. Returns true if no such entry exists,
-- or if t[key] does not exist.
--
-- @param t Table of entries, where t[key] is a list of tables with 'path'.
-- @param key The key to look up in t.
-- @param path The path to check for uniqueness.
-- @return true if the path is unique (not present), false otherwise.
function util.export_is_unique(t, key, path)
    if not t or not t[key] then
        return true
    end
    for _, entry in ipairs(t[key]) do
        if entry.path == path then
            return false
        end
    end
    return true
end

--- Finds the lowest available increment in a sequence.
-- Given a table t[key] containing entries with an 'increment' field,
-- this function returns the lowest non-negative integer not present in the sequence.
-- If the sequence does not start at 0, it returns 0.
--
-- Example:
--   If increments are 0, 1, 3, returns 2 (gap at 2).
--   If increments are 4, 5, 7, returns 0 (0 is lowest).
--   If increments are 0, 1, 2, returns 3 (no gap).
--
-- @param t Table of entries, where t[key] is a list of tables with 'increment'.
-- @param key The key to look up in t.
-- @return The lowest available increment (the smallest non-negative integer not present).
function util.find_lowest_increment(t, key)
    if not t[key] or #t[key] == 0 then return 0 end
    local set, max = {}, 0
    for _, entry in ipairs(t[key]) do
        set[entry.increment] = true
        if entry.increment > max then max = entry.increment end
    end
    for i = 0, max do
        if not set[i] then
            return i
        end
    end
    return max + 1
end

--- Compares two color tables for equality.
-- Returns true if all RGBA components (red, green, blue, alpha) are equal.
--
-- @param color1 First color table with fields: red, green, blue, alpha.
-- @param color2 Second color table with fields: red, green, blue, alpha.
-- @return true if all components are equal, false otherwise.
function util.equal_colors(color1, color2)
    return color1.red == color2.red and
           color1.green == color2.green and
           color1.blue == color2.blue and
           color1.alpha == color2.alpha
end

--- Parses slice user data or export info.
-- Accepts a string (legacy folder path or table-like string).
-- If the string starts with '{' and ends with '}', attempts to parse it as a Lua table.
-- If parsing succeeds, returns a table with fields:
--   folder (string, default "")
--   export (boolean, default true)
-- If parsing fails or the string is not table-like, returns the string as a folder path.
-- Returns nil if data is missing.
--
-- @param data The slice user data or export info to parse (string).
-- @return Folder path string (legacy) or table { folder, export } (enhanced), or nil if invalid.
function util.parse_slice_data(data)
    if not data then
        return nil
    end
    -- Always treat as string
    local trimmed = data:match("^%s*(.-)%s*$")
    if trimmed:sub(1,1) == "{" and trimmed:sub(-1,-1) == "}" then
        local chunk, err = load("return " .. trimmed)
        if chunk then
            local ok, tbl = pcall(chunk)
            if ok and type(tbl) == "table" then
                local folder = tbl.folder or ""
                local export = tbl.export
                if export == nil then export = true end
                return {
                    folder = folder,
                    export = export
                }
            end
        end
        -- If parsing fails, treat as string
    end
    return data
end

--- Recursively deletes all files and subdirectories inside a directory.
-- Does not delete the directory itself, only its contents.
-- Uses app.fs functions to iterate and delete directory entries.
--
-- @param path The directory path whose contents should be deleted (string).
-- @return success (boolean): true if deletion succeeded, false otherwise.
-- @return err (string|nil): error message if failed, nil if successful.
function util.delete_directory_contents(path)
    if not path or path == "" then
        return false, "Path is empty or nil"
    end
    
    local ok, err = pcall(function()
        -- List all files and directories in the path
        local entries = app.fs.listFiles(path)
        if not entries then
            return true -- Directory is empty or already doesn't exist
        end
        
        -- Delete each entry
        for _, entry in ipairs(entries) do
            local full_path = app.fs.joinPath(path, entry)
            
            if app.fs.isDirectory(full_path) then
                -- Recursively delete subdirectory
                util.delete_directory_contents(full_path)
                -- After deleting contents, remove the empty directory
                local _, dir_err = os.remove(full_path)
                if dir_err then
                    error("Failed to delete directory " .. full_path .. ": " .. tostring(dir_err))
                end
            else
                -- Delete file
                local _, file_err = os.remove(full_path)
                if file_err then
                    error("Failed to delete file " .. full_path .. ": " .. tostring(file_err))
                end
            end
        end
        return true
    end)
    
    if ok then
        return true
    else
        return false, err or "Unknown error during deletion"
    end
end

--- Recursively lists all files in a directory and returns them with paths relative to the base.
-- Files at the base level are returned as "filename.png".
-- Files in subfolders are returned as "subfolder/filename.png".
-- Returns a table where keys are relative file paths (string) and values are true for quick lookup.
--
-- @param base_path The base directory path to scan (string).
-- @return A table with relative file paths as keys, all with value true.
function util.get_existing_files(base_path)
    local files = {}
    
    -- Helper function to recursively walk directory
    local function walk(current_path, relative_prefix)
        local entries = app.fs.listFiles(current_path) or {}
        for _, entry in ipairs(entries) do
            local full_path = app.fs.joinPath(current_path, entry)
            local relative_path = relative_prefix .. entry
            
            if app.fs.isDirectory(full_path) then
                -- Recurse into subdirectory (use forward slash as separator for consistency)
                walk(full_path, relative_path .. "/")
            else
                -- Add file to results table
                files[relative_path] = true
            end
        end
    end
    
    walk(base_path, "")
    return files
end

--- Returns the file size in bytes. Returns 0 if file does not exist or cannot be accessed.
--
-- @param path The file path (string).
-- @return The file size in bytes (number), or 0 if file cannot be accessed.
function util.get_file_size(path)
    if not path or path == "" then
        return 0
    end
    local ok, err = pcall(function()
        local file = io.open(path, "rb")
        if file then
            local size = file:seek("end")
            file:close()
            return size or 0
        end
        return 0
    end)
    if ok then
        return err or 0
    else
        return 0
    end
end

--- Calculates summary statistics from export details.
-- Aggregates counts and file sizes in a single pass.
--
-- @param export_details A list of export detail entries, each with: slice_name, action, file_path, file_size, original_name (optional).
-- @param total_sprite_slices The total number of slices in the sprite (number).
-- @return A table with fields: total_slices, exported_count, unique_count, duplicates_count, skipped_count, total_file_size, avg_file_size, export_duration_ms.
function util.calculate_export_summary(export_details, total_sprite_slices, export_duration_ms)
    local summary = {
        total_slices = total_sprite_slices or 0,
        exported_count = 0,
        unique_count = 0,
        duplicates_count = 0,
        skipped_count = 0,
        total_file_size = 0,
        avg_file_size = 0,
        export_duration_ms = export_duration_ms or 0
    }
    
    if not export_details or #export_details == 0 then
        return summary
    end
    
    -- Single pass through export_details
    for _, entry in ipairs(export_details) do
        if entry.action == "exported" then
            summary.exported_count = summary.exported_count + 1
            summary.unique_count = summary.unique_count + 1
        elseif entry.action == "duplicate_renamed" then
            summary.exported_count = summary.exported_count + 1
            summary.duplicates_count = summary.duplicates_count + 1
        elseif entry.action == "skipped_export_false" then
            summary.skipped_count = summary.skipped_count + 1
        elseif entry.action == "skipped_exists" then
            summary.skipped_count = summary.skipped_count + 1
        end
        
        -- Accumulate file sizes
        local file_size = entry.file_size or 0
        summary.total_file_size = summary.total_file_size + file_size
    end
    
    -- Calculate average file size
    if summary.exported_count > 0 then
        summary.avg_file_size = math.floor(summary.total_file_size / summary.exported_count)
    end
    
    return summary
end

--- ReportFormatter class for formatting export reports.
-- Provides methods to format summary statistics and detail entries for display.
local ReportFormatter = {}
ReportFormatter.__index = ReportFormatter

function ReportFormatter:new()
    return setmetatable({}, ReportFormatter)
end

--- Formats a summary statistics block as a multi-line string.
--
-- @param summary A table with fields: total_slices, exported_count, unique_count, duplicates_count, skipped_count, total_file_size, avg_file_size, export_duration_ms.
-- @return A formatted multi-line string suitable for display.
function ReportFormatter:format_summary(summary)
    local lines = {}
    table.insert(lines, "=== EXPORT SUMMARY ===")
    table.insert(lines, "")
    table.insert(lines, "Total slices on sprite: " .. summary.total_slices)
    table.insert(lines, "Total exported: " .. summary.exported_count)
    table.insert(lines, "  - Unique: " .. summary.unique_count)
    table.insert(lines, "  - Duplicates (renamed): " .. summary.duplicates_count)
    table.insert(lines, "Total skipped: " .. summary.skipped_count)
    
    if summary.exported_count > 0 then
        table.insert(lines, "Total file size: " .. util.format_bytes(summary.total_file_size))
        table.insert(lines, "Average file size: " .. util.format_bytes(summary.avg_file_size))
    end
    
    if summary.export_duration_ms > 0 then
        local seconds = summary.export_duration_ms / 1000
        table.insert(lines, "Export duration: " .. string.format("%.2f", seconds) .. "s")
    end
    
    return table.concat(lines, "\n")
end

--- Formats a single detail entry as a single-line string.
--
-- @param entry A detail table with fields: slice_name, action, file_path, file_size, original_name (optional).
-- @return A formatted single-line string suitable for display in a list.
function ReportFormatter:format_detail_row(entry)
    local action_str = ""
    if entry.action == "exported" then
        action_str = "✓ Exported"
    elseif entry.action == "duplicate_renamed" then
        action_str = "✓ Duplicate (renamed)"
        if entry.original_name then
            action_str = action_str .. ": " .. entry.original_name .. " → " .. entry.slice_name
        end
    elseif entry.action == "skipped_export_false" then
        action_str = "✗ Skipped (export=false)"
    elseif entry.action == "skipped_exists" then
        action_str = "✗ Skipped (already exists)"
    else
        action_str = "? " .. entry.action
    end
    
    local size_str = entry.file_size and (" [" .. util.format_bytes(entry.file_size) .. "]") or ""
    return "  " .. entry.slice_name .. ": " .. action_str .. size_str
end

--- Builds a complete formatted report including summary and all detail rows.
--
-- @param summary A summary statistics table from calculate_export_summary().
-- @param export_details A list of export detail entries.
-- @return A complete formatted report as a multi-line string.
function ReportFormatter:build_full_report(summary, export_details)
    local lines = {}
    
    -- Add summary section
    table.insert(lines, self:format_summary(summary))
    table.insert(lines, "")
    table.insert(lines, "=== EXPORT DETAILS ===")
    table.insert(lines, "")
    
    -- Add detail rows
    if export_details and #export_details > 0 then
        for _, entry in ipairs(export_details) do
            table.insert(lines, self:format_detail_row(entry))
        end
    else
        table.insert(lines, "  (no exports)")
    end
    
    return table.concat(lines, "\n")
end

--- Formats bytes into human-readable size (e.g., "1.5 KB", "2.3 MB").
--
-- @param bytes The number of bytes (number).
-- @return A formatted string representation (e.g., "1.5 KB").
function util.format_bytes(bytes)
    if bytes == 0 then return "0 B" end
    
    local units = { "B", "KB", "MB", "GB" }
    local unit_index = 1
    local size = bytes
    
    while size >= 1024 and unit_index < #units do
        size = size / 1024
        unit_index = unit_index + 1
    end
    
    if unit_index == 1 then
        return string.format("%d %s", size, units[unit_index])
    else
        return string.format("%.1f %s", size, units[unit_index])
    end
end

util.ReportFormatter = ReportFormatter

return util