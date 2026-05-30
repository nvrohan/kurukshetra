# Kurukshetra dedicated-server image.
#
# Multi-stage build:
#   1. builder — fetches Godot 4.3 + export templates, runs tools/build-server.sh
#      to produce a stripped headless server binary with embedded PCK.
#   2. runner  — minimal Debian slim with the tiny set of runtime libs Godot's
#      headless build still links against. Exposes UDP 30000 and runs the
#      server as a non-root user.
#
# Every command in this file mirrors a step that has been validated on the
# build VM (~/kurukshetra/tools/build-server.sh actually runs and produces a
# working binary; see commit message and STATUS.md for D4 verification).
#
# Build:    docker build -t kurukshetra-server:dev .
# Run:      docker run --rm -p 30000:30000/udp kurukshetra-server:dev
# Healthy?  docker logs <container>  → expect "[NetworkManager] dedicated
#           server up on port 30000".
#
# Image size target: < 200 MB (server bin ~64 MiB + slim base).
# License: MIT (project), Godot binary is MIT, export templates are MIT.

# --- builder stage --------------------------------------------------------
FROM debian:bookworm-slim AS builder

ARG GODOT_VERSION=4.3
ARG GODOT_RELEASE=stable

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

# Download Godot headless binary + export templates pinned to GODOT_VERSION.
WORKDIR /opt/godot
RUN curl -fsSL -o godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip" \
 && unzip -q godot.zip \
 && mv "Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64" /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm godot.zip

RUN mkdir -p "/root/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}" \
 && curl -fsSL -o templates.tpz \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz" \
 && unzip -q templates.tpz \
 && mv templates/* "/root/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}/" \
 && rm -rf templates templates.tpz

# Copy project & build the dedicated-server binary.
WORKDIR /src
COPY . /src
ENV GODOT=/usr/local/bin/godot
RUN bash tools/build-server.sh \
 && ls -lh build/server/kurukshetra-server.x86_64

# --- runner stage ---------------------------------------------------------
FROM debian:bookworm-slim AS runner

# Godot headless still links against a few X libs even with --headless export
# (DisplayServer init paths). libfontconfig is for system font enumeration.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libfontconfig1 \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -r kurukshetra \
 && useradd -r -g kurukshetra -d /opt/kurukshetra -s /usr/sbin/nologin kurukshetra \
 && mkdir -p /opt/kurukshetra \
 && chown kurukshetra:kurukshetra /opt/kurukshetra

COPY --from=builder --chown=kurukshetra:kurukshetra \
     /src/build/server/kurukshetra-server.x86_64 \
     /opt/kurukshetra/kurukshetra-server

USER kurukshetra
WORKDIR /opt/kurukshetra

# ENet UDP. ARCHITECTURE.md §6.4. PORT_BASE=30000.
EXPOSE 30000/udp

# Default 30s tolerance for the server to bind & start the match scene.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD pgrep -x kurukshetra-serv >/dev/null || exit 1

ENTRYPOINT ["./kurukshetra-server", "--headless", "--", "--server"]
