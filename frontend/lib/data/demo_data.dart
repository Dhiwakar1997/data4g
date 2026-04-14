import '../models/comparison_models.dart';
import '../models/dashboard_models.dart';
import '../models/endpoint_models.dart';
import '../models/project_models.dart';
import '../models/reference_models.dart';
import '../models/risk_models.dart';
import '../models/share_models.dart';
import '../models/spec_models.dart';
import '../models/team_models.dart';
import '../models/topology_models.dart';
import '../models/traffic_models.dart';

class DemoDataFactory {
  DemoDataFactory._();

  static List<ProjectSummary> projects() {
    return const [
      ProjectSummary(
        projectId: 'proj_demo',
        ownerId: 'user_demo',
        name: 'Retail Intelligence Platform',
        description:
            'Browser-first planning workspace for the DataForge rollout.',
        topologyCount: 2,
        createdAt: '2026-03-28T10:00:00Z',
        updatedAt: '2026-03-28T10:30:00Z',
      ),
    ];
  }

  static List<TopologyModel> topologies() {
    return [
      TopologyModel(
        id: 'topo_core',
        name: 'Core Platform',
        deploymentMode: DeploymentMode.multiTier,
        baseUserCount: 100000,
        growthTargets: const [1000, 10000, 100000, 1000000],
        components: [
          _component(
            'cmp_client',
            'Client App',
            ComponentType.client,
            140,
            250,
          ),
          _component('cmp_cdn', 'Edge CDN', ComponentType.cdn, 320, 120),
          _component(
            'cmp_lb',
            'Traffic Gateway',
            ComponentType.loadBalancer,
            520,
            230,
          ),
          _component('cmp_api', 'API Servers', ComponentType.compute, 760, 240),
          _component(
            'cmp_cache',
            'Redis Cache',
            ComponentType.cache,
            1000,
            130,
          ),
          _component('cmp_db', 'Primary DB', ComponentType.database, 1040, 340),
          _component(
            'cmp_obj',
            'Object Storage',
            ComponentType.objectStore,
            850,
            480,
          ),
          _component(
            'cmp_queue',
            'Event Queue',
            ComponentType.messageQueue,
            1230,
            230,
          ),
        ],
        edges: const [
          TopologyEdge(
            id: 'edge_1',
            sourceComponentId: 'cmp_client',
            targetComponentId: 'cmp_cdn',
            estimatedBandwidthMbps: 350,
            estimatedLatencyMs: 25,
          ),
          TopologyEdge(
            id: 'edge_2',
            sourceComponentId: 'cmp_cdn',
            targetComponentId: 'cmp_lb',
            estimatedBandwidthMbps: 250,
            estimatedLatencyMs: 12,
          ),
          TopologyEdge(
            id: 'edge_3',
            sourceComponentId: 'cmp_lb',
            targetComponentId: 'cmp_api',
            estimatedBandwidthMbps: 400,
            estimatedLatencyMs: 2,
          ),
          TopologyEdge(
            id: 'edge_4',
            sourceComponentId: 'cmp_api',
            targetComponentId: 'cmp_cache',
            estimatedBandwidthMbps: 180,
            estimatedLatencyMs: 1,
          ),
          TopologyEdge(
            id: 'edge_5',
            sourceComponentId: 'cmp_api',
            targetComponentId: 'cmp_db',
            estimatedBandwidthMbps: 200,
            estimatedLatencyMs: 2,
          ),
          TopologyEdge(
            id: 'edge_6',
            sourceComponentId: 'cmp_api',
            targetComponentId: 'cmp_obj',
            estimatedBandwidthMbps: 120,
            estimatedLatencyMs: 4,
          ),
          TopologyEdge(
            id: 'edge_7',
            sourceComponentId: 'cmp_api',
            targetComponentId: 'cmp_queue',
            estimatedBandwidthMbps: 90,
            estimatedLatencyMs: 3,
          ),
        ],
      ),
      TopologyModel(
        id: 'topo_ai',
        name: 'AI Analytics Expansion',
        deploymentMode: DeploymentMode.distributed,
        baseUserCount: 250000,
        growthTargets: const [1000, 10000, 100000, 1000000],
        components: [
          _component('ai_client', 'Client App', ComponentType.client, 130, 260),
          _component('ai_lb', 'Ingress', ComponentType.loadBalancer, 380, 240),
          _component(
            'ai_compute',
            'Inference Cluster',
            ComponentType.compute,
            650,
            210,
          ),
          _component(
            'ai_vector',
            'Vector Store',
            ComponentType.database,
            980,
            290,
          ),
          _component(
            'ai_cache',
            'Realtime Cache',
            ComponentType.cache,
            880,
            110,
          ),
          _component(
            'ai_store',
            'Media Bucket',
            ComponentType.objectStore,
            760,
            420,
          ),
        ],
        edges: const [
          TopologyEdge(
            id: 'ai_edge_1',
            sourceComponentId: 'ai_client',
            targetComponentId: 'ai_lb',
            estimatedBandwidthMbps: 220,
            estimatedLatencyMs: 18,
          ),
          TopologyEdge(
            id: 'ai_edge_2',
            sourceComponentId: 'ai_lb',
            targetComponentId: 'ai_compute',
            estimatedBandwidthMbps: 320,
            estimatedLatencyMs: 2,
          ),
          TopologyEdge(
            id: 'ai_edge_3',
            sourceComponentId: 'ai_compute',
            targetComponentId: 'ai_vector',
            estimatedBandwidthMbps: 240,
            estimatedLatencyMs: 2,
          ),
          TopologyEdge(
            id: 'ai_edge_4',
            sourceComponentId: 'ai_compute',
            targetComponentId: 'ai_cache',
            estimatedBandwidthMbps: 160,
            estimatedLatencyMs: 1,
          ),
        ],
      ),
    ];
  }

