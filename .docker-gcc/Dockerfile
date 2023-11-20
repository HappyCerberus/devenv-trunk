FROM buildpack-deps:bookworm
ENV GCC_VERSION 14.0.0
ARG TARGETARCH

# Building GCC from sources
RUN set -ex; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends dpkg-dev flex gnupg; \
    rm -r /var/lib/apt/lists/*; \
    curl -fL https://github.com/gcc-mirror/gcc/archive/refs/heads/master.zip -o gcc.zip; \
    mkdir -p /usr/src; \
    unzip gcc.zip -d /usr/src; \
    mv /usr/src/gcc-master /usr/src/gcc; \
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