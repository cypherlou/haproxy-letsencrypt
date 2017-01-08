# Designed to be run from cron or logrotated (post processing) to renew certs on the box

# configuration
BASE_DIR=$(dirname $(realpath $0) )
source letsencrypt-config.sh

# correct number of parameters?
if [[ $# -ne 0 ]]; then
    echo -e "${RED}usage: $0${RESET}"
    exit 2
fi

#
CERT_START=$(date +%s)
echo -e "${BLUE}Executing letsencrypt command${RESET}"
echo -en "${YELLOW}"
${CERT_RENEW_CMD}
if [[ $? -ne 0 ]]; then
    echo -e "${LRED}The cert request process has failed, aborting${RESET}"
    exit 2
fi

# helper message related to processing time
CERT_AGE=$( expr $(date +%s) - $CERT_START )
echo -e "${BLUE}Processing took ${CERT_AGE} second(s).${RESET}"

# copy the newly renewed cert files into their correspinding PEMs and install in the HAProxy cert dir
files=$( ls $CERT_DIR )
for f in $files; do
    echo -e "${BLUE}Installing ${f}${RESET}"
    $INSTALL_CMD $f $HAPROXY_CERT_DIR
    if [[ $? -ne 0 ]]; then
        echo -e "${LRED}The cert installation process has failed, aborting${RESET}"
        exit 2
    fi
done

# tidy up messages
echo -e "${LRED}You will have to restart HAProxy manually.${RESET}"
