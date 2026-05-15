# 星海ERP组件库规范 v1.0

> 最后更新：2026-05-15
> 维护者：阿里小二主

---

## 一、组件库架构

```
framework-components/          # 框架基础组件（第一层）
  ├─ Ui/                      # 通用UI组件
  │   ├─ StatusTag.vue       # 状态徽章
  │   ├─ DateRange.vue       # 日期范围选择
  │   ├─ ConfirmDialog.vue   # 确认对话框
  │   ├─ ImagePreview.vue    # 图片预览
  │   ├─ FileUpload.vue      # 文件上传
  │   ├─ EmptyState.vue      # 空状态
  │   ├─ LoadingSkeleton.vue # 骨架屏
  │   └─ AddressPicker.vue   # 地址选择器
  │
  ├─ Layout/                  # 布局组件
  │   ├─ PageHeader.vue      # 页面头部
  │   ├─ StatCard.vue        # 统计卡片
  │   ├─ TrendChart.vue      # 趋势迷你图
  │   └─ BatchToolbar.vue    # 批量操作工具栏
  │
  ├─ Tree/                    # 树形组件
  │   └─ OrgTree.vue         # 组织树（统一实现）
  │
  └─ Print/                   # 打印组件
      └─ PrintTemplate.vue    # 通用打印模板

page-components/              # 列表页组件（第二层）
  ├─ SearchForm.vue           # 搜索表单
  ├─ DataTable.vue            # 数据表格
  ├─ CrudDialog.vue           # 增删改弹窗
  ├─ Pagination.vue          # 分页器
  └─ ColumnSettings.vue       # 列设置

fsm-components/               # FSM业务组件（第三层）
  ├─ PhotoCompare.vue         # 施工前后对比
  ├─ SignatureCapture.vue     # 电子签名
  ├─ EngineerPicker.vue       # 工程师选择器
  ├─ PartPicker.vue           # 配件选择器
  ├─ StockAlertBadge.vue      # 库存预警徽章
  ├─ WorkOrderStatusFlow.vue  # 工单状态流转图
  ├─ EngineerMap.vue          # 工程师位置地图
  ├─ ServiceTimePicker.vue    # 预约时间选择
  └─ CostEstimator.vue        # 费用预估

finance-components/           # 财务专用组件（第三层）
  ├─ ApprovalPanel.vue        # 审批流程面板
  ├─ VoucherPrint.vue        # 凭证打印
  ├─ PaymentQRCode.vue       # 收款二维码
  └─ SubjectPicker.vue        # 科目选择器
```

---

## 二、组件设计原则

### 2.1 命名规范
- 文件名：PascalCase（StatusTag.vue）
- Props：camelCase，名称体现业务含义
- Events：camelCase，以 handle 开头表示动作
- Slots：PascalCase，名称体现用途

### 2.2 Props 设计原则
```vue
// ✅ 正确：所有选项都显式声明，无any
props: {
  // 简单值
  status: { type: [Number, String], required: true },
  
  // 带默认值
  size: { type: String, default: 'default' },
  
  // 多类型
  value: { type: [Number, String, Array], default: () => [] },
  
  // 带验证
  options: {
    type: Array as PropType<Array<{ label: string, value: string | number }>>,
    required: true
  },
  
  // 回调
  onChange: { type: Function as PropType<(val: any) => void>, default: null },
}
```

### 2.3 样式规范
- 使用 Element Plus CSS 变量，不硬编码颜色
- 组件根元素使用 `class="xh-[component-name]"` 命名空间
- 响应式：`xs/sm/md/lg` 断点统一
- 暗黑模式支持（预留 `.dark` 命名空间）

---

## 三、第一层：框架基础组件

### 3.1 StatusTag.vue — 状态徽章

**用途**：在所有列表页和详情页中显示状态

**Props**：
```ts
interface StatusTagProps {
  status: number | string      // 状态值
  map: Record<string | number, { label: string, type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }>  // 状态映射表
  size?: 'large' | 'default' | 'small'
  effect?: 'light' | 'dark' | 'plain'
  bold?: boolean               // 是否加粗
}
```

**使用方式**：
```vue
<!-- 基础用法 -->
<StatusTag :status="row.status" :map="WORK_ORDER_STATUS_MAP" />

<!-- 固定颜色 -->
<StatusTag :status="1" :map="{ 1: { label: '进行中', type: 'primary' } }" />

<!-- 小尺寸 -->
<StatusTag :status="status" :map="map" size="small" />
```

**实现要求**：
- 内置常用映射表：`WORK_ORDER_STATUS_MAP`（工单）、`FINANCE_STATUS_MAP`（财务）、`APPROVAL_STATUS_MAP`（审批）
- 当 status 不在 map 中时，显示灰色标签 + 原值
- 点击事件支持（可点击的状态标签，如"点击处理"）

---

### 3.2 DateRange.vue — 日期范围选择

**用途**：统一所有页面的日期范围筛选逻辑

**Props**：
```ts
interface DateRangeProps {
  modelValue: [string, string] | null   // v-model
  placeholder?: string
  shortcuts?: Array<{ label: string, value: [string, string] }>  // 预设快捷选项
  format?: string                        // 显示格式，默认 'YYYY-MM-DD'
  valueFormat?: string                   // 值格式，默认 'YYYY-MM-DD'
  disabled?: boolean
  rangeSeparator?: string
  startPlaceholder?: string
  endPlaceholder?: string
  size?: 'large' | 'default' | 'small'
}
```

**快捷选项默认配置**：
```js
const DEFAULT_SHORTCUTS = [
  { label: '今天', value: () => [dayjs().startOf('day'), dayjs().endOf('day')] },
  { label: '近7天', value: () => [dayjs().subtract(7, 'day'), dayjs()] },
  { label: '近30天', value: () => [dayjs().subtract(30, 'day'), dayjs()] },
  { label: '本月', value: () => [dayjs().startOf('month'), dayjs()] },
  { label: '上月', value: () => [dayjs().subtract(1, 'month').startOf('month'), dayjs().subtract(1, 'month').endOf('month')] },
  { label: '本年', value: () => [dayjs().startOf('year'), dayjs()] },
]
```

