/**
 * 通用Composes统一导出
 * 
 * 用法：
 * import { usePagination, usePermission, useDictData } from '@/composables'
 */

export {
  usePagination,
  usePaginationWithSearch,
  type UsePaginationOptions,
  type PaginationState
} from './usePagination'

export {
  usePermission,
  authDirective,
  authDisableDirective
} from './usePermission'

export {
  useDictData,
  useMultiDict,
  useDictSelect,
  getDictLabel,
  getDictValue,
  refreshDict,
  clearDictCache,
  getDictColor,
  DICT_COLOR_MAP
} from './useDict'

export {
  useRequest as request,
  getWithRetry,
  requestWithLoading,
  downloadFile,
  batchRequest
} from './useRequest'
