#!/usr/bin/env python3
"""Batch apply seq column + ColumnSettings + remove PageHeader + buttons to table-panel to all list pages."""

import re
import sys

FILES = [
    'src/views/system/UserList.vue',
    'src/views/system/RoleList.vue',
    'src/views/system/ConfigList.vue',
    'src/views/wms/StockList.vue',
    'src/views/wms/PartList.vue',
    'src/views/hr/SalaryList.vue',
    'src/views/hr/EmployeeList.vue',
    'src/views/hr/DepartmentList.vue',
    'src/views/finance/VoucherList.vue',
    'src/views/finance/PaymentList.vue',
    'src/views/finance/ReceiptList.vue',
    'src/views/finance/SubjectList.vue',
    'src/views/finance/BankAccountList.vue',
    'src/views/logistics/DeliveryOrderList.vue',
    'src/views/logistics/DriverList.vue',
    'src/views/sales/ProjectOrders.vue',
    'src/views/sales/Quotes.vue',
    'src/views/sales/Customers.vue',
]

BASE = '/home/admin/xinghai-web'

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    changes = []

    # ── 1. Remove PageHeader import from '@/components/page-components' ──
    # Pattern: import { ..., PageHeader, ... } from '@/components/page-components'
    # Remove PageHeader from the import list
    def remove_pageheader_import(m):
        inner = m.group(1)
        parts = [p.strip() for p in inner.split(',')]
        parts = [p for p in parts if p and p != 'PageHeader']
        if not parts:
            return ''  # remove entire import line
        return f"import {{{', '.join(parts)}}} from '@/components/page-components'"

    new_content = re.sub(
        r"import\s+\{([^}]+)\}\s+from\s+'@/components/page-components'",
        remove_pageheader_import,
        content
    )
    if new_content != content:
        changes.append('remove PageHeader import')
        content = new_content

    # Also check for standalone import: import PageHeader from '...'
    if "import PageHeader from" in content:
        content = re.sub(r"\n?import\s+PageHeader\s+from\s+'[^']+';?", '', content)
        changes.append('remove standalone PageHeader import')

    # ── 2. Remove <PageHeader> block ──
    # Match <PageHeader title="..."> ... </PageHeader>
    # Handle both self-closing and with #actions slot
    new_content = re.sub(
        r'\s*<PageHeader\s+title="([^"]+)"[^>]*>.*?</PageHeader>',
        '',
        content,
        flags=re.DOTALL
    )
    if new_content != content:
        changes.append('remove PageHeader block')
        content = new_content

    # ── 3. Find the .panel that wraps DataTable and extract its class/position ──
    # We need to add table-panel class + toolbar inside that panel
    # Pattern: <div class="panel"> ... <DataTable ...> </DataTable> </div>

    # ── 4. Add :show-index="false" to DataTable ──
    # Handle both :show-index="true" and no show-index attr
    # First, remove existing :show-index="true" or :show-index="false"
    if ':show-index=' in content:
        content = re.sub(r'\s*:show-index="[^"]*"', '', content)
        changes.append('remove existing show-index')

    # Add :show-index="false" to DataTable tag (after row-key if exists, or after DataTable)
    # Try to insert after row-key="..." attribute
    def add_show_index(m):
        tag = m.group(0)
        # Remove trailing > or /> to insert attribute
        tag_body = tag.rstrip()
        if tag_body.endswith('/>'):
            return tag_body[:-2] + ' :show-index="false" />'
        elif tag_body.endswith('>'):
            return tag_body[:-1] + ' :show-index="false">'
        return tag + ' :show-index="false"'

    content = re.sub(
        r'<DataTable\b(?!.*:show-index=)([^>]*?)(?=>)',
        add_show_index,
        content,
        flags=re.DOTALL
    )
    # If there's already :show-index, our earlier substitution already removed it
    # Now re-add by finding DataTable without show-index
    # Actually, the above regex won't match if we already stripped it, let's be more careful

    # Find DataTable and ensure it has :show-index="false"
    if '<DataTable' in content and ':show-index="false"' not in content:
        # Insert after <DataTable
        content = re.sub(
            r'(<DataTable\b)',
            r'\1\n        :show-index="false"',
            content,
            count=1
        )
        changes.append('add :show-index="false" to DataTable')

    # ── 5. Add ColumnSettings import ──
    if "import ColumnSettings from" not in content and "ColumnSettings" not in content.split("from '@/components/page-components'")[0] if "from '@/components/page-components'" in content else True:
        # Need to add ColumnSettings import
        # Check if there's already a separate import for ColumnSettings
        has_col_settings_import = bool(re.search(r"import\s+ColumnSettings\s+from", content))
        if not has_col_settings_import:
            # Add after the @/components/page-components import line
            content = re.sub(
                r"(import\s+\{[^}]+\}\s+from\s+'@/components/page-components')",
                r"\1\nimport ColumnSettings from '@/views/components/ColumnSettings.vue'",
                content
            )
            changes.append('add ColumnSettings import')

    # ── 6. Add ColumnSettings slot inside DataTable ──
    # Find the closing </DataTable> tag and add slot before it
    # Slot: <template #header___seq__><div class="table-header-bar"><ColumnSettings .../></div></template>
    # We need to know the page-path for each file
    page_path_map = {
        'UserList.vue': '/system/users',
        'RoleList.vue': '/system/roles',
        'ConfigList.vue': '/system/configs',
        'StockList.vue': '/wms/stocks',
        'PartList.vue': '/wms/parts',
        'SalaryList.vue': '/hr/salary',
        'EmployeeList.vue': '/hr/employees',
        'DepartmentList.vue': '/hr/departments',
        'VoucherList.vue': '/finance/vouchers',
        'PaymentList.vue': '/finance/payments',
        'ReceiptList.vue': '/finance/receipts',
        'SubjectList.vue': '/finance/subjects',
        'BankAccountList.vue': '/finance/bank-accounts',
        'DeliveryOrderList.vue': '/logistics/delivery-orders',
        'DriverList.vue': '/logistics/drivers',
        'ProjectOrders.vue': '/sales/project-orders',
        'Quotes.vue': '/sales/quotes',
        'Customers.vue': '/sales/customers',
    }
    filename = filepath.split('/')[-1]
    page_path = page_path_map.get(filename, '/' + filename.replace('.vue', '').lower())

    col_settings_slot = f'''
        <template #header___seq__>
          <div class="table-header-bar">
            <ColumnSettings
              :columns="mergedColumns"
              page-path="{page_path}"
              @change="onColumnConfigChange"
            >
              <template #trigger>
                <el-icon class="seq-settings-btn"><Setting /></el-icon>
              </template>
            </ColumnSettings>
          </div>
        </template>'''

    if '#header___seq__' not in content and 'ColumnSettings' in content:
        # Insert before </DataTable>
        content = content.replace('</DataTable>', col_settings_slot + '\n      </DataTable>')
        changes.append('add ColumnSettings #header___seq__ slot')

    # ── 7. Add __seq__ as first entry in TABLE_COLUMNS ──
    # Find TABLE_COLUMNS array and add __seq__ as first item
    seq_entry = "{ key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' }"

    # Check if __seq__ already exists
    if '__seq__' not in content:
        # Find first entry in TABLE_COLUMNS and prepend
        # Pattern: const TABLE_COLUMNS = [ ... { key: 'firstKey', ...
        content = re.sub(
            r'(const TABLE_COLUMNS\s*=\s*\[)',
            r'\1\n  ' + seq_entry + ',\n  ',
            content,
            count=1
        )
        changes.append('add __seq__ as first TABLE_COLUMNS entry')
    else:
        changes.append('(skip: __seq__ already exists)')

    # ── 8. Add onColumnConfigChange + mergedColumns if not exists ──
    if 'onColumnConfigChange' not in content:
        # Add after handleSizeChange function
        # Find the function and add after it
        content = re.sub(
            r'(const\s+handleSizeChange\s*=\s*\([^)]*\)\s*=>\s*\{[^}]+\})',
            r'\1\n\n  const onColumnConfigChange = (cols) => {\n    tableColumns.value = cols\n  }',
            content
        )
        changes.append('add onColumnConfigChange')

    if 'mergedColumns' not in content:
        # Add computed mergedColumns
        content = re.sub(
            r'(const\s+onColumnConfigChange\s*=\s*\([^)]*\)\s*=>\s*\{[^}]+\})',
            r'\1\n\n  const mergedColumns = computed(() => tableColumns.value)',
            content
        )
        changes.append('add mergedColumns computed')

    # ── 9. Add CSS for .table-panel and .table-toolbar ──
    if '.table-panel' not in content and '.table-toolbar' not in content:
        css_append = '''
/* seq column toolbar */
.table-panel {
  position: relative;
  padding-top: 48px;
}
.table-toolbar {
  position: absolute;
  top: 10px;
  right: 16px;
  display: flex;
  gap: 8px;
  align-items: center;
  z-index: 5;
}
.table-header-bar {
  display: flex;
  align-items: center;
  justify-content: center;
}
.seq-settings-btn {
  cursor: pointer;
  color: #909399;
  transition: color 0.2s;
}
.seq-settings-btn:hover {
  color: #409eff;
}
'''
        # Insert before </style> or at end
        if '</style>' in content:
            content = content.replace('</style>', css_append + '\n</style>')
        else:
            content += css_append
        changes.append('add CSS .table-panel/.table-toolbar')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    return changes

for f in FILES:
    path = f'{BASE}/{f}'
    try:
        changes = process_file(path)
        print(f'✅ {f}: {", ".join(changes) if changes else "no changes"}')
    except Exception as e:
        print(f'❌ {f}: {e}')