**使用方式**：
```vue
<!-- 基础用法 -->
<DateRange v-model="searchParams.dateRange" />

<!-- 自定义快捷选项 -->
<DateRange v-model="searchParams.dateRange" :shortcuts="customShortcuts" />

<!-- 精确到时间 -->
<DateRange v-model="searchParams.dateRange" format="YYYY-MM-DD HH:mm:ss" />
```

---

### 3.3 ConfirmDialog.vue — 确认对话框

**用途**：统一所有删除/危险操作的确认框

**Props**：
```ts
interface ConfirmDialogProps {
  visible: boolean
  title?: string
  message: string | (() => string)   // 支持函数（延迟解析）
  type?: 'warning' | 'danger' | 'info'
  confirmText?: string
  cancelText?: string
  confirmLoading?: boolean
  icon?: string                        // el-icon-xxx
  showIcon?: boolean
}
```

**使用方式**：
```vue
<!-- 基础用法 -->
<ConfirmDialog
  v-model="deleteDialogVisible"
  title="删除确认"
  message="确定删除客户「测试酒店」吗？此操作不可恢复。"
  type="danger"
  @confirm="handleDelete"
/>

<!-- 动态消息 -->
<ConfirmDialog
  v-model="dialogVisible"
  :message="() => `确定${action === 'disable' ? '禁用' : '启用'}用户 ${currentUser.name} 吗？`"
  type="warning"
/>
```

**实现要求**：
- `type="danger"` 时确认按钮为红色
- 支持 loading 状态（防重复提交）
- ESC 键和点击遮罩可关闭（cancel）
- 危险操作记录日志到 `tb_operation_log`

---

### 3.4 ImagePreview.vue — 图片预览

**用途**：查看工单照片、配件图片、合同附件

**Props**：
```ts
interface ImagePreviewProps {
  images: Array<{ url: string, label?: string, thumbUrl?: string }>
  index?: number              // 当前显示的索引
  zIndex?: number             // 层级，默认 2000
  hideOnClickModal?: boolean // 点击遮罩关闭，默认 true
}
```

**使用方式**：
```vue
<!-- 基础用法 -->
<ImagePreview :images="workOrderPhotos" @change="currentIndex = $event" />

<!-- 触发按钮模式 -->
<el-button @click="previewVisible = true; currentIndex = 0">
  查看照片 ({{ photos.length }}张)
</el-button>
<ImagePreview
  v-model:visible="previewVisible"
  :images="photos"
  :index="currentIndex"
/>
```

**实现要求**：
- 支持多图左右切换
- 支持图片旋转、放大、缩小
- 显示当前索引 "3 / 12"
- 支持键盘左右箭头切换
- 缩略图列表（可选）

---

### 3.5 FileUpload.vue — 文件上传

**用途**：工单附件、合同上传、凭证上传

**Props**：
```ts
interface FileUploadProps {
  modelValue: string[] | string    // 文件URL列表，或单个URL
  accept?: string                   // 文件类型，如 '.pdf,.doc,.docx,.jpg'
  maxSize?: number                  // 单文件最大MB，默认 10
  maxCount?: number                 // 最多上传数量，默认 10
  multiple?: boolean
  disabled?: boolean
  tip?: string                      // 提示文字
  uploadUrl?: string               // 上传地址，默认 /api/v1/common/upload
  showFileList?: boolean            // 显示文件列表，默认 true
  drag?: boolean                    // 拖拽上传模式
}
```

**使用方式**：
```vue
<!-- 基础用法 -->
<FileUpload v-model="form.attachments" accept=".jpg,.pdf" :max-size="20" />

<!-- 拖拽模式 -->
<FileUpload v-model="form.attachments" drag multiple />

<!-- 单文件 -->
<FileUpload v-model="form.contract" :max-count="1" />
```

**实现要求**：
- 上传前校验文件大小和类型
- 上传进度条
- 支持 PDF、图片、Word、Excel
- 删除前二次确认
- 文件名过长时省略显示（tooltip 完整名称）
- 下载时直接打开（不弹出新窗口）

---

### 3.6 EmptyState.vue — 空状态

**用途**：列表/搜索无结果时的友好提示

**Props**：
```ts
interface EmptyStateProps {
  type?: 'no-data' | 'no-result' | 'loading' | 'error' | 'network'
  title?: string
  description?: string
  image?: string              // 自定义图片，默认为内置 SVG
  showAction?: boolean        // 是否显示操作按钮
  actionText?: string         // 操作按钮文字
  icon?: string               // el-icon-xxx，与 type 二选一
}
```

**使用方式**：
```vue
<!-- 基础用法 -->
<EmptyState type="no-data" description="暂无工单数据" />

<!-- 搜索无结果 -->
<EmptyState
  type="no-result"
  :title="`未找到「${keyword}」相关结果`"
  description="请尝试其他关键词"
  action-text="清除搜索"
  @action="clearSearch"
/>
```

**内置类型**：
- `no-data`：暂无数据（列表为空）
- `no-result`：筛选无结果（搜索/过滤后无匹配）
- `loading`：加载中（el-skeleton 骨架屏）
- `error`：加载失败（网络错误）
- `network`：网络异常

---

### 3.7 LoadingSkeleton.vue — 骨架屏

**用途**：数据加载中时显示骨架屏，提升感知性能

**Props**：
```ts
interface LoadingSkeletonProps {
  active?: boolean      // 是否动画，默认 true
  rows?: number         // 骨架行数，默认 3
  avatar?: boolean       // 是否显示头像占位
  title?: boolean       // 是否显示标题占位
  titleWidth?: string   // 标题宽度，如 '40%'
  columns?: number      // 列数（用于表格骨架）
}
```

**使用方式**：
```vue
<LoadingSkeleton v-if="loading" :rows="5" />
<div v-else>
  <!-- 真实内容 -->
</div>
```

---

### 3.8 AddressPicker.vue — 地址选择器

**用途**：客户地址、服务地址的省市区三级联动选择

**Props**：
```ts
interface AddressPickerProps {
  modelValue: string | { province: string, city: string, district: string, detail: string }
  level?: 2 | 3           // 显示级别，默认3（省市区）
  placeholder?: string
  disabled?: boolean
  showDetail?: boolean   // 是否显示详细地址输入框，默认 true
}
```

