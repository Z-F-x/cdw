replace_dot_slash_with_tilde() {
    local cd_history_file="$1"
    
    # Replace occurrences of './' with '~' in the file
    sed -i 's|^\./|~|g' "$cd_history_file"
}

# TODO:
# The problem seems to be that the full path to .cd_visits is not being written.
# I need to go through it and figure out where it's going wrong; the correct path must be written just like .cd_history.
# I also need to add an increment for each hit / each time the user searches for a file path.

 update_cd_visits() {
    local cd_history_file="$1"
    local cd_visits_file="$2"

    # Create a temporary file to store new visit counts
    tmp_file=$(mktemp)

    # Count visits to each directory and write to the temporary file
    awk '
    {
        count[$0]++;
    }
    END {
        for (dir in count) {
            print dir " " count[dir];
        }
    }' "$cd_history_file" | sort -k2,2nr -k1,1 > "$tmp_file"

    # If the visits file already exists, update it with new counts
    if [[ -f "$cd_visits_file" ]]; then
        # Merge the existing visits file with the new counts and sort them
        awk '
        BEGIN {
            while ((getline < "'"$cd_visits_file"'") > 0) {
                # Read existing data into the count array
                count[$1] = $2;
            }
        }
        {
            # Add the new counts from the temporary file
            count[$1] += $2;
        }
        END {
            for (dir in count) {
                print dir " " count[dir];
            }
        }' "$tmp_file" | sort -k2,2nr -k1,1 > "$cd_visits_file"
    else
        # If no visits file exists, simply create it with the new counts
        mv "$tmp_file" "$cd_visits_file"
    fi
}

cd() {
    builtin cd "$@" || return

    # Create .cd_history if it doesn't exist
    local cd_history_file=~/.cd_history
    [[ -f "$cd_history_file" ]] || touch "$cd_history_file"

    # Get the current directory path
    local current_dir=$(pwd)
    local home_dir="$HOME"

    # If the current directory is the home directory, log as ~
    if [[ "$current_dir" == "$home_dir" ]]; then
        current_dir="~"  # Log as ~ if we're in the home directory
    # If the current directory is inside the home directory, log it as an absolute path
    elif [[ "$current_dir" == "$home_dir"* ]]; then
        current_dir="$current_dir"  # Keep it as absolute path
    # If the user types `cd ~`, log it as `~`
    elif [[ "$current_dir" == "~" ]]; then
        current_dir="~"  # Log as ~ if explicitly in the home directory
    fi
    
    # If the path contains spaces, wrap the entire path in quotes
    if [[ "$current_dir" =~ \  ]]; then
        current_dir="\"$current_dir\""
    fi

    # Log the current absolute directory to .cd_history
    echo "$current_dir" >> "$cd_history_file"     

    # Remove duplicates and update .cd_visits
    remove_duplicates_and_update_visits
}


cdw() {
    local cd_history_file=~/.cd_history

    # Check if .cd_visits exists
    [[ -f "$cd_history_file" ]] || touch "$cd_history_file"

    # Use fzf to list directories, ensuring quoted paths with spaces are handled
   # local dir=$(cat "$cd_history_file" | fzf --height 20 --reverse --prompt="Select directory: ")
    local dir=$(cat "$cd_history_file" | head -n 25 | fzf --height 20 --reverse --prompt="Select directory: ")
    # Check if the selected directory is not empty
    if [[ -n "$dir" ]]; then
        # Display the cd command in the terminal
        echo "cd $dir"

        # Change to the selected directory
        eval "cd $dir"
    else
        echo "No directory selected."
    fi

        remove_duplicates_and_update_visits
}
