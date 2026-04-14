import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/topology_models.dart';

/// Stateless node widget for auto-layout topology canvas.
///
/// Displays component icon, name, type label, cloud badge, and region.
/// Supports onTap (select) and onDoubleTap (drill-down navigation).
class TopologyNodeWidget extends StatelessWidget {
  const TopologyNodeWidget({
    super.key,
    required this.component,
    required this.isSelected,
    this.onTap,
    this.onDoubleTap,
    this.width = 136,
  });

  final TopologyComponent component;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final nodeColor = componentColor(component.type);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: component.enabled ? 1 : 0.45,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.panelSoft.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandYellow
                  : nodeColor.withValues(alpha: 0.6),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: nodeColor.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: nodeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      componentIcon(component.type),
                      color: nodeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Cloud provider badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      component.cloudProvider.value.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 8,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.radio_button_checked_rounded,
                      color: AppColors.brandYellow,
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                component.name,
                style: AppTheme.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      component.type.label,
                      style: GoogleFonts.spaceMono(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                component.location.region,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns the icon for a given component type.
IconData componentIcon(ComponentType type) {
  return switch (type) {
    ComponentType.compute => Icons.memory_rounded,
    ComponentType.database => Icons.storage_rounded,
    ComponentType.cache => Icons.bolt_rounded,
    ComponentType.loadBalancer => Icons.balance_rounded,
    ComponentType.cdn => Icons.public_rounded,
    ComponentType.client => Icons.devices_rounded,
    ComponentType.objectStore => Icons.inventory_2_rounded,
    ComponentType.messageQueue => Icons.alt_route_rounded,
    ComponentType.apiGateway => Icons.api_rounded,
    ComponentType.cronJob => Icons.schedule_rounded,
    ComponentType.serviceMesh => Icons.hub_rounded,
    ComponentType.thirdPartyApi => Icons.cloud_outlined,
  };
}

/// Returns the color for a given component type.
Color componentColor(ComponentType type) {
  return switch (type) {
    ComponentType.compute => AppColors.info,
    ComponentType.database => AppColors.success,
    ComponentType.cache => const Color(0xFFFAB1A0),
    ComponentType.loadBalancer => const Color(0xFFA29BFE),
    ComponentType.cdn => const Color(0xFF55EFC4),
    ComponentType.client => AppColors.textMuted,
    ComponentType.objectStore => AppColors.brandYellow,
    ComponentType.messageQueue => const Color(0xFFFF8AD8),
    ComponentType.apiGateway => AppColors.apiGatewayColor,
    ComponentType.cronJob => AppColors.cronJobColor,
    ComponentType.serviceMesh => AppColors.serviceMeshColor,
    ComponentType.thirdPartyApi => AppColors.thirdPartyColor,
  };
}
