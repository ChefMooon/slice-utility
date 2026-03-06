local lu = require('/../lib/luaunit')
local util = require('../src/util')

local test_data = {}

test_data["block/yellow"] = {
    { path = "block/yellow", increment = 0 },
    { path = "block/yellow_1", increment = 1 },
    { path = "block/yellow_3", increment = 3 }
}
test_data["block/red"] = { { path = "block/red", increment = 0 } }
test_data["block/green"] = { { path = "block/green_2", increment = 2 } }
test_data["block/orange"] = {
    { path = "block/orange_1", increment = 1 },
    { path = "block/orange_3", increment = 3 }
}

--- Test cases for find_lowest_increment ---
function TestFindLowestIncrement_Yellow()
    lu.assertEquals( util.find_lowest_increment(test_data, "block/yellow"), 2 )
end

function TestFindLowestIncrement_Red()
    lu.assertEquals( util.find_lowest_increment(test_data, "block/red"), 1 )
end

function TestFindLowestIncrement_Blue()
    lu.assertEquals( util.find_lowest_increment(test_data, "block/blue"), 0 )
end

function TestFindLowestIncrement_Green()
    lu.assertEquals( util.find_lowest_increment(test_data, "block/green"), 0 )
end

function TestFindLowestIncrement_Orange()
    lu.assertEquals( util.find_lowest_increment(test_data, "block/orange"), 0 )
end
-- TODO: Add more test cases for edge cases (e.g., non-sequential increments, empty tables, etc.)

--- Tests for util.make_directory ---

-- Mock app.fs for testing
local original_app = _G.app

local function mock_isDirectory(path)
    return _G._mock_dirs[path] == true
end

local function mock_makeDirectory(path)
    if path == "error" then error("Simulated error") end
    _G._mock_dirs[path] = true
end

_G._mock_dirs = {}
_G.app = {
    fs = {
        isDirectory = mock_isDirectory,
        makeDirectory = mock_makeDirectory
    }
}
app = _G.app  -- Also set as local for convenience

function TestMakeDirectory_EmptyPath()
    local ok, err = util.make_directory("")
    lu.assertFalse(ok)
    lu.assertEquals(err, "Path is empty or nil")
end

function TestMakeDirectory_NilPath()
    local ok, err = util.make_directory(nil)
    lu.assertFalse(ok)
    lu.assertEquals(err, "Path is empty or nil")
end

function DisabledTestMakeDirectory_NewDir()
    _G._mock_dirs["newdir"] = nil
    local ok, err = util.make_directory("newdir")
    lu.assertTrue(ok)
    lu.assertNil(err)
    lu.assertTrue(_G._mock_dirs["newdir"])
end

function DisabledTestMakeDirectory_AlreadyExists()
    _G._mock_dirs["exists"] = true
    local ok, err = util.make_directory("exists")
    lu.assertTrue(ok)
    lu.assertNil(err)
end

function DisabledTestMakeDirectory_Error()
    _G._mock_dirs["error"] = nil
    local ok, err = util.make_directory("error")
    lu.assertFalse(ok)
    lu.assertStrContains(err, "Simulated error")
end

--- Tests for util.export_is_unique ---

-- Should return true for a unique path not present in the key's entries
function TestExportIsUnique_Unique()
    lu.assertTrue(util.export_is_unique(test_data, "block/yellow", "block/yellow_2"))
end

-- Should return false for a path already present in the key's entries
function TestExportIsUnique_NotUnique()
    lu.assertFalse(util.export_is_unique(test_data, "block/yellow", "block/yellow_1"))
end

-- Should return true if the key does not exist in the table
function TestExportIsUnique_KeyDoesNotExist()
    lu.assertTrue(util.export_is_unique(test_data, "block/blue", "block/blue"))
end

-- Should return true if the value for the key is an empty table
function TestExportIsUnique_EmptyTable()
    local t = { ["block/empty"] = {} }
    lu.assertTrue(util.export_is_unique(t, "block/empty", "block/empty_1"))
end

-- Should return true if the table t is empty
function TestExportIsUnique_EmptyT()
    lu.assertTrue(util.export_is_unique(test_data, "block/none", "block/none_1"))
end

-- Should return true if t is nil
function TestExportIsUnique_NilT()
    local t = nil
    lu.assertTrue(util.export_is_unique(t, "block/none", "block/none_1"))
