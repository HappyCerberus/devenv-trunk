FROM buildpack-deps:bookworm
ENV GCC_VERSION 14.0.0
ARG TARGETARCH
ENV GCC_GIT=26a7e775a20aeea7eff620e03cd5504c4eb9d48e

# Building GCC from sources
RUN set -ex; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends dpkg-dev flex gnupg; \
    rm -r /var/lib/apt/lists/*; \
    curl -fL https://github.com/gcc-mirror/gcc/archive/$GCC_GIT.zip -o gcc.zip; \
    mkdir -p /usr/src; \
    unzip gcc.zip -d /usr/src; \
    mv /usr/src/gcc-$GCC_GIT /usr/src/gcc; \
    rm gcc.zip; \
    cd /usr/src/gcc; \
    ./contrib/download_prerequisites; \
    { rm *.tar.* || true; }; \
    for f in config.guess config.sub; do \
        wget -O "$f" "https://git.savannah.gnu.org/cgit/config.git/plain/$f?id=7d3d27baf8107b630586c962c057e22149653deb"; \
        find -mindepth 2 -name "$f" -exec cp -v "$f" '{}' ';'; \
    done; \
    dir="$(mktemp -d)"; \
    cd "$dir"; \
    extraConfigureArgs=''; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "$dpkgArch" in \
		armel) \
			extraConfigureArgs="$extraConfigureArgs --with-arch=armv5te --with-float=soft" \
			;; \
		armhf) \
			extraConfigureArgs="$extraConfigureArgs --with-arch=armv7-a+fp --with-float=hard --with-mode=thumb" \
			;; \
		\
		i386) \
			extraConfigureArgs="$extraConfigureArgs --with-arch-32=i686"; \
			;; \
	esac; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    /usr/src/gcc/configure --build="$gnuArch" --disable-multilib --enable-languages=c,c++ $extraConfigureArgs; \
    make -j "$(nproc)"; \
    make install-strip; \
    cd ..; \
    rm -rf "$dir" /usr/src/gcc; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# gcc installs .so files in /usr/local/lib64 (and /usr/local/lib)...
RUN set -ex; \
# this filename needs to sort higher than all the architecture filenames ("aarch64-...", "armeabi...", etc)
	{ echo '/usr/local/lib64'; echo '/usr/local/lib'; } > /etc/ld.so.conf.d/000-local-lib.conf; \
    ldconfig -v; \
    # the libc created by gcc might be too old for a newer Debian
	# check that the Debian libstdc++ doesn't have newer requirements than the gcc one
	bash -Eeuo pipefail -xc ' \
		deb="$(strings /usr/lib/*/libstdc++.so* | grep "^GLIBC" | sort -u)"; \
		gcc="$(strings /usr/local/lib*/libstdc++.so | grep "^GLIBC" | sort -u)"; \
		diff="$(comm -23 <(cat <<<"$deb") <(cat <<<"$gcc"))"; \
		test -z "$diff"; \
	'

# ensure that alternatives are pointing to the new compiler and that old one is no longer used
RUN set -ex; \
	dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc; \
	dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++; \
	update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999

# Building CMake from sources
RUN set -ex; \
    curl -fL https://gitlab.kitware.com/cmake/cmake/-/archive/master/cmake-master.zip -o cmake.zip; \
    unzip cmake.zip -d /usr/src; \
    rm cmake.zip; \
    cd /usr/src/cmake-master; \
    ./bootstrap && make && make install; \
    rm -rf /usr/src/cmake-master

# Ninja build (required for C++20 modules with CMake)
RUN set -ex &&\
    apt-get update &&\
    apt-get install -y ninja-build


ENV CC=/usr/local/bin/gcc
RUN set -ex &&\
    apt-get update &&\
    apt-get install -y python3-dev &&\
    curl -fL https://ftp.gnu.org/gnu/gdb/gdb-13.2.tar.gz -o gdb-13.2.tar.gz && \
	tar -xf gdb-13.2.tar.gz -C /tmp && rm gdb-13.2.tar.gz && \
	cd /tmp/gdb-13.2 && \
	./configure --prefix=/usr/local --enable-tui --with-python && make && make install && \
	rm -rf /tmp/gdb-13.2

# Go (required for bazel)
RUN curl -fL https://go.dev/dl/go1.21.0.linux-${TARGETARCH}.tar.gz -o go1.21.0.linux-${TARGETARCH}.tar.gz && \
    tar -xf go1.21.0.linux-${TARGETARCH}.tar.gz -C /usr/local && \
    rm go1.21.0.linux-${TARGETARCH}.tar.gz

# Bazel
ENV PATH="${PATH}:/usr/local/go/bin"
RUN set -ex && \
    GOBIN=/usr/local/go/bin go install github.com/bazelbuild/bazelisk@latest && \
    GOBIN=/usr/local/go/bin go install github.com/bazelbuild/buildtools/buildifier@latest && \
    ln -s /usr/local/go/bin/bazelisk /usr/local/bin/bazel

# LLVM
RUN set -ex &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends lsb-release  wget software-properties-common gnupg &&\
    curl -fL https://apt.llvm.org/llvm.sh -o llvm.sh &&\
    chmod +x llvm.sh &&\
    ./llvm.sh 17 all || echo ""

# For whatever reason we have to manually update and run the llvm script again.
RUN set -ex &&\
    apt-get update &&\
    ./llvm.sh 17 all

# Make GDB avoid security checks and autoload the python pretty-printing
RUN mkdir -p /root/.config/gdb &&\
    echo "set auto-load safe-path /" >/root/.config/gdb/gdbinit
