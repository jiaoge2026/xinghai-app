class WorkflowInstanceModel {
  final String id;
  final String instanceNo;
  final String workflowName;
  final String businessType;
  final int? businessId;
  final String applicantName;
  final DateTime applyTime;
  final String? currentNode;
  final String? currentApproverNames;
  final int status;
  final DateTime? completeTime;
  final Map<String, dynamic>? businessData;

  WorkflowInstanceModel({
    required this.id,
    required this.instanceNo,
    required this.workflowName,
    required this.businessType,
    this.businessId,
    required this.applicantName,
    required this.applyTime,
    this.currentNode,
    this.currentApproverNames,
    required this.status,
    this.completeTime,
    this.businessData,
  });

  factory WorkflowInstanceModel.fromJson(Map<String, dynamic> json) {
    return WorkflowInstanceModel(
      id: json['id'] ?? json['instanceId'] ?? '',
      instanceNo: json['instanceNo'] ?? json['instance_no'] ?? '',
      workflowName: json['workflowName'] ?? json['workflow_name'] ?? '',
      businessType: json['businessType'] ?? json['business_type'] ?? '',
      businessId: json['businessId'] ?? json['business_id'],
      applicantName: json['applicantName'] ?? json['applicant_name'] ?? '',
      applyTime: json['applyTime'] != null
          ? DateTime.tryParse(json['applyTime'].toString()) ?? DateTime.now()
          : (json['apply_time'] != null
              ? DateTime.tryParse(json['apply_time'].toString()) ?? DateTime.now()
              : DateTime.now()),
      currentNode: json['currentNode'] ?? json['current_node'],
      currentApproverNames: json['currentApproverNames'] ?? json['current_approver_names'],
      status: json['status'] ?? 1,
      completeTime: json['completeTime'] != null
          ? DateTime.tryParse(json['completeTime'].toString())
          : (json['complete_time'] != null
              ? DateTime.tryParse(json['complete_time'].toString())
              : null),
      businessData: json['businessData'] ?? json['business_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instanceNo': instanceNo,
      'workflowName': workflowName,
      'businessType': businessType,
      'businessId': businessId,
      'applicantName': applicantName,
      'applyTime': applyTime.toIso8601String(),
      'currentNode': currentNode,
      'currentApproverNames': currentApproverNames,
      'status': status,
      'completeTime': completeTime?.toIso8601String(),
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return '待审批';
      case 2:
        return '审批中';
      case 3:
        return '已通过';
      case 4:
        return '已驳回';
      case 5:
        return '已撤回';
      case 6:
        return '已取消';
      default:
        return '未知';
    }
  }
}

class WorkflowNodeModel {
  final String id;
  final String instanceId;
  final String nodeName;
  final String nodeType;
  final String? approverName;
  final DateTime? approveTime;
  final int approveStatus;
  final String? comment;

  WorkflowNodeModel({
    required this.id,
    required this.instanceId,
    required this.nodeName,
    required this.nodeType,
    this.approverName,
    this.approveTime,
    required this.approveStatus,
    this.comment,
  });

  factory WorkflowNodeModel.fromJson(Map<String, dynamic> json) {
    return WorkflowNodeModel(
      id: json['id'] ?? '',
      instanceId: json['instanceId'] ?? json['instance_id'] ?? '',
      nodeName: json['nodeName'] ?? json['node_name'] ?? '',
      nodeType: json['nodeType'] ?? json['node_type'] ?? '',
      approverName: json['approverName'] ?? json['approver_name'],
      approveTime: json['approveTime'] != null
          ? DateTime.tryParse(json['approveTime'].toString())
          : (json['approve_time'] != null
              ? DateTime.tryParse(json['approve_time'].toString())
              : null),
      approveStatus: json['approveStatus'] ?? json['approve_status'] ?? 0,
      comment: json['comment'],
    );
  }

  String get statusText {
    switch (approveStatus) {
      case 1:
        return '待审批';
      case 2:
        return '已通过';
      case 3:
        return '已驳回';
      case 4:
        return '已撤回';
      default:
        return '未知';
    }
  }
}

class WorkflowDetailModel {
  final WorkflowInstanceModel instance;
  final List<WorkflowNodeModel> nodes;

  WorkflowDetailModel({
    required this.instance,
    required this.nodes,
  });

  factory WorkflowDetailModel.fromJson(Map<String, dynamic> json) {
    return WorkflowDetailModel(
      instance: WorkflowInstanceModel.fromJson(json['instance'] ?? json),
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => WorkflowNodeModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WorkflowDefinitionModel {
  final String workflowCode;
  final String workflowName;
  final String businessType;
  final String? description;

  WorkflowDefinitionModel({
    required this.workflowCode,
    required this.workflowName,
    required this.businessType,
    this.description,
  });

  factory WorkflowDefinitionModel.fromJson(Map<String, dynamic> json) {
    return WorkflowDefinitionModel(
      workflowCode: json['workflowCode'] ?? json['workflow_code'] ?? '',
      workflowName: json['workflowName'] ?? json['workflow_name'] ?? '',
      businessType: json['businessType'] ?? json['business_type'] ?? '',
      description: json['description'],
    );
  }
}
