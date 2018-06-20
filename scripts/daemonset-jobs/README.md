# Example daemonset-job

The file named `clear-exited-containers.yaml` in this folder is an example.  It will clean up the exited containers and
unused docker images on your host.  You can use it as a basis for your own daemonset-job definitions.  It is simply
a job definition with variables throughout to be replaced at start-time by the upstream `job` in the /openshift/
folder.


