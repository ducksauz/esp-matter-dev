FROM ubuntu:focal

ARG DEBIAN_FRONTEND=nointeractive

RUN : \
  && apt-get update \
  && apt install -fy --fix-missing \
    autoconf \
    automake \
    bison \
    bridge-utils \
    ccache \
    clang \
    clang-format \
    clang-tidy \
    curl \
    dfu-util \
    flex \
    g++ \
    git \
    git-lfs \
    gperf \
    hwdata \
    iproute2 \
    jq \
    lcov \
    libavahi-client-dev \
    libavahi-common-dev \
    libcairo-dev \
    libcairo2-dev \
    libdbus-1-dev \
    libdbus-glib-1-dev \
    libdmalloc-dev \
    libffi-dev \
    libgif-dev \
    libglib2.0-dev \
    libical-dev \
    libjpeg-dev \
    libmbedtls-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libnl-3-dev \
    libnl-route-3-dev \
    libnspr4-dev \
    libnuma1 \
    libpango1.0-dev \
    libpixman-1-dev \
    libreadline-dev \
    libsdl-pango-dev \
    libsdl2-dev \
    libssl-dev \
    libtool \
    libudev-dev \
    libusb-1.0-0 \
    libusb-dev \
    libxml2-dev \
    linux-tools-virtual \
    make \
    meson \
    net-tools \
    ninja-build \
    openjdk-8-jdk \
    pkg-config \
    python-is-python3 \
    python3.9 \
    python3.9-dev \
    python3.9-venv \
    rsync \
    shellcheck \
    strace \
    systemd \
    udev \
    unzip \
    wget \
    vim \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/ \
  && git lfs install \
  && : # last line

RUN : \
  && (cd /tmp \
      && wget --progress=dot:giga https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-Linux-x86_64.sh \
      && sh cmake-3.23.1-Linux-x86_64.sh --exclude-subdir --prefix=/usr/local \
      && rm -rf cmake-3.23.1-Linux-x86_64.sh) \
  && exec bash \
  && : # last line

RUN : \
  && apt-get update \
  && apt-get install -y libgirepository1.0-dev \
  && apt-get install -y software-properties-common \
  && add-apt-repository universe \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
  && python3.9 get-pip.py \
  && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 \
  && rm -rf /var/lib/apt/lists/ \
  && : # last line

RUN : \
  && pip3 install --no-cache-dir \
    attrs \
    click \
    coloredlogs \
    cxxfilt \
    flake8 \
    future \
    ghapi \
    mobly \
    pandas \
    portpicker \
    pygit \
    PyGithub \
    tabulate \
    && : # last line

RUN : \
  && git clone https://gn.googlesource.com/gn \
  && cd gn \
  && python3 build/gen.py \
  && ninja -C out \
  && cp out/gn /usr/local/bin \
  && cd .. \
  && rm -rf gn \
  && : # last line

RUN : \
  && git clone https://github.com/google/bloaty.git \
  && mkdir -p bloaty/build \
  && cd bloaty/build \
  && cmake ../ \
  && make -j8 \
  && make install \
  && cd ../.. \
  && rm -rf bloaty \
  && : # last line

RUN : \
  && apt-get update \
  && apt-get install -fy --fix-missing clang-12 libclang-12-dev \
  && git clone --depth=1 --branch=clang_12 https://github.com/include-what-you-use/include-what-you-use.git \
  && mkdir -p include-what-you-use/build \
  && cd include-what-you-use/build \
  && cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_PREFIX_PATH=/usr/lib/llvm-12 -DIWYU_LINK_CLANG_DYLIB=OFF .. \
  && make -j8 \
  && make install \
  && tar -cf clang-12-files.tar $(dpkg -L libclang-common-12-dev |grep /include) /usr/lib/llvm-12/lib/libLLVM-12.so.1 \
  && apt autopurge -fy clang-12 libclang-12-dev \
  && rm -rf /var/lib/apt/lists/ \
  && tar -xf clang-12-files.tar -C / \
  && cd ../.. \
  && rm -rf include-what-you-use \
  && : # last line

# No idea about this. Just cargo-culting from the existing espressif Dockerfile
ENV LD_LIBRARY_PATH_TSAN=/usr/lib/x86_64-linux-gnu-tsan

RUN : \
  && mkdir -p $LD_LIBRARY_PATH_TSAN \
  && export CCACHE_DISABLE=1 PYTHONDONTWRITEBYTECODE=1 \
  && GLIB_VERSION=$(pkg-config --modversion glib-2.0) \
  && git clone --depth=1 --branch=$GLIB_VERSION https://github.com/GNOME/glib.git \
  && CFLAGS="-O2 -g -fsanitize=thread" meson glib/build glib \
  && DESTDIR=../build-image ninja -C glib/build install \
  && mv glib/build-image/usr/local/lib/x86_64-linux-gnu/lib* $LD_LIBRARY_PATH_TSAN \
  && rm -rf glib \
  && : # last line

ENV CHIP_NODE_VERSION=v16.13.2

