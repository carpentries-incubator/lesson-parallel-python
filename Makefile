.PHONY: docker

podman:
	podman build -t sandpaper -f ./Dockerfile
	podman run -it --replace --name efficient-julia -v $$(pwd):/lesson --security-opt label=disable --network=host sandpaper
