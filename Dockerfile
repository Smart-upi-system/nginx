# ── Nginx reverse proxy for the UPI microservices stack ─────────────────
# Single public entry point in front of the api-gateway (port 4000).
# All backend services stay internal on the docker network.

FROM nginx:alpine

# Remove the stock default site so only our nginx.conf is used
RUN rm -f /etc/nginx/conf.d/default.conf

# Our full configuration (events + http blocks)
COPY nginx.conf /etc/nginx/nginx.conf

# NOTE: config is NOT tested here with `nginx -t`. The upstream uses the
# Docker DNS name api-gateway:4000, which only resolves at runtime (once the
# container joins the internal network). nginx validates the config on startup
# anyway and exits loudly if it's wrong.

EXPOSE 8080

# Healthcheck must target 127.0.0.1, not localhost: nginx's `listen 8080` binds
# IPv4 only, but /etc/hosts maps localhost to ::1 first, and busybox wget does not
# fall back to IPv4 — so `localhost` gets "Connection refused" even when nginx is up.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/health >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