  static ComputeSpec computeSpec(String componentId) {
    return ComputeSpec(
      topologyComponentId: componentId,
      cpuCores: componentId == 'ai_compute' ? 16 : 8,
      ramGb: componentId == 'ai_compute' ? 64 : 32,
      gpuType: componentId == 'ai_compute' ? 'a10g' : 'none',
      gpuCount: componentId == 'ai_compute' ? 2 : 0,
      gpuVramGb: componentId == 'ai_compute' ? 24 : 0,
      instanceFamily: componentId == 'ai_compute' ? 'g5' : 'm7g',
      instanceSize: componentId == 'ai_compute' ? '4xlarge' : '2xlarge',
      os: 'linux',
      storageGb: 150,
      cloudProvider: 'aws',
      region: 'us-east-1',
      autoscalingEnabled: true,
      minInstances: 2,
      maxInstances: componentId == 'ai_compute' ? 12 : 6,
      targetCpuUtilization: 0.7,
      targetMemoryUtilization: 0.8,
    );
  }

  static CacheSpec cacheSpec(String componentId) {
    return CacheSpec(
      topologyComponentId: componentId,
      cacheDatabase: 'redis',
      memoryGb: 8,
      evictionPolicy: 'allkeys_lru',
      ttlSeconds: 1800,
      clusterNodes: 2,
      highAvailability: true,
    );
  }

  static LoadBalancerSpec loadBalancerSpec(String componentId) {
    return LoadBalancerSpec(
      topologyComponentId: componentId,
      algorithm: 'least_connections',
      targetComponentIds: const ['cmp_api'],
      healthCheckIntervalSeconds: 15,
      sslTermination: true,
      estimatedRequestsPerSecond: 1400,
      estimatedDataProcessedGbMonth: 1800,
    );
  }

  static CdnSpec cdnSpec(String componentId) {
    return CdnSpec(
      topologyComponentId: componentId,
      provider: 'cloudflare',
      estimatedDataTransferGbMonth: 2400,
      estimatedRequestsMillionMonth: 55,
      cacheHitRatio: 0.91,
      customDomain: true,
      ssl: true,
    );
  }

