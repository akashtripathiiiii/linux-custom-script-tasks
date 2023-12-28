#!/bin/bash

USER_DATA_FILE="/etc/passwd"
SUDOERS_FILE="/etc/sudoers"

function create_user() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a username."
        exit 1
    fi

    username=$1

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "Error: User '$username' already exists."
        exit 1
    fi

    useradd -m "$username"

    echo "User '$username' created successfully."
}

function list_users() {
    if [ "$1" == "--sudo-only" ]; then
        grep -E '^\w+:\w+:.*sudo' "$USER_DATA_FILE" | cut -d: -f1
    else
        cut -d: -f1 "$USER_DATA_FILE"
    fi
}

# Function to display help information for CPU and Memory
display_cpu_memory_help() {
    echo "Usage: internsctl [options]"
    echo "Options:"
    echo "  cpu getinfo      Display CPU information (similar to 'lscpu')"
    echo "  memory getinfo   Display memory information (similar to 'free')"
}

display_file_help() {
    echo "Usage: internsctl file getinfo [options] <file-name>"
    echo "Options:"
    echo "  --size, -s           Print file size"
    echo "  --permissions, -p   Print file permissions"
    echo "  --owner, -o         Print file owner"
    echo "  --last-modified, -m Print last modified time"
    echo "  --help              Display this help message"
}

get_cpu_info() {
    lscpu
}

get_memory_info() {
    free -h
}

get_file_info() {
    file=$1
    size=$(stat -c%s "$file")
    permissions=$(stat -c%a "$file")
    owner=$(stat -c%U "$file")
    last_modified=$(stat -c%y "$file")

    echo "File: $file"
    
    if [ "$print_size" = true ]; then
        echo "Size(B): $size"
    fi

    if [ "$print_permissions" = true ]; then
        echo "Access: $permissions"
    fi

    if [ "$print_owner" = true ]; then
        echo "Owner: $owner"
    fi

    if [ "$print_last_modified" = true ]; then
        echo "Modify: $last_modified"
    fi
}

# Check for command-line arguments
if [[ "$#" -eq 0 ]]; then
    echo "Error: Missing command-line arguments. Use 'internsctl --help' for usage information."
    exit 1
fi

case "$1" in
    user)
        shift
        case "$1" in
            create)
                shift
                create_user "$1"
                ;;
            list)
                shift
                list_users "$1"
                ;;
            *)
                echo "Error: Invalid user subcommand."
                exit 1
                ;;
        esac
        ;;
    cpu)
        case "$2" in
            getinfo)
                get_cpu_info
                ;;
            *)
                echo "Error: Unknown subcommand for 'cpu'. Use 'internsctl cpu getinfo' for CPU information."
                exit 1
                ;;
        esac
        ;;
    memory)
        case "$2" in
            getinfo)
                get_memory_info
                ;;
            *)
                echo "Error: Unknown subcommand for 'memory'. Use 'internsctl memory getinfo' for memory information."
                exit 1
                ;;
        esac
        ;;
    file)
        case "$2" in
            getinfo)
                shift # consume 'getinfo' argument
                while [[ "$#" -gt 0 ]]; do
                    case "$1" in
                        --size|-s)
                            print_size=true
                            ;;
                        --permissions|-p)
                            print_permissions=true
                            ;;
                        --owner|-o)
                            print_owner=true
                            ;;
                        --last-modified|-m)
                            print_last_modified=true
                            ;;
                        --help)
                            display_file_help
                            exit 0
                            ;;
                        *)
                            file="$1"
                            ;;
                    esac
                    shift
                done

                if [ -z "$file" ]; then
                    echo "Error: Missing file name. Use 'internsctl file getinfo --help' for usage information."
                    exit 1
                fi

                # Get file information
                get_file_info "$file"
                ;;
            *)
                echo "Error: Unknown subcommand for 'file'. Use 'internsctl file getinfo' for file information."
                exit 1
                ;;
        esac
        ;;
    --help)
        display_cpu_memory_help
        display_file_help
        ;;
    *)
        echo "Error: Unknown option. Use 'internsctl --help' for usage information."
        exit 1
        ;;
esac