**使用方式**：
```vue
<!-- 基础用法 -->
<AddressPicker v-model="form.address" />

<!-- 分离式（省市区和详细地址分开） -->
<AddressPicker v-model="form.address" @change="handleAddressChange" />
<!-- form.address = { province: '山东省', city: '济南市', district: '历下区', detail: 'XX路XX号' } -->
```

**实现要求**：
- 集成中国省市区数据（内置，约3MB JSON）
- 支持任意级别（如只选省市）
- 详细地址自动拼接显示
- 支持搜索（输入模糊匹配省市区）
- 选择后自动填充邮编（可选）

---

### 3.9 PageHeader.vue — 页面头部

**用途**：统一所有列表页的页面头部

**Props**：
```ts
interface PageHeaderProps {
  title: string
  subtitle?: string
  icon?: string              // el-icon-xxx
  showBorder?: boolean       // 是否显示底部边框，默认 true
  showBreadcrumb?: boolean   // 是否显示面包屑，默认 true
  actions?: Array<{ label: string, type?: string, icon?: string, onClick: Function }>
}
```

**使用方式**：
```vue
<PageHeader title="工单管理" icon="el-icon-tickets" :actions="headerActions">
  <template #breadcrumb>
    <el-breadcrumb separator="/">
      <el-breadcrumb-item :to="{ path: '/dashboard' }">首页</el-breadcrumb-item>
      <el-breadcrumb-item>工单管理</el-breadcrumb-item>
    </el-breadcrumb>
  </template>
</PageHeader>
```

---

### 3.10 StatCard.vue — 统计卡片

**用途**：Dashboard 和各业务域首页的指标卡片

**Props**：
```ts
interface StatCardProps {
  title: string
  value: number | string
  prefix?: string             // 前缀，如 '¥'
  suffix?: string             // 后缀，如 '%'
  precision?: number          // 数值精度，默认 0
  trend?: { value: number, type: 'up' | 'down' | 'neutral' }  // 趋势
  trendLabel?: string         // 趋势说明，如 '较上月'
  color?: 'primary' | 'success' | 'warning' | 'danger' | 'info'
  icon?: string               // el-icon-xxx
  loading?: boolean
  gradient?: boolean          // 是否渐变背景
}
```

**使用方式**：
```vue
<div class="stat-cards">
  <StatCard title="今日新增" :value="4757" icon="el-icon-plus" color="primary" />
  <StatCard title="进行中" :value="641" icon="el-icon-loading" color="warning" />
  <StatCard title="本月完成" :value="2938" icon="el-icon-check" color="success" />
  <StatCard
    title="本月营收"
    :value="124345.85"
    prefix="¥"
    :precision="2"
    :trend="{ value: 12.5, type: 'up' }"
    trend-label="较上月"
    color="success"
  />
</div>
```

---

### 3.11 TrendChart.vue — 趋势迷你图

**用途**：在列表行或卡片中内嵌小尺寸趋势图

**Props**：
```ts
interface TrendChartProps {
  data: number[]              // 数据点数组
  color?: string               // 线条颜色
  height?: number              // 高度，默认 40
  width?: number | string      // 宽度，默认 100
  showArea?: boolean          // 是否填充区域，默认 false
  smooth?: boolean            // 平滑曲线，默认 true
}
```

**使用方式**：
```vue
<!-- 表格内嵌趋势 -->
<el-table-column label="30日趋势" width="120">
  <template #default="{ row }">
    <TrendChart :data="row.revenueHistory" :height="30" show-area />
  </template>
</el-table-column>
```

**实现要求**：
- 纯 SVG 实现，不引入 ECharts（太重）
- 支持 5 个数据点以上自动适配
- 悬浮显示数值 tooltip

---

### 3.12 BatchToolbar.vue — 批量操作工具栏

**用途**：列表页勾选后的批量操作

**Props**：
```ts
interface BatchToolbarProps {
  selectedCount: number       // 已勾选数量
  max?: number                // 最大勾选数量，null 表示不限制
  actions: Array<{
    key: string
    label: string
    icon?: string
    type?: string              // 'default' | 'primary' | 'success' | 'warning' | 'danger'
    disabled?: boolean
    dividerBefore?: boolean    // 分隔线
  }>
  position?: 'top' | 'bottom' | 'both'
}
```

**使用方式**：
```vue
<BatchToolbar
  :selected-count="selectedRows.length"
  :actions="[
    { key: 'export', label: '导出选中', icon: 'el-icon-download' },
    { key: 'print', label: '批量打印', icon: 'el-icon-printer' },
    { key: 'delete', label: '批量删除', icon: 'el-icon-delete', type: 'danger' },
  ]"
  @action="handleBatchAction"
/>
```

**实现要求**：
- 选中数量 > 0 时自动显示
- 工具栏悬浮在表格上方/下方
- 有删除操作时，显示红色警告色
- 点击操作后弹出确认框

---

### 3.13 OrgTree.vue — 组织树（统一实现）

**用途**：服务站/部门/网点选择

**Props**：
```ts
interface OrgTreeProps {
  modelValue: string | number | Array    // 选中值
  multiple?: boolean                    // 多选，默认 false
  showCheckbox?: boolean               // 显示复选框，默认 false
  placeholder?: string
  disabled?: boolean
  size?: 'large' | 'default' | 'small'
  nodeType?: 'service_station' | 'department' | 'all'
  defaultExpandAll?: boolean
  checkStrictly?: boolean              // 勾选父子不关联，默认 false
}
```

**使用方式**：
```vue
<!-- 单选 -->
<OrgTree v-model="form.serviceStationId" node-type="service_station" />

<!-- 多选带复选框 -->
<OrgTree v-model="selectedStations" multiple show-checkbox node-type="service_station" />

<!-- 带搜索 -->
<OrgTree v-model="form.deptId" :filterable="true" placeholder="搜索组织" />
```

**实现要求**：
- 内置海尔服务商组织架构数据（服务站→区域→总部）
- 支持按名称搜索过滤
- 支持懒加载子节点（数据量大时）
- 默认展开到用户所属服务站

---

### 3.14 PrintTemplate.vue — 通用打印模板

**用途**：工单打印、凭证打印、报表打印

**Props**：
```ts
interface PrintTemplateProps {
  title: string
  width?: string               // 纸张宽度，默认 '210mm'
  height?: string               // 纸张高度，默认 '297mm'
  direction?: 'portrait' | 'landscape'
  showHeader?: boolean          // 显示页眉，默认 true
  showFooter?: boolean          // 显示页脚（页码），默认 true
  headerContent?: string        // 页眉内容
  printCss?: string             // 自定义打印CSS
}
```

