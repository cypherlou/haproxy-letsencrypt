# general purpose definitions - mostly from pretty logging
RESET="\e[39m"
RED="\e[31m"
LRED="\e[91m"
YELLOW="\e[33m"
BLUE="\e[94m"

# config used by letsencrypt-new.sh
# post to start letsencrypt on. Note this needs to match up with the HAProxy configuration you have used.
BASE_PORT=9999
LETS_ENCRYPT_DIR="/usr/local/bin/letsencrypt"
CERT_CMD="${LETS_ENCRYPT_DIR}/letsencrypt-auto certonly --standalone --preferred-challenges http --http-01-port ${BASE_PORT} --renew-by-default --agree-tos --quiet --non-interactive"
INSTALL_CMD="${BASE_DIR}/letsencrypt-copy-haproxy.sh"
CERT_DIR="/etc/letsencrypt/live/"
HAPROXY_CERT_DIR="/etc/haproxy/certs"

# config used by letsencrypt-copy-haproxy.sh
BASE_LE_DIR="/etc/letsencrypt/live"
OPEN_SSL_CMD="/usr/bin/openssl"

# config used by
CERT_RENEW_CMD="${LETS_ENCRYPT_DIR}/letsencrypt-auto renew --standalone --preferred-challenges http --http-01-port ${BASE_PORT} --agree-tos --non-interactive"
