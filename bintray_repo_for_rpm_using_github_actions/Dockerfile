FROM alpine:latest

LABEL "com.github.actions.name"="git-commit-push-packages"
LABEL "com.github.actions.description"="Git commit pushes packages to bintray repo after creating new version"
LABEL "com.github.actions.icon"="check-square"
LABEL "com.github.actions.color"="yellow"

RUN apk add --no-cache \
    jq \
    curl \
    git

COPY "entrypoint.sh" /usr/bin/entrypoint

CMD ["sh", "/usr/bin/entrypoint"]