**使用方式**：
```vue
<PrintTemplate
  title="工单详情"
  width="210mm"
  :show-footer="true"
  footer-content="第 {page} 页 / 共 {total} 页"
>
  <!-- 打印内容 -->
  <div class="print-content">
    <h1>工单编号：WO202605150001</h1>
    <el-descriptions :column="2" border>
      <!-- ... -->
    </el-descriptions>
  </div>
</PrintTemplate>
```

**实现要求**：
- 使用 `@media print` CSS 隐藏非打印内容
- 打印时自动分页（避免表格断裂）
- 打印预览弹窗（用户确认后再打印）
- 支持 A4 / A5 / 热敏纸（58mm/80mm）多种纸张

---

### 3.15 OperationLog — 操作日志

**数据表**：`tb_operation_log`
```sql
CREATE TABLE tb_operation_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  username VARCHAR(64) NOT NULL,
  module VARCHAR(64) NOT NULL COMMENT '模块：工单/客户/财务',
  action VARCHAR(32) NOT NULL COMMENT '动作：CREATE/UPDATE/DELETE/EXPORT/APPROVE',
  target_type VARCHAR(64) COMMENT '操作对象类型：WorkOrder/Customer',
  target_id BIGINT COMMENT '操作对象ID',
  target_name VARCHAR(256) COMMENT '操作对象名称（冗余，方便查询）',
  detail JSON COMMENT '变更详情，JSON格式',
  ip_address VARCHAR(64),
  user_agent VARCHAR(512),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_target (target_type, target_id),
  INDEX idx_module_action (module, action),
  INDEX idx_created_at (created_at)
);
```

**API**：
- `POST /api/v1/common/logs` — 记录操作日志
- `GET /api/v1/common/logs` — 查询操作日志（支持按模块/操作对象/时间/用户筛选）

**实现要求**：
- 全局日志切面（AOP），自动记录所有 CREATE/UPDATE/DELETE
- 财务模块强制记录（审批流每一步都要记录）
- 日志不可删除（软删都禁止）
- 敏感操作（删除/审批）记录变更前后对比

---

### 3.16 NotificationCenter — 消息通知中心

**数据表**：`tb_notification`
```sql
CREATE TABLE tb_notification (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL COMMENT '通知对象',
  type VARCHAR(32) NOT NULL COMMENT '类型：WORK_ORDER/APPROVAL/REMINDER/SYSTEM',
  title VARCHAR(256) NOT NULL,
  content TEXT,
  link_url VARCHAR(512) COMMENT '点击跳转链接',
  link_params JSON COMMENT '跳转参数',
  is_read TINYINT DEFAULT 0,
  read_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_unread (user_id, is_read),
  INDEX idx_created_at (created_at)
);
```

**API**：
- `GET /api/v1/common/notifications` — 我的通知列表
- `PUT /api/v1/common/notifications/:id/read` — 标记已读
- `PUT /api/v1/common/notifications/read-all` — 全部已读
- `GET /api/v1/common/notifications/unread-count` — 未读数

**组件**：`NotificationBell.vue`
```vue
<!-- 通知铃铛，放在 Header 右侧 -->
<NotificationBell :user-id="currentUser.id" @click-notification="handleClick" />
```

**触发场景**：
| 场景 | 通知类型 | 接收人 |
|------|----------|--------|
| 工单状态变更 | WORK_ORDER | 工程师 + 客服 |
| 新的派工 | WORK_ORDER | 工程师 |
| 工单完工待结算 | WORK_ORDER | 财务 |
| 审批提交 | APPROVAL | 审批人 |
| 审批通过/拒绝 | APPROVAL | 申请人 |
| 库存不足预警 | REMINDER | 仓库管理员 |
| 系统公告 | SYSTEM | 全体用户 |

---

## 四、第二层：列表页组件

### 4.1 SearchForm.vue — 搜索表单

**用途**：所有列表页的搜索条件区域

**Props**：
```ts
interface SearchFormProps {
  fields: Array<{
    key: string
    label: string
    type: 'input' | 'select' | 'date-range' | 'date' | 'cascader' | 'org-tree' | 'status-select'
    placeholder?: string
    options?: Array<{ label: string, value: any }>  // select用
    map?: Record<any, any>                          // status-select用
    defaultValue?: any
    cols?: number           // 占用列数，默认1，最大4
    events?: Record<string, Function>  // 事件监听
  }>
  modelValue: Record<string, any>   // v-model
  layout?: 'inline' | 'grid'        // inline=单行，grid=多行网格
  columns?: number                  // grid模式列数，默认4
  showAdvanced?: boolean            // 显示高级筛选，默认 false
  advancedFields?: Array<string>    // 高级筛选字段keys
  loading?: boolean
}
```

**使用方式**：
```vue
<SearchForm
  v-model="searchParams"
  :fields="searchFields"
  layout="inline"
  @search="handleSearch"
  @reset="handleReset"
>
  <!-- 高级筛选折叠区域 -->
  <template #advanced>
    <!-- 高级筛选字段 -->
  </template>
</SearchForm>

<script setup>
const searchFields = [
  { key: 'woNo', label: '工单编号', type: 'input', placeholder: '请输入工单编号' },
  { key: 'status', label: '状态', type: 'status-select', map: WORK_ORDER_STATUS_MAP },
  { key: 'engineerName', label: '工程师', type: 'input', placeholder: '工程师姓名' },
  { key: 'dateRange', label: '完工时间', type: 'date-range' },
  { key: 'serviceStationId', label: '服务站', type: 'org-tree', nodeType: 'service_station' },
]
</script>
```

**内置行为**：
- 回车触发搜索
- 搜索后自动收起键盘（移动端）
- 重置时恢复默认值（不是清空）
- 搜索历史记录（localStorage，最多10条）
- 防抖输入（300ms）

---

### 4.2 DataTable.vue — 数据表格

**用途**：统一所有列表页的表格

