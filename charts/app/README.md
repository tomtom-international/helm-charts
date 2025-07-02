# App Helm chart

Contents:

- [Why](#why)
- [What](#what)
- [How](#how)
  - [Try](#try)
  - [More details](#more-details)
    - [`dict` to `list` expansion](#dict-to-list-expansion)
    - [Reducers](#reducers)
    - [Extra logic](#extra-logic)
    - [Post-rendering](#post-rendering)
- [Best practices](#best-practices)
- [Development](#development)

## Why

Helm is a very powerful tool, that quickly became standard-de-facto when it comes to defining configurable workload manifests in Kubernetes.

At the same time, creating and maintaining Helm charts for thousands of workloads by hundreds of teams on global scale is expensive. Especially when done by engineers with diverse level of expertise and background, it creates countless "ways of doing things" in Kubernetes with Helm, making hard to impossible costless code succession when ownership is passed between teams, or seeking support from engineers outside of own team. Most often:
- Helm templates code/syntax and value names are highly influenced by the primary expertise of engineers on a team (e.g. Java, C, Python, JavaScript, ...)
- Helm templates are very specific and tailored for one workload/service/team, rich with conditions and business logic specific to teams' business domains
- engineers have limited/no prior experience with Kubernetes and/or Helm, requiring steep learning curve to uphold to Helm Best practices.

## What

App Helm chart offers a view on the problem by suggesting a simple approach to define and override workloads with Helm values, with no need of creating and maintaining own Helm charts specific to only 1 team and/or business domain.

It provides a transparent and finite (yet powerful) mechanism of Kubernetes manifests definition with minimal clean amount of code/configuration in the form of Helm values.

The results of applying App Helm chart in several TT services demonstrate 20-40% lines of code/configuration reduction on average (up to x10 in proven cases), and significant time reduction spent on maintenance and support both within and outside of the team owning workloads.

## How

App Helm chart implements a few simple rules:

1. App Helm chart values are simple dictionaries representing different kinds of supported Kubernetes manifests in the structure of key-value pairs, with minimal meaningful default values. For example, define `ServiceAccount` and `Pod` resources named `app`, using default values coming with App chart:

```yaml
serviceAccounts:
  app: {}

pods:
  app: {}
```

2. The `common` dictionary provides access to defaults applied to all manifests of specific kind across all rendered manifests. For example, define `pod` defaults across all `cronJobs` and `pods`:

```yaml
common:
  pod:
    spec:
      serviceAccountName: other

pods:
  app: {}

cronJobs:
  report: {}
```

3. Frequently used manifest fields of `list` type can be presented as `dict`s, allowing overrides in more specific context. For example, override default `pod`s `container.image`:

```yaml
common:
  pod:
    spec:
      containers:
        app:
          image: busybox:latest

pods:
  app:
    spec:
      containers:
        app:
          image: busybox:19700101

cronJobs:
  report: {}
```

For more details refer to [`dict` to `list` expansion](#dict-to-list-expansion) section.

4. The `~` (ie. shortened `null`) value set on a `list` field supporting expansion to `dict` in a narrower context removes item from the manifest. For example, remove an item from a list of `containers` in a `pod`:

```yaml
common:
  pod:
    spec:
      containers:
        app:
          image: busybox:latest
        sidecar:
          image: busybox:latest

pods:
  app:
    spec:
      containers:
        sidecar: ~

cronJobs:
  report: {}
```

5. Kind-specific reducers, simplifying frequently used configurations. For example, pass container environment variables as simple key-values:

```yaml
common:
  pod:
    spec:
      containers:
        app:
          image: busybox:latest
          env:
            A: B

pods:
  app: {}
```

For more details refer to [Reducers](#reducers) section.

6. Some manifests support extra logic to aid common issues. For example: properly rendering `deployment.replicas` in Go template requires special/well-known care. For example, since both `0` and `null` equate to `false` in Go template, it must be rendered only when set to `0` (or other positive number):

```yaml
deployments:
  app1:
    spec:
      selector:
        matchLabels:
          app: app1
      replicas: 0
  app2:
    spec:
      selector:
        matchLabels:
          app: app2
      replicas: ~
```

For more details refer to [Extra logic](#extra-logic) section.

7. Manifests post-rendering happens immediately after a top-level dictionary item is converted to a native Kubernetes manifest, providing a simple way to configure fields hidden deep in manifests structure without repetitive nested overrides. For example, render `image.tag` value inside a `container.image` field:

```yaml
image:
  tag: latest

pods:
  app:
    spec:
      containers:
        app:
          image: "busybox:{{ .Values.image.tag }}"
```

For more details refer to [Post-rendering](#post-rendering) section.

### Try

To see App Helm chart in action, try the above examples with `helm` tool.

First, install Helm chart repository:

```shell
helm repo add tomtom-international https://tomtom-international.github.io/helm-charts
# run once in a while
helm repo update
```

and then use the following command, placing snippets in a `values.yaml` file:

```shell
# with each example
helm template tomtom-international/app -f values.yaml
```

### More details

#### `dict` to `list` expansion

Some manifests have fields of type `list` (e.g. `Pod#spec.containers`) while Helm can only deep-merge `dict`s.

App Helm chart allows to represent selected manifest fields as dictionaries, allowing simple overrides of particular item on destination list.

While key-value pairs in a `dict` are not ordered (comparing to `list` items), keys in dictionaries define an order of each item in destination `list` by their alphabetical order. In addition to that, keys are used as default destination items' `name` field value (can be overridden or disabled), helping to reduce LoC without readability sacrifice.

NB: when using keys as `name` field, order of items in destination `list` will follow alphabetical order of keys. When key needs to change to adjust order, not affecting `name` field, specify desired `name` field in items explicitly.

##### List of fields supporting `dict` to `list` expansion

```
Application#spec.sources
ExternalSecret#spec
Service#spec.ports
VMAlertmanagerConfig#spec.receivers
VMAlertmanagerConfig#spec.receivers.*
VMAlertmanagerConfig#spec.route.routes
VMRule#spec.groups
VMRule#spec.groups.*.rules
# each: Pod#spec, CronJob#spec.jobTemplate.template.spec, Deployment#spec.template.spec
*.volumes
*.containers
*.initContainers
*.containers.*.env
*.containers.*.ports
*.containers.*.volumeMounts
*.initContainers.*.env
*.initContainers.*.ports
*.initContainers.*.volumeMounts
```

For implementation details on all supported manifests and fields, please search for `dict-to-list:` phrase in the sources.

#### Reducers

Besides default values supplied by App Helm chart for some manifests, there is several frequent use cases, where specifying or overriding a value adds a lot of repetitive boilerplate code. A good example is the `ContainerSpec#env` field, which can be reduced to simple key-value dictionary, expanding during rendering into a `list` of `{name: <name>, value: <value>}` dictionaries as expected by Kubernetes.

##### List of fields supporting reducers

```
Application#spec.destination.namespace
Certificate#spec.target.secretName
ExternalSecret#spec
HTTPRoute#spec.parentRefs.*.name
VMAlertmanagerConfig#spec.route.routes.*.continue
# each: Pod#spec, CronJob#spec.jobTemplate.template.spec, Deployment#spec.template.spec
*.containers.*.env
*.initContainers.*.env
```

For implementation details on all supported manifests and fields, please search for `reducers:` phrase in the sources.

#### Extra logic

App Helm chart assumes control of a small number of manifest fields that require special care in normal circumstances.

To keep App Helm chart reusable across teams and business domains, only well-known quirks/behaviour is being addressed. For example: setting `deployment.replicas` to `0` or specifying only one of the `podDisruptionBudget.{minAvailable,maxUnavaible}` fields but not both at the same time.

##### List of fields supporting extra logic

```
Application#spec.syncPolicy.automated
Deployment#spec.replicas
PodDisruptionBudget#spec.minAvailable
PodDisruptionBudget#spec.maxUnavailable
```

For implementation details on all supported manifests and fields, please search for `extra-logic:` phrase in the sources.

#### Post-rendering

While most of the things can be accomplished by simple nested dictionary overrides and multiple value files, there are some situations when you'd want to render manifest fields (including keys) from other values.

One of the above examples demonstrated custom `image.tag` value and its use to render `container.image` field, that often must be supplied as separate value/argument from a command line (e.g. when using ArgoCD Image Updater).

Or, for example, you could use `.Release.Name` as dynamic resource names, generalising definition of multiple applications with same/similar manifests, different only in image name/tag or set of resources:

```yaml
pods:
  '{{ .Release.Name }}':
    spec:
      containers:
        app:
          image: 'xyz.azurecr.io/abc/{{ .Release.Name }}:latest'
```

In fact, `.` context passed into post-rendering provides access to all values passed to `helm` command, including pre-defined `.Release` and `.Namespace` Helm values.

## Best practices

1. Use short and simple resource names.

**Do**: use simple and repetitive resource names across multiple manifest kinds, for example: `Pod` and `Secret` resources both named `redis` will help to unambiguously identify resource relationships without the need for extra characters.

**Don't**: use prefix/suffix resource names with resource types (or its abbreviation), for example: resource `Secret` with name `redis-secret` is better read if called just `redis`, it's already known to be of `Secret` kind.

2. Use simple value file names and structure for configuration overrides depending on an environment instance.

**Do**: top-level value file named `app.yaml` in root folder and `{dev,prod}/app.yaml` environment-specific files in subfolders help to consolidate related configurations.

**Don't**: multiple environment-specific value files called `values{,.dev,.prod}.yaml`, besides having unnecessary prefix is not easy to navigate in plain structure when working with more than one App Helm chart release values under single repo/path prefix.

## Development

Use [`helm unittest`](https://github.com/helm-unittest/helm-unittest) for testing:

```shell
helm plugin install https://github.com/helm-unittest/helm-unittest.git
helm unittest .
```
