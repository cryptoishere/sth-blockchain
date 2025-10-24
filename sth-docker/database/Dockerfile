FROM postgres:${POSTGRES_VERSION:-18}

# Copy initialization SQL
COPY ./init/*.sql /docker-entrypoint-initdb.d/
RUN chmod 755 /docker-entrypoint-initdb.d/*.sql

# Keep defaults
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]