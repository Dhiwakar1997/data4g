import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatting.dart';
import '../../models/reference_models.dart';
import '../../models/spec_models.dart';
import '../../models/topology_models.dart';
import '../workspace/workspace_controller.dart';

class SpecEditorView extends ConsumerWidget {
  const SpecEditorView({super.key, required this.state});

  final WorkspaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topology = state.selectedTopology;
    if (topology == null) {
      return const _SpecPlaceholder(
        title: 'Select a project topology',
        message:
            'Stage 2 editors appear after you choose a project and topology. Pick a component to configure compute, database, cache, traffic, and container details.',
      );
    }

    if (topology.components.isEmpty) {
      return const _SpecPlaceholder(
        title: 'No components yet',
        message:
            'Add components on the topology canvas first. Then this screen will unlock API-backed editors for compute, database, cache, load balancer, and CDN nodes.',
      );
    }

    final controller = ref.read(workspaceControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
        final navigator = _SpecNavigator(
          state: state,
          onSelect: controller.selectComponent,
        );
        final editor = _SpecEditorBody(state: state);

        if (compact) {
          return Column(
            children: [
              SizedBox(height: 280, child: navigator),
              const SizedBox(height: 18),
              Expanded(child: editor),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 320, child: navigator),
            const SizedBox(width: 18),
            Expanded(child: editor),
          ],
        );
      },
    );
  }
}

class _SpecNavigator extends StatelessWidget {
  const _SpecNavigator({required this.state, required this.onSelect});

