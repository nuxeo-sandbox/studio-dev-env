ARG DEV_BASE
FROM $DEV_BASE

WORKDIR /home/nuxeo/workspace

COPY docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
USER nuxeo:nuxeo
