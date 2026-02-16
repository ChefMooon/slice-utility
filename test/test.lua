local lu = require('/../lib/luaunit')
local util = require('../util')

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

-- luaunit runner. Must stay at the end of the file to run tests.
local runner = lu.LuaUnit.new()
runner:setOutputType("text")
os.exit( runner:runSuite() )