end

-- Should return true if entries are missing the path field
function TestExportIsUnique_EntryMissingPath()
    local t = { ["block/missing"] = { { not_path = "block/missing_1" } } }
    lu.assertTrue(util.export_is_unique(t, "block/missing", "block/missing_1"))
end

-- Should return true if entries are not tables
function TestExportIsUnique_EntryIsNotTable()
    local t = { ["block/notatable"] = { "block/notatable_1", "block/notatable_2" } }
    lu.assertTrue(util.export_is_unique(t, "block/notatable", "block/notatable_3"))
end

-- Should return true for an empty path
function TestExportIsUnique_EmptyPath()
    lu.assertTrue(util.export_is_unique(test_data, "block/yellow", ""))
end

-- Should return false for duplicate paths, true for a new path
function TestExportIsUnique_AllEntriesSamePath()
    local t = { ["block/dup"] = { { path = "block/dup_1" }, { path = "block/dup_1" } } }
    lu.assertFalse(util.export_is_unique(t, "block/dup", "block/dup_1"))
    lu.assertTrue(util.export_is_unique(t, "block/dup", "block/dup_2"))
end

--- Tests for util.get_export_data ---

-- Should parse increment from path ending with _3
function TestGetExportData_WithIncrement()
    local result = util.get_export_data("block/yellow_3")
    lu.assertEquals(result, { key = "block/yellow", path = "block/yellow_3", increment = 3 })
end

-- Should return increment 0 and key same as path when no increment suffix
function TestGetExportData_WithoutIncrement()
    local result = util.get_export_data("block/red")
    lu.assertEquals(result, { key = "block/red", path = "block/red", increment = 0 })
end

-- Should handle increment 0 correctly
function TestGetExportData_ZeroIncrement()
    local result = util.get_export_data("block/yellow_0")
    lu.assertEquals(result, { key = "block/yellow", path = "block/yellow_0", increment = 0 })
end

-- Should handle empty string input
function TestGetExportData_EmptyString()
    local result = util.get_export_data("")
    lu.assertEquals(result, { key = "", path = "", increment = 0 })
end

-- Should ignore non-numeric suffix and treat as no increment
function TestGetExportData_NonNumericSuffix()
    local result = util.get_export_data("block/yellow_a")
    lu.assertEquals(result, { key = "block/yellow_a", path = "block/yellow_a", increment = 0 })
end

--- Tests for util.equal_colors ---

-- Should return true for identical color tables
function TestEqualColors_Identical()
    local c1 = { red = 255, green = 128, blue = 64, alpha = 255 }
    local c2 = { red = 255, green = 128, blue = 64, alpha = 255 }
    lu.assertTrue(util.equal_colors(c1, c2))
end

-- Should return false for different red component
function TestEqualColors_DifferentRed()
    local c1 = { red = 100, green = 128, blue = 64, alpha = 255 }
    local c2 = { red = 101, green = 128, blue = 64, alpha = 255 }
    lu.assertFalse(util.equal_colors(c1, c2))
end

-- Should return false for different green component
function TestEqualColors_DifferentGreen()
    local c1 = { red = 100, green = 128, blue = 64, alpha = 255 }
    local c2 = { red = 100, green = 129, blue = 64, alpha = 255 }
    lu.assertFalse(util.equal_colors(c1, c2))
end

-- Should return false for different blue component
function TestEqualColors_DifferentBlue()
    local c1 = { red = 100, green = 128, blue = 64, alpha = 255 }
    local c2 = { red = 100, green = 128, blue = 65, alpha = 255 }
    lu.assertFalse(util.equal_colors(c1, c2))
end

-- Should return false for different alpha component
function TestEqualColors_DifferentAlpha()
    local c1 = { red = 100, green = 128, blue = 64, alpha = 255 }
    local c2 = { red = 100, green = 128, blue = 64, alpha = 254 }
    lu.assertFalse(util.equal_colors(c1, c2))
end

-- Should return true for both fully transparent black
function TestEqualColors_TransparentBlack()
    local c1 = { red = 0, green = 0, blue = 0, alpha = 0 }
    local c2 = { red = 0, green = 0, blue = 0, alpha = 0 }
    lu.assertTrue(util.equal_colors(c1, c2))
end

