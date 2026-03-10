#!/bin/bash

# ============================================
# PlantUML SVG Generator - Mac/Linux
# Generates SVG files from all .puml files
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGES_DIR="$PROJECT_ROOT/static/images"
PLANTUML_JAR="$IMAGES_DIR/plantuml.jar"
PLANTUML_URL="https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar"

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "[ERROR] Java is not installed or not in PATH"
    echo "Please install Java and try again"
    exit 1
fi

# Download PlantUML if not exists
if [ ! -f "$PLANTUML_JAR" ]; then
    echo "[INFO] PlantUML jar not found, downloading..."
    curl -L -o "$PLANTUML_JAR" "$PLANTUML_URL"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to download PlantUML"
        exit 1
    fi
    echo "[INFO] PlantUML downloaded successfully"
fi

# Process each subdirectory
echo "[INFO] Scanning for .puml files in $IMAGES_DIR..."
COUNT=0

for dir in "$IMAGES_DIR"/*/; do
    if [ -d "$dir" ]; then
        puml_files=("$dir"*.puml)
        if [ -f "${puml_files[0]}" ]; then
            echo "[INFO] Processing folder: $(basename "$dir")"
            for puml_file in "$dir"*.puml; do
                if [ -f "$puml_file" ]; then
                    echo "  - Generating: $(basename "$puml_file")"
                    java -jar "$PLANTUML_JAR" -tsvg "$puml_file"
                    ((COUNT++))
                fi
            done
        fi
    fi
done

echo "[INFO] Done! Generated $COUNT SVG files."
