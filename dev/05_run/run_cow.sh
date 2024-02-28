#!/bin/bash


# Function to display usage information
display_usage() {
    echo "Usage: $0 [-tag <docker_image_tag>] "
    echo "  -cow_tag <docker_image_tag> : The tag of the cow docker image to use. Default is 'latest' "
    echo "  -cow_port <port> : The port to use for the cow container. Default is 9998 "
}

# Function to handle cleanup when script is interrupted
cleanup() {
    echo "Stopping the Docker container cow..."
    docker stop cow >/dev/null 2>&1
    docker rm cow >/dev/null 2>&1
    echo "Script interrupted. Exiting..."
    exit 1
}

# Trap SIGINT (Ctrl+C) and call the cleanup function
trap cleanup SIGINT

# Check for optional parameter
cow_docker_image_tag="latest"
cow_port=9998

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
    -cow_tag)
        shift
        if [ $# -gt 0 ]; then
            cow_docker_image_tag=$1
        else
            display_usage
            exit 1
        fi
        ;;
    -cow_port)
        shift
        if [ $# -gt 0 ]; then
            cow_port=$1
        else
            display_usage
            exit 1
        fi
        ;;
    *)
        # Unknown option
        display_usage
        exit 1
        ;;
    esac
    shift
done



# update images
docker pull eu.gcr.io/finngen-sandbox-v3-containers/cow:$docker_image_tag

# Stop and remove the existing container, if it exists
docker stop cow >/dev/null 2>&1
docker rm cow >/dev/null 2>&1

# Start the Docker container
docker run -d -p $cow_port:8888 -v /tmp:/tmp  \
    --name cow  \
    eu.gcr.io/finngen-sandbox-v3-containers/cow:$cow_docker_image_tag

# Check if the container was started successfully
if [ $? -ne 0 ]; then
    echo "Failed to run the Docker containers."
    exit 1
fi

echo "Docker image pulled and container started successfully."

# Show container logs continuously
echo "Container logs:"
docker logs -f cow &

# open the browser
firefox http://localhost:$cow_port &

# Wait indefinitely (or until interrupted) to keep the script running
echo "Press Ctrl+C to stop the Docker container and exit."
while true; do
    sleep 1
done

