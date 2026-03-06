# Changelog

## v0.5.0

### Added
- Export report functionality with detailed statistics and file size calculations
- File selection dialog for choosing export location

### Changed
- Improved button text formatting in dialogs for better visibility
- Improved folder overwrite options: "Overwrite", "New Only", and "Delete & Replace"

## v0.4

### Added
- Handle duplicate slices during export (no filename is reused)
- Default keyboard shortcuts:
   - Export Slices -> Ctrl+Shift+E
   - Update Slice Data -> Ctrl+Shift+W
- Slice exclusion via enhanced slice "user_data" parsing (can specify folder and export flag)
- Commands now implement onenabled() checks

### Changed
- "Selected Only" checkbox changed to a button
- "Update Slice Data..." now uses application default slice color
- "Slice Export" -> "Export" button now focussed
- Commands are now dynamically enabled or disabled based on context, preventing usage when requirements are not satisfied.
- The "Export Slices" dialog now displays a clearer and more informative success message, including new/updated slices

### Fixed
- No longer overwrites slices with the same name

### Removed
- On exit message removed

## v0.3

### Fixed

- After export returns to source sprite

## v0.2

### Added
- Exported images can be resized

### Changed
- Export All Slices label updated -> Export Slices...
- Update exit message
- Will prompt decision before overwriting a folder

## v0.1

Initial Release