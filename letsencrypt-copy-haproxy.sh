#!/bin/bash
# This script accepts a domain name and the location of the HAProxy cert directory.
# It chains the cert and the private key into a temporary file, checks the cert is valid and then
# copies it into the HAProxy cert directory.
#

# load configuration
source letsencrypt-config.sh

# correct number of parameters?
if [[ $# -ne 2 ]]; then
    echo -e "${RED}usage: $0 domain-name haproxy-cert-directory${RESET}"
    exit 2
fi

# create a name for the temp directory
TEMP_FILE="/tmp/letsencrypt_copy_haproxy_$1.pem"

# create the new cert with the temporary name for validation purposes
echo -e "${BLUE}Creating cert $1.pem${RESET}"
cat ${BASE_LE_DIR}/$1/fullchain.pem ${BASE_LE_DIR}/$1/privkey.pem > $TEMP_FILE

# validate the cert via openssl
echo -e "${BLUE}Verifying cert $1.pem${YELLOW}"
$OPEN_SSL_CMD verify -CAfile ${BASE_LE_DIR}/$1/chain.pem $TEMP_FILE
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Failed to verify certificate file - installation ABORTED${RESET}"
    exit 2
fi
echo -en "$RESET"

# copy the cert into place
echo -e "${BLUE}Installing cert $1{YELLOW}"
mv -v $TEMP_FILE $2/${1}.pem
echo -en "${RESET}"

# exit messages
echo -e "${BLUE}Certificate installed successfully.${RESET}"
