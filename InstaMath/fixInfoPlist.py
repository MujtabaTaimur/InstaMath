#!/usr/bin/env python3
import re
import os
import shutil

# Path to the project.pbxproj file
pbxproj_path = "/Users/admin/Desktop/InstaMath/InstaMath.xcodeproj/project.pbxproj"

# Make sure the file exists
if not os.path.exists(pbxproj_path):
    print(f"Error: {pbxproj_path} not found")
    exit(1)

# Create a backup
backup_path = pbxproj_path + ".bak"
shutil.copy2(pbxproj_path, backup_path)
print(f"Created backup at {backup_path}")

# Read the file content
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Find all Copy Bundle Resources build phase sections
copy_resources_sections = []
for match in re.finditer(r'/\* Copy Bundle Resources \*/ = \{(.*?)\};', content, re.DOTALL):
    copy_resources_sections.append(match.group(0))

modified = False
new_content = content

for section in copy_resources_sections:
    # Check if the section contains InstaMathInfo.plist
    if "InstaMathInfo.plist" in section:
        print("Found InstaMathInfo.plist in Copy Bundle Resources")
        
        # Find the line with InstaMathInfo.plist and the previous line
        lines = section.split('\n')
        for i, line in enumerate(lines):
            if "InstaMathInfo.plist" in line:
                # Prepare the modified section
                if i > 0 and lines[i-1].strip().endswith(','):
                    # Remove the comma from the previous line
                    lines[i-1] = lines[i-1].rstrip(',')
                
                # Remove the line with InstaMathInfo.plist
                lines.pop(i)
                
                modified_section = '\n'.join(lines)
                new_content = new_content.replace(section, modified_section)
                modified = True
                print("Removed InstaMathInfo.plist from Copy Bundle Resources")
                break

if modified:
    # Write the modified content back to the file
    with open(pbxproj_path, 'w') as f:
        f.write(new_content)
    print("Successfully updated project.pbxproj")
else:
    print("No changes were made")
