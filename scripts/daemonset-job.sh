#!/bin/bash

################
#
# Starts a job on each of the hosts specified in NODE_SELECTOR_VALUE
# and then run the script found in the RUN_SCRIPT environment
# variable.  It also sends along any additional env vars specified
# so that the downstream jobs can use them.  They MUST be prepended
# with DAEMONSETJOB_ in order to be found.
#
# We also specify JOB_TO_RUN as the name of the yaml config
# for the downstream job to be run. Place that yaml file in the
# scripts/daemonset-jobs/ folder, and also a JOB_NAME.
# There is an example file already in scripts/daemonset-jobs/
#
# The container running this will need permissions to kick off other
# jobs via the OCP API or some other method.  See main README
#
###############

if [ -z "${NODE_SELECTOR_VALUE}" ]; then
    echo "The NODE_SELECTOR_VALUE environment variable has not been specified.  You must first specify it in the daemonset-job yaml defintion file.  Exiting"
    exit 0
fi

if [ -z "${RUN_SCRIPT}" ]; then
    echo "The RUN_SCRIPT environment variable has not been specified.  Without a script to run on the downstream jobs, they're pointless. You must first specify it in the daemonset-job yaml defintion file.  Exiting"
    exit 0
fi

if [ -z "${JOB_TO_RUN}" ]; then
    echo "The JOB_TO_RUN environment variable has not been specified.  You need to specify the yaml config file that the Job object will be created from. You must first specify it in the daemonset-job yaml defintion file. Since we don't have that, this cronjob is exiting with error."
    exit 0
fi

if [ -z "${JOB_NAME}" ]; then
    echo "The JOB_NAME environment variable has not been specified.  You need to specify a name for the downstream target Job. You must first specify it in the daemonset-job yaml defintion file.  Since we don't have that, this cronjob is exiting with error."
    exit 0
fi

/bin/oc login https://${OCP_EXT_HOSTNAME}:8443 -u ${WEBOPS_USER} -p ${WEBOPS_PASS} --insecure-skip-tls-verify

VAR_EXPANSION="/scripts/includes/var_expansion.sh"
ENDPOINT="https://ose.dev.nm.cbc.ca:8443"
source "$VAR_EXPANSION"

# Out what it is we're about to do
echo "${RUN_SCRIPT} will now be run as a Job object on ${NODE_SELECTOR_VALUE}"

# Any environment variable that is prepended with "DAEMONSETJOB_" will be picked up here and passed
# along to the downstream job/pod for consumption.
VARS_ARRAY=($(env | grep "DAEMONSETJOB_"))
HOSTS_ARRAY=($(echo ${NODE_SELECTOR_VALUE}))

re='^[0-9]+([.][0-9]+)?$'
# Update the JOB_TO_RUN file with environment variables passed by this script
ENVIRONMENT_VARIABLE_REPLACEMENT=""
for VARIABL in "${VARS_ARRAY[@]}"; do
    VARIABL="${VARIABL//DAEMONSETJOB_/}"
    VAR_VAL=$(echo ${VARIABL} | awk -F '=' '{print $2}')
    if [[ $VAR_VAL =~ $re || "${VAR_VAL}" == "true" || "${VAR_VAL}" == "false" ]] ; then
        VAR_VAL="'${VAR_VAL}'"
    fi

    ENVIRONMENT_VARIABLE_REPLACEMENT="${ENVIRONMENT_VARIABLE_REPLACEMENT}
            - name: $(echo ${VARIABL} | awk -F '=' '{print $1}')
              value: ${VAR_VAL}"
done

EVR="${ENVIRONMENT_VARIABLE_REPLACEMENT}"
JOB_NAME_ORIG="${JOB_NAME}"
# Update the nodeSelector values
NODE_SELECTOR_VALUE=null
let i=0
for NODE in "${HOSTS_ARRAY[@]}"; do
    NODE_SELECTOR_VALUE="${NODE}"
    ENVIRONMENT_VARIABLE_REPLACEMENT="${EVR}
            - name: NODE_NAME
              value: ${NODE}"

    JOB_NAME="${JOB_NAME_ORIG}-${i}"

    echo "Deleting historic job - ${JOB_NAME}"
    /bin/oc delete job ${JOB_NAME} -n monitor

    # Replace the variables in the yaml file with variables expanded from this script
    printf "%s\n" "$(expand_variables_in_textfile /scripts/daemonset-jobs/${JOB_TO_RUN})" > /scripts/daemonset-jobs/${JOB_NAME}.yaml
    echo "################################################################"
    echo "Here's what the file for ${NODE_SELECTOR_VALUE} looks like"
    echo "################################################################"
    cat /scripts/daemonset-jobs/${JOB_NAME}.yaml
    echo "################################################################"

    # Create the Job object
    echo "Creating the job ${JOB_NAME}"
    /bin/oc apply -f /scripts/daemonset-jobs/${JOB_NAME}.yaml -n monitor
    echo "Done."
    ((++i))
done

exit 0
