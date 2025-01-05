cd() {
    builtin cd "$@" || return

    # Create .cd_history if it doesn't exist
    if [[ ! -f ~/.cd_history ]]; then
        touch ~/.cd_history
    fi

    # Get the current directory path
    local current_dir=$(pwd)

    # Get the home directory
    local home_dir="$HOME"

    # Check if the current directory is inside the home directory
    if [[ "$current_dir" == "$home_dir"* ]]; then
        # If the directory is inside the home directory, strip the home directory part
        current_dir="${current_dir/$home_dir/}"
    fi

    # Remove the leading / from the path
    current_dir="${current_dir#/}"

    # Split the path into components
    local base_dir
    local last_dir
    base_dir=$(dirname "$current_dir")
    last_dir=$(basename "$current_dir")

    # Escape spaces in the last directory name with backslashes
    last_dir="${last_dir// /\\ }"

    # Reconstruct the full path with escaped spaces in the last directory
    if [[ "$current_dir" != "$base_dir/$last_dir" ]]; then
        current_dir="$base_dir/$last_dir"
    fi

    # Log the current directory to .cd_history, ensuring spaces are escaped
    echo "$current_dir" >> ~/.cd_history
}


 cdl() {
    # Use fzf to list the directories exactly as they are in .cd_history
    local dir=$(cat ~/.cd_history | fzf --height 20 --reverse --prompt="Select directory: ")

    # Check if the selected directory is not empty
    if [[ "$dir" ]]; then
        # Display the cd command in the terminal
        echo "cd $dir"
        
        # Change to the selected directory
        eval "cd $dir"
    else
        echo "No directory selected."
    fi
}    
