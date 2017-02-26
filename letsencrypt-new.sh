#!/bin/bash
# makes letsencrypt requests for the list of space separated domains and then copies them to the HAProxy cert directory.
# These scripts assume;
#    1. the are in the same directory.
#    2. the HAProxy certs directory is /etc/haproxy/certs. Update HAPROXY_CERT_DIR orherwise.
#    3. The letsencrypt installation is at /usr/local/bin/letsencrypt. Update LETS_ENCRYPT_DIR to the directory holding your
#       letsencrypt installation (git clone https://github.com/letsencrypt/letsencrypt)
#    4. the script is running under sudo
#    5. that the openssl binary is at /usr/bin/openssl. Update OPEN_SSL_CMD in letsencrypt-copy-haproxy.sh otherwise.
#
# NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE
# This script will install all certs known to this installation's Let's Encrypt configuration. This means it will
# installation the current request and any others that exist on the system.
# NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE * NOTE

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
if [[ $# -lt 1 ]]; then
    echo -e "${RED}usage: $0 domain-name [ domain-name ...]${RESET}"
    exit 2
fi

# prep the configuration
echo -e "${BLUE}domains to process: $#${RESET}"
DOMAINS=$(expr $# - 1 )
DOMAIN_LIST=""

# build a list of domain names to be created/renewed
DOMAIN_LIST_U=$( echo $* | tr " " "\n" | awk '{ print length, $0 }' | sort -n | cut -d" " -f2- )
for d in $DOMAIN_LIST_U; do
    echo -e "\t${BLUE}adding${LRED} ${d}${RESET}"
    DOMAIN_LIST+=" -d $d"
done

# output some guidance information
CERT_START=$(date +%s)
echo -e "${BLUE}Executing letsencrypt command${RESET}"
echo -en "${YELLOW}"
${CERT_CMD} $DOMAIN_LIST
if [[ $? -ne 0 ]]; then
    echo -e "${LRED}The cert request process has failed, aborting${RESET}"
    exit 2
fi

# helper message related to processing time
CERT_AGE=$( expr $(date +%s) - $CERT_START )
echo -e "${BLUE}Processing took ${CERT_AGE} second(s).${RESET}"

# copy the newly created files into their correspinding PEMs and install in the HAProxy cert dir
files=$( ls $CERT_DIR )
for f in $files; do
    echo -e "${BLUE}Installing ${f}${RESET}"
    $INSTALL_CMD $f $HAPROXY_CERT_DIR
    if [[ $? -ne 0 ]]; then
	echo -e "${LRED}The cert installation process has failed, aborting${RESET}"
	exit 2
    fi
done

# check the HAProxy config to ensure a restart will not fail due to config issues.
echo -e "${BLUE}Checking HAProxy's configuration.${RESET}"
echo -en "${YELLOW}"
${HAPROXY_CMD} -c -f ${HAPROXY_CONFIG}
if [[ $? -ne 0 ]]; then
    echo -e "${RED}HAProxy config check has failed, aborting${RESET}"
    exit 2
else
    echo -e "${LRED}You will have to restart HAProxy manually.${RESET}"
fi