  static DbModelSpec dbSpec(String componentId) {
    return DbModelSpec(
      topologyComponentId: componentId,
      databaseId: componentId == 'ai_vector' ? 'pgvector' : 'postgresql',
      baseUserCount: componentId == 'ai_vector' ? 250000 : 100000,
      entities: [
        const EntityModel(
          id: 'entity_user',
          name: 'User',
          isCentral: true,
          description: 'Primary customer profile table.',
          indexes: [],
          fields: [
            EntityFieldModel(
              id: 'field_user_id',
              name: 'user_id',
              type: 'uuid',
              required: true,
              unique: true,
              indexed: true,
              avgSizeBytes: 16,
              key: FieldKeyConfig(keyType: 'primary'),
            ),
            EntityFieldModel(
              id: 'field_email',
              name: 'email',
              type: 'string',
              required: true,
              unique: true,
              indexed: true,
              avgSizeBytes: 48,
              key: FieldKeyConfig(keyType: 'none'),
            ),
            EntityFieldModel(
              id: 'field_segment',
              name: 'segment',
              type: 'string',
              required: true,
              unique: false,
              indexed: false,
              avgSizeBytes: 32,
              key: FieldKeyConfig(keyType: 'none'),
            ),
          ],
        ),
        const EntityModel(
          id: 'entity_order',
          name: 'Order',
          isCentral: false,
          description: 'Commercial order model.',
          indexes: [],
          fields: [
            EntityFieldModel(
              id: 'field_order_id',
              name: 'order_id',
              type: 'uuid',
              required: true,
              unique: true,
              indexed: true,
              avgSizeBytes: 16,
              key: FieldKeyConfig(keyType: 'primary'),
            ),
            EntityFieldModel(
              id: 'field_order_user_id',
              name: 'user_id',
              type: 'uuid',
              required: true,
              unique: false,
              indexed: true,
              avgSizeBytes: 16,
              key: FieldKeyConfig(
                keyType: 'foreign',
                referencesEntityId: 'entity_user',
                referencesFieldId: 'field_user_id',
              ),
            ),
            EntityFieldModel(
              id: 'field_total',
              name: 'total',
              type: 'decimal',
              required: true,
              unique: false,
              indexed: false,
              avgSizeBytes: 12,
              key: FieldKeyConfig(keyType: 'none'),
            ),
          ],
        ),
        const EntityModel(
          id: 'entity_event',
          name: 'Event',
          isCentral: false,
          description: 'Telemetry and feature usage stream.',
          indexes: [],
          fields: [
            EntityFieldModel(
              id: 'field_event_id',
              name: 'event_id',
              type: 'uuid',
              required: true,
              unique: true,
              indexed: true,
              avgSizeBytes: 16,
              key: FieldKeyConfig(keyType: 'primary'),
            ),
            EntityFieldModel(
              id: 'field_event_user_id',
              name: 'user_id',
              type: 'uuid',
              required: true,
              unique: false,
              indexed: true,
              avgSizeBytes: 16,
              key: FieldKeyConfig(
                keyType: 'foreign',
                referencesEntityId: 'entity_user',
                referencesFieldId: 'field_user_id',
              ),
            ),
            EntityFieldModel(
              id: 'field_payload',
              name: 'payload',
              type: 'json',
              required: true,
              unique: false,
              indexed: false,
              avgSizeBytes: 196,
              key: FieldKeyConfig(keyType: 'none'),
            ),
          ],
        ),
      ],
      relationships: const [
        RelationshipModel(
          id: 'rel_1',
          sourceEntityId: 'entity_user',
          targetEntityId: 'entity_order',
          type: '1:N',
          ratio: 12,
          fkFieldId: 'field_order_user_id',
          description: 'Each user can place many orders.',
        ),
        RelationshipModel(
          id: 'rel_2',
          sourceEntityId: 'entity_user',
          targetEntityId: 'entity_event',
          type: '1:N',
          ratio: 120,
          fkFieldId: 'field_event_user_id',
          description: 'Each user emits many events.',
        ),
      ],
    );
  }

  static DbStorageProjection storageProjection(String componentId) {
    return const DbStorageProjection(
      topologyComponentId: 'cmp_db',
      databaseId: 'postgresql',
      totalDataBytes: 503316480,
      totalIndexBytes: 104857600,
      walJournalBytes: 67108864,
      totalStorageBytes: 675282944,
      totalRecords: 13200000,
      perEntity: [
        EntityStorageProjection(
          entityId: 'entity_user',
          entityName: 'User',
          recordCount: 100000,
          avgRecordSizeBytes: 96,
          dataSizeBytes: 9600000,
          indexOverheadBytes: 2400000,
          totalSizeBytes: 12000000,
        ),
        EntityStorageProjection(
          entityId: 'entity_order',
          entityName: 'Order',
          recordCount: 1200000,
          avgRecordSizeBytes: 72,
          dataSizeBytes: 86400000,
          indexOverheadBytes: 22000000,
          totalSizeBytes: 108400000,
        ),
        EntityStorageProjection(
          entityId: 'entity_event',
          entityName: 'Event',
          recordCount: 12000000,
          avgRecordSizeBytes: 220,
          dataSizeBytes: 2640000000,
          indexOverheadBytes: 380000000,
          totalSizeBytes: 3020000000,
        ),
      ],
    );
  }

