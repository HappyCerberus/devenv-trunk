TAG=20240118
docker buildx build --no-cache --push --platform linux/arm64 --tag happycerberus/devenv-trunk:latest-arm64 --tag happycerberus/devenv-trunk:${TAG}-arm64 .