-- Should return false if one color is missing a component (edge case)
function TestEqualColors_MissingComponent()
    local c1 = { red = 100, green = 128, blue = 64, alpha = 255 }
    local c2 = { red = 100, green = 128, blue = 64 } -- missing alpha
    lu.assertFalse(util.equal_colors(c1, c2))
end


--- Tests for util.parse_slice_data ---

--- Should return nil if data is missing
function TestParseSliceData_Nil()
    lu.assertNil(util.parse_slice_data(nil))
end

--- Should return string if data is a plain string
function TestParseSliceData_String()
    lu.assertEquals(util.parse_slice_data("folder/subfolder"), "folder/subfolder")
end

--- Should return formatted table if data is a table-like string with folder and export
function TestParseSliceData_TableString()
    local result = util.parse_slice_data("{ folder = 'sprites', export = false }")
    lu.assertEquals(result, { folder = "sprites", export = false })
end

--- Should default export to true if not specified in table-like string
function TestParseSliceData_TableString_DefaultExport()
    local result = util.parse_slice_data("{ folder = 'icons' }")
    lu.assertEquals(result, { folder = "icons", export = true })
end

--- Should default folder to empty string if not specified in table-like string
function TestParseSliceData_TableString_DefaultFolder()
    local result = util.parse_slice_data("{ export = false }")
    lu.assertEquals(result, { folder = "", export = false })
end

--- Should handle empty table-like string
function TestParseSliceData_TableString_Empty()
    local result = util.parse_slice_data("{}")
    lu.assertEquals(result, { folder = "", export = true })
end

--- Tests for util.get_file_size ---

--- Should return 0 for non-existent file
function TestGetFileSize_NonExistent()
    local size = util.get_file_size("/nonexistent/path/to/file.png")
    lu.assertEquals(size, 0)
end

--- Should return 0 for empty path
function TestGetFileSize_EmptyPath()
    local size = util.get_file_size("")
    lu.assertEquals(size, 0)
end

--- Should return 0 for nil path
function TestGetFileSize_NilPath()
    local size = util.get_file_size(nil)
    lu.assertEquals(size, 0)
end

--- Tests for util.calculate_export_summary ---

--- Should calculate correct summary from export details
function TestCalculateExportSummary_BasicExport()
    local export_details = {
        { slice_name = "block/yellow", action = "exported", file_path = "block/yellow.png", file_size = 1024 },
        { slice_name = "block/red", action = "exported", file_path = "block/red.png", file_size = 2048 },
        { slice_name = "block/blue", action = "duplicate_renamed", file_path = "block/blue_1.png", file_size = 1024, original_name = "block/blue" },
        { slice_name = "block/green", action = "skipped_export_false", file_path = "", file_size = 0 }
    }
    local summary = util.calculate_export_summary(export_details, 4, 5000)
    lu.assertEquals(summary.total_slices, 4)
    lu.assertEquals(summary.exported_count, 3)
    lu.assertEquals(summary.unique_count, 2)
    lu.assertEquals(summary.duplicates_count, 1)
    lu.assertEquals(summary.skipped_count, 1)
    lu.assertEquals(summary.total_file_size, 4096)
    lu.assertEquals(summary.avg_file_size, 1365)
    lu.assertEquals(summary.export_duration_ms, 5000)
end

--- Should handle empty export details
function TestCalculateExportSummary_EmptyDetails()
    local summary = util.calculate_export_summary({}, 10, 1000)
    lu.assertEquals(summary.total_slices, 10)
    lu.assertEquals(summary.exported_count, 0)
    lu.assertEquals(summary.unique_count, 0)
    lu.assertEquals(summary.duplicates_count, 0)
    lu.assertEquals(summary.skipped_count, 0)
    lu.assertEquals(summary.total_file_size, 0)
    lu.assertEquals(summary.avg_file_size, 0)
end

--- Should handle nil export details
function TestCalculateExportSummary_NilDetails()
    local summary = util.calculate_export_summary(nil, 5, 0)
    lu.assertEquals(summary.total_slices, 5)
    lu.assertEquals(summary.exported_count, 0)
end

--- Tests for util.format_bytes ---

--- Should format bytes correctly
function TestFormatBytes_Bytes()
    lu.assertEquals(util.format_bytes(0), "0 B")
    lu.assertEquals(util.format_bytes(512), "512 B")
    lu.assertEquals(util.format_bytes(1023), "1023 B")
