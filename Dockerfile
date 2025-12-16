FROM ubuntu:25.10

ARG JUST_VERSION="1.8.0"
ARG EZA_VERSION="0.23.4"
ARG NEOVIM_VERSION="v0.11.5"
ARG STARSHIP_VERSION="v1.9.0"
ARG DIRENV_VERSION="v2.32.0"
ARG CHEZMOI_VERSION="v2.18.0"
ARG LAZYGIT_VERSION="v0.38.1"
ARG RIPGREP_VERSION="13.0.0"
ARG GO_VERSION="1.21.6"
ARG UV_VERSION="0.9.17"
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Core packages with apt
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git unzip lsb-release gnupg apt-transport-https \
    procps jq tar gzip xz-utils build-essential python3 python3-venv python3-pip \
    pipx nodejs npm fish tmux openssh-client gpg software-properties-common iputils-ping iproute2 fzf bat lazygit fd-find \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# install docker-cli
RUN  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install eza
RUN curl -L -o /tmp/eza.zip https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.zip \
 && unzip -q /tmp/eza.zip -d /usr/local/bin \
 && chmod +x /usr/local/bin/eza \
 && rm /tmp/eza.zip

# Install chezmoi 
RUN set -eux; \
    CV="${CHEZMOI_VERSION}"; \
    if [ "$CV" = "latest" ] || [ "$CV" = "LATEST" ]; then \
      TAG="$(curl -sSfL https://api.github.com/repos/twpayne/chezmoi/releases/latest | jq -r '.tag_name')"; \
    else \
      TAG="v${CV#v}"; \
    fi; \
    ASSET="chezmoi_${TAG#v}_linux_amd64.tar.gz"; \
    URL="https://github.com/twpayne/chezmoi/releases/download/${TAG}/${ASSET}"; \
    tmpdir=$(mktemp -d); \
    curl -fsSL -o "${tmpdir}/chezmoi.tar.gz" "${URL}"; \
    tar -xzf "${tmpdir}/chezmoi.tar.gz" -C "${tmpdir}"; \
    mv "${tmpdir}/chezmoi" /usr/local/bin/chezmoi && chmod +x /usr/local/bin/chezmoi; \
    rm -rf "${tmpdir}"

# Install starship
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# Install neovim 
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.appimage -o /tmp/nvim \
 && chmod +x /tmp/nvim \
 && /tmp/nvim --appimage-extract \
 && cp /squashfs-root/usr/bin/nvim /usr/local/bin/nvim \
 && mkdir -p /usr/local/share/nvim \
 && cp -r /squashfs-root/usr/share/nvim/* /usr/local/share/nvim/ \
 && rm -rf /squashfs-root /tmp/nvim

# Install direnv
RUN curl -fsSL https://github.com/direnv/direnv/releases/download/${DIRENV_VERSION}/direnv.linux-386 -o /usr/local/bin/direnv \
 && chmod +x /usr/local/bin/direnv

# Install go
RUN wget https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz \
    && rm go$GO_VERSION.linux-amd64.tar.gz 

# Create non-root user 'dev'
RUN useradd -m -s /usr/bin/fish dev \
 && mkdir -p /home/dev/.local/bin /home/dev/.local/pipx \
 && chown -R dev:dev /home/dev \
 && groupadd docker \
 && usermod -aG docker dev

USER dev
ENV HOME=/home/dev
WORKDIR /home/dev
ENV PATH="/home/dev/.local/bin:/usr/local/cargo/bin:/usr/local/go/bin:/go/bin:/usr/local/bin:${PATH}"
ENV PIPX_HOME=/home/dev/.local/pipx
ENV PIPX_BIN_DIR=/home/dev/.local/bin

# Install zoxide
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Install uv
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh

# Initialize  and apply chezmoi
RUN /usr/local/bin/chezmoi init https://github.com/lefterisALEX/dotfiles.git 2>/dev/null || true \
 && rm -rf /home/dev/.local/share/chezmoi/.chezmoiscripts \
 && /usr/local/bin/chezmoi apply || true

# Setup nvim
RUN mkdir -p /home/dev/.local/share/nvim/lazy \
    /home/dev/.local/state/nvim \
    /home/dev/.cache/nvim

# Clone lazy.nvim
RUN git clone --filter=blob:none --depth=1 \
    https://github.com/folke/lazy.nvim.git \
    --branch=stable \
    /home/dev/.local/share/nvim/lazy/lazy.nvim

# Install neovim plugins 
RUN nvim --headless --noplugin \
    -u NONE \
    -c "set rtp+=/home/dev/.local/share/nvim/lazy/lazy.nvim" \
    -c "lua require('lazy').setup({spec={{import='plugins'}}, install={missing=true}, ui={border='none'}, checker={enabled=false}, change_detection={enabled=false}})" \
    -c "lua require('lazy').sync({wait=true})" \
    -c "quitall" 2>&1 || true

# Install treesitter parsers
RUN nvim --headless \
    -c "TSUpdateSync" \
    -c "quitall" 2>&1 || true

# Disable plugin updates at runtime
ENV LAZY_NO_UPDATE=1
ENV LAZY_NO_CHECK=1

# Final directory setup
RUN mkdir -p /home/dev/bin

CMD ["fish"]
