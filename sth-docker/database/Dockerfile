FROM postgres:${POSTGRES_VERSION:-18}

# Copy initialization SQL
COPY ./init/*.sql /docker-entrypoint-initdb.d/
RUN chmod 755 /docker-entrypoint-initdb.d/*.sql

COPY ./init/*.sh /docker-entrypoint-initdb.d/
RUN chmod 755 /docker-entrypoint-initdb.d/*.sh

COPY ./init/*.dump /docker-entrypoint-initdb.d/

# Keep defaults
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]