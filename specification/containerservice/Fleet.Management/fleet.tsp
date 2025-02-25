import "@typespec/rest";
import "@typespec/openapi";
import "@typespec/versioning";
import "@azure-tools/typespec-providerhub";
import "@azure-tools/typespec-azure-core";
import "@azure-tools/typespec-azure-resource-manager";
import "./helpers.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using TypeSpec.Versioning;
using Azure.ResourceManager;
using Azure.ResourceManager.Foundations;
using Azure.Core;
using Azure.Core.Traits;
using TypeSpec.OpenAPI;

namespace Microsoft.ContainerService;

@doc("The Fleet resource.")
@resource("fleets")
model Fleet is TrackedResource<FleetProperties> {
  @doc("The name of the Fleet resource.")
  @pattern("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$")
  @minLength(1)
  @maxLength(63)
  @key("fleetName")
  @path
  @segment("fleets")
  @visibility("create", "read")
  name: string;

  ...EntityTag;

  #suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-invalid-envelope-property" "https://github.com/Azure/typespec-azure/issues/2840"
  @added(Versions.v2023_06_15_preview)
  @doc("Managed identity.")
  identity?: Azure.ResourceManager.Foundations.ManagedIdentityProperties;
}

@doc("Fleet properties.")
model FleetProperties {
  // adding a response header in the model currently impacts the model used in the List result model.
  // omitting it for now as response headers do not impact SDK generation.
  //  ...EtagResponseEnvelope;

  @visibility("read")
  @doc("The status of the last operation.")
  provisioningState?: FleetProvisioningState;

  @doc("The FleetHubProfile configures the Fleet's hub.")
  hubProfile?: FleetHubProfile;
}

@doc("The FleetHubProfile configures the fleet hub.")
model FleetHubProfile {
  @doc("DNS prefix used to create the FQDN for the Fleet hub.")
  @visibility("read", "create")
  @pattern("^[a-zA-Z0-9]$|^[a-zA-Z0-9][a-zA-Z0-9-]{0,52}[a-zA-Z0-9]$")
  @minLength(1)
  @maxLength(54)
  dnsPrefix?: string;

  @added(Versions.v2023_06_15_preview)
  @doc("The access profile for the Fleet hub API server.")
  @visibility("read", "create")
  apiServerAccessProfile?: APIServerAccessProfile;

  @added(Versions.v2023_06_15_preview)
  @doc("The agent profile for the Fleet hub.")
  @visibility("read", "create")
  agentProfile?: AgentProfile;

  @visibility("read")
  @doc("The FQDN of the Fleet hub.")
  fqdn?: string;

  @visibility("read")
  @doc("The Kubernetes version of the Fleet hub.")
  kubernetesVersion?: string;

  @added(Versions.v2023_08_15_preview)
  @visibility("read")
  @doc("The Azure Portal FQDN of the Fleet hub.")
  portalFqdn?: string;
}

scalar SubnetResourceId
  extends Azure.ResourceManager.ResourceIdentifier<[
    {
      type: "Microsoft.Network/virtualNetworks/subnets",
    }
  ]>;

#suppress "@azure-tools/typespec-azure-core/casing-style" "match existing AKS APIServerAccessProfile"
@doc("Access profile for the Fleet hub API server.")
model APIServerAccessProfile {
  @visibility("read", "create")
  @doc("Whether to create the Fleet hub as a private cluster or not.")
  enablePrivateCluster?: boolean;

  @visibility("read", "create")
  @doc("Whether to enable apiserver vnet integration for the Fleet hub or not.")
  enableVnetIntegration?: boolean;

  @visibility("read", "create")
  @doc("The subnet to be used when apiserver vnet integration is enabled. It is required when creating a new Fleet with BYO vnet.")
  subnetId?: SubnetResourceId;
}

