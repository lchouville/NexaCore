#!/bin/bash
##############################################
#                   CONFIG
##############################################
SOURCE_DIR="./Documents/Edition-files"
DEST_DIR="./Documents/Graph"
TRANSLATIONS_DIR="./Translations/Mermaid"
MMDC="./node_modules/.bin/mmdc"
MERMAID_CONFIG="./mermaid-config.json"
MISSING_KEYS_FILE="./Translations/addedKey.json"

# Global associative array declaration
declare -gA TRANSLATIONS
declare -gA USED_KEYS
declare -gA ALL_PLACEHOLDERS
declare -gA MISSING_KEYS_BY_LANG

# Variables for options
PROCESS_ALL=false
TARGET_FILES=()
VALIDATE_ONLY=false
AUTO_CLEAN=false

##############################################
#               HELP
##############################################
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [FILES...]

Options:
  -a, --all              Generate all files (default if no file specified)
  -v, --validate         Validate placeholders without generating files
  -c, --clean            Automatically remove unused keys from JSON files
  -h, --help             Show this help

Arguments:
  FILES                  List of .mmd files to process (with or without .mmd)
                         Can be a filename or a relative path

Examples:
  $0 -a                                    # Generate all
  $0 -v                                    # Validate only
  $0 -v -c                                 # Validate and clean JSON
  $0 diagram1.mmd diagram2.mmd            # Specific files
  $0 subfolder/diagram.mmd                # File in a subfolder

Note:
  Missing keys will be automatically added to: $MISSING_KEYS_FILE
  Keys are organized by language (en, fr, etc.)
EOF
}

