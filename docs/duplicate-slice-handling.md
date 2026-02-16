# Duplicate Slice Handling Strategy

This document provides a detailed explanation of how the Slice Utility extension handles duplicate slice names during export, ensuring unique filenames and robust batch export behavior.

## How It Works

1. **Tracking Exported Names:**
   - During export, a table is initialized to keep track of all exported slice names and their used increments for the current session.

2. **Parsing Slice Keys:**
   - Each slice's export path is parsed to extract a base key and any increment (e.g., `block/yellow_1` → key: `block/yellow`, increment: `1`).
   - If no increment is present, the increment is considered `0` and the key is the full path.

3. **Checking for Duplicates:**
   - Before exporting, the utility checks if the current slice's path (including increment) is unique for its key.
   - If unique, it is exported as-is.
   - If not unique, the utility finds the lowest available increment for that key (starting from 0) that is not already used.
   - The filename is then constructed:
     - If increment is `0`: `name.png`
     - If increment > `0`: `name_<increment>.png`

4. **Edge Case Handling:**
   - If increments are non-contiguous (e.g., 0, 1, 3), the first gap (e.g., 2) is used for the next duplicate.
   - If all increments up to the maximum are used, the next available increment is one higher than the current maximum.
   - If a slice's user data is used as a subfolder, uniqueness is tracked per subfolder.
   - The logic ensures that no filename is reused within a single export session, even if slices are renamed or reordered.

5. **Implementation Details:**
   - The logic is implemented in `util.lua` with functions like `get_export_data`, `export_is_unique`, and `find_lowest_increment`.
   - The export process in `slice_utility.lua` uses these helpers to manage naming and avoid overwriting files.
   - The export dialog will prompt the user if the export folder already exists, allowing them to cancel or overwrite.

## Example

Suppose you have three slices named `block`, `block`, and `block_2`:

- The first `block` exports as `block.png` (increment 0).
- The second `block` (duplicate) exports as `block_1.png` (increment 1).
- The third `block_2` exports as `block_2.png` (increment 2).

If you export again and add another `block`, it will export as `block_3.png` (increment 3), filling the next available slot.

## Additional Notes

- The strategy is robust against gaps in numbering and works for any number of duplicates.
- User Data (if set) is used as a subfolder, so uniqueness is managed within each subfolder.
- The utility does not currently sanitize filenames; avoid using characters not allowed by your operating system.
- The logic is session-based: it only ensures uniqueness for the current export operation, not across multiple exports unless the output folder is preserved.

This approach ensures exported slices are never accidentally overwritten and are always uniquely named, making batch asset export safe and predictable.
