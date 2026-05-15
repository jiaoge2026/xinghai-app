#!/usr/bin/env python3
"""Fix #header___seq__ slot in all files: add 序号 label, inline ColumnSettings."""

import re

FILES = [
    'src/views/system/RoleList.vue',
    'src/views/system/ConfigList.vue',
    'src/views/wms/StockList.vue',
    'src/views/wms/PartList.vue',
    'src/views/hr/EmployeeList.vue',
    'src/views/hr/SalaryList.vue',
    'src/views/hr/DepartmentList.vue',
    'src/views/finance/VoucherList.vue',
    'src/views/finance/PaymentList.vue',
    'src/views/finance/ReceiptList.vue',
    'src/views/finance/SubjectList.vue',
    'src/views/finance/BankAccountList.vue',
    'src/views/logistics/DriverList.vue',
    'src/views/logistics/DeliveryOrderList.vue',
    'src/views/sales/ProjectOrders.vue',
    'src/views/sales/Quotes.vue',
    'src/views/sales/Customers.vue',
    'src/views/fsm/WorkOrderList.vue',
]

# Map filepath -> page-path for ColumnSettings
PATH_MAP = {
    'src/views/system/RoleList.vue': '/system/roles',
    'src/views/system/ConfigList.vue': '/system/configs',
    'src/views/wms/StockList.vue': '/wms/stock',
    'src/views/wms/PartList.vue': '/wms/parts',
    'src/views/hr/EmployeeList.vue': '/hr/employees',
    'src/views/hr/SalaryList.vue': '/hr/salaries',
    'src/views/hr/DepartmentList.vue': '/hr/departments',
    'src/views/finance/VoucherList.vue': '/finance/vouchers',
    'src/views/finance/PaymentList.vue': '/finance/payments',
    'src/views/finance/ReceiptList.vue': '/finance/receipts',
    'src/views/finance/SubjectList.vue': '/finance/subjects',
    'src/views/finance/BankAccountList.vue': '/finance/bank-accounts',
    'src/views/logistics/DriverList.vue': '/logistics/drivers',
    'src/views/logistics/DeliveryOrderList.vue': '/logistics/delivery-orders',
    'src/views/sales/ProjectOrders.vue': '/sales/project-orders',
    'src/views/sales/Quotes.vue': '/sales/quotes',
    'src/views/sales/Customers.vue': '/sales/customers',
    'src/views/fsm/WorkOrderList.vue': '/fsm/work-orders',
}

for filepath in FILES:
    with open(filepath) as f: c = f.read()
    orig = c

    page_path = PATH_MAP.get(filepath, '')

    # Pattern to match the entire #header___seq__ slot
    old_pattern = r'<template #header___seq__>\s*<div class="table-header-bar">\s*<ColumnSettings\b[^>]*>.*?</div>\s*</template>'
    new_slot = f'''<template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="tableColumns"
            page-path="{page_path}"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>'''

    c = re.sub(old_pattern, new_slot, c, flags=re.DOTALL)

    if c != orig:
        with open(filepath, 'w') as f: f.write(c)
        print(f"FIXED: {filepath}")
    else:
        print(f"SAME:  {filepath}")

print("\nDone")