##############################################
#            ARGUMENT PARSING
##############################################
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        PROCESS_ALL=true
        return
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                PROCESS_ALL=true
                shift
                ;;
            -v|--validate)
                VALIDATE_ONLY=true
                shift
                ;;
            -c|--clean)
                AUTO_CLEAN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                TARGET_FILES+=("$1")
                shift
                ;;
        esac
    done

    # If files are specified, do not process all
    if [[ ${#TARGET_FILES[@]} -gt 0 ]]; then
        PROCESS_ALL=false
    else
        PROCESS_ALL=true
    fi
}

##############################################
#          FILE SEARCH
##############################################
find_file() {
    target="$1"

    # Add .mmd if missing
    if [[ ! "$target" =~ \.mmd$ ]]; then
        target="${target}.mmd"
    fi

    # Search for the file
    found=$(find "$SOURCE_DIR" -type f -name "$target" -o -path "*/$target" | head -n 1)

    if [[ -z "$found" ]]; then
        echo "❌ File not found: $target" >&2
        return 1
    fi

    echo "$found"
    return 0
}

get_files_to_process() {
    if [[ "$PROCESS_ALL" == true ]]; then
        find "$SOURCE_DIR" -type f -name "*.mmd"
    else
        for target in "${TARGET_FILES[@]}"; do
            find_file "$target"
        done
    fi
}

##############################################
#        PLACEHOLDER VALIDATION
##############################################

# Extract all placeholders from a file
extract_placeholders() {
    file="$1"
    grep -oP '\{\{[A-Z_][A-Z0-9_]*\}\}' "$file" | sed 's/[{}]//g' | sort -u
}

# Extract all placeholders from all files
scan_all_placeholders() {
    echo ""
    echo "🔍 Scanning placeholders in .mmd files..."

    ALL_PLACEHOLDERS=()

    files_to_scan=()
    while IFS= read -r file; do
        files_to_scan+=("$file")
    done < <(get_files_to_process)

    total_files=${#files_to_scan[@]}
    current=0

    for file in "${files_to_scan[@]}"; do
        ((current++))
        rel_path="${file#$SOURCE_DIR/}"

        while IFS= read -r placeholder; do
            if [[ -n "$placeholder" ]]; then
                ALL_PLACEHOLDERS["$placeholder"]=1
            fi
        done < <(extract_placeholders "$file")

        printf "\r   Files scanned: %d/%d" "$current" "$total_files"
    done

    echo ""
    echo "✅ ${#ALL_PLACEHOLDERS[@]} unique placeholders found"
}

##############################################
#        MISSING KEYS MANAGEMENT
##############################################

# Save missing keys to addedKey.json organized by language
save_missing_keys() {
    # Check if there are any missing keys across all languages
    has_missing=false
    for lang_keys in "${MISSING_KEYS_BY_LANG[@]}"; do
        if [[ -n "$lang_keys" ]]; then
            has_missing=true
            break
        fi
    done

    if [[ "$has_missing" == false ]]; then
        return 0
    fi

    echo ""
    echo "💾 Saving missing keys to $MISSING_KEYS_FILE..."

    # Load existing file structure if it exists
    existing_json="{}"
    if [[ -f "$MISSING_KEYS_FILE" ]]; then
        existing_json=$(cat "$MISSING_KEYS_FILE")
    fi

    # Get list of languages
    lang_list=()
    for lang in "${!MISSING_KEYS_BY_LANG[@]}"; do
        lang_list+=("$lang")
    done

    # Build the new JSON structure
    json_output="{"
    first_lang=true

    for lang in $(printf '%s\n' "${lang_list[@]}" | sort); do
        if [[ "$first_lang" == false ]]; then
            json_output+=","
        fi
        json_output+="
  \"$lang\": {"

        # Get existing keys for this language
        existing_keys=()
        if [[ -f "$MISSING_KEYS_FILE" ]]; then
            while IFS= read -r key; do
                [[ -n "$key" ]] && existing_keys+=("$key")
            done < <(echo "$existing_json" | jq -r ".[\"$lang\"] // {} | keys[]" 2>/dev/null)
        fi

        # Get new missing keys for this language
        missing_keys_str="${MISSING_KEYS_BY_LANG[$lang]}"
        new_missing_keys=()
        if [[ -n "$missing_keys_str" ]]; then
            IFS='|' read -ra new_missing_keys <<< "$missing_keys_str"
        fi

        # Combine and deduplicate keys
        all_keys=()
        for key in "${existing_keys[@]}"; do
            all_keys+=("$key")
        done
        for key in "${new_missing_keys[@]}"; do
            # Check if already exists
            exists=false
            for existing in "${existing_keys[@]}"; do
                if [[ "$key" == "$existing" ]]; then
                    exists=true
                    break
                fi
            done
            if [[ "$exists" == false ]]; then
                all_keys+=("$key")
                echo "   ➕ Added to $lang: $key"
            fi
        done

        # Sort and add keys
        first_key=true
        for key in $(printf '%s\n' "${all_keys[@]}" | sort -u); do
            if [[ -n "$key" ]]; then
                if [[ "$first_key" == false ]]; then
                    json_output+=","
                fi

                # Get existing value if present, otherwise empty string
                existing_value=""
                if [[ -f "$MISSING_KEYS_FILE" ]]; then
                    existing_value=$(echo "$existing_json" | jq -r ".[\"$lang\"][\"$key\"] // \"\"" 2>/dev/null)
                fi

                json_output+="
    \"$key\": \"$existing_value\""
                first_key=false
            fi
        done

        json_output+="
  }"
        first_lang=false
    done

    json_output+="
}"

    # Write and format with jq
    echo "$json_output" | jq -S . > "$MISSING_KEYS_FILE"

    echo "✅ Missing keys saved to $MISSING_KEYS_FILE"
    echo ""
}

# Validate placeholders for a language
validate_placeholders() {
    lang="$1"

    echo ""
    echo "=============================="
    echo "   🔍 Validation: $lang"
    echo "=============================="

    load_translations "$lang" || return 1

    missing_keys=()
    unused_keys=()
    duplicate_keys=()

    # Check for missing keys
    echo "→ Checking for missing keys..."
    for placeholder in "${!ALL_PLACEHOLDERS[@]}"; do
        if [[ -z "${TRANSLATIONS[$placeholder]}" ]]; then
            missing_keys+=("$placeholder")
        fi
    done

    # Store missing keys for this language
    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        MISSING_KEYS_BY_LANG["$lang"]=$(IFS='|'; echo "${missing_keys[*]}")
    fi

    # Check for unused keys
    echo "→ Checking for unused keys..."
    for key in "${!TRANSLATIONS[@]}"; do
        if [[ -z "${ALL_PLACEHOLDERS[$key]}" ]]; then
            unused_keys+=("$key")
        fi
    done

    # Check for duplicates between JSON files
    echo "→ Checking for duplicates..."
    dir="$TRANSLATIONS_DIR/$lang"
    all_keys_with_files=()

    for json_file in "$dir"/*.json; do
        [[ ! -f "$json_file" ]] && continue
        filename=$(basename "$json_file")

        while IFS= read -r key; do
            all_keys_with_files+=("$key|$filename")
        done < <(jq -r 'keys[]' "$json_file")
    done

    # Detect duplicates
    seen_keys=()
    declare -A key_files

    for entry in "${all_keys_with_files[@]}"; do
        key="${entry%|*}"
        file="${entry#*|}"

        if [[ -n "${key_files[$key]}" ]]; then
            duplicate_keys+=("$key (${key_files[$key]}, $file)")
        else
            key_files["$key"]="$file"
        fi
    done

    # Display results
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   📊 Validation Results"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    has_issues=false

    # Missing keys
    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        has_issues=true
        echo ""
        echo "❌ MISSING keys in JSON (${#missing_keys[@]}):"
        for key in "${missing_keys[@]}"; do
            echo "   - $key"
        done
    fi

    # Unused keys
    if [[ ${#unused_keys[@]} -gt 0 ]]; then
        has_issues=true
        echo ""
        echo "⚠️  UNUSED keys in JSON (${#unused_keys[@]}):"
        for key in "${unused_keys[@]}"; do
            echo "   - $key"
        done
    fi

    # Duplicates
    if [[ ${#duplicate_keys[@]} -gt 0 ]]; then
        has_issues=true
        echo ""
        echo "⚠️  DUPLICATE keys between files (${#duplicate_keys[@]}):"
        for entry in "${duplicate_keys[@]}"; do
            echo "   - $entry"
        done
    fi

    # Success
    if [[ "$has_issues" == false ]]; then
        echo ""
        echo "✅ No issues detected!"
        echo "   - ${#ALL_PLACEHOLDERS[@]} placeholders used"
        echo "   - ${#TRANSLATIONS[@]} keys available"
        echo "   - Perfect match ✨"
    fi

    echo ""

    # Suggest cleaning
    if [[ ${#unused_keys[@]} -gt 0 ]]; then
        if [[ "$AUTO_CLEAN" == true ]]; then
            clean_unused_keys "$lang" "${unused_keys[@]}"
        else
            echo "💡 Tip: Use -c or --clean to automatically remove unused keys"
            echo ""
        fi
    fi

    # Return 1 if keys are missing (blocking)
    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Clean unused keys
clean_unused_keys() {
    lang="$1"
    shift
    unused_keys=("$@")

    echo "🧹 Cleaning unused keys..."

    dir="$TRANSLATIONS_DIR/$lang"
    cleaned_count=0

    for json_file in "$dir"/*.json; do
        [[ ! -f "$json_file" ]] && continue

        filename=$(basename "$json_file")
        temp_file="${json_file}.tmp"
        file_cleaned=false

        # Load JSON
        json_content=$(cat "$json_file")

        # Remove each unused key
        for key in "${unused_keys[@]}"; do
            # Check if the key exists in this file
            if jq -e "has(\"$key\")" "$json_file" &>/dev/null; then
                json_content=$(echo "$json_content" | jq "del(.\"$key\")")
                echo "   ✓ Removed: $key (from $filename)"
                ((cleaned_count++))
                file_cleaned=true
            fi
        done

        # Save if modified
        if [[ "$file_cleaned" == true ]]; then
            echo "$json_content" | jq . > "$temp_file"
            mv "$temp_file" "$json_file"
        fi
    done

    echo "✅ $cleaned_count key(s) removed"
    echo ""
}

# Generate a detailed report
generate_validation_report() {
    output_file="validation-report.md"

    echo "📝 Generating validation report..."

    # Count total missing keys across all languages
    total_missing=0
    for lang in "${!MISSING_KEYS_BY_LANG[@]}"; do
        keys_str="${MISSING_KEYS_BY_LANG[$lang]}"
        if [[ -n "$keys_str" ]]; then
            IFS='|' read -ra keys_array <<< "$keys_str"
            total_missing=$((total_missing + ${#keys_array[@]}))
        fi
    done

    cat > "$output_file" << EOF
# 📊 Placeholder Validation Report

**Date**: $(date '+%Y-%m-%d %H:%M:%S')

## 🔍 Global Statistics

- **Unique placeholders found**: ${#ALL_PLACEHOLDERS[@]}
- **.mmd files scanned**: $(get_files_to_process | wc -l)
- **Total missing keys**: $total_missing

## 📋 List of Used Placeholders

EOF

    for placeholder in "${!ALL_PLACEHOLDERS[@]}"; do
        echo "- \`{{$placeholder}}\`" >> "$output_file"
    done | sort >> "$output_file"

    if [[ $total_missing -gt 0 ]]; then
        echo "" >> "$output_file"
        echo "## ❌ Missing Keys by Language" >> "$output_file"
        echo "" >> "$output_file"
        echo "The following keys are missing from translation files and have been added to \`$MISSING_KEYS_FILE\`:" >> "$output_file"
        echo "" >> "$output_file"

        for lang in $(printf '%s\n' "${!MISSING_KEYS_BY_LANG[@]}" | sort); do
            keys_str="${MISSING_KEYS_BY_LANG[$lang]}"
            if [[ -n "$keys_str" ]]; then
                echo "### Language: $lang" >> "$output_file"
                echo "" >> "$output_file"
                IFS='|' read -ra keys_array <<< "$keys_str"
                for key in $(printf '%s\n' "${keys_array[@]}" | sort); do
                    echo "- \`$key\`" >> "$output_file"
                done
                echo "" >> "$output_file"
            fi
        done
    fi

    echo "## 🌐 Validation by Language" >> "$output_file"
    echo "" >> "$output_file"

    for lang in fr en; do
        if [[ -d "$TRANSLATIONS_DIR/$lang" ]]; then
            echo "### Language: $lang" >> "$output_file"
            echo "" >> "$output_file"

            load_translations "$lang"

            missing=0
            unused=0

            # Count missing
            for placeholder in "${!ALL_PLACEHOLDERS[@]}"; do
                if [[ -z "${TRANSLATIONS[$placeholder]}" ]]; then
                    ((missing++))
                fi
            done

            # Count unused
            for key in "${!TRANSLATIONS[@]}"; do
                if [[ -z "${ALL_PLACEHOLDERS[$key]}" ]]; then
                    ((unused++))
                fi
            done

            echo "- ✅ Valid keys: $((${#TRANSLATIONS[@]} - unused))" >> "$output_file"
            echo "- ❌ Missing keys: $missing" >> "$output_file"
            echo "- ⚠️  Unused keys: $unused" >> "$output_file"
            echo "" >> "$output_file"
        fi
    done

    echo "✅ Report generated: $output_file"
}

##############################################
#               UTILITIES
##############################################

# Load a JSON file into an associative array
load_translations() {
    lang="$1"
    dir="$TRANSLATIONS_DIR/$lang"

    # In validation mode, display less info
    if [[ "$VALIDATE_ONLY" != true ]]; then
        echo "→ Loading translations from: $dir"
    fi

    # Check if directory exists
    if [[ ! -d "$dir" ]]; then
        echo "❌ Translation directory not found: $dir"
        return 1
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "❌ jq is not installed. Install it with: sudo apt install jq"
        return 1
    fi

    # Reset associative array
    for key in "${!TRANSLATIONS[@]}"; do
        unset TRANSLATIONS["$key"]
    done

    count=0

    # Load all JSON files
    for json_file in "$dir"/*.json; do
        [[ ! -f "$json_file" ]] && continue

        if [[ "$VALIDATE_ONLY" != true ]]; then
            echo "   📄 $(basename "$json_file")"
        fi

        # Read each key=value pair
        while IFS="=" read -r key value; do
            TRANSLATIONS["$key"]="$value"
            ((count++))
        done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "$json_file")
    done

    if [[ "$VALIDATE_ONLY" != true ]]; then
        echo "✅ $count keys loaded"
    fi

    return 0
}

# Replace placeholders {{KEY}}
apply_translations() {
    file="$1"
    content=$(cat "$file")

    for key in "${!TRANSLATIONS[@]}"; do
        value="${TRANSLATIONS[$key]}"
        # Escape special characters for sed
        escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
        content=$(printf '%s\n' "$content" | sed "s/{{$key}}/$escaped_value/g")
    done

    printf '%s\n' "$content"
}

# Convert .mmd to .svg
convert_to_svg() {
    input="$1"
    output="$2"

    # If a config file exists, use it
    if [[ -f "$MERMAID_CONFIG" ]]; then
        $MMDC -i "$input" -o "$output" -c "$MERMAID_CONFIG" -b transparent >/dev/null 2>&1
    else
        # Otherwise, use dark theme via command line
        $MMDC -i "$input" -o "$output" -t dark -b transparent >/dev/null 2>&1
    fi

    return $?
}

# Format time (seconds -> HH:MM:SS or MM:SS)
format_time() {
    seconds=$1

    if [[ $seconds -lt 60 ]]; then
        printf "%ds" "$seconds"
    elif [[ $seconds -lt 3600 ]]; then
        printf "%dm %ds" $((seconds / 60)) $((seconds % 60))
    else
        printf "%dh %dm %ds" $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
    fi
}

# Display progress bar with remaining time
show_progress() {
    current="$1"
    total="$2"
    start_time="$3"

    percentage=$((current * 100 / total))
    bar_length=40
    filled=$((percentage * bar_length / 100))
    empty=$((bar_length - filled))

    # Calculate elapsed time
    elapsed=$(($(date +%s) - start_time))

    # Calculate remaining time (only after a few files)
    eta_str=""
    if [[ $current -gt 0 ]]; then
        avg_time=$((elapsed / current))
        remaining=$((total - current))
        eta=$((avg_time * remaining))
        eta_str=" | ETA: $(format_time $eta)"
    fi

    # Display bar
    printf "\033[J["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%% (%d/%d)%s\r" "$percentage" "$current" "$total" "$eta_str"
}

##############################################
#           LANGUAGE PROCESSING
##############################################

process_language() {
    lang="$1"

    echo ""
    echo "=============================="
    echo "   🌐 Language: $lang"
    echo "=============================="

    load_translations "$lang" || return 1

    OUTPUT="$DEST_DIR/$lang"
    mkdir -p "$OUTPUT"

    # Get the list of files to process
    files_to_process=()
    while IFS= read -r file; do
        files_to_process+=("$file")
    done < <(get_files_to_process)

    total_files=${#files_to_process[@]}
    current=0
    errors=0

    if [[ $total_files -eq 0 ]]; then
        echo "❌ No files to process"
        return 1
    fi

    echo "→ $total_files Mermaid file(s) to process"
    echo ""

    # Start timer
    start_time=$(date +%s)

    for file in "${files_to_process[@]}"; do
        ((current++))

        rel_path="${file#$SOURCE_DIR/}"
        subdir="$(dirname "$rel_path")"
        mkdir -p "$OUTPUT/$subdir"

        filename="$(basename -- "$file")"
        name="${filename%.*}"
        tmp="/tmp/${name}_${lang}.mmd"
        svg="$OUTPUT/$subdir/$name.svg"

        # Generate translated MMD file
        apply_translations "$file" > "$tmp"

        # Convert
        convert_to_svg "$tmp" "$svg"
        status=$?

        # Remove temporary file
        rm -f "$tmp"

        if [[ $status -ne 0 ]] || [[ ! -s "$svg" ]]; then
            printf "\033[J"
            echo "❌ Error: $file"
            ((errors++))
        fi

        show_progress "$current" "$total_files" "$start_time"
    done

    # Calculate total time
    end_time=$(date +%s)
    total_time=$((end_time - start_time))

    echo ""
    echo ""

    if [ $errors -gt 0 ]; then
        echo "✓ Done with $errors error(s) out of $total_files files in $(format_time $total_time)."
    else
        echo "✓ All files processed successfully in $(format_time $total_time)."
    fi
}

##############################################
#              MAIN PROGRAM
##############################################

# Parse arguments
parse_arguments "$@"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   🚀 NexaCore Translation Generator    ║"
echo "╚════════════════════════════════════════╝"

if [[ "$PROCESS_ALL" == true ]]; then
    echo "Mode: Process all files"
else
    echo "Mode: Process specific files"
    echo "Target files: ${TARGET_FILES[*]}"
fi

# Scan placeholders
scan_all_placeholders

# Validation only mode
if [[ "$VALIDATE_ONLY" == true ]]; then
    echo ""
    echo "🔍 Mode: VALIDATION ONLY"
    echo ""

    LANG_LIST=($(find "$TRANSLATIONS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

    if [[ ${#LANG_LIST[@]} -eq 0 ]]; then
        echo "❌ No language directory found."
        exit 1
    fi

    validation_failed=false

    for lang in "${LANG_LIST[@]}"; do
        validate_placeholders "$lang" || validation_failed=true
    done

    # Save missing keys
    save_missing_keys

    # Generate report
    generate_validation_report

    if [[ "$validation_failed" == true ]]; then
        echo ""
        echo "❌ Validation failed. Fix the issues before generating files."
        echo "📝 Missing keys have been saved to: $MISSING_KEYS_FILE"
        exit 1
    else
        echo ""
        echo "✅ Validation successful! You can safely generate files."
        exit 0
    fi
fi

# Normal generation mode
echo ""
echo "Searching for languages in: $TRANSLATIONS_DIR"

LANG_LIST=($(find "$TRANSLATIONS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

if [[ ${#LANG_LIST[@]} -eq 0 ]]; then
    echo "❌ No language directory found."
    exit 1
fi

echo "Detected languages: ${LANG_LIST[*]}"

# Validate before generating
echo ""
echo "🔍 Validating placeholders..."
validation_failed=false

for lang in "${LANG_LIST[@]}"; do
    validate_placeholders "$lang" || validation_failed=true
done

# Save missing keys
save_missing_keys

if [[ "$validation_failed" == true ]]; then
    echo ""
    echo "⚠️  Issues detected in translations."
    echo "📝 Missing keys have been saved to: $MISSING_KEYS_FILE"
    echo "❓ Do you want to continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Generation cancelled."
        exit 1
    fi
fi

# Global start time
GLOBAL_START=$(date +%s)

for lang in "${LANG_LIST[@]}"; do
    process_language "$lang"
done

# Total time for all languages
GLOBAL_END=$(date +%s)
GLOBAL_TIME=$((GLOBAL_END - GLOBAL_START))

echo ""
echo "🎉 Multi-language generation completed in $(format_time $GLOBAL_TIME)."

# Count total missing keys
total_missing_count=0
for lang in "${!MISSING_KEYS_BY_LANG[@]}"; do
    keys_str="${MISSING_KEYS_BY_LANG[$lang]}"
    if [[ -n "$keys_str" ]]; then
        IFS='|' read -ra keys_array <<< "$keys_str"
        total_missing_count=$((total_missing_count + ${#keys_array[@]}))
    fi
done

if [[ $total_missing_count -gt 0 ]]; then
    echo ""
    echo "📝 Note: $total_missing_count missing key(s) saved to: $MISSING_KEYS_FILE"
    echo "   Keys are organized by language for easy translation."
fi
