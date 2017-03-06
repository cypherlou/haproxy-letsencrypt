# Dump the domains in a given cert

# configuration
if [ "$(which realname)" == "" ]; then
    dir=$(dirname $0)
    if [ ${dir:0:1} == '.' ]; then
        dir="$(pwd)/${dir}"
    fi
    BASE_DIR=$dir
else
    BASE_DIR=$(dirname $(realpath $0) )
fi
source ${BASE_DIR}/letsencrypt-config.sh

# correct number of parameters?
if [[ $# -ne 1 ]]; then
    echo -e "${RED}usage: $0$ domain-name${RESET}"
    exit 2
fi

# location of cert file based on naming convention
domain=$1
cert_file="${HAPROXY_CERT_DIR}/${domain}.pem"

# check is the cert file exists
if [ -f "${cert_file}" ]; then
    # output the location
    echo -e "${BLUE}Certificates in ${cert_file};${YELLOW}"
    # and then the certs
    for x in $( ${OPEN_SSL_CMD} x509 -in ${cert_file} -text -noout | grep DNS ) ; do echo $x | cut -d, -f 1 | cut -d: -f2 ; done
    # set the shell colour back
    echo -en "${RESET}"
    exit 1
else
    echo -e "${RED}No cert file found for domain ${BLUE}${domain}${RED} found in the haproxy cert directory.${RESET}"
    exit 2
fi