end

--- Should format kilobytes
function TestFormatBytes_Kilobytes()
    lu.assertEquals(util.format_bytes(1024), "1.0 KB")
    lu.assertEquals(util.format_bytes(1536), "1.5 KB")
    lu.assertEquals(util.format_bytes(1048575), "1024.0 KB")
end

--- Should format megabytes
function TestFormatBytes_Megabytes()
    lu.assertEquals(util.format_bytes(1048576), "1.0 MB")
    lu.assertEquals(util.format_bytes(5242880), "5.0 MB")
end

--- Tests for ReportFormatter ---

--- Should format summary correctly
function TestReportFormatter_FormatSummary()
    local formatter = util.ReportFormatter:new()
    local summary = {
        total_slices = 5,
        exported_count = 3,
        unique_count = 2,
        duplicates_count = 1,
        skipped_count = 2,
        total_file_size = 5120,
        avg_file_size = 1706,
        export_duration_ms = 2500
    }
    local formatted = formatter:format_summary(summary)
    lu.assertNotNil(formatted)
    lu.assertStrContains(formatted, "Total slices on sprite: 5")
    lu.assertStrContains(formatted, "Total exported: 3")
    lu.assertStrContains(formatted, "Unique: 2")
    lu.assertStrContains(formatted, "Duplicates (renamed): 1")
    lu.assertStrContains(formatted, "Total skipped: 2")
end

--- Should format detail row for exported slice
function TestReportFormatter_FormatDetailRow_Exported()
    local formatter = util.ReportFormatter:new()
    local entry = {
        slice_name = "block/yellow",
        action = "exported",
        file_path = "block/yellow.png",
        file_size = 1024
    }
    local formatted = formatter:format_detail_row(entry)
    lu.assertNotNil(formatted)
    lu.assertStrContains(formatted, "block/yellow")
    lu.assertStrContains(formatted, "Exported")
end

--- Should format detail row for duplicate slice with original name
function TestReportFormatter_FormatDetailRow_Duplicate()
    local formatter = util.ReportFormatter:new()
    local entry = {
        slice_name = "block/red_1",
        action = "duplicate_renamed",
        file_path = "block/red_1.png",
        file_size = 2048,
        original_name = "block/red"
    }
    local formatted = formatter:format_detail_row(entry)
    lu.assertNotNil(formatted)
    lu.assertStrContains(formatted, "Duplicate (renamed)")
    lu.assertStrContains(formatted, "block/red")
    lu.assertStrContains(formatted, "block/red_1")
end

--- Should build complete report
function TestReportFormatter_BuildFullReport()
    local formatter = util.ReportFormatter:new()
    local summary = {
        total_slices = 2,
        exported_count = 2,
        unique_count = 2,
        duplicates_count = 0,
        skipped_count = 0,
        total_file_size = 2048,
        avg_file_size = 1024,
        export_duration_ms = 1000
    }
    local export_details = {
        { slice_name = "block/yellow", action = "exported", file_path = "block/yellow.png", file_size = 1024 },
        { slice_name = "block/red", action = "exported", file_path = "block/red.png", file_size = 1024 }
    }
    local report = formatter:build_full_report(summary, export_details)
    lu.assertNotNil(report)
    lu.assertStrContains(report, "EXPORT SUMMARY")
    lu.assertStrContains(report, "EXPORT DETAILS")
    lu.assertStrContains(report, "block/yellow")
    lu.assertStrContains(report, "block/red")
end

--- Should handle empty export details in full report
function TestReportFormatter_BuildFullReport_Empty()
    local formatter = util.ReportFormatter:new()
    local summary = {
        total_slices = 0,
        exported_count = 0,
        unique_count = 0,
        duplicates_count = 0,
        skipped_count = 0,
        total_file_size = 0,
        avg_file_size = 0,
        export_duration_ms = 0
    }
    local report = formatter:build_full_report(summary, {})
    lu.assertNotNil(report)
    lu.assertStrContains(report, "no exports")
end

-- luaunit runner. Must stay at the end of the file to run tests. New tests go above this line.
local runner = lu.LuaUnit.new()
runner:setOutputType("text")
local result = runner:runSuite()
-- Note: Keeping mock app active for all tests - not restoring original_app
os.exit( result )