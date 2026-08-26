# azure-devops-agents

Runs self-hosted Azure Pipelines agents as ephemeral KEDA `ScaledJob` pods, scaled
from the depth of an agent-pool queue.

## Breaking change in 0.14.0

The container entrypoint moved:

```diff
- command: ["./start.sh"]
+ command: ["/usr/local/bin/start.sh"]
```

**Your agent image must provide `start.sh` at `/usr/local/bin/start.sh`.** An image
that only has it in the working directory will fail to start on 0.14.0.

The old layout is unsafe whenever a volume is mounted over the agent working
directory. The chart's default values mount an `emptyDir` at `/mnt`, so an image
that bakes `start.sh` into a working directory below `/mnt` has that copy masked at
runtime and depends on a ConfigMap mount to put the script back. Moving the script
outside the mounted path removes that hidden coupling.

Pin `version: 0.13.0` if you are not ready to rebuild your image.

## Authentication

Two options, selected by `managedIdentity.enabled`.

### Personal access token (default)

A PAT is read from a Secret and passed to both the agent and the KEDA scaler.
Use `secret.*` to have the chart create it, or `externalSecret.*` to source it
from a secret store.

### Azure AD Workload Identity

Set `managedIdentity.enabled: true` and no PAT is rendered anywhere: the pod runs
under the named ServiceAccount with the `azure.workload.identity/use` label, the
`AZP_TOKEN` environment variable is omitted, and the `azure-pipelines` trigger
authenticates through a `TriggerAuthentication` instead of a token.

```yaml
managedIdentity:
  enabled: true
  serviceAccountName: ado-agent-mi
  triggerAuthName: ado-keda-wi

# nothing consumes a PAT in this mode, so do not have the chart create one
secret:
  create: false
```

Note that `secret.create` and `externalSecret.create` are still honoured
independently of `managedIdentity.enabled`; set them to `false` yourself, or the
chart will create a PAT Secret that nothing reads.

This chart deliberately does not create either object. Both are shared by every
pool in the namespace, and the ServiceAccount has to carry the client-id of the
identity federated to it, so they belong to whatever manages the namespace:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ado-agent-mi
  annotations:
    azure.workload.identity/client-id: "<client-id of the user-assigned identity>"
    azure.workload.identity/tenant-id: "<tenant-id>"
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: ado-keda-wi
spec:
  podIdentity:
    provider: azure-workload
```

You also need, outside the chart:

- Workload identity enabled on the KEDA operator, so the scaler can poll the queue
  as a federated identity. The KEDA chart exposes this as `podIdentity.azureWorkload`.
- Federated credentials on the identity for both subjects — the KEDA operator's
  ServiceAccount and the agent ServiceAccount above — against the cluster's OIDC
  issuer.
- The identity granted permission on the agent pool in your Azure DevOps
  organization.
- An agent image whose entrypoint exchanges the projected federated token for an
  Azure DevOps access token. The agent accepts an Entra token wherever it accepts
  a PAT.
