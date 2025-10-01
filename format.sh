#!/bin/bash

# Format script to handle forge fmt issues
echo "Running forge fmt on project files..."

# Format only source, test, and script directories
forge fmt src/ test/ script/

# Check if formatting was successful
if [ $? -eq 0 ]; then
    echo "✅ Formatting completed successfully"
    exit 0
else
    echo "❌ Formatting failed"
    exit 1
fi