**Props**：
```ts
interface DataTableProps {
  data: Array<Record<string, any>>
  columns: Array<{
    key: string
    label: string
    width?: string | number
    minWidth?: string | number
    align?: 'left' | 'center' | 'right'
    fixed?: 'left' | 'right' | boolean
    sortable?: boolean
    prop?: string                    // 等同于key，用于el-table-column
    type?: 'selection' | 'index' | 'expand'
    
    // 特殊列类型
    columnType?: 'status' | 'date' | 'datetime' | 'currency' | 'image' | 'actions' | 'tags'
    
    // Status列
    statusMap?: Record<any, { label: string, type: string }>
    
    // DateTime列
    format?: string                   // 显示格式，默认 'YYYY-MM-DD HH:mm'
    
    // Currency列
    prefix?: string                   // 前缀，如 '¥'
    precision?: number                // 小数位，默认2
    
    // Image列
    imageWidth?: string
    imageHeight?: string
    
    // Actions列
    actions?: Array<{
      key: string
      label: string
      type?: string
      icon?: string
      danger?: boolean
      disabled?: boolean | string
      confirm?: { title: string, message: string, type?: string }
    }>
    
    // 自定义列
    slot?: string                     // 自定义插槽名
    
    // 条件显示
    show?: boolean | { xs?: boolean, sm?: boolean, md?: boolean }
  }>
  
  loading?: boolean
  selection?: boolean                // 是否可勾选
  selectedRows?: Array<any>           // v-model:selected-rows
  expandable?: boolean               // 行展开
  expandSlot?: string                 // 展开行插槽名
  stripe?: boolean                   // 斑马纹，默认 true
  border?: boolean
  size?: 'large' | 'default' | 'small'
  rowClassName?: string | Function
  emptyText?: string
  
  // 列设置
  columnSettingsKey?: string         // 用户列设置存储key
}
```

**使用方式**：
```vue
<DataTable
  v-model:selected-rows="selectedRows"
  :data="tableData"
  :columns="tableColumns"
  :loading="loading"
  @sort-change="handleSort"
  @row-click="handleRowClick"
>
  <!-- 自定义列插槽 -->
  <template #column_photo="{ row }">
    <el-image :src="row.photoUrl" preview-src-list=[row.photoUrl] fit="cover" style="width:40px;height:40px" />
  </template>
  
  <!-- 操作列（也可在columns里定义actions） -->
  <template #column_actions="{ row }">
    <el-button link type="primary" @click="handleEdit(row)">编辑</el-button>
    <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
  </template>
</DataTable>
```

**内置行为**：
- 双击行进入编辑
- 行悬浮高亮
- 点击行选中/取消选中（selection模式）
- 列排序（服务端/客户端）
- 列拖拽排序
- 列宽可拖拽调整（持久化到用户设置）
- 复制单元格内容（选中文本后Ctrl+C）
- 右键菜单（查看/编辑/删除）

---

### 4.3 CrudDialog.vue — 增删改弹窗

**用途**：统一所有新建/编辑弹窗

**Props**：
```ts
interface CrudDialogProps {
  visible: boolean           // v-model
  mode: 'create' | 'edit' | 'view'
  title?: string             // 默认根据mode显示「新建/编辑/查看」
  width?: string | number    // 默认 '600px'，view模式默认 '800px'
  labelWidth?: string        // 表单标签宽度，默认 '120px'
  labelPosition?: 'left' | 'right' | 'top'
  fields: Array<{            // 表单字段定义
    key: string
    label: string
    type: 'input' | 'textarea' | 'number' | 'select' | 'radio' | 'switch'
             | 'date' | 'datetime' | 'date-range' | 'cascader' | 'org-tree'
             | 'image-upload' | 'file-upload' | 'address-picker' | 'editor'
    placeholder?: string
    rules?: Array<Rule>      // Element Plus rules
    options?: Array<any>      // select用
    map?: Record<any, any>    // select/Status用
    props?: Record<string, any>  // 透传给内部组件
    defaultValue?: any
    cols?: number             // 所占列数，默认1（最多2列）
    show?: boolean | Function  // 条件显示
    disabled?: boolean | Function
    if?: boolean              // if为false则不渲染该字段
  }>
  modelValue: Record<string, any>   // v-model
  saving?: boolean                  // 保存中loading
  showFooter?: boolean              // 显示底部按钮，默认 true
  confirmText?: string
  cancelText?: string
  
  // 异步数据加载（编辑时需要回填数据）
  loadData?: (id: any) => Promise<Record<string, any>>
  dataLoader?: { url: string, params?: Record<string, any> }  // 简写方式
}
```

**使用方式**：
```vue
<CrudDialog
  v-model="dialogVisible"
  v-model:model-value="formData"
  mode="edit"
  :fields="formFields"
  title="编辑客户"
  :load-data="loadWorkOrderDetail"
  @save="handleSave"
  @cancel="dialogVisible = false"
/>

<script setup>
const formFields = [
  { key: 'customerName', label: '客户名称', type: 'input', rules: [{ required: true, message: '必填' }] },
  { key: 'industry', label: '行业', type: 'select', options: INDUSTRY_OPTIONS },
  { key: 'contactName', label: '联系人', type: 'input' },
  { key: 'phone', label: '手机', type: 'input', rules: [{ pattern: /^1[3-9]\d{9}$/, message: '手机号格式错误' }] },
  { key: 'address', label: '地址', type: 'address-picker', cols: 2 },
  { key: 'status', label: '状态', type: 'switch', props: { activeValue: 1, inactiveValue: 0 } },
]
</script>
```

**内置行为**：
- 切换 mode 时自动处理字段只读/隐藏
- `view` 模式所有字段 disabled，隐藏底部按钮
- `edit` 模式显示保存按钮
- 表单提交前自动校验
- 校验失败时滚动到第一个错误字段
- ESC 关闭（view模式）或弹出确认（edit模式有变更时）
- 编辑模式下自动通过 `loadData` 加载数据并回填
- 支持子表单（嵌套数组字段，如多个联系人）

---

### 4.4 Pagination.vue — 分页器

**用途**：统一所有列表页分页

**Props**：
```ts
interface PaginationProps {
  modelValue: { page: number, pageSize: number }  // v-model
  total: number
  pageSizes?: Array<number>      // 可选每页条数，默认 [10, 20, 50, 100]
  layout?: string                 // el-pagination layout，默认 'total, sizes, prev, pager, next, jumper'
  background?: boolean            // 背景样式，默认 true
  sizes?: 'default' | 'small'
}
```