  final WorkspaceState state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final topology = state.selectedTopology!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(color: AppColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stage 2 Specs',
            style: AppTheme.syne(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            topology.name,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaBadge(
                label: 'Components',
                value: '${topology.components.length}',
              ),
              _MetaBadge(label: 'Mode', value: topology.deploymentMode.label),
              _MetaBadge(
                label: 'Base users',
                value: compactNumber(topology.baseUserCount),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'API-backed editors are ready for compute, database, cache, load balancer, and CDN. Other nodes stay editable from the topology canvas for now.',
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: topology.components.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final component = topology.components[index];
                final selected = state.selectedComponentId == component.id;
                final apiBacked = _isApiBackedComponent(component.type);
                return InkWell(
                  onTap: () => onSelect(component.id),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandYellow.withValues(alpha: 0.12)
                          : AppColors.panel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? AppColors.brandYellow
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _componentColor(
                              component.type,
                            ).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _componentIcon(component.type),
                            color: _componentColor(component.type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                component.name,
                                style: AppTheme.syne(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                component.type.label,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _StatusChip(
                                    label: apiBacked
                                        ? 'API-backed'
                                        : 'Topology only',
                                    color: apiBacked
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                  ),
                                  _StatusChip(
                                    label: titleCase(component.location.region),
                                    color: AppColors.info,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecEditorBody extends StatelessWidget {
  const _SpecEditorBody({required this.state});

  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final component = state.selectedComponent;
    if (component == null) {
      return const _SpecPlaceholder(
        title: 'Pick a component',
        message:
            'Choose a node from the spec navigator to open its Stage 2 editor. The browser layout keeps topology design and configuration close together so future tablet work stays aligned.',
      );
    }

    return Container(
      decoration: AppTheme.glassCard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditorHero(component: component, state: state),
            const SizedBox(height: 18),
            switch (component.type) {
              ComponentType.compute => _ComputeSpecEditor(
                component: component,
                state: state,
              ),
              ComponentType.database => _DatabaseSpecEditor(
                component: component,
                state: state,
              ),
              ComponentType.cache => _CacheSpecEditor(
                component: component,
                state: state,
              ),
              ComponentType.loadBalancer => _LoadBalancerSpecEditor(
                component: component,
                state: state,
              ),
              ComponentType.cdn => _CdnSpecEditor(
                component: component,
                state: state,
              ),
              _ => _UnsupportedSpecEditor(component: component),
            },
          ],
        ),
      ),
    );
  }
}

class _EditorHero extends StatelessWidget {
  const _EditorHero({required this.component, required this.state});

  final TopologyComponent component;
  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final apiBacked = _isApiBackedComponent(component.type);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.panelSoft,
            _componentColor(component.type).withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _componentColor(
                    component.type,
                  ).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _componentIcon(component.type),
                  color: _componentColor(component.type),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component.name,
                      style: AppTheme.syne(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      component.description ??
                          '${component.type.label} configuration inside ${state.selectedTopology?.name ?? 'the current topology'}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: apiBacked ? 'Connected to API' : 'Topology-level only',
                color: apiBacked ? AppColors.success : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaBadge(label: 'Type', value: component.type.label),
              _MetaBadge(
                label: 'Provider',
                value: component.cloudProvider.label,
              ),
              _MetaBadge(
                label: 'Region',
                value: titleCase(component.location.region),
              ),
              _MetaBadge(
                label: 'Stage',
                value: apiBacked ? 'Spec + cost' : 'Canvas only',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComputeSpecEditor extends ConsumerStatefulWidget {
  const _ComputeSpecEditor({required this.component, required this.state});

  final TopologyComponent component;
  final WorkspaceState state;

  @override
  ConsumerState<_ComputeSpecEditor> createState() => _ComputeSpecEditorState();
}

class _ComputeSpecEditorState extends ConsumerState<_ComputeSpecEditor> {
  late ComputeSpec _draft;
  late K8sClusterSpec _k8sDraft;
  late DockerContainerSpec _dockerDraft;

  @override
  void initState() {
    super.initState();
    _syncDrafts();
  }

  @override
  void didUpdateWidget(covariant _ComputeSpecEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final componentId = widget.component.id;
    final shouldSync =
        oldWidget.component.id != componentId ||
        (oldWidget.state.computeSpecs[componentId] == null &&
            widget.state.computeSpecs[componentId] != null) ||
        (oldWidget.state.k8sSpecs[componentId] == null &&
            widget.state.k8sSpecs[componentId] != null) ||
        (oldWidget.state.dockerSpecs[componentId] == null &&
            widget.state.dockerSpecs[componentId] != null);
    if (shouldSync) {
      _syncDrafts();
    }
  }

  void _syncDrafts() {
    _draft =
        widget.state.computeSpecs[widget.component.id] ??
        _defaultComputeSpec(widget.component);
    _k8sDraft =
        widget.state.k8sSpecs[widget.component.id] ??
        _defaultK8sSpec(widget.component);
    _dockerDraft =
        widget.state.dockerSpecs[widget.component.id] ??
        _defaultDockerSpec(widget.component);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final regionOptions = _mergeOptions(
      _draft.region,
      widget.state.regions.map((item) => item.id),
    );
    final providerOptions = _mergeOptions(
      _draft.cloudProvider,
      widget.state.cloudProviders.map((item) => item.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Compute sizing',
          subtitle:
              'Shape server capacity, cloud placement, and autoscaling targets that feed the cost engine.',
          child: Column(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaBadge(label: 'Family', value: _draft.instanceFamily),
                  _MetaBadge(label: 'Size', value: _draft.instanceSize),
                  _MetaBadge(label: 'OS', value: titleCase(_draft.os)),
                  _MetaBadge(
                    label: 'Autoscaling',
                    value: _draft.autoscalingEnabled ? 'Enabled' : 'Fixed',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SliderField(
                label: 'CPU cores',
                value: _draft.cpuCores.toDouble(),
                min: 1,
                max: 64,
                divisions: 63,
                display: '${_draft.cpuCores}',
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(cpuCores: value.round());
                }),
              ),
              _SliderField(
                label: 'RAM',
                value: _draft.ramGb,
                min: 1,
                max: 256,
                divisions: 255,
                display: '${_draft.ramGb.toStringAsFixed(0)} GB',
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(ramGb: value);
                }),
              ),
              _SliderField(
                label: 'Attached storage',
                value: _draft.storageGb,
                min: 20,
                max: 2048,
                divisions: 2028,
                display: '${_draft.storageGb.toStringAsFixed(0)} GB',
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(storageGb: value);
                }),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _draft.instanceFamily,
                      decoration: const InputDecoration(
                        labelText: 'Instance family',
                      ),
                      items: _buildStringItems(
                        _mergeOptions(_draft.instanceFamily, const [
                          'general_purpose',
                          'm7g',
                          'c7g',
                          'r7g',
                          'g5',
                          'n2-standard',
                        ]),
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(instanceFamily: value);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _draft.instanceSize,
                      decoration: const InputDecoration(
                        labelText: 'Instance size',
                      ),
                      items: _buildStringItems(
                        _mergeOptions(_draft.instanceSize, const [
                          'small',
                          'medium',
                          'large',
                          'xlarge',
                          '2xlarge',
                          '4xlarge',
                        ]),
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(instanceSize: value);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _draft.os,
                      decoration: const InputDecoration(labelText: 'OS'),
                      items: _buildStringItems(
                        _mergeOptions(_draft.os, const [
                          'linux',
                          'ubuntu',
                          'debian',
                          'windows',
                        ]),
                        titleCaseValues: true,
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(os: value);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _draft.gpuType,
                      decoration: const InputDecoration(labelText: 'GPU'),
                      items: _buildStringItems(
                        _mergeOptions(_draft.gpuType, const [
                          'none',
                          't4',
                          'a10g',
                          'a100',
                          'l4',
                          'h100',
                        ]),
                        titleCaseValues: true,
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(
                            gpuType: value,
                            gpuCount: value == 'none'
                                ? 0
                                : _draft.gpuCount.clamp(1, 8),
                            gpuVramGb: value == 'none' ? 0 : _draft.gpuVramGb,
                          );
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _draft.cloudProvider,
                      decoration: const InputDecoration(
                        labelText: 'Cloud provider',
                      ),
                      items: _buildStringItems(
                        providerOptions,
                        titleCaseValues: true,
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(cloudProvider: value);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _draft.region,
                      decoration: const InputDecoration(labelText: 'Region'),
                      items: regionOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                titleCase(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(region: value);
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_draft.gpuType != 'none') ...[
                const SizedBox(height: 12),
                _SliderField(
                  label: 'GPU count',
                  value: _draft.gpuCount.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  display: '${_draft.gpuCount}',
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(gpuCount: value.round());
                  }),
                ),
                _SliderField(
                  label: 'GPU VRAM',
                  value: _draft.gpuVramGb,
                  min: 8,
                  max: 120,
                  divisions: 28,
                  display: '${_draft.gpuVramGb.toStringAsFixed(0)} GB',
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(gpuVramGb: value);
                  }),
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => controller.saveComputeSpec(_draft),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save compute spec'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Autoscaling policy',
          subtitle:
              'Use the same high-level server model for local, single-instance, and distributed deployments.',
          child: Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.autoscalingEnabled,
                activeColor: AppColors.brandYellow,
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(
                    autoscalingEnabled: value,
                    minInstances: value ? _draft.minInstances : 1,
                    maxInstances: value ? _draft.maxInstances : 1,
                  );
                }),
                title: const Text('Enable autoscaling'),
                subtitle: const Text(
                  'When disabled, the topology cost model uses a single instance for this server.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 10),
              _SliderField(
                label: 'Minimum instances',
                value: _draft.minInstances.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                display: '${_draft.minInstances}',
                onChanged: _draft.autoscalingEnabled
                    ? (value) => setState(() {
                        final nextMin = value.round();
                        _draft = _draft.copyWith(
                          minInstances: nextMin,
                          maxInstances: _draft.maxInstances < nextMin
                              ? nextMin
                              : _draft.maxInstances,
                        );
                      })
                    : null,
              ),
              _SliderField(
                label: 'Maximum instances',
                value: _draft.maxInstances.toDouble(),
                min: _draft.minInstances.toDouble(),
                max: 40,
                divisions: 40 - _draft.minInstances,
                display: '${_draft.maxInstances}',
                onChanged: _draft.autoscalingEnabled
                    ? (value) => setState(() {
                        _draft = _draft.copyWith(maxInstances: value.round());
                      })
                    : null,
              ),
              _SliderField(
                label: 'Target CPU utilization',
                value: _draft.targetCpuUtilization,
                min: 0.3,
                max: 0.95,
                divisions: 13,
                display: '${(_draft.targetCpuUtilization * 100).round()}%',
                onChanged: _draft.autoscalingEnabled
                    ? (value) => setState(() {
                        _draft = _draft.copyWith(targetCpuUtilization: value);
                      })
                    : null,
              ),
              _SliderField(
                label: 'Target memory utilization',
                value: _draft.targetMemoryUtilization,
                min: 0.3,
                max: 0.95,
                divisions: 13,
                display: '${(_draft.targetMemoryUtilization * 100).round()}%',
                onChanged: _draft.autoscalingEnabled
                    ? (value) => setState(() {
                        _draft = _draft.copyWith(
                          targetMemoryUtilization: value,
                        );
                      })
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Kubernetes cluster',
          subtitle:
              'Capture orchestration settings for future deployment generation and cluster cost work.',
          action: ElevatedButton.icon(
            onPressed: () => ref
                .read(workspaceControllerProvider.notifier)
                .saveK8sSpec(_k8sDraft),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save k8s spec'),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 220,
                    child: _InlineTextField(
                      label: 'Namespace',
                      value: _k8sDraft.namespace,
                      onChanged: (value) => setState(() {
                        _k8sDraft = _k8sDraft.copyWith(namespace: value);
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _k8sDraft.serviceType,
                      decoration: const InputDecoration(
                        labelText: 'Service type',
                      ),
                      items: _buildStringItems(
                        _mergeOptions(_k8sDraft.serviceType, const [
                          'ClusterIP',
                          'NodePort',
                          'LoadBalancer',
                        ]),
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _k8sDraft = _k8sDraft.copyWith(serviceType: value);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _InlineTextField(
                      label: 'Service port',
                      value: '${_k8sDraft.servicePort}',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final port = int.tryParse(value);
                        if (port == null) {
                          return;
                        }
                        setState(() {
                          _k8sDraft = _k8sDraft.copyWith(servicePort: port);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _InlineTextField(
                      label: 'Target port',
                      value: '${_k8sDraft.targetPort}',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final port = int.tryParse(value);
                        if (port == null) {
                          return;
                        }
                        setState(() {
                          _k8sDraft = _k8sDraft.copyWith(targetPort: port);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SliderField(
                label: 'Replicas',
                value: _k8sDraft.replicas.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                display: '${_k8sDraft.replicas}',
                onChanged: (value) => setState(() {
                  _k8sDraft = _k8sDraft.copyWith(replicas: value.round());
                }),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _k8sDraft.hpaEnabled,
                activeColor: AppColors.brandYellow,
                onChanged: (value) => setState(() {
                  _k8sDraft = _k8sDraft.copyWith(
                    hpaEnabled: value,
                    minReplicas: value ? _k8sDraft.minReplicas : 1,
                    maxReplicas: value ? _k8sDraft.maxReplicas : 1,
                  );
                }),
                title: const Text('Enable horizontal pod autoscaling'),
              ),
              _SliderField(
                label: 'Minimum replicas',
                value: _k8sDraft.minReplicas.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                display: '${_k8sDraft.minReplicas}',
                onChanged: _k8sDraft.hpaEnabled
                    ? (value) => setState(() {
                        final min = value.round();
                        _k8sDraft = _k8sDraft.copyWith(
                          minReplicas: min,
                          maxReplicas: _k8sDraft.maxReplicas < min
                              ? min
                              : _k8sDraft.maxReplicas,
                        );
                      })
                    : null,
              ),
              _SliderField(
                label: 'Maximum replicas',
                value: _k8sDraft.maxReplicas.toDouble(),
                min: _k8sDraft.minReplicas.toDouble(),
                max: 40,
                divisions: 40 - _k8sDraft.minReplicas,
                display: '${_k8sDraft.maxReplicas}',
                onChanged: _k8sDraft.hpaEnabled
                    ? (value) => setState(() {
                        _k8sDraft = _k8sDraft.copyWith(
                          maxReplicas: value.round(),
                        );
                      })
                    : null,
              ),
              _SliderField(
                label: 'Target CPU',
                value: _k8sDraft.targetCpuUtilization.toDouble(),
                min: 30,
                max: 95,
                divisions: 13,
                display: '${_k8sDraft.targetCpuUtilization}%',
                onChanged: _k8sDraft.hpaEnabled
                    ? (value) => setState(() {
                        _k8sDraft = _k8sDraft.copyWith(
                          targetCpuUtilization: value.round(),
                        );
                      })
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Containers',
                    style: AppTheme.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _k8sDraft = _k8sDraft.copyWith(
                          containers: [
                            ..._k8sDraft.containers,
                            K8sContainerModel(
                              name: 'app-${_k8sDraft.containers.length + 1}',
                              image: 'dataforge/app',
                              tag: 'latest',
                              ports: const [
                                K8sContainerPort(
                                  name: 'http',
                                  containerPort: 8080,
                                  protocol: 'TCP',
                                ),
                              ],
                            ),
                          ],
                        );
                      });
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add container'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._k8sDraft.containers.asMap().entries.map((entry) {
                final index = entry.key;
                final container = entry.value;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              container.name,
                              style: AppTheme.syne(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _k8sDraft.containers.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      final updated = [..._k8sDraft.containers]
                                        ..removeAt(index);
                                      _k8sDraft = _k8sDraft.copyWith(
                                        containers: updated,
                                      );
                                    });
                                  },
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 180,
                            child: _InlineTextField(
                              label: 'Container name',
                              value: container.name,
                              onChanged: (value) => _updateK8sContainer(
                                index,
                                container.copyWith(name: value),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: _InlineTextField(
                              label: 'Image',
                              value: container.image,
                              onChanged: (value) => _updateK8sContainer(
                                index,
                                container.copyWith(image: value),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: _InlineTextField(
                              label: 'Tag',
                              value: container.tag,
                              onChanged: (value) => _updateK8sContainer(
                                index,
                                container.copyWith(tag: value),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: container.ports.asMap().entries.map((
                          portEntry,
                        ) {
                          final portIndex = portEntry.key;
                          final port = portEntry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.panelSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${port.name} ${port.containerPort}/${port.protocol}',
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _showK8sPortDialog(
                                    containerIndex: index,
                                    portIndex: portIndex,
                                    port: port,
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      final updatedPorts = [...container.ports]
                                        ..removeAt(portIndex);
                                      _updateK8sContainer(
                                        index,
                                        container.copyWith(ports: updatedPorts),
                                      );
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showK8sPortDialog(containerIndex: index),
                        icon: const Icon(Icons.add_link_rounded),
                        label: const Text('Add port'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Docker container',
          subtitle:
              'Capture image and port mappings for single-host or dev-mode deployments.',
          action: ElevatedButton.icon(
            onPressed: () => ref
                .read(workspaceControllerProvider.notifier)
                .saveDockerSpec(_dockerDraft),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save docker spec'),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: _InlineTextField(
                      label: 'Container name',
                      value: _dockerDraft.containerName,
                      onChanged: (value) => setState(() {
                        _dockerDraft = _dockerDraft.copyWith(
                          containerName: value,
                        );
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: _InlineTextField(
                      label: 'Image',
                      value: _dockerDraft.image,
                      onChanged: (value) => setState(() {
                        _dockerDraft = _dockerDraft.copyWith(image: value);
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: _InlineTextField(
                      label: 'Tag',
                      value: _dockerDraft.tag,
                      onChanged: (value) => setState(() {
                        _dockerDraft = _dockerDraft.copyWith(tag: value);
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _InlineTextField(
                      label: 'Network',
                      value: _dockerDraft.network,
                      onChanged: (value) => setState(() {
                        _dockerDraft = _dockerDraft.copyWith(network: value);
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _dockerDraft.restartPolicy,
                      decoration: const InputDecoration(
                        labelText: 'Restart policy',
                      ),
                      items: _buildStringItems(
                        _mergeOptions(_dockerDraft.restartPolicy, const [
                          'unless-stopped',
                          'always',
                          'on-failure',
                          'no',
                        ]),
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _dockerDraft = _dockerDraft.copyWith(
                            restartPolicy: value,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Exposed ports',
                    style: AppTheme.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showDockerPortDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add mapping'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_dockerDraft.ports.isEmpty)
                const Text(
                  'No port mappings yet. Add the host/container ports that should be exposed.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ..._dockerDraft.ports.asMap().entries.map((entry) {
                final index = entry.key;
                final port = entry.value;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${port.hostPort}:${port.containerPort}/${port.protocol}',
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showDockerPortDialog(index: index, port: port),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final updated = [..._dockerDraft.ports]
                              ..removeAt(index);
                            _dockerDraft = _dockerDraft.copyWith(
                              ports: updated,
                            );
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _updateK8sContainer(int index, K8sContainerModel container) {
    setState(() {
      final updated = [..._k8sDraft.containers];
      updated[index] = container;
      _k8sDraft = _k8sDraft.copyWith(containers: updated);
    });
  }

  Future<void> _showK8sPortDialog({
    required int containerIndex,
    int? portIndex,
    K8sContainerPort? port,
  }) async {
    final nameController = TextEditingController(text: port?.name ?? 'http');
    final containerPortController = TextEditingController(
      text: '${port?.containerPort ?? 8080}',
    );
    var protocol = port?.protocol ?? 'TCP';

    final result = await showDialog<K8sContainerPort>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                port == null ? 'Add container port' : 'Edit container port',
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Port name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: containerPortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Container port',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: protocol,
                      decoration: const InputDecoration(labelText: 'Protocol'),
                      items: _buildStringItems(const ['TCP', 'UDP']),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          protocol = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final containerPort = int.tryParse(
                      containerPortController.text,
                    );
                    if (nameController.text.trim().isEmpty ||
                        containerPort == null) {
                      return;
                    }
                    Navigator.of(context).pop(
                      K8sContainerPort(
                        name: nameController.text.trim(),
                        containerPort: containerPort,
                        protocol: protocol,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final container = _k8sDraft.containers[containerIndex];
    final updatedPorts = [...container.ports];
    if (portIndex == null) {
      updatedPorts.add(result);
    } else {
      updatedPorts[portIndex] = result;
    }
    _updateK8sContainer(
      containerIndex,
      container.copyWith(ports: updatedPorts),
    );
  }

  Future<void> _showDockerPortDialog({
    int? index,
    DockerPortMapping? port,
  }) async {
    final hostPortController = TextEditingController(
      text: '${port?.hostPort ?? 8080}',
    );
    final containerPortController = TextEditingController(
      text: '${port?.containerPort ?? 8080}',
    );
    var protocol = port?.protocol ?? 'TCP';

    final result = await showDialog<DockerPortMapping>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                port == null ? 'Add port mapping' : 'Edit port mapping',
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: hostPortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Host port'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: containerPortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Container port',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: protocol,
                      decoration: const InputDecoration(labelText: 'Protocol'),
                      items: _buildStringItems(const ['TCP', 'UDP']),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          protocol = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final hostPort = int.tryParse(hostPortController.text);
                    final containerPort = int.tryParse(
                      containerPortController.text,
                    );
                    if (hostPort == null || containerPort == null) {
                      return;
                    }
                    Navigator.of(context).pop(
                      DockerPortMapping(
                        hostPort: hostPort,
                        containerPort: containerPort,
                        protocol: protocol,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final updated = [..._dockerDraft.ports];
      if (index == null) {
        updated.add(result);
      } else {
        updated[index] = result;
      }
      _dockerDraft = _dockerDraft.copyWith(ports: updated);
    });
  }
}

class _DatabaseSpecEditor extends ConsumerStatefulWidget {
  const _DatabaseSpecEditor({required this.component, required this.state});

  final TopologyComponent component;
  final WorkspaceState state;

  @override
  ConsumerState<_DatabaseSpecEditor> createState() =>
      _DatabaseSpecEditorState();
}

class _DatabaseSpecEditorState extends ConsumerState<_DatabaseSpecEditor> {
  late DbModelSpec _draft;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _syncDraft();
  }

  @override
  void didUpdateWidget(covariant _DatabaseSpecEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final componentId = widget.component.id;
    if (oldWidget.component.id != componentId ||
        (oldWidget.state.dbSpecs[componentId] == null &&
            widget.state.dbSpecs[componentId] != null)) {
      _syncDraft();
    }
  }

  void _syncDraft() {
    _draft =
        widget.state.dbSpecs[widget.component.id] ??
        _defaultDbSpec(widget.component);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final projection = widget.state.storageProjections[widget.component.id];
    final databases = widget.state.databases.isEmpty
        ? const [
            DatabaseReference(
              id: 'postgresql',
              name: 'PostgreSQL',
              category: 'sql',
            ),
          ]
        : widget.state.databases;
    final hasCentralEntity = _draft.entities.any((entity) => entity.isCentral);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Database model',
          subtitle:
              'Define schema structure, relationship ratios, and the base user count that drives storage projection.',
          action: ElevatedButton.icon(
            onPressed: () => controller.saveDbSpec(_draft),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save database spec'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _draft.databaseId,
                      decoration: const InputDecoration(
                        labelText: 'Database engine',
                      ),
                      items: databases
                          .map(
                            (database) => DropdownMenuItem(
                              value: database.id,
                              child: Text(
                                '${database.name} · ${titleCase(database.category)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(databaseId: value);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: _InlineTextField(
                      label: 'Base user count',
                      value: '${_draft.baseUserCount}',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _draft = _draft.copyWith(baseUserCount: parsed);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaBadge(
                    label: 'Entities',
                    value: '${_draft.entities.length}',
                  ),
                  _MetaBadge(
                    label: 'Relationships',
                    value: '${_draft.relationships.length}',
                  ),
                  _MetaBadge(
                    label: 'Central entity',
                    value: hasCentralEntity ? 'Present' : 'Missing',
                  ),
                ],
              ),
              if (!hasCentralEntity) ...[
                const SizedBox(height: 14),
                const _InlineHint(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  text:
                      'A central entity is expected for growth propagation. Mark one entity as central before saving the production-ready model.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Entities',
          subtitle:
              'Tables or collections live here. Add fields, mark the central entity, and tune average record sizes.',
          action: OutlinedButton.icon(
            onPressed: _showEntityDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add entity'),
          ),
          child: Column(
            children: _draft.entities.map((entity) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    entity.name,
                                    style: AppTheme.syne(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (entity.isCentral)
                                    const _StatusChip(
                                      label: 'Central',
                                      color: AppColors.brandYellow,
                                    ),
                                  if (entity.indexes.isNotEmpty)
                                    _StatusChip(
                                      label: '${entity.indexes.length} indexes',
                                      color: AppColors.info,
                                    ),
                                ],
                              ),
                              if ((entity.description ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  entity.description!,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Approx. ${formatBytes(entity.avgRecordSizeBytes)} per record · ${entity.fields.length} fields',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showEntityDialog(entity: entity),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              final entities = _draft.entities
                                  .where((item) => item.id != entity.id)
                                  .toList();
                              final relationships = _draft.relationships
                                  .where(
                                    (item) =>
                                        item.sourceEntityId != entity.id &&
                                        item.targetEntityId != entity.id,
                                  )
                                  .toList();
                              _draft = _draft.copyWith(
                                entities: entities,
                                relationships: relationships,
                              );
                            });
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (entity.fields.isEmpty)
                      const Text(
                        'No fields yet. Add columns or document properties to start modelling storage.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ...entity.fields.map((field) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.panelSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        field.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      _StatusChip(
                                        label: titleCase(field.type),
                                        color: AppColors.info,
                                      ),
                                      if (field.key.keyType != 'none')
                                        _StatusChip(
                                          label: titleCase(field.key.keyType),
                                          color: AppColors.brandYellow,
                                        ),
                                      if (field.unique)
                                        const _StatusChip(
                                          label: 'Unique',
                                          color: AppColors.success,
                                        ),
                                      if (field.indexed)
                                        const _StatusChip(
                                          label: 'Indexed',
                                          color: AppColors.success,
                                        ),
                                      if (!field.required)
                                        const _StatusChip(
                                          label: 'Optional',
                                          color: AppColors.textMuted,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${field.avgSizeBytes} B average size${field.vectorDimensions == null ? '' : ' · ${field.vectorDimensions} dims'}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  if ((field.description ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      field.description!,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showFieldDialog(
                                entity: entity,
                                field: field,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  final updatedFields = entity.fields
                                      .where((item) => item.id != field.id)
                                      .toList();
                                  _upsertEntity(
                                    entity.copyWith(fields: updatedFields),
                                  );
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: () => _showFieldDialog(entity: entity),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add field'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Relationships',
          subtitle:
              'Ratios propagate records from the central entity through the rest of the model.',
          action: OutlinedButton.icon(
            onPressed: _draft.entities.length < 2
                ? null
                : _showRelationshipDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add relationship'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_draft.relationships.isEmpty)
                const Text(
                  'No relationships yet. Add at least one ratio to project child entity sizes from your central entity.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ..._draft.relationships.map((relationship) {
                final source = _entityName(relationship.sourceEntityId);
                final target = _entityName(relationship.targetEntityId);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$source  ->  $target',
                              style: AppTheme.syne(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusChip(
                                  label: relationship.type,
                                  color: AppColors.info,
                                ),
                                _StatusChip(
                                  label: 'Ratio ${relationship.ratio}',
                                  color: AppColors.brandYellow,
                                ),
                                if ((relationship.description ?? '').isNotEmpty)
                                  _StatusChip(
                                    label: relationship.description!,
                                    color: AppColors.textMuted,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showRelationshipDialog(relationship: relationship),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _draft = _draft.copyWith(
                              relationships: _draft.relationships
                                  .where((item) => item.id != relationship.id)
                                  .toList(),
                            );
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Storage projection',
          subtitle:
              'Projection data comes from `/db/{component}/storage-projection` after the database spec is saved.',
          child: projection == null
              ? const Text(
                  'Save the database structure to calculate projected record counts, storage, index overhead, and WAL/journal usage.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetaBadge(
                          label: 'Records',
                          value: compactNumber(projection.totalRecords),
                        ),
                        _MetaBadge(
                          label: 'Data',
                          value: formatBytes(projection.totalDataBytes),
                        ),
                        _MetaBadge(
                          label: 'Indexes',
                          value: formatBytes(projection.totalIndexBytes),
                        ),
                        _MetaBadge(
                          label: 'Total',
                          value: formatBytes(projection.totalStorageBytes),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...projection.perEntity.map((entity) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entity.entityName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${compactNumber(entity.recordCount)} records · ${formatBytes(entity.avgRecordSizeBytes)} avg record',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatBytes(entity.totalSizeBytes)),
                                const SizedBox(height: 6),
                                Text(
                                  '${formatBytes(entity.indexOverheadBytes)} index overhead',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  String _entityName(String entityId) {
    for (final entity in _draft.entities) {
      if (entity.id == entityId) {
        return entity.name;
      }
    }
    return entityId;
  }

  void _upsertEntity(EntityModel entity) {
    final updated = [..._draft.entities];
    final index = updated.indexWhere((item) => item.id == entity.id);
    if (index == -1) {
      updated.add(entity);
    } else {
      updated[index] = entity;
    }
    _draft = _draft.copyWith(entities: updated);
  }

  Future<void> _showEntityDialog({EntityModel? entity}) async {
    final nameController = TextEditingController(text: entity?.name ?? '');
    final descriptionController = TextEditingController(
      text: entity?.description ?? '',
    );
    var isCentral = entity?.isCentral ?? _draft.entities.isEmpty;

    final result = await showDialog<EntityModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(entity == null ? 'Add entity' : 'Edit entity'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Entity name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isCentral,
                      onChanged: (value) {
                        setDialogState(() {
                          isCentral = value;
                        });
                      },
                      title: const Text('Central entity'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      EntityModel(
                        id: entity?.id ?? 'ent_${_uuid.v4()}',
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        fields: entity?.fields ?? const [],
                        indexes: entity?.indexes ?? const [],
                        isCentral: isCentral,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final entities = _draft.entities.map((item) {
        if (result.isCentral && item.id != result.id) {
          return item.copyWith(isCentral: false);
        }
        return item;
      }).toList();

      final existingIndex = entities.indexWhere((item) => item.id == result.id);
      if (existingIndex == -1) {
        entities.add(result);
      } else {
        entities[existingIndex] = result;
      }
      _draft = _draft.copyWith(entities: entities);
    });
  }

  Future<void> _showFieldDialog({
    required EntityModel entity,
    EntityFieldModel? field,
  }) async {
    final nameController = TextEditingController(text: field?.name ?? '');
    final descriptionController = TextEditingController(
      text: field?.description ?? '',
    );
    final avgSizeController = TextEditingController(
      text: '${field?.avgSizeBytes ?? 64}',
    );
    final vectorDimensionsController = TextEditingController(
      text: field?.vectorDimensions == null ? '' : '${field!.vectorDimensions}',
    );
    var type = field?.type ?? 'string';
    var keyType = field?.key.keyType ?? 'none';
    var required = field?.required ?? true;
    var unique = field?.unique ?? false;
    var indexed = field?.indexed ?? false;
    var referencesEntityId =
        field?.key.referencesEntityId ??
        (entity.id != (_draft.entities.firstOrNull?.id ?? '') &&
                _draft.entities.isNotEmpty
            ? _draft.entities.first.id
            : null);
    String? referencesFieldId = field?.key.referencesFieldId;

    final result = await showDialog<EntityFieldModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final referenceEntities = _draft.entities
                .where((item) => item.id != entity.id)
                .toList();
            final selectedReferenceEntity = referenceEntities
                .where((item) => item.id == referencesEntityId)
                .firstOrNull;
            final referenceFields =
                selectedReferenceEntity?.fields ?? const <EntityFieldModel>[];
            referencesFieldId =
                referenceFields.any((item) => item.id == referencesFieldId)
                ? referencesFieldId
                : (referenceFields.isNotEmpty
                      ? referenceFields.first.id
                      : null);

            return AlertDialog(
              title: Text(field == null ? 'Add field' : 'Edit field'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Field name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _buildStringItems(
                          _fieldTypes,
                          titleCaseValues: true,
                        ),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            type = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: keyType,
                        decoration: const InputDecoration(
                          labelText: 'Key type',
                        ),
                        items: _buildStringItems(const [
                          'none',
                          'primary',
                          'foreign',
                          'composite_primary',
                        ], titleCaseValues: true),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            keyType = value;
                          });
                        },
                      ),
                      if (keyType == 'foreign') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: referencesEntityId,
                          decoration: const InputDecoration(
                            labelText: 'Reference entity',
                          ),
                          items: referenceEntities
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              referencesEntityId = value;
                              referencesFieldId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: referencesFieldId,
                          decoration: const InputDecoration(
                            labelText: 'Reference field',
                          ),
                          items: referenceFields
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              referencesFieldId = value;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: avgSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Average size (bytes)',
                        ),
                      ),
                      if (type == 'vector') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: vectorDimensionsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Vector dimensions',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: required,
                        onChanged: (value) {
                          setDialogState(() {
                            required = value ?? true;
                          });
                        },
                        title: const Text('Required'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        value: unique,
                        onChanged: (value) {
                          setDialogState(() {
                            unique = value ?? false;
                          });
                        },
                        title: const Text('Unique'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        value: indexed,
                        onChanged: (value) {
                          setDialogState(() {
                            indexed = value ?? false;
                          });
                        },
                        title: const Text('Indexed'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final avgSize = int.tryParse(avgSizeController.text);
                    final vectorDimensions =
                        vectorDimensionsController.text.trim().isEmpty
                        ? null
                        : int.tryParse(vectorDimensionsController.text.trim());
                    if (nameController.text.trim().isEmpty || avgSize == null) {
                      return;
                    }
                    Navigator.of(context).pop(
                      EntityFieldModel(
                        id: field?.id ?? 'fld_${_uuid.v4()}',
                        name: nameController.text.trim(),
                        type: type,
                        required: required,
                        unique: unique,
                        indexed: indexed,
                        avgSizeBytes: avgSize,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        vectorDimensions: vectorDimensions,
                        enumValues: field?.enumValues,
                        defaultValue: field?.defaultValue,
                        key: FieldKeyConfig(
                          keyType: keyType,
                          referencesEntityId: keyType == 'foreign'
                              ? referencesEntityId
                              : null,
                          referencesFieldId: keyType == 'foreign'
                              ? referencesFieldId
                              : null,
                          onDelete: 'CASCADE',
                          onUpdate: 'CASCADE',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final updatedFields = [...entity.fields];
      final index = updatedFields.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        updatedFields.add(result);
      } else {
        updatedFields[index] = result;
      }
      _upsertEntity(entity.copyWith(fields: updatedFields));
    });
  }

  Future<void> _showRelationshipDialog({
    RelationshipModel? relationship,
  }) async {
    String? sourceEntityId =
        relationship?.sourceEntityId ??
        (_draft.entities.isNotEmpty ? _draft.entities.first.id : null);
    String? targetEntityId =
        relationship?.targetEntityId ??
        (_draft.entities.length > 1 ? _draft.entities[1].id : null);
    var type = relationship?.type ?? '1:N';
    final ratioController = TextEditingController(
      text: '${relationship?.ratio ?? 10}',
    );
    final descriptionController = TextEditingController(
      text: relationship?.description ?? '',
    );

    final result = await showDialog<RelationshipModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                relationship == null ? 'Add relationship' : 'Edit relationship',
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: sourceEntityId,
                      decoration: const InputDecoration(
                        labelText: 'Source entity',
                      ),
                      items: _draft.entities
                          .map(
                            (entity) => DropdownMenuItem(
                              value: entity.id,
                              child: Text(entity.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          sourceEntityId = value;
                          if (targetEntityId == sourceEntityId) {
                            targetEntityId = _draft.entities
                                .firstWhere((item) => item.id != value)
                                .id;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: targetEntityId,
                      decoration: const InputDecoration(
                        labelText: 'Target entity',
                      ),
                      items: _draft.entities
                          .where((entity) => entity.id != sourceEntityId)
                          .map(
                            (entity) => DropdownMenuItem(
                              value: entity.id,
                              child: Text(entity.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          targetEntityId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Relationship type',
                      ),
                      items: _buildStringItems(const ['1:1', '1:N', 'N:M']),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          type = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ratioController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Ratio multiplier',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final ratio = double.tryParse(ratioController.text);
                    if (sourceEntityId == null ||
                        targetEntityId == null ||
                        ratio == null) {
                      return;
                    }
                    Navigator.of(context).pop(
                      RelationshipModel(
                        id: relationship?.id ?? 'rel_${_uuid.v4()}',
                        sourceEntityId: sourceEntityId!,
                        targetEntityId: targetEntityId!,
                        type: type,
                        ratio: ratio,
                        fkFieldId: relationship?.fkFieldId,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final relationships = [..._draft.relationships];
      final index = relationships.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        relationships.add(result);
      } else {
        relationships[index] = result;
      }
      _draft = _draft.copyWith(relationships: relationships);
    });
  }
}

class _CacheSpecEditor extends ConsumerStatefulWidget {
  const _CacheSpecEditor({required this.component, required this.state});

  final TopologyComponent component;
  final WorkspaceState state;

  @override
  ConsumerState<_CacheSpecEditor> createState() => _CacheSpecEditorState();
}

class _CacheSpecEditorState extends ConsumerState<_CacheSpecEditor> {
  late CacheSpec _draft;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.state.cacheSpecs[widget.component.id] ??
        _defaultCacheSpec(widget.component);
  }

  @override
  void didUpdateWidget(covariant _CacheSpecEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final componentId = widget.component.id;
    if (oldWidget.component.id != componentId ||
        (oldWidget.state.cacheSpecs[componentId] == null &&
            widget.state.cacheSpecs[componentId] != null)) {
      _draft =
          widget.state.cacheSpecs[componentId] ??
          _defaultCacheSpec(widget.component);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    return _SectionCard(
      title: 'Cache profile',
      subtitle:
          'Configure memory footprint, TTL, and cluster behavior for the selected cache component.',
      action: ElevatedButton.icon(
        onPressed: () => controller.saveCacheSpec(_draft),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save cache spec'),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _draft.cacheDatabase,
                  decoration: const InputDecoration(labelText: 'Cache engine'),
                  items: _buildStringItems(
                    _mergeOptions(_draft.cacheDatabase, const [
                      'redis',
                      'valkey',
                      'memcached',
                      'dragonfly',
                    ]),
                    titleCaseValues: true,
                  ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _draft = _draft.copyWith(cacheDatabase: value);
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _draft.evictionPolicy,
                  decoration: const InputDecoration(
                    labelText: 'Eviction policy',
                  ),
                  items: _buildStringItems(
                    _mergeOptions(_draft.evictionPolicy, const [
                      'allkeys_lru',
                      'lru',
                      'lfu',
                      'ttl',
                      'random',
                    ]),
                    titleCaseValues: true,
                  ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _draft = _draft.copyWith(evictionPolicy: value);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SliderField(
            label: 'Memory',
            value: _draft.memoryGb,
            min: 1,
            max: 512,
            divisions: 511,
            display: '${_draft.memoryGb.toStringAsFixed(0)} GB',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(memoryGb: value);
            }),
          ),
          _SliderField(
            label: 'TTL',
            value: _draft.ttlSeconds.toDouble(),
            min: 60,
            max: 86400,
            divisions: 47,
            display: '${_draft.ttlSeconds}s',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(ttlSeconds: value.round());
            }),
          ),
          _SliderField(
            label: 'Cluster nodes',
            value: _draft.clusterNodes.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            display: '${_draft.clusterNodes}',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(clusterNodes: value.round());
            }),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _draft.highAvailability,
            activeColor: AppColors.brandYellow,
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(highAvailability: value);
            }),
            title: const Text('High availability'),
            subtitle: const Text(
              'Use multi-node redundancy in higher tiers.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadBalancerSpecEditor extends ConsumerStatefulWidget {
  const _LoadBalancerSpecEditor({required this.component, required this.state});

  final TopologyComponent component;
  final WorkspaceState state;

  @override
  ConsumerState<_LoadBalancerSpecEditor> createState() =>
      _LoadBalancerSpecEditorState();
}

class _LoadBalancerSpecEditorState
    extends ConsumerState<_LoadBalancerSpecEditor> {
  late LoadBalancerSpec _draft;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.state.loadBalancerSpecs[widget.component.id] ??
        _defaultLoadBalancerSpec(
          widget.component,
          widget.state.selectedTopology?.components ?? const [],
        );
  }

  @override
  void didUpdateWidget(covariant _LoadBalancerSpecEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final componentId = widget.component.id;
    if (oldWidget.component.id != componentId ||
        (oldWidget.state.loadBalancerSpecs[componentId] == null &&
            widget.state.loadBalancerSpecs[componentId] != null)) {
      _draft =
          widget.state.loadBalancerSpecs[componentId] ??
          _defaultLoadBalancerSpec(
            widget.component,
            widget.state.selectedTopology?.components ?? const [],
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final candidates =
        (widget.state.selectedTopology?.components ??
                const <TopologyComponent>[])
            .where(
              (item) =>
                  item.id != widget.component.id &&
                  item.type != ComponentType.client &&
                  item.type != ComponentType.cdn &&
                  item.type != ComponentType.loadBalancer,
            )
            .toList();

    return _SectionCard(
      title: 'Load balancer',
      subtitle:
          'Choose routing behavior and the target services that should sit behind this traffic layer.',
      action: ElevatedButton.icon(
        onPressed: () => controller.saveLoadBalancerSpec(_draft),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save LB spec'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _draft.algorithm,
                  decoration: const InputDecoration(labelText: 'Algorithm'),
                  items: _buildStringItems(
                    _mergeOptions(_draft.algorithm, const [
                      'round_robin',
                      'least_connections',
                      'ip_hash',
                      'weighted',
                    ]),
                    titleCaseValues: true,
                  ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _draft = _draft.copyWith(algorithm: value);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Targets',
            style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: candidates.map((item) {
              final selected = _draft.targetComponentIds.contains(item.id);
              return FilterChip(
                selected: selected,
                label: Text(item.name),
                onSelected: (value) {
                  setState(() {
                    final updated = [..._draft.targetComponentIds];
                    if (value) {
                      updated.add(item.id);
                    } else {
                      updated.remove(item.id);
                    }
                    _draft = _draft.copyWith(targetComponentIds: updated);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _SliderField(
            label: 'Health check interval',
            value: _draft.healthCheckIntervalSeconds.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            display: '${_draft.healthCheckIntervalSeconds}s',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(
                healthCheckIntervalSeconds: value.round(),
              );
            }),
          ),
          _SliderField(
            label: 'Estimated requests/sec',
            value: _draft.estimatedRequestsPerSecond,
            min: 100,
            max: 20000,
            divisions: 50,
            display: compactNumber(_draft.estimatedRequestsPerSecond.round()),
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(estimatedRequestsPerSecond: value);
            }),
          ),
          _SliderField(
            label: 'Estimated data/month',
            value: _draft.estimatedDataProcessedGbMonth,
            min: 50,
            max: 50000,
            divisions: 50,
            display:
                '${_draft.estimatedDataProcessedGbMonth.toStringAsFixed(0)} GB',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(estimatedDataProcessedGbMonth: value);
            }),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _draft.sslTermination,
            activeColor: AppColors.brandYellow,
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(sslTermination: value);
            }),
            title: const Text('SSL termination'),
          ),
        ],
      ),
    );
  }
}

class _CdnSpecEditor extends ConsumerStatefulWidget {
  const _CdnSpecEditor({required this.component, required this.state});

  final TopologyComponent component;
  final WorkspaceState state;

  @override
  ConsumerState<_CdnSpecEditor> createState() => _CdnSpecEditorState();
}

class _CdnSpecEditorState extends ConsumerState<_CdnSpecEditor> {
  late CdnSpec _draft;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.state.cdnSpecs[widget.component.id] ??
        _defaultCdnSpec(widget.component);
  }

  @override
  void didUpdateWidget(covariant _CdnSpecEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final componentId = widget.component.id;
    if (oldWidget.component.id != componentId ||
        (oldWidget.state.cdnSpecs[componentId] == null &&
            widget.state.cdnSpecs[componentId] != null)) {
      _draft =
          widget.state.cdnSpecs[componentId] ??
          _defaultCdnSpec(widget.component);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    return _SectionCard(
      title: 'CDN profile',
      subtitle:
          'Estimate edge transfer and request volume to compare public delivery patterns.',
      action: ElevatedButton.icon(
        onPressed: () => controller.saveCdnSpec(_draft),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save CDN spec'),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _draft.provider,
              decoration: const InputDecoration(labelText: 'CDN provider'),
              items: _buildStringItems(
                _mergeOptions(_draft.provider, const [
                  'cloudfront',
                  'cloudflare',
                  'fastly',
                  'akamai',
                  'none',
                ]),
                titleCaseValues: true,
              ),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _draft = _draft.copyWith(provider: value);
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _SliderField(
            label: 'Transfer per month',
            value: _draft.estimatedDataTransferGbMonth,
            min: 100,
            max: 100000,
            divisions: 60,
            display:
                '${_draft.estimatedDataTransferGbMonth.toStringAsFixed(0)} GB',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(estimatedDataTransferGbMonth: value);
            }),
          ),
          _SliderField(
            label: 'Requests per month',
            value: _draft.estimatedRequestsMillionMonth,
            min: 1,
            max: 500,
            divisions: 99,
            display:
                '${_draft.estimatedRequestsMillionMonth.toStringAsFixed(0)}M',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(estimatedRequestsMillionMonth: value);
            }),
          ),
          _SliderField(
            label: 'Cache hit ratio',
            value: _draft.cacheHitRatio,
            min: 0.1,
            max: 1,
            divisions: 18,
            display: '${(_draft.cacheHitRatio * 100).round()}%',
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(cacheHitRatio: value);
            }),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _draft.customDomain,
            activeColor: AppColors.brandYellow,
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(customDomain: value);
            }),
            title: const Text('Custom domain'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _draft.ssl,
            activeColor: AppColors.brandYellow,
            onChanged: (value) => setState(() {
              _draft = _draft.copyWith(ssl: value);
            }),
            title: const Text('Managed SSL'),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedSpecEditor extends StatelessWidget {
  const _UnsupportedSpecEditor({required this.component});

  final TopologyComponent component;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '${component.type.label} details',
      subtitle:
          'This first browser build follows the currently available backend endpoints. Unsupported nodes stay editable on the topology canvas and are ready for a future API slice.',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineHint(
            icon: Icons.construction_rounded,
            color: AppColors.brandYellow,
            text:
                'Dedicated Stage 2 endpoints are available today for compute, database, cache, load balancer, Kubernetes, Docker, and CDN configuration. Client, object storage, and queue specs can be added once the backend exposes them.',
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.syne(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 16), action!],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String display;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                display,
                style: const TextStyle(
                  color: AppColors.brandYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              inactiveTrackColor: AppColors.border,
              activeTrackColor: AppColors.brandYellow,
              thumbColor: AppColors.brandYellow,
              overlayColor: AppColors.brandYellow.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineTextField extends StatefulWidget {
  const _InlineTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: widget.onChanged,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(fontSize: 11, color: color),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.6))),
        ],
      ),
    );
  }
}

class _SpecPlaceholder extends StatelessWidget {
  const _SpecPlaceholder({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.glassCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 54,
                color: AppColors.brandYellow,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTheme.syne(fontSize: 30, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isApiBackedComponent(ComponentType type) {
  return type == ComponentType.compute ||
      type == ComponentType.database ||
      type == ComponentType.cache ||
      type == ComponentType.loadBalancer ||
      type == ComponentType.cdn;
}

List<String> _mergeOptions(String current, Iterable<String> values) {
  return [current, ...values.where((item) => item != current)];
}

List<DropdownMenuItem<String>> _buildStringItems(
  Iterable<String> values, {
  bool titleCaseValues = false,
}) {
  return values
      .map(
        (value) => DropdownMenuItem(
          value: value,
          child: Text(
            titleCaseValues ? titleCase(value) : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
      .toList();
}

ComputeSpec _defaultComputeSpec(TopologyComponent component) {
  return ComputeSpec(
    topologyComponentId: component.id,
    cpuCores: 4,
    ramGb: 16,
    gpuType: 'none',
    gpuCount: 0,
    gpuVramGb: 0,
    instanceFamily: 'general_purpose',
    instanceSize: 'large',
    os: 'linux',
    storageGb: 100,
    cloudProvider: component.cloudProvider.value,
    region: component.location.region,
    autoscalingEnabled: true,
    minInstances: 2,
    maxInstances: 6,
    targetCpuUtilization: 0.7,
    targetMemoryUtilization: 0.8,
  );
}

K8sClusterSpec _defaultK8sSpec(TopologyComponent component) {
  return K8sClusterSpec(
    topologyComponentId: component.id,
    namespace: 'dataforge',
    replicas: 2,
    serviceType: 'ClusterIP',
    servicePort: 80,
    targetPort: 8080,
    hpaEnabled: true,
    minReplicas: 2,
    maxReplicas: 8,
    targetCpuUtilization: 70,
    containers: const [
      K8sContainerModel(
        name: 'app',
        image: 'dataforge/app',
        tag: 'latest',
        ports: [
          K8sContainerPort(name: 'http', containerPort: 8080, protocol: 'TCP'),
        ],
      ),
    ],
  );
}

DockerContainerSpec _defaultDockerSpec(TopologyComponent component) {
  return DockerContainerSpec(
    topologyComponentId: component.id,
    containerName: component.name.toLowerCase().replaceAll(' ', '-'),
    image: 'dataforge/app',
    tag: 'latest',
    network: 'bridge',
    restartPolicy: 'unless-stopped',
    ports: const [
      DockerPortMapping(hostPort: 8080, containerPort: 8080, protocol: 'TCP'),
    ],
  );
}

CacheSpec _defaultCacheSpec(TopologyComponent component) {
  return CacheSpec(
    topologyComponentId: component.id,
    cacheDatabase: 'redis',
    memoryGb: 8,
    evictionPolicy: 'allkeys_lru',
    ttlSeconds: 1800,
    clusterNodes: 2,
    highAvailability: true,
  );
}

LoadBalancerSpec _defaultLoadBalancerSpec(
  TopologyComponent component,
  List<TopologyComponent> topologyComponents,
) {
  final targets = topologyComponents
      .where(
        (item) =>
            item.id != component.id &&
            item.type != ComponentType.client &&
            item.type != ComponentType.cdn &&
            item.type != ComponentType.loadBalancer,
      )
      .map((item) => item.id)
      .take(2)
      .toList();
  return LoadBalancerSpec(
    topologyComponentId: component.id,
    algorithm: 'round_robin',
    targetComponentIds: targets,
    healthCheckIntervalSeconds: 15,
    sslTermination: true,
    estimatedRequestsPerSecond: 1500,
    estimatedDataProcessedGbMonth: 1800,
  );
}

CdnSpec _defaultCdnSpec(TopologyComponent component) {
  return CdnSpec(
    topologyComponentId: component.id,
    provider: 'cloudfront',
    estimatedDataTransferGbMonth: 2500,
    estimatedRequestsMillionMonth: 45,
    cacheHitRatio: 0.88,
    customDomain: true,
    ssl: true,
  );
}

DbModelSpec _defaultDbSpec(TopologyComponent component) {
  return DbModelSpec(
    topologyComponentId: component.id,
    databaseId: 'postgresql',
    baseUserCount: 100000,
    entities: const [
      EntityModel(
        id: 'ent_user',
        name: 'User',
        fields: [
          EntityFieldModel(
            id: 'fld_user_id',
            name: 'user_id',
            type: 'uuid',
            required: true,
            unique: true,
            indexed: true,
            key: FieldKeyConfig(keyType: 'primary'),
            avgSizeBytes: 16,
            description: 'Primary user identifier',
          ),
          EntityFieldModel(
            id: 'fld_user_email',
            name: 'email',
            type: 'string',
            required: true,
            unique: true,
            indexed: true,
            key: FieldKeyConfig(keyType: 'none'),
            avgSizeBytes: 48,
            description: 'Unique account email',
          ),
          EntityFieldModel(
            id: 'fld_user_name',
            name: 'name',
            type: 'string',
            required: false,
            unique: false,
            indexed: false,
            key: FieldKeyConfig(keyType: 'none'),
            avgSizeBytes: 40,
            description: 'Display name',
          ),
        ],
        indexes: [],
        isCentral: true,
        description: 'Central customer profile entity.',
      ),
      EntityModel(
        id: 'ent_order',
        name: 'Order',
        fields: [
          EntityFieldModel(
            id: 'fld_order_id',
            name: 'order_id',
            type: 'uuid',
            required: true,
            unique: true,
            indexed: true,
            key: FieldKeyConfig(keyType: 'primary'),
            avgSizeBytes: 16,
          ),
          EntityFieldModel(
            id: 'fld_order_user_id',
            name: 'user_id',
            type: 'uuid',
            required: true,
            unique: false,
            indexed: true,
            key: FieldKeyConfig(
              keyType: 'foreign',
              referencesEntityId: 'ent_user',
              referencesFieldId: 'fld_user_id',
            ),
            avgSizeBytes: 16,
          ),
          EntityFieldModel(
            id: 'fld_order_total',
            name: 'total',
            type: 'decimal',
            required: true,
            unique: false,
            indexed: false,
            key: FieldKeyConfig(keyType: 'none'),
            avgSizeBytes: 12,
          ),
        ],
        indexes: [],
        isCentral: false,
        description: 'Transactional order entity.',
      ),
    ],
    relationships: const [
      RelationshipModel(
        id: 'rel_user_order',
        sourceEntityId: 'ent_user',
        targetEntityId: 'ent_order',
        type: '1:N',
        ratio: 25,
        description: 'Average orders per user',
      ),
    ],
  );
}

const List<String> _fieldTypes = [
  'string',
  'text',
  'integer',
  'float',
  'decimal',
  'boolean',
  'date',
  'datetime',
  'timestamp',
  'uuid',
  'json',
  'array',
  'binary',
  'enum',
  'vector',
  'geospatial',
  'reference',
];

IconData _componentIcon(ComponentType type) {
  return switch (type) {
    ComponentType.compute => Icons.memory_rounded,
    ComponentType.database => Icons.storage_rounded,
    ComponentType.cache => Icons.bolt_rounded,
    ComponentType.loadBalancer => Icons.balance_rounded,
    ComponentType.cdn => Icons.public_rounded,
    ComponentType.client => Icons.devices_rounded,
    ComponentType.objectStore => Icons.inventory_2_rounded,
    ComponentType.messageQueue => Icons.alt_route_rounded,
  };
}

Color _componentColor(ComponentType type) {
  return switch (type) {
    ComponentType.compute => AppColors.info,
    ComponentType.database => AppColors.success,
    ComponentType.cache => const Color(0xFFFAB1A0),
    ComponentType.loadBalancer => const Color(0xFFA29BFE),
    ComponentType.cdn => const Color(0xFF55EFC4),
    ComponentType.client => AppColors.textMuted,
    ComponentType.objectStore => AppColors.brandYellow,
    ComponentType.messageQueue => const Color(0xFFFF8AD8),
  };
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension on K8sContainerModel {
  K8sContainerModel copyWith({
    String? name,
    String? image,
    String? tag,
    List<K8sContainerPort>? ports,
  }) {
    return K8sContainerModel(
      name: name ?? this.name,
      image: image ?? this.image,
      tag: tag ?? this.tag,
      ports: ports ?? this.ports,
    );
  }
}
