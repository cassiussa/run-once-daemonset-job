# Changes you must make first

There are some changes to the `daemonset-job_sample.yaml` file that you must make before trying to use it.

Look for the commented-out lines and perform updates to them.  For example...
```
              - name: NODE_SELECTOR_VALUE
#               value: app01.mydomain.com app02.mydomain.com opp03.mydomain.com buildnode01.mydomain.com infra01.mydomain.com infra02.mydomain.com infra03.mydomain.com logs01.mydomain.com logs02.mydomain.com
              - name: IMAGE_TO_USE
#               value: <my-daemonset-job-image:latest>
#             image: <daemonset-jobs:latest <-- build from the Dockerfile in this repository>
```

- For `NODE_SELECTOR_VALUE` values, use a space-separated list of nodes on your OpenShift cluster that you'd like for the daemonset-job to run on.
- For `IMAGE_TO_USE`, specify the location to the Docker image for your `job`.
- Point the `image` to the location of the Docker image you build using the Dockerfile in this repository
