ARG PROJECT_BASE
ARG THEIA_BASE
FROM $PROJECT_BASE as base
# Final Image
FROM $THEIA_BASE

COPY --from=base --chown=nuxeo:nuxeo /docker-entrypoint.sh /
COPY --from=base --chown=nuxeo:nuxeo /docker-entrypoint-init.d /docker-entrypoint-init.d/

USER nuxeo:nuxeo

COPY 99-start-ide.sh /docker-entrypoint-init.d/
ENTRYPOINT ["/docker-entrypoint.sh"]
