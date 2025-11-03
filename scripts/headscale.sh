#!/bin/bash
# Headscale Helper Script

set -e

CONTAINER_NAME="headscale"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if container is running
check_container() {
    if ! docker ps | grep -q $CONTAINER_NAME; then
        echo -e "${RED}Error: Headscale container is not running${NC}"
        exit 1
    fi
}

# Print usage
usage() {
    cat << EOF
Headscale Management Script

Usage: $0 <command> [arguments]

Commands:
    users list                              List all users
    users create <username>                 Create a new user
    users destroy <username>                Delete a user

    nodes list                              List all nodes
    nodes delete <node-id>                  Delete a node
    nodes expire                            Expire all offline nodes

    keys list <username>                    List pre-auth keys for user
    keys create <username> [options]        Create a new pre-auth key
        Options:
            --reusable                      Key can be used multiple times
            --ephemeral                     Node will be removed when disconnected
            --expiration <duration>         Key expiration (e.g., 24h, 7d)

    routes list                             List all routes
    routes enable <route-id>                Enable a route

    status                                  Show Headscale status
    health                                  Check Headscale health
    logs [lines]                            Show Headscale logs (default: 50 lines)

Examples:
    $0 users create myuser
    $0 keys create myuser --reusable --expiration 24h
    $0 nodes list
    $0 logs 100

EOF
}

# Execute headscale command
headscale() {
    docker exec $CONTAINER_NAME headscale "$@"
}

# Main command handler
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    case "$1" in
        users)
            check_container
            shift
            case "$1" in
                list)
                    headscale users list
                    ;;
                create)
                    if [ -z "$2" ]; then
                        echo -e "${RED}Error: Username required${NC}"
                        exit 1
                    fi
                    headscale users create "$2"
                    echo -e "${GREEN}User '$2' created successfully${NC}"
                    ;;
                destroy)
                    if [ -z "$2" ]; then
                        echo -e "${RED}Error: Username required${NC}"
                        exit 1
                    fi
                    echo -e "${YELLOW}Warning: This will delete user '$2' and all associated data${NC}"
                    read -p "Are you sure? (yes/no): " confirm
                    if [ "$confirm" = "yes" ]; then
                        headscale users destroy "$2"
                        echo -e "${GREEN}User '$2' destroyed${NC}"
                    else
                        echo "Cancelled"
                    fi
                    ;;
                *)
                    echo -e "${RED}Unknown users command: $1${NC}"
                    usage
                    exit 1
                    ;;
            esac
            ;;

        nodes)
            check_container
            shift
            case "$1" in
                list)
                    headscale nodes list
                    ;;
                delete)
                    if [ -z "$2" ]; then
                        echo -e "${RED}Error: Node ID required${NC}"
                        exit 1
                    fi
                    headscale nodes delete --identifier "$2"
                    echo -e "${GREEN}Node deleted${NC}"
                    ;;
                expire)
                    headscale nodes expire --all-offline
                    echo -e "${GREEN}Expired all offline nodes${NC}"
                    ;;
                *)
                    echo -e "${RED}Unknown nodes command: $1${NC}"
                    usage
                    exit 1
                    ;;
            esac
            ;;

        keys)
            check_container
            shift
            case "$1" in
                list)
                    if [ -z "$2" ]; then
                        echo -e "${RED}Error: Username required${NC}"
                        exit 1
                    fi
                    headscale preauthkeys list --user "$2"
                    ;;
                create)
                    if [ -z "$2" ]; then
                        echo -e "${RED}Error: Username required${NC}"
                        exit 1
                    fi
                    username="$2"
                    shift 2
                    headscale preauthkeys create --user "$username" "$@"
                    ;;
                *)
                    echo -e "${RED}Unknown keys command: $1${NC}"
                    usage
                    exit 1
                    ;;
            esac
            ;;

        routes)
            check_container
            shift
            case "$1" in
                list)
                    headscale routes list
                    ;;
                enable)
                    if [ -z "$2" ]; then
                        echo -e "${RED}Error: Route ID required${NC}"
                        exit 1
                    fi
                    headscale routes enable --route-id "$2"
                    echo -e "${GREEN}Route enabled${NC}"
                    ;;
                *)
                    echo -e "${RED}Unknown routes command: $1${NC}"
                    usage
                    exit 1
                    ;;
            esac
            ;;

        status)
            check_container
            echo -e "${GREEN}Docker Container Status:${NC}"
            docker ps | grep -E "(CONTAINER|$CONTAINER_NAME|nginx|postgres)"
            ;;

        health)
            check_container
            echo "Checking Headscale health..."
            docker exec $CONTAINER_NAME wget -q -O - http://localhost:8080/health
            echo ""
            ;;

        logs)
            lines=${2:-50}
            docker compose logs --tail=$lines -f headscale
            ;;

        help|--help|-h)
            usage
            ;;

        *)
            echo -e "${RED}Unknown command: $1${NC}"
            usage
            exit 1
            ;;
    esac
}

main "$@"
