  
remove_duplicates_and_update_visits() {
    local cd_history_file=~/.cd_history
    local cd_visits_file=~/.cd_visits

    # Check if .cd_history exists
    [[ -f "$cd_history_file" ]] || touch "$cd_history_file"

    # Create or update .cd_visits
    awk '
    {
        count[$0]++;
    }
    END {
        for (dir in count) {
            print dir " " count[dir];
        }
    }' "$cd_history_file" | sort > "$cd_visits_file"

    # Remove duplicates from .cd_history while preserving the latest entry order
    tac "$cd_history_file" | awk '!seen[$0]++' | tac > "${cd_history_file}.tmp"
    mv "${cd_history_file}.tmp" "$cd_history_file"
    
    # Replace ./ with ~ in .cd_history
    replace_dot_slash_with_tilde "$cd_history_file"
}

replace_dot_slash_with_tilde() {
    local cd_history_file="$1"
    
    # Replace occurrences of './' with '~' in the file
    sed -i 's|^\./|~|g' "$cd_history_file"
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
        current_dir=""  # Log as ~ if we're in the home directory
    # If the current directory is inside the home directory, log it as an absolute path
    elif [[ "$current_dir" == "$home_dir"* ]]; then
        current_dir="$current_dir"  # Keep it as absolute path
    # If the user types `cd ~`, log it as `~`
    elif [[ "$current_dir" == "~" ]]; then
        current_dir="~"  # Log as ~ if explicitly in the home directory
    # If the directory is `./`, log as ~ (indicating current directory in home)
#    elif [[ "$current_dir" == "./" ]]; then
 #       current_dir="~"  # Log as ~ if it’s ./ (current directory)
    fi
    
        # Split the path into components
    local base_dir
    local last_dir
    base_dir=$(dirname "$current_dir")
    last_dir=$(basename "$current_dir")

    # Ensure that last directory with spaces is properly quoted
    if [[ "$last_dir" =~ \  ]]; then
        last_dir="\"$last_dir\""
    fi

    # Reconstruct the full path with quotes around the last directory if necessary
    if [[ "$current_dir" != "$base_dir/$last_dir" ]]; then
        current_dir="$base_dir/$last_dir"
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
    local dir=$(cat "$cd_history_file" | fzf --height 20 --reverse --prompt="Select directory: ")

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