**使用方式**：
```vue
<Pagination
  v-model="pagination"
  :total="total"
  @change="handlePageChange"
/>
```

**内置行为**：
- 切换每页条数时自动回到第1页
- 输入页码跳转后自动失焦
- 总数 < 10 不显示分页器（可选）
- 记住用户偏好的每页条数（localStorage）

---

### 4.5 ColumnSettings.vue — 列设置（已完成，需通用化）

**用途**：用户自定义表格列的显示/隐藏/顺序/宽度

**已实现功能**：
- 拖拽排序列
- 显示/隐藏列
- 保存到 `tb_user_column_config`（后端持久化）
- 切换视图（命名视图）

**需要通用化**：
- 从工单列表泛化到所有列表页
- 提取 `column-settings` 为独立组件
- 支持按页面唯一标识存储多套配置

---

## 五、第三层：FSM业务组件

### 5.1 PhotoCompare.vue — 施工前后对比

**用途**：工单详情页显示施工前后照片对比

**Props**：
```ts
interface PhotoCompareProps {
  before: { url: string, label?: string, timestamp?: string }   // 施工前
  after: { url: string, label?: string, timestamp?: string }       // 施工后
  height?: string | number     // 默认 400
  syncScroll?: boolean          // 同步滚动，默认 true
  showTimestamp?: boolean       // 显示时间戳，默认 true
  downloadable?: boolean       // 显示下载按钮，默认 false
}
```

**使用方式**：
```vue
<PhotoCompare
  :before="{ url: row.beforePhotoUrl, label: '维修前', timestamp: row.createdAt }"
  :after="{ url: row.afterPhotoUrl, label: '维修后', timestamp: row.completeTime }"
  :height="450"
/>
```

**实现要求**：
- 左右分屏对比，可拖拽分割线
- 支持单图模式（只有before或after）
- 放大镜功能（鼠标悬停放大）
- 点击图片全屏预览（调用 ImagePreview）

---

### 5.2 SignatureCapture.vue — 电子签名

**用途**：完工确认时客户电子签名

**Props**：
```ts
interface SignatureCaptureProps {
  modelValue: string             // Base64签名图片
  width?: number                 // 画布宽度，默认 400
  height?: number                // 画布高度，默认 200
  strokeColor?: string           // 笔颜色，默认 '#000'
  strokeWidth?: number           // 笔粗细，默认 2
  disabled?: boolean
  placeholder?: string           // 提示文字
}
```

**使用方式**：
```vue
<!-- 签名区 -->
<SignatureCapture v-model="form.signature" />

<!-- 已有签名（查看模式） -->
<SignatureCapture v-model="workOrder.signature" disabled />
```

**实现要求**：
- Canvas 绑定鼠标/触摸事件
- 支持撤销（undo最近一笔）
- 支持清空（重新签名）
- 生成 PNG Base64，保存到服务器
- 水印：签名人 + 签名时间（渲染到图片上）
- 签名区边框虚线提示

---

### 5.3 EngineerPicker.vue — 工程师选择器

**用途**：派工时按条件筛选工程师

**Props**：
```ts
interface EngineerPickerProps {
  modelValue: number | string | Array   // 选中的工程师ID
  multiple?: boolean
  placeholder?: string
  size?: 'large' | 'default' | 'small'
  disabled?: boolean
  
  // 筛选条件
  filterServiceStation?: number | string   // 服务站ID
  filterSkill?: string                     // 技能标签
  filterStatus?: 'available' | 'busy' | 'offline'  // 实时状态
  filterRegion?: string                    // 服务区域
  showStatus?: boolean                    // 显示当前状态，默认 true
  showSkill?: boolean                     // 显示技能标签，默认 true
  showLocation?: boolean                  // 显示当前位置，默认 false（需要GPS）
  showDistance?: boolean                  // 显示距离客户的距离，默认 false
}
```

**使用方式**：
```vue
<EngineerPicker
  v-model="form.engineerId"
  :filter-service-station="userStore.serviceStationId"
  filter-status="available"
  show-location
  @change="handleEngineerChange"
/>
```

**实现要求**：
- 下拉列表显示工程师卡片（照片+姓名+状态+技能）
- 状态颜色：绿色=空闲、橙色=服务中、灰色=离线
- 支持按姓名/电话搜索
- 显示当前服务中的工单数量
- 显示今日已完成工单数
- 按距离排序（当 showDistance=true 时）
- 移动端支持从通讯录选择

---

### 5.4 PartPicker.vue — 配件选择器

**用途**：工单中配件出库时按库存选择

**Props**：
```ts
interface PartPickerProps {
  modelValue: Array<{ partId: number, quantity: number, price: number }>  // 已选配件
  warehouseId?: number | string
  disabled?: boolean
  maxTotal?: number              // 总数量上限
  showPrice?: boolean            // 显示单价，默认 true
  showStock?: boolean            // 显示库存，默认 true
  filterCategory?: string         // 配件类别筛选
}
```

**使用方式**：
```vue
<PartPicker
  v-model="selectedParts"
  :warehouse-id="form.warehouseId"
  :show-stock="true"
  @change="handlePartsChange"
/>

<!-- 显示已选配件汇总 -->
<div class="parts-summary">
  共 {{ selectedParts.length }} 种配件，
  合计 ¥{{ selectedParts.reduce((s, p) => s + p.price * p.quantity, 0).toFixed(2) }}
</div>
```

**实现要求**：
- 搜索配件（按名称/编号）
- 按类别筛选
- 库存为0时置灰不可选
- 选择时显示当前库存和可用数量
- 自动计算金额小计
- 支持扫码添加（配件条码扫描）
- 超过库存时红色警告

---

### 5.5 StockAlertBadge.vue — 库存预警徽章

**用途**：配件库存不足时在菜单/图标上显示红色徽章

**Props**：
```ts
interface StockAlertBadgeProps {
  partId: number
  type?: 'dot' | 'count'         // 点状或数字
  threshold?: number              // 预警阈值，默认 5
  placement?: string              // 徽章位置，默认 'right-top'
}
```

