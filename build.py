import zipfile  # For creating zip archives
import os       # For file and directory operations
import json     # For reading package.json
import glob     # For finding files matching a pattern

# Get the directory where this script is located
directory = os.path.dirname(os.path.abspath(__file__))

# Read the version number from package.json
package_json_path = os.path.join(directory, "package.json")
with open(package_json_path, "r") as f:
    package_data = json.load(f)
version = package_data.get("version", "0.1")
name = package_data.get("name", "extension")

# Create the 'build' folder if it doesn't exist
build_folder = os.path.join(directory, "build")
os.makedirs(build_folder, exist_ok=True)

# List the files to include in the zip archive
files_to_zip = sorted(glob.glob("src/*")) + [
    "package.json",
    "default-keys.aseprite-keys"
]

# Construct the zip filename using the name and version
zip_filename = f"{name}-v{version}.aseprite-extension"
zip_path = os.path.join(build_folder, zip_filename)


# Create the zip archive and add files
with zipfile.ZipFile(zip_path, 'w') as zipf:
    for filename in files_to_zip:
        
        file_path = os.path.join(directory, filename)
        if os.path.exists(file_path):
            # Remove 'src/' prefix from the archive name so files are at root level in the zip
            arcname = filename.replace("src/", "").replace("src\\", "")
            zipf.write(file_path, arcname=arcname)

# Print the path to the created zip archive
print(f"Created zip: {zip_path}")