  static K8sClusterSpec k8sSpec(String componentId) {
    return K8sClusterSpec(
      topologyComponentId: componentId,
      namespace: 'dataforge',
      replicas: 4,
      serviceType: 'LoadBalancer',
      servicePort: 80,
      targetPort: 8080,
      hpaEnabled: true,
      minReplicas: 2,
      maxReplicas: 12,
      targetCpuUtilization: 70,
      containers: const [
        K8sContainerModel(
          name: 'api',
          image: 'ghcr.io/dataforge/api',
          tag: 'latest',
          ports: [
            K8sContainerPort(
              name: 'http',
              containerPort: 8080,
              protocol: 'TCP',
            ),
          ],
        ),
      ],
    );
  }

  static DockerContainerSpec dockerSpec(String componentId) {
    return DockerContainerSpec(
      topologyComponentId: componentId,
      containerName: 'dataforge-api',
      image: 'ghcr.io/dataforge/api',
      tag: 'latest',
      network: 'bridge',
      restartPolicy: 'unless-stopped',
      ports: const [
        DockerPortMapping(hostPort: 8080, containerPort: 8080, protocol: 'TCP'),
      ],
    );
  }

  static ConsolidatedDashboard dashboard() {
    return const ConsolidatedDashboard(
      projectId: 'proj_demo',
      projectName: 'Retail Intelligence Platform',
      deploymentMode: 'multi_tier',
      baseUserCount: 100000,
      totalMonthlyCost: 1247.30,
      comparisonDatabase: null,
      comparisonTotalMonthly: null,
      comparisonDelta: null,
      perComponent: [
        ComponentCostSummary(
          topologyComponentId: 'cmp_api',
          componentName: 'API Servers',
          componentType: ComponentType.compute,
          totalMonthly: 524,
          details: {'instance': 416, 'storage': 108},
        ),
        ComponentCostSummary(
          topologyComponentId: 'cmp_db',
          componentName: 'Primary DB',
          componentType: ComponentType.database,
          totalMonthly: 387.3,
          details: {'instance': 220, 'storage': 86, 'iops': 51.3, 'backup': 30},
        ),
        ComponentCostSummary(
          topologyComponentId: 'cmp_cache',
          componentName: 'Redis Cache',
          componentType: ComponentType.cache,
          totalMonthly: 100,
          details: {'memory': 100},
        ),
        ComponentCostSummary(
          topologyComponentId: 'cmp_lb',
          componentName: 'Traffic Gateway',
          componentType: ComponentType.loadBalancer,
          totalMonthly: 60,
          details: {'fixed': 22, 'lcu': 18, 'data_processing': 20},
        ),
        ComponentCostSummary(
          topologyComponentId: 'cmp_cdn',
          componentName: 'Edge CDN',
          componentType: ComponentType.cdn,
          totalMonthly: 50,
          details: {'data_transfer': 37, 'requests': 13},
        ),
        ComponentCostSummary(
          topologyComponentId: 'cmp_obj',
          componentName: 'Object Storage',
          componentType: ComponentType.objectStore,
          totalMonthly: 126,
          details: {'storage': 126},
        ),
      ],
      perCategory: [
        CategoryCostSummary(
          category: 'compute',
          totalMonthly: 524,
          percentage: 42,
        ),
        CategoryCostSummary(
          category: 'storage',
          totalMonthly: 287.3,
          percentage: 23,
        ),
        CategoryCostSummary(
          category: 'network',
          totalMonthly: 186,
          percentage: 15,
        ),
        CategoryCostSummary(
          category: 'cache',
          totalMonthly: 100,
          percentage: 8,
        ),
        CategoryCostSummary(
          category: 'licensing',
          totalMonthly: 50,
          percentage: 4,
        ),
        CategoryCostSummary(
          category: 'backup',
          totalMonthly: 30,
          percentage: 2,
        ),
      ],
      perEntityStorage: [
        EntityCostDetail(
          entityId: 'entity_event',
          entityName: 'Event',
          recordCount: 12000000,
          storageGb: 2.81,
          storageCostMonthly: 24,
          percentageOfDbCost: 52,
        ),
        EntityCostDetail(
          entityId: 'entity_order',
          entityName: 'Order',
          recordCount: 1200000,
          storageGb: 0.10,
          storageCostMonthly: 8.4,
          percentageOfDbCost: 18,
        ),
        EntityCostDetail(
          entityId: 'entity_user',
          entityName: 'User',
          recordCount: 100000,
          storageGb: 0.012,
          storageCostMonthly: 2.1,
          percentageOfDbCost: 5,
        ),
      ],
      growthProjections: [
        GrowthProjection(userCount: 1000, totalMonthly: 110, perComponent: []),
        GrowthProjection(userCount: 10000, totalMonthly: 420, perComponent: []),
        GrowthProjection(
          userCount: 100000,
          totalMonthly: 1247.3,
          perComponent: [],
        ),
        GrowthProjection(
          userCount: 1000000,
          totalMonthly: 12250,
          perComponent: [],
        ),
      ],
      optimizationHints: [
        OptimizationHint(
          category: 'cache',
          message: 'Redis absorbs repeated reads and trims database IOPS cost.',
          estimatedSavingsMonthly: 47,
          confidence: 0.82,
        ),
        OptimizationHint(
          category: 'compute',
          message:
              'Reserved compute on the API tier would reduce steady-state spend.',
          estimatedSavingsMonthly: 94,
          confidence: 0.74,
        ),
        OptimizationHint(
          category: 'storage',
          message:
              'Event payloads dominate storage. Consider TTL and archive policies.',
          estimatedSavingsMonthly: 31,
          confidence: 0.78,
        ),
      ],
    );
  }