**使用方式**：
```vue
<!-- 仓库菜单显示预警数量 -->
<el-menu-item index="/wms/stock">
  <span>库存管理</span>
  <StockAlertBadge :part-id="0" type="count" />
</el-menu-item>

<!-- 配件卡片显示 -->
<el-badge :value="stockAlert" :hidden="stockAlert === 0" type="danger">
  <span>{{ partName }}</span>
</el-badge>
```

**实现要求**：
- 实时查询低于阈值的配件数量
- 支持轮询（每5分钟刷新一次）
- 点击徽章展开预警配件列表
- 支持配置预警规则（每个配件独立阈值）

---

### 5.6 WorkOrderStatusFlow.vue — 工单状态流转图

**用途**：在工单详情页显示当前状态在流程中的位置

**Props**：
```ts
interface WorkOrderStatusFlowProps {
  currentStatus: number | string
  statusMap: Record<string | number, string>
  completedAt?: Record<string, string>   // 每个状态的完成时间
  showTime?: boolean
  direction?: 'horizontal' | 'vertical'
}
```

**使用方式**：
```vue
<WorkOrderStatusFlow
  :current-status="workOrder.status"
  :status-map="WORK_ORDER_STATUS_FLOW"
  :completed-at="statusTimestamps"
  show-time
/>
```

**流程定义（固定8步）**：
```
派工(WAITING_ASSIGN) → 接单(ASSIGNED) → 上门(ON_WAY) → 开始服务(SERVING)
→ 完工(COMPLETED) → 结算(PENDING_SETTLE) → 已结算(SETTLED) → 归档(ARCHIVED)
```

**实现要求**：
- 当前状态高亮，前面的步骤显示绿色勾
- 后面的步骤显示灰色
- 支持时间戳显示（每个步骤完成时间）
- 点击历史步骤可查看该步骤的操作记录
- 异常状态（超时/取消）特殊颜色标记

---

### 5.7 ServiceTimePicker.vue — 预约服务时间

**用途**：客户预约上门服务时间

**Props**：
```ts
interface ServiceTimePickerProps {
  modelValue: string | null     // 预约日期时间
  serviceStationId: number | string
  disabledDate?: Function       // 禁选日期函数
  timeSlots?: Array<{ label: string, value: string, available: boolean }>
  minAdvanceDays?: number       // 最少提前天数，默认0
  maxAdvanceDays?: number       // 最多提前天数，默认30
}
```

**使用方式**：
```vue
<ServiceTimePicker
  v-model="form.appointmentTime"
  :service-station-id="form.serviceStationId"
  @change="handleAppointmentChange"
/>
```

**实现要求**：
- 日期选择：排除不可预约日期（服务站休息日/已满额日期）
- 时间段选择：上午(8:00-12:00)/下午(12:00-18:00)/晚上(18:00-20:00)
- 显示每个时间段剩余可预约数
- 节假日自动显示"不可预约"
- 选择后自动检查工程师排班（可选）
- 变更预约时显示违约金提示

---

### 5.8 CostEstimator.vue — 费用预估

**用途**：上门前根据故障类型预估费用

**Props**：
```ts
interface CostEstimatorProps {
  modelValue: { laborFee: number, partsFee: number, transportFee: number, total: number }
  productCategory?: string       // 产品类别（影响工时费率）
  productBrand?: string          // 品牌（影响配件折扣）
  faultType?: string             // 故障类型
  customerType?: 'home' | 'business'
  readonly?: boolean
}
```

**使用方式**：
```vue
<CostEstimator
  v-model="estimateCost"
  :product-category="form.productCategory"
  :product-brand="form.productBrand"
  :fault-type="form.faultDescription"
  customer-type="home"
  @change="form.estimatedCost = $event.total"
/>
```

**实现要求**：
- 自动根据产品类别和故障类型填充工时费
- 配件费由 PartPicker 实时汇总
- 交通费根据服务距离计算
- 显示总价和明细
- 提供"上门检测费"选项（先收检测费后抵扣维修费）
- readonly 模式下仅展示预估单

---

## 六、第三层：财务专用组件

### 6.1 ApprovalPanel.vue — 审批流程面板

**用途**：审批流程可视化 + 审批操作按钮

**Props**：
```ts
interface ApprovalPanelProps {
  processInstanceId: string | number
  currentNode: { nodeId: string, nodeName: string, assignee: string }
  historyNodes: Array<{
    nodeId: string
    nodeName: string
    assignee: string
    assigneeName: string
    action: 'APPROVE' | 'REJECT' | 'TRANSFER' | 'SUBMIT'
    comment: string
    completedAt: string
  }>
  currentUserId: number
  canApprove?: boolean          // 当前用户是否有审批权限
}
```

**使用方式**：
```vue
<ApprovalPanel
  :process-instance-id="processInstanceId"
  :current-node="currentNode"
  :history-nodes="historyNodes"
  :current-user-id="currentUser.id"
  :can-approve="canApprove"
  @approve="handleApprove"
  @reject="handleReject"
  @transfer="handleTransfer"
/>
```

**实现要求**：
- 时间线形式展示审批历史
- 当前节点高亮 + 待办提示
- 审批意见（文字）
- 支持驳回（驳回到任意历史节点）
- 支持转交（转交给其他人审批）
- 支持加签（在当前节点前后加签）
- 审批按钮权限控制

---

### 6.2 VoucherPrint.vue — 凭证打印

**用途**：财务凭证的打印预览和打印

**Props**：
```ts
interface VoucherPrintProps {
  voucher: {
    voucherNo: string
    voucherDate: string
    accountant: string
    auditor: string
    postDate: string
    attachments: number
    entries: Array<{
      serialNo: number
      subjectCode: string
      subjectName: string
      debitAmount: number
      creditAmount: number
      summary: string
    }>
    totalDebit: number
    totalCredit: number
    amountInWords: string
  }
  printDirection?: 'portrait' | 'landscape'
}
```

**使用方式**：
```vue
<VoucherPrint :voucher="voucherData" />
```

**实现要求**：
- 凭证纸打印格式（记账凭证标准样式）
- 借贷方金额自动大写
- 附件张数显示
- 主管/会计/审核/出纳签章区
- 套打模式（预先印好格式的纸张上打印）
- PDF导出

---

### 6.3 PaymentQRCode.vue — 收款二维码

**用途**：向客户展示收款二维码

