# runOnce Daemonset Job for OpenShift (and Kubernetes)
Lets say you want to be able to run a `job` on a series of nodes with a specific label.
- A Daemonset would let you run pods on different nodes, but not as a `job`
- A Job will let you run something once, but there's no guarantee it'll run on all the nodes you want it to

This git repo can help...

# A CronJob whose job is to create downstream Jobs - aka daemonset-jobs
In it's simplest form, 'runOnce Daemonset Job' is a Kubernetes CronJob that will kick off downstream Job(s), passing down things like environment variables, images, scripts etc, as needed.

A bit more detail: The main Job will create your yaml Job definitions, replacing variables as needed, and then creating the Job based on that definition.

# How does it work?
First, we create a `cronjob` definition named `daemonset-jobs.yaml`. There's a sample in this repository at `scripts/daemonset-jobs-sample.yaml`.  The file contains a typical Kubernetes definition for a `cronjob` and also includes any environment variables or other details you want to pass down to your `daemonset-job`.

Check out this pretty image to better understand what's going on under the hood.
![runOnce Daemonset-Job for OpenShift](daemonset-job.png)

# Required variables
Before you get going, there's a few variables that MUST be specified in your main `cronjob` definition.

- `JOB_NAME` : The name that the downstream job will use.  The final job name will appended with a numerical value, depending on the number of nodes you run it on
- `JOB_TO_RUN` : This is the yaml definition for the downstream Job you want to run.  Example value for the key would be host-checks.yaml
- `RUN_SCRIPT` : The script to run as `CMD` on the downstream Job's pod.
- `NODE_SELECTOR_KEY` : The key to be used for the nodeSelector.  A recommendation is to specify 'kubernetes.io/hostname' for this value as it would give the most control
- `NODE_SELECTOR_VALUE` : A space-separated list of nodeSelector values to use.  My recommendation is that this is list of node names.  In combination with 'kubernetes.io/hostname' you can specify all the nodes you want the daemonset-job to run on by their hostname
- `IMAGE_TO_USE` : This is the Docker image to use for the downstream Job.
- `DAEMONSETJOB_<ANYTHING>` :  Use this when you want the downstream Job to have environment variables.  Any variable prepended with `DAEMONSETJOB_` will be interpreted as an environment variable to be used by the downstream Job and the `DAEMONSETJOB_` will be removed from the final variable name.

Here's an example of what your environment variables might look like in your main `cronJob` definition.
```
kind: CronJob
spec:
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - env:
              - name: JOB_NAME
                value: host-disk-checks
              - name: JOB_TO_RUN
                value: host-checks.yaml
              - name: RUN_SCRIPT
                value: host-checks.sh
              - name: NODE_SELECTOR_KEY
                value: kubernetes.io/hostname
              - name: NODE_SELECTOR_VALUE
                value: app01.mydomain.com app02.mydomain.com opp03.mydomain.com
                  buildnode01.mydomain.com infra01.mydomain.com infra02.mydomain.com
                  infra03.mydomain.com logs01.mydomain.com logs02.mydomain.com
              - name: IMAGE_TO_USE
                value: docker-registry.default.svc:5000/monitor/ocp-ops-base-image:latest
              - name: DAEMONSETJOB_SOME_NUMBER
                value: "70"
              - name: DAEMONSETJOB_SOME_BOOLEAN
                value: 'true'
              - name: DAEMONSETJOB_SOME_STRING
                value: here's some text I want to pass into the downstream Job
```