  static TopologyComparison comparison() {
    return const TopologyComparison(
      sourceProjectId: 'proj_demo',
      sourceTopologyId: 'topo_core',
      sourceTopologyName: 'Core Platform',
      targetProjectId: 'proj_demo',
      targetTopologyId: 'topo_ai',
      targetTopologyName: 'AI Analytics Expansion',
      addedComponents: 2,
      removedComponents: 1,
      modifiedComponents: 2,
      unchangedComponents: 2,
      componentDiffs: [
        ComponentDiff(
          componentName: 'Inference Cluster',
          componentType: 'compute',
          status: 'added',
          changes: ['Adds GPU-backed serving nodes for analytics.'],
        ),
        ComponentDiff(
          componentName: 'Primary DB',
          componentType: 'database',
          status: 'modified',
          changes: ['Swaps relational workload for pgvector search patterns.'],
        ),
        ComponentDiff(
          componentName: 'Redis Cache',
          componentType: 'cache',
          status: 'unchanged',
          changes: ['Keeps realtime serving cache.'],
        ),
      ],
    );
  }

  static List<MemberRecord> members() {
    return const [
      MemberRecord(
        projectId: 'proj_demo',
        userId: 'user_demo',
        role: ProjectRole.owner,
        topologyAccess: [],
        addedBy: 'user_demo',
        createdAt: '2026-03-28T10:00:00Z',
      ),
      MemberRecord(
        projectId: 'proj_demo',
        userId: 'user_architect',
        role: ProjectRole.member,
        topologyAccess: ['topo_core'],
        addedBy: 'user_demo',
        createdAt: '2026-03-28T10:05:00Z',
      ),
    ];
  }

  static List<DatabaseReference> databases() {
    return const [
      DatabaseReference(id: 'postgresql', name: 'PostgreSQL', category: 'sql'),
      DatabaseReference(id: 'mysql', name: 'MySQL', category: 'sql'),
      DatabaseReference(
        id: 'mongodb',
        name: 'MongoDB',
        category: 'document_kv',
      ),
      DatabaseReference(id: 'pgvector', name: 'PGVector', category: 'vector'),
      DatabaseReference(id: 'redis', name: 'Redis', category: 'in_memory'),
      DatabaseReference(
        id: 'opensearch',
        name: 'OpenSearch',
        category: 'search',
      ),
    ];
  }