RUN : \
  && mkdir node_js \
  && cd node_js \
  && wget https://nodejs.org/dist/$CHIP_NODE_VERSION/node-$CHIP_NODE_VERSION-linux-x64.tar.xz \
  && tar xfvJ node-$CHIP_NODE_VERSION-linux-x64.tar.xz \
  && mv node-$CHIP_NODE_VERSION-linux-x64 /opt/ \
  && ln -s /opt/node-$CHIP_NODE_VERSION-linux-x64 /opt/node \
  && ln -s /opt/node/bin/* /usr/bin \
  && cd .. \
  && rm -rf node_js \
  && : # last line



# Nifty USB over IP tool. We'll see if we can make this work. Otherwise
# we can just interact with the device in the host OS
RUN update-alternatives --install /usr/local/bin/usbip usbip `ls /usr/lib/linux-tools/*/usbip | tail -n1` 20

# To build the image for a branch or a tag of IDF, pass --build-arg IDF_CLONE_BRANCH_OR_TAG=name.
# To build the image with a specific commit ID of IDF, pass --build-arg IDF_CHECKOUT_REF=commit-id.
# It is possibe to combine both, e.g.:
#   IDF_CLONE_BRANCH_OR_TAG=release/vX.Y
#   IDF_CHECKOUT_REF=<some commit on release/vX.Y branch>.
# Use IDF_CLONE_SHALLOW=1 to peform shallow clone (i.e. --depth=1 --shallow-submodules)
# Use IDF_INSTALL_TARGETS to install tools only for selected chip targets (CSV)

ARG IDF_CLONE_URL=https://github.com/espressif/esp-idf.git
ARG IDF_CLONE_BRANCH_OR_TAG=release/v5.1
ARG IDF_CHECKOUT_REF=
ARG IDF_CLONE_SHALLOW=1
ARG IDF_INSTALL_TARGETS=all

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV IDF_PATH=/opt/esp/idf
ENV IDF_TOOLS_PATH=/opt/esp/tools

RUN echo IDF_CHECKOUT_REF=$IDF_CHECKOUT_REF IDF_CLONE_BRANCH_OR_TAG=$IDF_CLONE_BRANCH_OR_TAG && \
    git clone --recursive \
      ${IDF_CLONE_SHALLOW:+--depth=1 --shallow-submodules} \
      ${IDF_CLONE_BRANCH_OR_TAG:+-b $IDF_CLONE_BRANCH_OR_TAG} \
      $IDF_CLONE_URL $IDF_PATH && \
    if [ -n "$IDF_CHECKOUT_REF" ]; then \
      cd $IDF_PATH && \
      if [ -n "$IDF_CLONE_SHALLOW" ]; then \
        git fetch origin --depth=1 --recurse-submodules ${IDF_CHECKOUT_REF}; \
      fi && \
      git checkout $IDF_CHECKOUT_REF && \
      git submodule update --init --recursive; \
    fi

# Install all the required tools
RUN : \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install required --targets=${IDF_INSTALL_TARGETS} \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install cmake \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install-python-env \
  && rm -rf $IDF_TOOLS_PATH/dist \
  && :

# Install the Matter SDK and tools
ENV ESP_MATTER_PATH=/opt/esp/esp-matter

RUN : \
  && cd /opt/esp \
  && git clone --depth 1 https://github.com/espressif/esp-matter.git \
  && cd esp-matter \
  && git submodule update --init --depth 1 \
  && cd ./connectedhomeip/connectedhomeip \
  &&  ./scripts/checkout_submodules.py --platform esp32 linux --shallow \
  && cd ../.. \
  && . $IDF_PATH/export.sh \
  &&  ./install.sh \
  && : # last line

# WORKDIR /opt/espressif/esp-matter

# Ccache is installed, enable it by default
ENV IDF_CCACHE_ENABLE=1
COPY entrypoint.sh /opt/esp/entrypoint.sh

ENTRYPOINT [ "/opt/esp/entrypoint.sh" ]
CMD [ "/bin/bash" ]



# Run the install script just for esp32c6 support
#
# Because we're customizing IDF_TOOLS_PATH we need to ensure it's set
# when the export script is run below
# ENV LC_ALL=C.UTF-8
# ENV LANG=C.UTF-8
# ENV IDF_TOOLS_PATH=/opt/esp/espressif
# RUN mkdir -p ${IDF_TOOLS_PATH} \
#   && cd /opt/esp/esp-idf \
#   && ./install.sh esp32c6

# # QEMU
# ENV QEMU_REL=esp-develop-20220919
# ENV QEMU_SHA256=f6565d3f0d1e463a63a7f81aec94cce62df662bd42fc7606de4b4418ed55f870
# ENV QEMU_DIST=qemu-${QEMU_REL}.tar.bz2
# ENV QEMU_URL=https://github.com/espressif/qemu/releases/download/${QEMU_REL}/${QEMU_DIST}

# RUN wget --no-verbose ${QEMU_URL} \
#   && echo "${QEMU_SHA256} *${QEMU_DIST}" | sha256sum --check --strict - \
#   && tar -xf $QEMU_DIST -C /opt \
#   && rm ${QEMU_DIST}

# ENV PATH=/opt/qemu/bin:${PATH}

# RUN echo "source /opt/espressif/esp-idf/export.sh > /dev/null 2>&1" >> ~/.bashrc \
#   && echo "source /opt/espressif/esp-matter/export.sh > /dev/null 2>&1" >> ~/.bashrc \
#   && echo "cd /workspaces/ > /dev/null 2>&1" >> ~/.bashrc

# ENTRYPOINT [ "/opt/esp/entrypoint.sh" ]

# CMD ["/bin/bash"]