import zipfile
import os
import json

# Change this to your target directory
directory = os.path.dirname(os.path.abspath(__file__))

# Read version from package.json
package_json_path = os.path.join(directory, "package.json")
with open(package_json_path, "r") as f:
    package_data = json.load(f)
version = package_data.get("version", "0.1")

# Create 'build' folder if it doesn't exist
build_folder = os.path.join(directory, "build")
os.makedirs(build_folder, exist_ok=True)

# List your target files
files_to_zip = [
    "init.lua",
    "slice_utility.lua",
    "util.lua",
    "package.json"
]

zip_filename = f"slice_utility_v{version}.aseprite-extension"
zip_path = os.path.join(build_folder, zip_filename)

with zipfile.ZipFile(zip_path, 'w') as zipf:
    for filename in files_to_zip:
        file_path = os.path.join(directory, filename)
        if os.path.exists(file_path):
            zipf.write(file_path, arcname=filename)

print(f"Created zip: {zip_path}")