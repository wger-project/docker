FROM postgres:15-bookworm AS builder

ENV VERSION=1.12

RUN apt-get update && \
    apt-get install -y \
        git \
        build-essential \
        postgresql-server-dev-15

WORKDIR /tmp
RUN git clone -b v${VERSION} https://github.com/sraoss/pg_ivm.git

WORKDIR /tmp/pg_ivm
RUN make

# Create the final image
FROM postgres:15-bookworm

COPY --from=builder /tmp/pg_ivm/pg_ivm*.sql /usr/share/postgresql/15/extension
COPY --from=builder /tmp/pg_ivm/pg_ivm.control /usr/share/postgresql/15/extension
COPY --from=builder /tmp/pg_ivm/pg_ivm.so /usr/lib/postgresql/15/lib

EXPOSE 5432