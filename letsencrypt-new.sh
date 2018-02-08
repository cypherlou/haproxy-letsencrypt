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

copy_cert() {

    echo -e "${BLUE}Installing ${1}${RESET}"
    $INSTALL_CMD $1 $HAPROXY_CERT_DIR
    if [[ $? -ne 0 ]]; then
	echo -e "${LRED}The cert installation process has failed, aborting${RESET}"
	exit 2
    fi

}

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
BASE_DOMAIN=$(cut DOMAIN_LIST -d' ' -f1 )

# output some guidance information
CERT_START=$(date +%s)
echo -e "${BLUE}Executing letsencrypt command${RESET}"
echo -en "${YELLOW}"
${CERT_CMD} $DOMAIN_LIST
if [[ $? -ne 0 ]]; then
    echo -e "${LRED}The cert request process has failed, aborting${RESET}"
    exit 2
fi
echo -en "${RESET}"

# helper message related to processing time
CERT_AGE=$( expr $(date +%s) - $CERT_START )
echo -e "${BLUE}Processing took ${CERT_AGE} second(s).${RESET}"

# copy the newly created files into their correspinding PEMs and install in the HAProxy cert dir
files_copied=0
files=$( ls $CERT_DIR )

for f in $files; do
    if [[ $MINIMAL_INSTALL -eq 1 ]]; then
	if [[ $f =~ ${BASE_DOMAIN} ]]; then
	    copy_cert $f
	    files_copied=$((files_copied+1))
	fi
    else
	copy_cert $f
	files_copied=$((files_copied+1))
    fi
done

# if no files have been copied then exit with code 4 so haproxy restarts do not take place
if [[ $files_copied -eq 0 ]]; then
    echo -e "${LRED}No files copied on this run, exiting with code 3.${RESET}"
    exit 3
fi

# check if the HAProxy check is required
if [[ $HAPROXY_CHECK -eq 0 ]]; then
    echo -e "${RED}The HAProxy check has been disabled${RESET}"
    exit 0
fi

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
