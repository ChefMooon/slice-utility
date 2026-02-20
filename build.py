import zipfile  # For creating zip archives
import os       # For file and directory operations
import json     # For reading package.json

# Get the directory where this script is located
directory = os.path.dirname(os.path.abspath(__file__))

# Read the version number from package.json
package_json_path = os.path.join(directory, "package.json")
with open(package_json_path, "r") as f:
    package_data = json.load(f)
version = package_data.get("version", "0.1")

# Create the 'build' folder if it doesn't exist
build_folder = os.path.join(directory, "build")
os.makedirs(build_folder, exist_ok=True)

# List the files to include in the zip archive
files_to_zip = [
    "src/init.lua",
    "src/slice_utility.lua",
    "src/util.lua",
    "package.json",
    "default-keys.aseprite-keys"
]

# Construct the zip filename using the version
zip_filename = f"slice_utility_v{version}.aseprite-extension"
zip_path = os.path.join(build_folder, zip_filename)


# Create the zip archive and add files
with zipfile.ZipFile(zip_path, 'w') as zipf:
    for filename in files_to_zip:
        file_path = os.path.join(directory, filename)
        if os.path.exists(file_path):
            # Remove 'src/' prefix if present so all files are at the root of the archive
            arcname = filename.split("src/", 1)[-1] if filename.startswith("src/") else filename
            zipf.write(file_path, arcname=arcname)

# Print the path to the created zip archive
print(f"Created zip: {zip_path}")