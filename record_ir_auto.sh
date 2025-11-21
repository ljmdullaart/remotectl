#!/bin/bash

# --- Configuration ---
LIRC_RECEIVER="/dev/lirc1" # IR Receiver device (gpio-ir)
LIRC_TRANSMITTER="/dev/lirc0" # IR Transmitter device for confirmation message
CARRIER_FREQ="38000"       # Standard carrier frequency

if [ -z "$1" ]; then
    echo "Usage: $0 <remote_name>"
    echo "Example: $0 amino"
    echo "The script will look for <remote_name>.keys (e.g., amino.keys)."
    exit 1
fi

remote_name="$1"
# Create the prefix for filenames (e.g., amino_). Sanitize and lowercase.
prefix="$(echo "$remote_name" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]_' '_')_"
keys_file="${remote_name}.keys"

echo "---"
echo "**Starting Automated Recording**"
echo "Remote Name: ${remote_name}"
echo "Key List File: ${keys_file}"
echo "Output Prefix: ${prefix}"
echo "---"

# Check if the keys file exists
if [ ! -f "$keys_file" ]; then
    echo "Error: Key list file '${keys_file}' not found."
    echo "Please create it with one key name per line."
    exit 1
fi

# --- Check Prerequisites ---
if ! command -v ir-ctl &> /dev/null; then
    echo "Error: 'ir-ctl' command not found. Please ensure v4l-utils is installed."
    exit 1
fi

if [ ! -c "$LIRC_RECEIVER" ]; then
    echo "Error: LIRC receiver device '$LIRC_RECEIVER' not found."
    echo "Please check your setup or set the correct device in the script."
    exit 1
fi

# Stop lircd to prevent it from consuming the raw IR data
echo "Stopping lircd to ensure raw capture is possible..."
sudo systemctl stop lircd.service 2>/dev/null

# --- Capture Loop ---
# Read key names line by line from the keys file
while IFS= read -r key_name; do
    key_name=${key_name%% *}
    if [ "$key_name" = '---' ]; then
        continue
    fi
    if [ "$key_name" = '#' ]; then
        continue
    fi
    if [ "$key_name" = '->' ]; then
        continue
    fi
    if [ "$key_name" = '===' ]; then
        continue
    fi
    if [ -z "$key_name" ]; then
        continue
    fi

    # Sanitize the key name and construct the filename
    sanitized_key=$(echo "$key_name" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]_' '_')
    filename="${prefix}${sanitized_key}.ir"

    echo "------------------------------------------------"
    echo "Recording Key: **${key_name}**"
    echo "---"
    echo "Output file: **${filename}**"
    echo "Press the '${key_name}' button **once NOW**, pointing the remote at the IR receiver."
    echo "Waiting for signal on $LIRC_RECEIVER (Timeout: 5 seconds)..."

    # Capture Code with Timeout
    temp_file=$(mktemp)
    
    # Use 'timeout' to prevent hanging and capture output to a temp file
    if ! sudo timeout 5 ir-ctl -r --mode2 -1 -d "$LIRC_RECEIVER" > "$temp_file"; then
        exit_status=$?
        rm "$temp_file" # Clean up temp file immediately

        if [ "$exit_status" -eq 124 ]; then
            echo "**Capture Failed.** No signal received within 5 seconds (Timed out)."
        else
            echo "**Capture Failed.** Error during ir-ctl execution (Exit Status: $exit_status)."
        fi
        echo "Please retry this key after the script finishes."
        echo "---"
        continue # Skip to next key
    fi

    # Check if the captured file is empty or too small (i.e., just noise)
    if [ ! -s "$temp_file" ] || [ $(wc -l < "$temp_file") -lt 16 ]; then
        echo "**Capture Failed.** Captured signal was too short or empty (likely noise)."
        rm "$temp_file"
        echo "Please retry this key after the script finishes."
        echo "---"
        continue # Skip to next key
    fi

    # --- Format and Save (Only runs if capture was successful and verified) ---
    echo "carrier $CARRIER_FREQ" > "$filename"
    grep -E 'pulse|space' "$temp_file" >> "$filename"

    # Cleanup
    rm "$temp_file"

    # Confirmation
    echo "**✅ Success! Code saved to:** ${filename}"
    echo "To test sending this code, run:"
    echo "ir-ctl -s ${filename} -d ${LIRC_TRANSMITTER} -g 100000 --carrier ${CARRIER_FREQ}"
    sleep 1   
done < "$keys_file"

echo "---"
# Restart lircd (optional, but good practice if other services rely on it)
# sudo systemctl start lircd.service 2>/dev/null
echo "**Automated recording session finished.**"
