ARG GITEA_BASE_TAG=${CIRCLE_TAG:-latest}
FROM uwebarthel/gitea-base:${GITEA_BASE_TAG}

# @see: https://gitlab.alpinelinux.org/alpine/infra/infra/-/issues/8087
# @see: https://github.com/alpinelinux/docker-alpine/issues/98
RUN sed -i 's/https/http/' /etc/apk/repositories

# Need old repo for npm et all.
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.16/main' >> /etc/apk/repositories
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.16/community' >> /etc/apk/repositories

RUN apk update

RUN apk --no-cache add asciidoctor && \
    asciidoctor --version

# @see: https://github.com/nodejs/docker-node/issues/1794
# @see: https://github.com/nodejs/docker-node/issues/1798
# @see: https://superuser.com/a/1058665
RUN apk --no-cache add 'nodejs-current<19' npm && \
    npm --version

# BBCode renderer
# @see: https://github.com/tcort/tcbbcode
RUN npm update --global --no-package-lock
RUN npm install --global --no-fund --omit=dev tcbbcode
RUN ln -snf /usr/local/lib/node_modules/tcbbcode/bin/tcbbode.js /usr/local/bin/tcbbcode && \
    chmod +x /usr/local/bin/tcbbcode

# setting DOCKER_BUILDKIT=1 in your environment
# Docker Buildx always enables BuildKit.
# @see: https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md#here-documents
RUN <<EOF cat >> /etc/templates/app.ini

; added via Dockerfile
[markup.bbcode]
ENABLED = true
FILE_EXTENSIONS = .bbcode,
RENDER_COMMAND = "/usr/local/bin/tcbbcode"
; Input is not a standard input but a file
IS_INPUT_FILE = true

; added via Dockerfile
; see: https://docs.gitea.io/en-us/external-renderers/#appini-file-configuration
[markup.asciidoc]
ENABLED = true
FILE_EXTENSIONS = .adoc,.asciidoc
RENDER_COMMAND = "asciidoctor -s -a showtitle --out-file=- -"
; Input is not a standard input but a file
IS_INPUT_FILE = false

EOF
