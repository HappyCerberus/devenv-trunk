TAG=20240118

docker manifest create happycerberus/devenv-trunk:latest --amend happycerberus/devenv-trunk:latest-arm64 --amend happycerberus/devenv-trunk:latest-amd64
docker manifest annotate happycerberus/devenv-trunk:latest happycerberus/devenv-trunk:latest-amd64 --arch amd64
docker manifest annotate happycerberus/devenv-trunk:latest happycerberus/devenv-trunk:latest-arm64 --arch arm64
docker manifest push happycerberus/devenv-trunk:latest

docker manifest create happycerberus/devenv-trunk:${TAG} --amend happycerberus/devenv-trunk:${TAG}-arm64 --amend happycerberus/devenv-trunk:${TAG}-amd64
docker manifest annotate happycerberus/devenv-trunk:${TAG} happycerberus/devenv-trunk:${TAG}-amd64 --arch amd64
docker manifest annotate happycerberus/devenv-trunk:${TAG} happycerberus/devenv-trunk:${TAG}-arm64 --arch arm64
docker manifest push happycerberus/devenv-trunk:${TAG}