  static List<ReferenceOption> regions() {
    return const [
      ReferenceOption(id: 'us-east-1', name: 'us-east-1'),
      ReferenceOption(id: 'us-west-2', name: 'us-west-2'),
      ReferenceOption(id: 'eu-west-1', name: 'eu-west-1'),
      ReferenceOption(id: 'ap-south-1', name: 'ap-south-1'),
    ];
  }

  static List<ReferenceOption> cloudProviders() {
    return const [
      ReferenceOption(id: 'aws', name: 'AWS'),
      ReferenceOption(id: 'azure', name: 'Azure'),
      ReferenceOption(id: 'gcp', name: 'GCP'),
      ReferenceOption(id: 'self_hosted', name: 'Self Hosted'),
    ];
  }

  static ServerEndpointRegistry endpointRegistry(String componentId) {
    return ServerEndpointRegistry(
      topologyComponentId: componentId,
      endpoints: [
        const EndpointMetadata(
          id: 'ep_get_users',
          path: '/api/v1/users',
          httpMethod: 'GET',
          handlerFunction: 'listUsers',
          sourceFile: 'src/handlers/users.go',
          dbCalls: [
            DBCallMetadata(
              queryType: 'SELECT',
              targetEntity: 'User',
              isPaginated: true,
              estimatedRowsAffected: '50',
            ),
          ],
          cacheCalls: [
            CacheCallMetadata(
              operation: 'GET',
              keyPattern: 'users:list:*',
              ttlSeconds: 300,
            ),
          ],
          serviceCalls: [],
          queueInteractions: [],
          riskScore: 12,
          riskFindings: [],
        ),
        const EndpointMetadata(
          id: 'ep_create_order',
          path: '/api/v1/orders',
          httpMethod: 'POST',
          handlerFunction: 'createOrder',
          sourceFile: 'src/handlers/orders.go',
          dbCalls: [
            DBCallMetadata(
              queryType: 'INSERT',
              targetEntity: 'Order',
              isPaginated: false,
            ),
            DBCallMetadata(
              queryType: 'SELECT',
              targetEntity: 'User',
              isPaginated: false,
              estimatedRowsAffected: '1',
            ),
          ],
          cacheCalls: [
            CacheCallMetadata(
              operation: 'DELETE',
              keyPattern: 'users:orders:*',
            ),
          ],
          serviceCalls: [
            ServiceCallMetadata(
              targetService: 'payment-service',
              targetEndpoint: '/charge',
              httpMethod: 'POST',
              isAsync: false,
            ),
          ],
          queueInteractions: [
            QueueInteraction(
              role: 'producer',
              queueName: 'order-events',
              messageType: 'OrderCreated',
            ),
          ],
          riskScore: 45,
          riskFindings: ['N+1 query on user lookup'],
        ),
        const EndpointMetadata(
          id: 'ep_get_events',
          path: '/api/v1/events',
          httpMethod: 'GET',
          handlerFunction: 'listEvents',
          sourceFile: 'src/handlers/events.go',
          dbCalls: [
            DBCallMetadata(
              queryType: 'SELECT',
              targetEntity: 'Event',
              isPaginated: false,
              estimatedRowsAffected: '10000',
            ),
          ],
          cacheCalls: [],
          serviceCalls: [],
          queueInteractions: [],
          riskScore: 78,
          riskFindings: ['Unbounded fetch', 'Missing pagination'],
        ),
      ],
      lastSyncedAt: '2026-04-10T14:30:00Z',
      syncVersion: 3,
    );
  }