@doc("Agent profile for the Fleet hub.")
model AgentProfile {
  @visibility("read", "create")
  @doc("The ID of the subnet which the Fleet hub node will join on startup. If this is not specified, a vnet and subnet will be generated and used.")
  subnetId?: SubnetResourceId;

  @added(Versions.v2023_08_15_preview)
  @doc("The virtual machine size of the Fleet hub.")
  @visibility("read", "create")
  vmSize?: string;
}

@lroStatus
@doc("The provisioning state of the last accepted operation.")
enum FleetProvisioningState {
  ...ResourceProvisioningState,

  @doc("The provisioning state of a fleet being created.")
  Creating,

  @doc("The provisioning state of a fleet being updated.")
  Updating,

  @doc("The provisioning state of a fleet being deleted.")
  Deleting,
}

@doc("Properties of a Fleet that can be patched.")
model FleetPatch {
  @doc("Resource tags.")
  tags?: Record<string>;

  // adding a response header in the model currently impacts the model used in the List result model.
  // omitting it for now as response headers do not impact SDK generation.
  // ...EtagResponseEnvelope;

  #suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-invalid-envelope-property" "https://github.com/Azure/typespec-azure/issues/2840"
  @added(Versions.v2023_06_15_preview)
  @doc("Managed identity.")
  identity?: Azure.ResourceManager.Foundations.ManagedIdentityProperties;
}

@doc("One credential result item.")
model FleetCredentialResult {
  @visibility("read")
  @doc("The name of the credential.")
  name?: string;

  @visibility("read")
  @doc("Base64-encoded Kubernetes configuration file.")
  value?: bytes;
}

@doc("The Credential results response.")
model FleetCredentialResults {
  @visibility("read")
  @doc("Array of base64-encoded Kubernetes configuration files.")
  @extension("x-ms-identifiers", ["name"])
  kubeconfigs?: FleetCredentialResult[];
}

@armResourceOperations
interface Fleets {
  @doc("Gets a Fleet.")
  get is ArmResourceRead<Fleet>;

  #suppress "@azure-tools/typespec-azure-core/no-operation-id" "changing the operation-id on an existing operation is an SDK breaking change"
  @doc("Creates or updates a Fleet.")
  @operationId("Fleets_CreateOrUpdate")
  create is ArmResourceCreateOrUpdateAsync<
    Fleet,
    BaseParameters<Fleet> &
      IfMatchParameters<Fleet> &
      IfNoneMatchParameters<Fleet>
  >;

  #suppress "@azure-tools/typespec-providerhub/non-breaking-versioning" "Actual breaking change"
  @sharedRoute
  @removed(Versions.v2023_06_15_preview)
  update is ArmCustomPatchSync<
    Fleet,
    FleetPatch,
    BaseParameters<Fleet> & IfMatchParameters<Fleet>
  >;

  #suppress "@azure-tools/typespec-azure-core/no-operation-id" "Use operationId to keep same name as deprecated sync operation"
  @added(Versions.v2023_06_15_preview)
  @operationId("Fleets_Update")
  @sharedRoute
  updateAsync is ArmCustomPatchAsync<
    Fleet,
    FleetPatch,
    BaseParameters<Fleet> & IfMatchParameters<Fleet>
  >;

  @sharedRoute // why do we need to set shared route on delete? compiler complains with an error
  // All shared routes must agree on the value of the shared parameter.TypeSpec(@typespec/http/shared-inconsistency)
  delete is ArmResourceDeleteAsync<
    Fleet,
    BaseParameters<Fleet> & IfMatchParameters<Fleet>
  >;

  @doc("Lists fleets in the specified subscription and resource group.")
  listByResourceGroup is ArmResourceListByParent<Fleet>;

  @doc("Lists fleets in the specified subscription.")
  listBySubscription is ArmListBySubscription<Fleet>;

  @doc("Lists the user credentials of a Fleet.")
  listCredentials is ArmResourceNoRequestBodyActionSync<
    Fleet,
    FleetCredentialResults
  >;
}
