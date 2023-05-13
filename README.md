# esp-matter-dev

Dev Container for ESP Matter Workshop

There's a handy Makefile

    make clean     - Remove untracked git files
    make cleanall  - Like clean but also removes docker image
    make build     - Build the tooling container
    make run       - Run the tooling container

`make run` or the below command will run the container with 
/workspaces mounted to $PWD. You'll do your builds inside the container,
but can use the editor of your choice in your host OS. You'll
also access build artifacts from your host OS to flash them to
the ESP32C6 boards.

```
docker run -it --mount type=bind,source="$(pwd)",target=/workspaces ducksauz/esp-matter-dev:latest
```