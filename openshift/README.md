# Changes you must make first

There are some changes to the `daemonset-job_sample.yaml` file that you must make before trying to use it.

Look for the commented-out lines and perform updates to them.  For example...
```
              - name: NODE_SELECTOR_VALUE
#               value: app01.mydomain.com app02.mydomain.com opp03.mydomain.com buildnode01.mydomain.com infra01.mydomain.com infra02.mydomain.com infra03.mydomain.com logs01.mydomain.com logs02.mydomain.com
              - name: IMAGE_TO_USE
#               value: <my-daemonset-job-image:latest>
#             image: <my-base-image:latest <-- build from the Dockerfile in this repository>
```
