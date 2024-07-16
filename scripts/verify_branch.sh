#!/bin/bash
# Script to verify changes are on the correct branch
# only applies to branches that start with develop-

# Get the current branch name
get_branch_name() {
  # First try to get the branch name using the simplest command
  branch_name=$(git rev-parse --abbrev-ref HEAD)

  # Check if the result is 'HEAD', which means it's in a detached HEAD state
  if [ "$branch_name" = "HEAD" ]; then
    # Since we're in a detached HEAD state, fetch the branches and find the correct one
    git fetch --depth=1 origin +refs/heads/*:refs/remotes/origin/*

    # Attempt to find a branch from the remotes that points to the current commit
    branch_name=$(git branch -r --contains HEAD | grep -v HEAD | sed -n 's|origin/||p' | head -n 1)
  fi

  echo "$branch_name"
}

# Get the branch name using the function
branch_name=$(get_branch_name)

# Echo the branch name
echo "branch_name: $branch_name"
echo "files: $@"
# Check if the branch name does not start with 'develop-'
if [[ ! "$branch_name" =~ ^develop- ]]; then
    echo "This script only processes branches starting with 'develop-'. Exiting..."
    exit 0
fi

# Strip 'develop-' from the branch name
branch_name=${branch_name#develop-}

echo "Processed branch_name: $branch_name"

# Define base file pattern based on branch name
if [[ "$branch_name" == "standard" ]]; then
    base_pattern="standard_schema"
else
    base_pattern="library_schemas/${branch_name}/"
fi

# Define the second pattern by appending 'prerelease' to the base pattern
file_pattern="${base_pattern}prerelease/"

# Check if the file paths start with the defined pattern for specified extensions
for file in "$@"; do  # "$@" will contain the list of modified files passed by pre-commit
    extension="${file##*.}"
    # Check files based on their extension
    if [[ "$extension" == "xml" || "$extension" == "mediawiki" || "$extension" == "tsv" ]]; then
        if [[ "$file" != "$file_pattern"* ]]; then
            error_message+="Error: '$file' with extension .$extension should start with '$file_pattern'\n"
        fi
    else
        # Allow other files to be modified anywhere under the base pattern directory
        if [[ "$file" != "$base_pattern"* ]]; then
            error_message+="Error: '$file' should not be modified on this branch.  Only files under '$base_pattern' directory\n"
        fi
    fi
done

# Print all accumulated errors and exit if there were any
if [[ -n "$error_message" ]]; then
    echo -e "$error_message"
    exit 1
fi