/**
 * 列配置公共函数 — 框架级基础能力
 * 
 * 使用方式（在列表页面 onMounted 中调用）：
 * 
 * import { useColumnConfig } from '@/utils/useColumnConfig'
 * 
 * const localColumns = ref([...TABLE_COLUMNS])
 * const { reload } = useColumnConfig('/fsm/work-orders', localColumns)
 * 
 * // ColumnSettings 保存后重新加载
 * @change="reload"
 */

// 保存列配置到服务器
export async function saveColumnConfigs(pagePath, columns) {
  const token = localStorage.getItem('token')
  const data = columns.map((col, idx) => ({
    columnKey: col.prop,
    visible: col.visible ? 1 : 0,
    sortOrder: idx + 1,
    fixed: col.fixed ? 1 : 0
  }))
  await fetch(`/api/v1/system/column-configs?pagePath=${encodeURIComponent(pagePath)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    body: JSON.stringify(data)
  })
}

/**
 * 从服务器加载列配置，用返回数据覆盖 localColumns
 * @param {string} pagePath  页面路径，如 '/fsm/work-orders'
 * @param {Ref} localColumns  列表页面的 localColumns ref
 * @returns {{ reload: () => Promise<void> }} 返回 reload 函数，ColumnSettings 保存后调用它
 */
export function useColumnConfig(pagePath, localColumns) {
  async function reload() {
    const token = localStorage.getItem('token')
    try {
      const res = await fetch(
        `/api/v1/system/column-configs?pagePath=${encodeURIComponent(pagePath)}`,
        { headers: { 'Authorization': 'Bearer ' + token } }
      )
      if (!res.ok) return
      const json = await res.json()
      const saved = json.data || []
      if (saved.length === 0) return

      const map = {}
      saved.forEach(s => { map[s.columnKey] = s })

      localColumns.value = localColumns.value.map(col => {
        const s = map[col.prop]
        if (!s) return col
        return {
          ...col,
          visible: s.visible === 1,
          sortOrder: s.sortOrder
        }
      })

      // 按 sortOrder 排序
      localColumns.value.sort((a, b) => (a.sortOrder || 999) - (b.sortOrder || 999))
    } catch (e) {
      console.error('[useColumnConfig] load failed', e)
    }
  }

  // 立即执行一次加载
  reload()

  return { reload }
}
