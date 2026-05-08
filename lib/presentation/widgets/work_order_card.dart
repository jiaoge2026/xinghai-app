import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/work_order_model.dart';
import 'status_badge.dart';

class WorkOrderCard extends StatelessWidget {
  final WorkOrderModel workOrder;
  final VoidCallback? onTap;

  const WorkOrderCard({
    super.key,
    required this.workOrder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workOrder.woNo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusBadge(status: workOrder.status),
                ],
              ),
              const SizedBox(height: 8),
              if (workOrder.customerName != null)
                _buildInfoRow(Icons.person_outline, workOrder.customerName!),
              if (workOrder.customerPhone != null)
                _buildInfoRow(Icons.phone_outlined, workOrder.customerPhone!),
              if (workOrder.customerAddress != null)
                _buildInfoRow(Icons.location_on_outlined, workOrder.customerAddress!),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (workOrder.applianceType != null) ...[
                    _buildTag(workOrder.applianceType!, AppColors.info),
                    const SizedBox(width: 8),
                  ],
                  if (workOrder.serviceType != null)
                    _buildTag(workOrder.serviceType!, AppColors.warning),
                  const Spacer(),
                  if (workOrder.scheduledDate != null)
                    Text(
                      '${workOrder.scheduledDate} ${workOrder.scheduledTimeSlot ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
              if (workOrder.faultDesc != null) ...[
                const SizedBox(height: 8),
                Text(
                  workOrder.faultDesc!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}
