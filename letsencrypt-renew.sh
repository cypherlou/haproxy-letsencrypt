# Designed to be run from cron or logrotated (post processing) to renew certs on the box

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

# check if the HAProxy check is required
if [[ $HAPROXY_CHECK -eq 0 ]]; then
    echo -e "${RED}The HAProxy check has been disabled${RESET}"
    exit 1
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
