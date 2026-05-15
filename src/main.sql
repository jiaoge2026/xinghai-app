
-- ═══════════════════════════════════════════════════════════════
-- 打印日志表 (2026-05-15 新增)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tb_print_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  template_type VARCHAR(32) NOT NULL COMMENT '模板类型: work-order/voucher/receipt等',
  record_id VARCHAR(64) COMMENT '对应业务记录ID',
  record_no VARCHAR(64) COMMENT '单据编号',
  printed_by VARCHAR(64) NOT NULL COMMENT '操作人',
  printed_at DATETIME NOT NULL COMMENT '打印时间',
  printer_name VARCHAR(128) COMMENT '打印机名称',
  paper_size VARCHAR(32) DEFAULT 'A4' COMMENT '纸张尺寸',
  orientation VARCHAR(16) DEFAULT 'portrait' COMMENT '方向: portrait/landscape',
  copies INT DEFAULT 1 COMMENT '打印份数',
  page_count INT COMMENT '页数',
  print_type VARCHAR(16) DEFAULT 'print' COMMENT '打印类型: print/pdf',
  file_url VARCHAR(256) COMMENT 'PDF文件存储地址',
  ip_address VARCHAR(64) COMMENT '操作人IP',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  INDEX idx_template_type (template_type),
  INDEX idx_record_id (record_id),
  INDEX idx_printed_by (printed_by),
  INDEX idx_printed_at (printed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='打印日志表';

-- ═══════════════════════════════════════════════════════════════
-- 打印设置表 (2026-05-15 新增)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tb_print_settings (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  user_id BIGINT NOT NULL COMMENT '用户ID',
  template_type VARCHAR(32) NOT NULL COMMENT '模板类型',
  paper_size VARCHAR(32) DEFAULT 'A4' COMMENT '纸张尺寸',
  orientation VARCHAR(16) DEFAULT 'portrait' COMMENT '方向',
  margin_top INT DEFAULT 15 COMMENT '上边距(mm)',
  margin_bottom INT DEFAULT 15 COMMENT '下边距(mm)',
  margin_left INT DEFAULT 20 COMMENT '左边距(mm)',
  margin_right INT DEFAULT 20 COMMENT '右边距(mm)',
  repeat_header BOOLEAN DEFAULT TRUE COMMENT '表头每页重复',
  include_watermark BOOLEAN DEFAULT FALSE COMMENT '包含水印',
  include_barcode BOOLEAN DEFAULT TRUE COMMENT '包含条码',
  copies INT DEFAULT 1 COMMENT '默认份数',
  last_used_at DATETIME COMMENT '最后使用时间',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_template (user_id, template_type),
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户打印设置表';

-- ═══════════════════════════════════════════════════════════════
-- 自动打印规则表 (2026-05-15 新增)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tb_print_rule (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  trigger_event VARCHAR(64) NOT NULL COMMENT '触发事件: work-order-completed/payment-received',
  template_type VARCHAR(32) NOT NULL COMMENT '模板类型',
  copies INT DEFAULT 1 COMMENT '打印份数',
  printer_name VARCHAR(128) COMMENT '打印机名称',
  conditions JSON COMMENT '触发条件JSON: {"amount_gt": 1000}',
  enabled BOOLEAN DEFAULT TRUE COMMENT '是否启用',
  created_by VARCHAR(64) COMMENT '创建人',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_trigger_event (trigger_event),
  INDEX idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自动打印规则表';
