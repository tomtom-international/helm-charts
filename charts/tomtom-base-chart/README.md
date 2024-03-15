# tomtom-base-chart

![Version: 0.0.3](https://img.shields.io/badge/Version-0.0.3-informational?style=flat-square)

TomTom Base Helm Chart (a.k.a Golden Helm Chart) is a project to help teams deploy their application more quickly.

The chart aims to:
- reduce repetition across the organization,
- reduce time spent on setting up deployment manifests,
- prevent errors and implement best practices by default,
- allow customers to onboard to Kubernetes (preferably KaaP) more easily,

The main motivation behind this initiative is to help engineers onboard to KaaP with less effort. Although some functionality is intended for use with KaaP, the chart can be used when deploying to self-managed Kubernetes clusters.

## Getting started
To start using the TomTom base chart, add it as a dependency to your application chart. The user basically creates a Helm chart per application, but does not have to go through setting up all the templates for their app one-by-one. Instead, they will be using templates that should work with most use cases. If one component of the base chart does not fulfil the requirements, users can always [extend the functionality](#extending-the-chart) by adding custom templates.

The basic configuration requires two files: a `Chart.yaml` and a `values.yaml`

```
.
└── my-app
    ├── Chart.yaml
    └── values.yaml
```

`Chart.yaml` is a basic file that defines the application's Helm chart.

Sample `Chart.yaml`:
```yaml
apiVersion: v2
appVersion: 1.0.0
description: Sample app helm chart
name: sample-app
type: application
version: 1.0.0
dependencies:
  - name: tomtom-base-chart
    version: 0.0.3
    repository: https://tomtom-international.github.io/helm-charts
```

The following table can be taken as a refence when creating this file. More details and options can be found in [Helm documentation](https://helm.sh/docs/topics/charts/#the-chartyaml-file).

| Key | Value | Description |
|---|---|---|
| apiVersion | v2 | `tomtom-base-chart` uses Helm v3, so apiVersion must be set to `v2`. |
| appVersion |  | Version of the application to be deployed via this Helm chart |
| description |  | A short description of the Helm chart |
| name |  | Chart name. Can be set to application name. |
| type | application | This is a Helm chart used for deployments, so this must be set to `application`. |
| version |  | Helm chart version. This must be incremented every time the chart changes. Changes in `values.yaml` do not require incrementing the version, but updating `tomtom-base-chart` version or adding a custom template do. |
| dependencies | _see example_ | This option is what allows the application chart to use `tomtom-base-chart`, so it is required to add `tomtom-base-chart` as a dependency as shown in the example above. Users can always define more dependencies, if needed. |

The second file, `values.yaml`, is where the user defines the "values" or the inputs for the templates defined in `tomtom-base-chart`. All values must be defined under the key `tomtom-base-chart`.

Sample `values.yaml`:
```yaml
tomtom-base-chart:
  basicSettings:
    replicas: 2
    image:
      repository: artifactory.tomtomgroup.com/docker/nginx
      tag: "1.0.0"
    #...
```

All supported values can be seen in the next section, as well as [values.yaml](./values.yaml) inside the git repository. The actual _values_ inside the [values.yaml](./values.yaml) act as default values, and are overriden by the values supplied by the user in the values.yaml file of the application chart.

## Chart values

<table height="400px" >
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td id="basicSettings--allowedIpRanges"><a href="./values.yaml#L123">basicSettings.allowedIpRanges</a></td>
			<td>list</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
[
  "0.0.0.0/0"
]
</pre>
</div>
			</td>
			<td>

**Allowed IP Ranges (IP Allowlist)**

Range of IP addresses that are allowed to access this application through ingress</td>
		</tr>
		<tr>
			<td id="basicSettings--autoscaling"><a href="./values.yaml#L266">basicSettings.autoscaling</a></td>
			<td>object</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
{
  "enabled": true,
  "maxReplicas": 10,
  "minReplicas": 2,
  "targetCPUUtilizationPercentage": 75
}
</pre>
</div>
			</td>
			<td>

**Autoscaling**

Enabled by default, creates a HorizontalPodAutoscaler resource.
This resource scales the deployment based on CPU (set to 75% by default) or memory usage.</td>
		</tr>
		<tr>
			<td id="basicSettings--command"><a href="./values.yaml#L62">basicSettings.command</a></td>
			<td>string</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
""
</pre>
</div>
			</td>
			<td>

**Command**

Command to run after starting the container.
If not set, `ENTRYPOINT` and `CMD` of the container will be used.</td>
		</tr>
		<tr>
			<td id="basicSettings--configFiles"><a href="./values.yaml#L197">basicSettings.configFiles</a></td>
			<td>list</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
[]
</pre>
</div>
			</td>
			<td>

**Configuration files**

Files to mount to the pod for the application to use.
The key for each item will be the file name with full path and the value will be the content.
This will create a Kubernetes ConfigMap and use this as a reference to mount files.

Configuration format:
```yaml
- name: <configmap-name>    # will be prefixed by release name
  path: <path-to-mount-the-files>
  files:
    <file-name>: <file-content>
```

Example:
```yaml
- name: example-config
  path: /etc/config
  files:
    example.ini: |
      [GLOBAL]
      foo = bar
```

This will create a file at `/etc/config/example.ini` with the content:
```
[GLOBAL]
foo = bar
```
</td>
		</tr>
		<tr>
			<td id="basicSettings--envs"><a href="./values.yaml#L162">basicSettings.envs</a></td>
			<td>object</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
{}
</pre>
</div>
			</td>
			<td>

**Environment variables**

Environment variables as key-value pairs for the application.
This will create a Kubernetes ConfigMap and create envs referring to that.

**IMPORTANT:** Use secretEnvs for sensitive environment variables.
Such variables should not be a part of the Helm values and
must be fetched from an external secret store like AKV.

Example:
```yaml
MY_ENV: value
```
</td>
		</tr>
		<tr>
			<td id="basicSettings--fqdn"><a href="./values.yaml#L115">basicSettings.fqdn</a></td>
			<td>string</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
""
</pre>
</div>
			</td>
			<td>

**Application FQDN**

Hostname (FQDN) part of the URL used to access the application.
If no "fqdn" is set, the application will not be accessible through a domain name.</td>
		</tr>
		<tr>
			<td id="basicSettings--image--pullSecret"><a href="./values.yaml#L49">basicSettings.image.pullSecret</a></td>
			<td>object</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
{
  "secretKey": "regcred",
  "secretStore": "azure-store"
}
</pre>
</div>
			</td>
			<td>

**Image pull credentials**

For this section to work, the secret store needs to be created in advance.
See docs for more information about how to create this.</td>
		</tr>
		<tr>
			<td id="basicSettings--image--repository"><a href="./values.yaml#L28">basicSettings.image.repository</a></td>
			<td>string</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
"nginx"
</pre>
</div>
			</td>
			<td>

**Container repository**

URL of the container image except for the tag</td>
		</tr>
		<tr>
			<td id="basicSettings--image--tag"><a href="./values.yaml#L40">basicSettings.image.tag</a></td>
			<td>string</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
null
</pre>
</div>
			</td>
			<td>

**Image tag**

Tag of the container image to pull.
Most of the time, this is the version of the application (e.g. 1.0.0).
If no tag is provided, appVersion in Chart.yaml will be used.
</td>
		</tr>
		<tr>
			<td id="basicSettings--port"><a href="./values.yaml#L79">basicSettings.port</a></td>
			<td>int</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
80
</pre>
</div>
			</td>
			<td>

**Service port**

Port number the application listens to</td>
		</tr>
		<tr>
			<td id="basicSettings--probe"><a href="./values.yaml#L106">basicSettings.probe</a></td>
			<td>object</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
{}
</pre>
</div>
			</td>
			<td>

**Probes**

`liveness`:  Used to determine if the application is alive or experiencing problems.
             If this fails, the container will be restarted.

`readiness`: Used to determine if the pod is ready to receive requests.
             If this fails, the pod will not receive traffic.

`settings` can be used for custom probe options for both probes.
See https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

Example:
```yaml
liveness:
  path: /healthz
  settings:
    periodSeconds: 60
readiness:
  path: /ready
  settings: {}
```
</td>
		</tr>
		<tr>
			<td id="basicSettings--replicas"><a href="./values.yaml#L18">basicSettings.replicas</a></td>
			<td>int</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
1
</pre>
</div>
			</td>
			<td>

**Replica count**

Number of replicas to run

**WARNING:** Does not get applied when autoscaling is enabled,
which is the default behavior. See `basicSettings.autoscaling`</td>
		</tr>
		<tr>
			<td id="basicSettings--resources"><a href="./values.yaml#L137">basicSettings.resources</a></td>
			<td>object</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
{}
</pre>
</div>
			</td>
			<td>

**Resource Requests & Limits**

CPU and memory usage requests and limits.

The average usage under regular load needs to be specified under `requests`.
The resource limits need to be specified under `limits`.

Please refer to https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/</td>
		</tr>
		<tr>
			<td id="basicSettings--secretEnvs"><a href="./values.yaml#L227">basicSettings.secretEnvs</a></td>
			<td>list</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
[]
</pre>
</div>
			</td>
			<td>

**Secret environment variables (uses External Secrets Operator)**

Secrets to be fetched from an external secret store and used by the application.
See docs for information on how to create the neccessary config before using ESO.

Configuration format:
```yaml
- name: <secret-name>               # will be prefixed by release name
  secretStore: <secretstore-name>   # must be configured beforehand
  secrets:
    <secret-name>: <remote-secret-name>
```

Example:
```yaml
- name: my-secrets
  secretStore: azure-kv-store
  secrets:
    A_SECRET_ENV: remote-secret-key-1
    ANOTHER_SECRET_ENV: remote-secret-key-2
```

This example creates a secret named `my-secrets` using the pre-created secret store
`azure-kv-store` and all secrets listed under `secrets` will be accessible by the
application through environment variables.</td>
		</tr>
		<tr>
			<td id="basicSettings--secretFiles"><a href="./values.yaml#L257">basicSettings.secretFiles</a></td>
			<td>list</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
[]
</pre>
</div>
			</td>
			<td>

**Secret configuration files (uses External Secrets Operator)**

Files with secret information to mount to the pod for the application to use.
The key for each item will be the file name with full path and the value defines how to fetch the content.

Configuration format:
```yaml
  - name: <secret-name>   # will be prefixed by release name
    path: <path-to-mount-the-files>
    secretStore: <secretstore-name>   # must be configured beforehand
    files:
      <file-name>: <remote-secret-name>
```

Example:
```yaml
- name: example-secret
  path: /etc/config
  secretStore: azure-kv-store
  files:
    secrets.txt: remote-secret-key
```

This example will create a file at `/etc/config/secrets.txt`
with the sensitive content defined in KV store secret `remote-secret-key`.</td>
		</tr>
		<tr>
			<td id="basicSettings--shell"><a href="./values.yaml#L71">basicSettings.shell</a></td>
			<td>string</td>
			<td>
				<div style="max-width: 300px;">
<pre lang="json">
"/bin/sh"
</pre>
</div>
			</td>
			<td>

**Shell**

Shell to run the command on.
This setting does not apply if `basicSettings.command` is not set.</td>
		</tr>
	</tbody>
</table>

### About advanced settings

The chart also provides advanced configuration options under `advancedSettings` key (see [values.yaml](./values.yaml)). These are intended for advanced requirements. Their naming convention follows the official configuration options.

Please refer to [Kubernetes documentation](https://kubernetes.io/docs/home/) when using these.

## Extending the chart

In case there is a need to deploy custom manifests along with the supported ones or if one of the base templated does not fulfil requirements, custom templates can be defined in the application Helm chart.

As explained in [Getting started](#getting-started), the application Helm chart consists primarily of `Chart.yaml` and `values.yaml`. However, this does not limit the user to use only templates from the tomtom-base-chart. More (custom) templates can be defined under a directory called `templates` inside the chart directory.

```
.
└── my-app
    ├── templates
    │   └── customresource.yaml
    ├── Chart.yaml
    └── values.yaml
```

Values for custom template(s) must be defined in the root context of the `values.yaml`.

```yaml
# values for custom templates
some-custom-option: true

# values for the base helm chart
tomtom-base-chart:
  basicSettings:
    replicas: 2
  #...
```

If you think the feature would benefit more people, consider contributing or creating an issue.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
