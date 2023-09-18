# helm-charts

This repository stores helm charts for `SP-Integration and Delivery Team` and publish them using github pages.

## Prerequisites

Before you can add and list Helm repositories, make sure you have the following prerequisites installed:

- [Helm](https://helm.sh/) - Make sure Helm is installed on your local machine.#

## Adding a Helm Repository

To add a Helm repository, follow these steps:

1. Open a terminal window.
2. Install helm using homebrew.

```bash
brew install helm
```

```bash
$ helm repo add tomtom-international https://tomtom-international.github.io/helm-charts
$ helm repo update
```

```
$ helm repo ls
NAME                       	URL
tomtom-international       	https://tomtom-international.github.io/helm-charts
```

```bash
$ helm search repo tomtom-international
NAME                                              	CHART VERSION	APP VERSION	DESCRIPTION
tomtom-international/azure-devops-agents          	0.9.0        	1.16.0     	A Helm chart for Kubernetes
tomtom-international/azure-devops-exporter        	0.6.0        	1.16.0     	A Helm chart for Kubernetes ADO Exporter
tomtom-international/gha-runner-scale-set         	0.6.0        	0.6.0      	A Helm chart for deploying an AutoScalingRunnerSet
tomtom-international/gha-runner-scale-set-contr...	0.6.0        	0.6.0      	A Helm chart for install actions-runner-control...
```