  static RiskDashboard riskDashboard() {
    return const RiskDashboard(
      projectId: 'proj_demo',
      topologyId: 'topo_core',
      totalEndpoints: 24,
      analyzedEndpoints: 24,
      overallRiskScore: 42,
      riskDistribution: {
        'critical': 1,
        'high': 3,
        'medium': 7,
        'low': 13,
      },
      topRisks: [
        EndpointRiskSummary(
          endpointId: 'ep_get_events',
          endpointPath: '/api/v1/events',
          httpMethod: 'GET',
          overallRiskScore: 78,
          findingCount: 2,
          criticalCount: 0,
          highCount: 1,
          mediumCount: 1,
          findings: [
            RiskFinding(
              id: 'rf_1',
              endpointId: 'ep_get_events',
              endpointPath: '/api/v1/events',
              riskType: RiskType.unboundedFetch,
              severity: RiskSeverity.high,
              message: 'Endpoint fetches up to 10,000 rows without LIMIT.',
              sourceFile: 'src/handlers/events.go',
              codeSnippet: 'db.Query("SELECT * FROM events WHERE user_id = ?")',
              recommendation: 'Add pagination with cursor-based or offset/limit.',
              detectedAt: '2026-04-10T14:30:00Z',
            ),
            RiskFinding(
              id: 'rf_2',
              endpointId: 'ep_get_events',
              endpointPath: '/api/v1/events',
              riskType: RiskType.missingPagination,
              severity: RiskSeverity.medium,
              message: 'No pagination parameters accepted on event listing.',
              sourceFile: 'src/handlers/events.go',
              recommendation: 'Accept page/limit query parameters and apply to query.',
              detectedAt: '2026-04-10T14:30:00Z',
            ),
          ],
        ),
        EndpointRiskSummary(
          endpointId: 'ep_create_order',
          endpointPath: '/api/v1/orders',
          httpMethod: 'POST',
          overallRiskScore: 45,
          findingCount: 1,
          criticalCount: 0,
          highCount: 0,
          mediumCount: 1,
          findings: [
            RiskFinding(
              id: 'rf_3',
              endpointId: 'ep_create_order',
              endpointPath: '/api/v1/orders',
              riskType: RiskType.nPlusOne,
              severity: RiskSeverity.medium,
              message: 'User lookup inside order loop causes N+1 queries.',
              sourceFile: 'src/handlers/orders.go',
              recommendation: 'Batch user lookups or use JOIN.',
              detectedAt: '2026-04-10T14:30:00Z',
            ),
          ],
        ),
      ],
      riskByType: {
        'n_plus_one': 4,
        'missing_pagination': 3,
        'unbounded_fetch': 2,
        'full_table_scan': 1,
        'missing_index': 1,
      },
      lastAnalyzedAt: '2026-04-10T14:30:00Z',
    );
  }

  static TrafficSimulationResult trafficSimulationResult() {
    return const TrafficSimulationResult(
      topologyId: 'topo_core',
      entryPointTotalQps: 2500,
      perComponentLoad: [
        ComponentTrafficLoad(
          componentId: 'cmp_lb',
          componentName: 'Traffic Gateway',
          componentType: 'loadBalancer',
          totalRequestsPerSecond: 2500,
          breakdown: [
            TrafficSource(
              sourceEndpointId: 'ep_get_users',
              sourceEndpointPath: '/api/v1/users',
              requestsPerSecond: 1500,
              multiplier: 1.0,
            ),
            TrafficSource(
              sourceEndpointId: 'ep_create_order',
              sourceEndpointPath: '/api/v1/orders',
              requestsPerSecond: 1000,
              multiplier: 1.0,
            ),
          ],
          capacityStatus: 'OK',
        ),
        ComponentTrafficLoad(
          componentId: 'cmp_api',
          componentName: 'API Servers',
          componentType: 'compute',
          totalRequestsPerSecond: 2500,
          breakdown: [],
          capacityStatus: 'WARNING',
          capacityReason: 'Approaching autoscaling ceiling at 2500 RPS with 6 max instances.',
        ),
        ComponentTrafficLoad(
          componentId: 'cmp_db',
          componentName: 'Primary DB',
          componentType: 'database',
          totalRequestsPerSecond: 3200,
          breakdown: [],
          capacityStatus: 'CRITICAL',
          capacityReason: 'Connection pool exhausted at ~3000 concurrent queries. Consider read replicas.',
        ),
        ComponentTrafficLoad(
          componentId: 'cmp_cache',
          componentName: 'Redis Cache',
          componentType: 'cache',
          totalRequestsPerSecond: 1800,
          breakdown: [],
          capacityStatus: 'OK',
        ),
      ],
      bottleneckComponents: ['cmp_api', 'cmp_db'],
      estimatedMonthlyCostAtTraffic: 3420.50,
      estimatedTotalLatencyMs: 85,
    );
  }

