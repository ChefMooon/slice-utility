# Example: Compress 3 files into a zip
import zipfile
import os

# Change this to your target directory
directory = os.path.dirname(os.path.abspath(__file__))

# Create 'build' folder if it doesn't exist
build_folder = os.path.join(directory, "build")
os.makedirs(build_folder, exist_ok=True)

# List your target files
files_to_zip = [
    "init.lua",
    "slice_utility.lua",
    "package.json"
]

zip_filename = "slice_utility.aseprite-extension"
zip_path = os.path.join(build_folder, zip_filename)

with zipfile.ZipFile(zip_path, 'w') as zipf:
    for filename in files_to_zip:
        file_path = os.path.join(directory, filename)
        if os.path.exists(file_path):
            zipf.write(file_path, arcname=filename)

print(f"Created zip: {zip_path}")