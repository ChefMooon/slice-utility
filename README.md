# slice utility

This Aseprite extension was created to streamline creating individual assets from a single large canvas.

## Features
- Adds the "Slice Utility" menu group to the "Sprite" dropdown with options:
	- Export Slices...
	- Update Slice Data
- Export Slices... -> Exports all defined slices to a specified folder.
	- By default creates a subfolder with origin sprite name and datetime. (can be disabled)
	- If Slice User Data is defined it will be used as a sub folder (e.g. item/block)
	- Options:
		- Create Subfolder: boolean
		- Create Subfolder with Date/Time: boolean
		- Selection Only: boolean
		- Resize: dropdown { "100%", "200%", "300%", "400%", "500%", "600%", "700%", "800%", "900%", "1000%"}
	- Will prompt with decision to overwrite files if output folder already exists

- Update Slice Data -> Updates slice data within the selected area
	- Color
	- User Data

## Screenshots

**Slice Utility - Menu Group**

<p align="center">
  <img src="img/v0.3_menu_group.png" alt="Slice Utility - Menu Group">
</p>

**Export Slices**

<p align="center">
  <img src="img/v0.2_export_slices.png" alt="Slice Utility - Export Slices">
</p>

**Update Slice Data**

<p align="center">
  <img src="img/v0.2_update_data.png" alt="Slice Utility - Update Slice Data">
</p>

## Details

### Duplicate Slice Handling Strategy

When exporting slices, the utility automatically ensures that each exported file has a unique name, even if multiple slices share the same base name or subfolder. Duplicate names are handled by appending the lowest available increment (e.g., `_1`, `_2`, etc.) to the filename, so no files are overwritten and all slices are exported safely.

For a full explanation of the logic, edge cases, and implementation details, see the [Detailed Duplicate Slice Handling Documentation](docs/duplicate-slice-handling.md).
   