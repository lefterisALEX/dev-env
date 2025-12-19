
############################
# Stage 1 — BUILDER
############################
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG JUST_VERSION=1.8.0
ARG EZA_VERSION=0.23.4
ARG NEOVIM_VERSION=v0.11.5
ARG STARSHIP_VERSION=v1.9.0
ARG DIRENV_VERSION=v2.32.0
ARG CHEZMOI_VERSION=v2.18.0
ARG LAZYGIT_VERSION=0.38.1
ARG RIPGREP_VERSION=13.0.0
ARG GO_VERSION=1.21.6
ARG UV_VERSION=0.9.17
ARG ZOXIDE_VERSION=0.9.8
ARG KUBECTL_VERSION=1.35.0
ARG HELM_VERSION=3.19.4
ARG STERN_VERSION=1.33.1
ARG KUBIE_VERSION=0.26.0
ARG CRANE_VERSION=0.20.7

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---- build + runtime deps ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git unzip jq tar gzip xz-utils \
    build-essential \
    python3 python3-venv python3-pip \
    nodejs npm \
    fish \
 && rm -rf /var/lib/apt/lists/*

# ---- core CLIs ----
RUN curl -L https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.zip \
    -o /tmp/eza.zip \
 && unzip -q /tmp/eza.zip -d /usr/local/bin \
 && rm /tmp/eza.zip

RUN curl -L https://github.com/sbstp/kubie/releases/download/${KUBIE_VERSION}/kubie-linux-amd64 \
    -o /usr/local/bin/kubie && chmod +x /usr/local/bin/kubie

RUN curl -LO https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
 && install -m 0755 kubectl /usr/local/bin/kubectl

RUN curl -LO https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
 && tar -xzf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
 && mv linux-amd64/helm /usr/local/bin/helm \
 && rm -rf linux-amd64 helm-v${HELM_VERSION}-linux-amd64.tar.gz

RUN curl -LO https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_amd64.tar.gz \
 && tar -xzf stern_${STERN_VERSION}_linux_amd64.tar.gz \
 && mv stern /usr/local/bin/stern \
 && rm stern_${STERN_VERSION}_linux_amd64.tar.gz

# ---- crane  ----
RUN curl -fsSL -o /tmp/crane.tar.gz \
    https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz \
 && tar -xzf /tmp/crane.tar.gz -C /tmp \
 && install -m 0755 /tmp/crane /usr/local/bin/crane \
 && rm -rf /tmp/crane /tmp/crane.tar.gz

# ---- neovim (appimage extract) ----
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.appimage \
    -o /tmp/nvim \
 && chmod +x /tmp/nvim \
 && /tmp/nvim --appimage-extract \
 && cp /squashfs-root/usr/bin/nvim /usr/local/bin/nvim \
 && mkdir -p /usr/local/share/nvim \
 && cp -r /squashfs-root/usr/share/nvim/* /usr/local/share/nvim \
 && rm -rf /squashfs-root /tmp/nvim

# ---- go ----
RUN wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz \
 && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
 && rm go${GO_VERSION}.linux-amd64.tar.gz

# ---- starship / direnv / uv ----
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y
RUN curl -fsSL https://github.com/direnv/direnv/releases/download/${DIRENV_VERSION}/direnv.linux-amd64 \
    -o /usr/local/bin/direnv && chmod +x /usr/local/bin/direnv
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh

# ---- zoxide ----
RUN curl -fsSL https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz \
 | tar -xz \
 && install -m 0755 zoxide /usr/local/bin/zoxide \
 && rm zoxide

# ---- lazygit ----
RUN curl -fsSL -o /tmp/lazygit.tar.gz \
    https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz \
 && tar -xzf /tmp/lazygit.tar.gz -C /tmp \
 && install -m 0755 /tmp/lazygit /usr/local/bin/lazygit \
 && rm -rf /tmp/lazygit /tmp/lazygit.tar.gz

# ---- chezmoi ----
RUN curl -fsSL https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION#v}/chezmoi_${CHEZMOI_VERSION#v}_linux_amd64.tar.gz \
 | tar -xz \
 && install -m 0755 chezmoi /usr/local/bin/chezmoi \
 && rm chezmoi

# ---- create dev user early ----
RUN useradd -m -s /usr/bin/fish dev
USER dev
ENV HOME=/home/dev
WORKDIR /home/dev


RUN chezmoi init https://github.com/lefterisALEX/dotfiles.git || true \
 && rm -rf ~/.local/share/chezmoi/.chezmoiscripts \
 && chezmoi apply || true

# ---- neovim plugins + treesitter (air-gapped ready) ----
RUN mkdir -p ~/.local/share/nvim/lazy
RUN git clone --filter=blob:none --depth=1 \
    https://github.com/folke/lazy.nvim.git \
    ~/.local/share/nvim/lazy/lazy.nvim

RUN nvim --headless --noplugin \
    -u NONE \
    -c "set rtp+=~/.local/share/nvim/lazy/lazy.nvim" \
    -c "lua require('lazy').setup({spec={{import='plugins'}}, install={missing=true}, checker={enabled=false}, change_detection={enabled=false}})" \
    -c "lua require('lazy').sync({wait=true})" \
    -c "quitall" || true

RUN nvim --headless -c "TSUpdateSync" -c "quitall" || true

############################
# Stage 2 — FINAL RUNTIME
############################
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git fish tmux openssh-client \
    procps jq iproute2 iputils-ping fzf bat fd-find   python3-pip  nodejs npm ripgrep\
 && rm -rf /var/lib/apt/lists/* \
 && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
 && ln -sf /usr/bin/batcat /usr/local/bin/bat \
 && rm -rf /var/lib/apt/lists/*

COPY verify-tools.sh /usr/local/bin/verify-tools
RUN chmod +x /usr/local/bin/verify-tools

# ---- user ----
RUN useradd -m -s /usr/bin/fish dev
USER dev
ENV HOME=/home/dev
WORKDIR /home/dev

# ---- paths ----
ENV PATH="/home/dev/.local/bin:/usr/local/go/bin:/usr/local/bin:${PATH}"
ENV LAZY_NO_UPDATE=1
ENV LAZY_NO_CHECK=1

# ---- copy hydrated tooling ----
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share /usr/local/share
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /home/dev /home/dev
# COPY --from=builder /usr/local/bin/lazygit /usr/local/bin/lazygit
# COPY --from=builder /usr/local/bin/crane /usr/local/bin/crane


CMD ["fish"]