  static APIGatewaySpec apiGatewaySpec(String componentId) {
    return APIGatewaySpec(
      topologyComponentId: componentId,
      rateLimitEnabled: true,
      rateLimitRps: 1000,
      rateLimitBurst: 200,
      rateLimitWindowSeconds: 60,
      authType: 'jwt',
      corsEnabled: true,
      requestLogging: true,
      routes: const [
        GatewayRoute(
          pathPattern: '/api/v1/*',
          targetComponentId: 'cmp_api',
          methods: ['GET', 'POST', 'PUT', 'DELETE'],
        ),
        GatewayRoute(
          pathPattern: '/health',
          targetComponentId: 'cmp_api',
          methods: ['GET'],
          rateLimit: 10,
        ),
      ],
      estimatedRps: 1400,
    );
  }

  static CronJobSpec cronJobSpec(String componentId) {
    return CronJobSpec(
      topologyComponentId: componentId,
      schedule: '0 */6 * * *',
      command: 'node scripts/sync-analytics.js',
      targetServiceId: 'cmp_api',
      targetEndpoint: '/internal/sync',
      timeoutSeconds: 600,
      maxRetries: 3,
      backoffMultiplier: 2.0,
      estimatedDurationSeconds: 120,
    );
  }

  static ObjectStorageSpec objectStorageSpec(String componentId) {
    return ObjectStorageSpec(
      topologyComponentId: componentId,
      provider: 's3',
      estimatedStorageGb: 500,
      estimatedRequestsMonth: 2000000,
      estimatedEgressGbMonth: 120,
      accessPolicy: 'private',
      versioningEnabled: true,
      lifecycleRules: const [
        'Transition to IA after 90 days',
        'Expire incomplete multipart after 7 days',
      ],
    );
  }

  static ServiceMeshSpec serviceMeshSpec(String componentId) {
    return ServiceMeshSpec(
      topologyComponentId: componentId,
      meshType: 'istio',
      mtlsEnabled: true,
      circuitBreakerEnabled: true,
      circuitBreakerThreshold: 5,
      circuitBreakerRecoveryMs: 30000,
      circuitBreakerHalfOpenRequests: 3,
      retryEnabled: true,
      retryMaxAttempts: 3,
      loadBalancingAlgorithm: 'round_robin',
      observabilityEnabled: true,
    );
  }

  static ThirdPartyAPISpec thirdPartyApiSpec(String componentId) {
    return ThirdPartyAPISpec(
      topologyComponentId: componentId,
      serviceName: 'Stripe Payments',
      baseUrl: 'https://api.stripe.com/v1',
      slaUptimePercent: 99.99,
      expectedLatencyMs: 180,
      fallbackBehavior: 'circuit_breaker',
      estimatedCallsMonth: 50000,
      costModel: 'per_call',
      costPerCall: 0.025,
      subscriptionCostMonthly: 0,
    );
  }

  static List<Team> teams() {
    return const [
      Team(
        teamId: 'team-demo-1',
        name: 'Platform Engineering',
        ownerId: 'user_demo',
        memberIds: ['user_demo', 'user_architect', 'user_dev'],
        createdAt: '2026-01-15T10:00:00Z',
      ),
    ];
  }

  static List<TeamInvite> teamInvites() {
    return const [
      TeamInvite(
        inviteId: 'inv-demo-1',
        teamId: 'team-demo-1',
        inviteToken: 'demo-invite-abc123',
        maxUses: 10,
        useCount: 2,
        expiresAt: '2026-05-15T00:00:00Z',
        isActive: true,
      ),
    ];
  }

  static List<ShareLink> shareLinks() {
    return const [
      ShareLink(
        id: 'share-demo-1',
        projectId: 'proj_demo',
        topologyId: 'topo_core',
        token: 'share-token-xyz789',
        readOnly: true,
        createdBy: 'user_demo',
        createdAt: '2026-04-01T10:00:00Z',
      ),
    ];
  }

  static TopologyComponent _component(
    String id,
    String name,
    ComponentType type,
    double x,
    double y,
  ) {
    return TopologyComponent(
      id: id,
      name: name,
      type: type,
      enabled: true,
      location: GeoLocation.defaultValue(),
      cloudProvider: CloudProvider.aws,
      description: '$name component',
      tags: {'canvas_x': '$x', 'canvas_y': '$y'},
    );
  }
}