**Props**：
```ts
interface PaymentQRCodeProps {
  amount: number
  orderNo: string
  methods?: Array<'wechat' | 'alipay' | 'bank'>
  expiryMinutes?: number        // 二维码有效期，默认 30
}
```

**使用方式**：
```vue
<PaymentQRCode
  :amount="settlementAmount"
  :order-no="workOrder.woNo"
  :methods="['wechat', 'alipay']"
  @paid="handlePaymentReceived"
/>
```

**实现要求**：
- 微信/支付宝二维码轮换显示（倒计时切换）
- 金额必须扫码后自动填充（不能写死）
- 倒计时显示有效期
- 过期自动刷新
- 收到通知后高亮"已支付"
- 扫码枪模式支持

---

### 6.4 SubjectPicker.vue — 科目选择器

**用途**：凭证录入时选择会计科目

**Props**：
```ts
interface SubjectPickerProps {
  modelValue: string | { code: string, name: string }
  level?: number                 // 显示级别，默认显示所有
  placeholder?: string
  disabled?: boolean
  size?: 'large' | 'default' | 'small'
  showCode?: boolean             // 显示科目编码，默认 true
  showBalance?: boolean          // 显示余额，默认 false
  filter?: (subject: Subject) => boolean  // 过滤函数
}
```

**使用方式**：
```vue
<!-- 基础用法 -->
<SubjectPicker v-model="entry.subject" />

<!-- 带余额（出纳模块用） -->
<SubjectPicker v-model="entry.subject" show-balance />
```

**实现要求**：
- 树形展示科目体系（一级/二级/三级/四级）
- 支持搜索（按编码或名称）
- 选择后显示 "1001 银行存款"
- 显示余额时实时查数据库
- 末级科目才能选择（非末级灰色不可选）
- 最近使用科目置顶

---

## 七、通用工具集（独立Utils，不依赖Vue）

### 7.1 数据格式化

```ts
// src/utils/format.ts
formatCurrency(amount: number, precision = 2, prefix = '¥'): string
formatDate(date: string | Date, format = 'YYYY-MM-DD'): string
formatDateTime(date: string | Date, format = 'YYYY-MM-DD HH:mm:ss'): string
formatNumber(num: number, precision = 0): string
formatPercent(value: number, precision = 1): string
formatFileSize(bytes: number): string
formatPhone(phone: string): string      // 显示为 136****6888
formatIdCard(idCard: string): string   // 显示为 3701***********1234
```

### 7.2 数据验证

```ts
// src/utils/validate.ts
isPhone(value: string): boolean
isIdCard(value: string): boolean
isEmail(value: string): boolean
isBankCard(value: string): boolean
isURL(value: string): boolean
validateAmount(value: number, min = 0, max?): { valid: boolean, message: string }
```

### 7.3 业务映射

```ts
// src/utils/maps.ts
// 统一导出所有业务状态映射表，任何页面直接 import 使用
WORK_ORDER_STATUS_MAP: Record<number, { label: string, type: string }>
WORK_ORDER_TYPE_MAP
FINANCE_VOUCHER_STATUS_MAP
APPROVAL_STATUS_MAP
STOCK_IN_STATUS_MAP
STOCK_OUT_STATUS_MAP
```

### 7.4 请求封装

```ts
// src/utils/request.ts
// 基于 axios 封装，统一处理：
// - Token 自动注入
// - 401 自动跳转登录
// - 错误消息 Toast
// - 导出请求进度
// - 请求重试（网络错误时）
```

---

## 八、开发计划

### Phase 0：基础设施（1天）
- [ ] 统一 `src/utils/maps.ts`（所有业务映射表）
- [ ] 统一 `src/utils/format.ts`（格式化工具）
- [ ] 统一 `src/utils/validate.ts`（验证工具）
- [ ] 统一 `src/utils/request.ts`（axios封装）
- [ ] 建立 `src/components/framework/` 和 `src/components/page/` 目录结构

### Phase 1：框架基础组件（2天）
- [ ] StatusTag.vue + 默认映射表
- [ ] DateRange.vue
- [ ] ConfirmDialog.vue
- [ ] ImagePreview.vue
- [ ] EmptyState.vue
- [ ] LoadingSkeleton.vue
- [ ] PageHeader.vue
- [ ] StatCard.vue

### Phase 2：列表页组件（2天）
- [ ] SearchForm.vue
- [ ] DataTable.vue
- [ ] CrudDialog.vue
- [ ] Pagination.vue
- [ ] ColumnSettings.vue（通用化）
- [ ] BatchToolbar.vue

### Phase 3：第二层组件在现有页面的应用（2天）
- [ ] 用新组件重构 WorkOrderList.vue
- [ ] 用新组件重构 CustomerList.vue
- [ ] 用新组件重构 PartList.vue
- [ ] 用新组件重构所有其他列表页（批量）

### Phase 4：FSM业务组件（3天）
- [ ] PhotoCompare.vue
- [ ] SignatureCapture.vue
- [ ] EngineerPicker.vue
- [ ] PartPicker.vue
- [ ] StockAlertBadge.vue
- [ ] WorkOrderStatusFlow.vue
- [ ] ServiceTimePicker.vue
- [ ] CostEstimator.vue

### Phase 5：财务专用组件（1天）
- [ ] ApprovalPanel.vue
- [ ] VoucherPrint.vue
- [ ] PaymentQRCode.vue
- [ ] SubjectPicker.vue

### Phase 6：通用框架（1天）
- [ ] AddressPicker.vue
- [ ] OrgTree.vue
- [ ] PrintTemplate.vue
- [ ] OperationLog（表+切面+API）
- [ ] NotificationCenter（表+API+Bell组件）

---

## 九、验收标准

每个组件必须满足：

1. **Props TS类型完整** — 所有 props 有 TypeScript 类型声明
2. **Element Plus 原生集成** — 使用 Element Plus 组件，不重复造轮子
3. **响应式** — 1366px 以上分辨率正常显示
4. **Loading 状态** — 所有异步操作有 loading 状态
5. **Error 处理** — 网络错误/异常数据有友好提示
6. **无 any 类型** — props/events/slots 全部显式声明
7. **单元测试** — 核心逻辑有 Jest/Vitest 测试用例
8. **文档注释** — 每个组件有 JSDoc 注释

---

*本文档为星海ERP组件库规范，所有新增页面必须使用本规范中的组件。*
