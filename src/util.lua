
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

return util