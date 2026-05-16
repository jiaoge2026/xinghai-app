/**
 * 分页Hook — 对标JeecgBoot的usePagination
 * 
 * JeecgBoot: src/components/Table/hooks/usePagination.ts
 * 
 * 用法：
 * const { list, loading, pagination, loadData, reset, changePage, changePageSize } = usePagination(api)
 * 
 * api 签名: (params: object) => Promise<{ code: 0, result: { records: T[], total: number } }>
 */

import { ref, reactive, computed } from 'vue'
import type { Ref } from 'vue'

export interface PaginationState {
  current: number
  pageSize: number
  total: number
}

export interface UsePaginationOptions {
  immediate?: boolean       // 是否在created时立即加载（默认true）
  defaultPageSize?: number // 默认每页条数（默认10）
  onSuccess?: (data: any[]) => void
  onError?: (err: any) => void
}

export function usePagination<T = any>(
  api: (params: object) => Promise<any>,
  options: UsePaginationOptions = {}
) {
  const { immediate = true, defaultPageSize = 10, onSuccess, onError } = options

  const list: Ref<T[]> = ref([]) as any
  const loading = ref(false)
  const pagination = reactive<PaginationState>({
    current: 1,
    pageSize: defaultPageSize,
    total: 0
  })

  // 构造请求参数（自动注入分页）
  const buildParams = (extra = {}) => ({
    ...extra,
    current: pagination.current,
    pageSize: pagination.pageSize
  })

  // 加载数据
  const loadData = async (params = {}) => {
    loading.value = true
    try {
      const res = await api(buildParams(params))
      if (res.code === 0 || res.code === 200) {
        list.value = res.result?.records ?? res.result ?? []
        pagination.total = res.result?.total ?? 0
        onSuccess?.(list.value)
      } else {
        console.error('[usePagination] API error:', res.message)
        onError?.(res)
      }
    } catch (err) {
      console.error('[usePagination] request failed:', err)
      onError?.(err)
    } finally {
      loading.value = false
    }
  }

  // 重置到第一页
  const reset = (params = {}) => {
    pagination.current = 1
    loadData(params)
  }

  // 翻页
  const changePage = (page: number) => {
    pagination.current = page
    loadData()
  }

  // 改变每页条数
  const changePageSize = (size: number) => {
    pagination.pageSize = size
    pagination.current = 1
    loadData()
  }

  // 是否还有更多数据
  const hasMore = computed(() => pagination.current * pagination.pageSize < pagination.total)

  // 总页数
  const totalPages = computed(() => Math.ceil(pagination.total / pagination.pageSize))

  // 立即加载
  if (immediate) {
    loadData()
  }

  return {
    list,
    loading,
    pagination,
    hasMore,
    totalPages,
    loadData,
    reset,
    changePage,
    changePageSize
  }
}

/**
 * 带搜索的分页Hook
 * 自动将 searchForm 里的字段作为查询参数
 */
export function usePaginationWithSearch<T = any>(
  api: (params: object) => Promise<any>,
  searchForm: Record<string, any>,
  options: UsePaginationOptions = {}
) {
  const pagination = usePagination<T>(api, { ...options, immediate: false })

  const search = () => {
    pagination.reset(searchForm)
  }

  const clear = () => {
    Object.keys(searchForm).forEach(key => { searchForm[key] = '' })
    pagination.reset()
  }

  return {
    ...pagination,
    search,
    clear
  }
}
