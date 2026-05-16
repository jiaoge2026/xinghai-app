/**
 * 字典Hook — 对标JeecgBoot的JDictSelectTag + DictDataService
 * 
 * JeecgBoot: src/utils/dict/index.ts
 * 
 * 功能：
 * 1. 批量获取字典数据（带本地缓存）
 * 2. 自动根据dictCode调API
 * 3. 返回 { label, value } 格式供 el-select/el-tag 使用
 */

import { ref, reactive } from 'vue'
import request from '@/utils/request'

// 字典缓存（模块级）
const dictCache: Record<string, any[]> = reactive({})
const dictLoading: Record<string, boolean> = reactive({})
const dictMetaCache: Record<string, { label: string; value: string; color?: string }> = {}

/**
 * 获取单个字典的数据
 * @param dictCode 字典编码
 * @param forceRefresh 是否强制从服务器刷新
 */
export async function useDictData(dictCode: string, forceRefresh = false) {
  // 命中缓存且非强制刷新
  if (!forceRefresh && dictCache[dictCode]) {
    return dictCache[dictCode]
  }

  // 防止重复请求
  if (dictLoading[dictCode]) {
    // 等待已有请求完成
    await new Promise(resolve => {
      const timer = setInterval(() => {
        if (!dictLoading[dictCode]) {
          clearInterval(timer)
          resolve(true)
        }
      }, 50)
    })
    return dictCache[dictCode] || []
  }

  dictLoading[dictCode] = true
  try {
    const res = await request.get(`/system/dict/items/${dictCode}`)
    if (res.code === 0 || res.code === 200) {
      dictCache[dictCode] = res.result || []
    } else {
      console.warn(`[useDict] failed to load dict: ${dictCode}`, res.message)
      dictCache[dictCode] = []
    }
  } catch (err) {
    console.error(`[useDict] request error for dict: ${dictCode}`, err)
    dictCache[dictCode] = []
  } finally {
    dictLoading[dictCode] = false
  }

  return dictCache[dictCode]
}

/**
 * 批量获取字典（一次调多个）
 * @param dictCodes 字典编码数组
 */
export async function useMultiDict(dictCodes: string[]) {
  await Promise.all(dictCodes.map(code => useDictData(code)))
}

/**
 * 根据 value 查找 label
 * @param dictCode 字典编码
 * @param value 存储值
 * @param fieldLabel  label字段名（默认item_text）
 * @param fieldValue value字段名（默认item_value）
 */
export function getDictLabel(
  dictCode: string,
  value: any,
  fieldLabel = 'item_text',
  fieldValue = 'item_value'
): string {
  const data = dictCache[dictCode]
  if (!data || value === null || value === undefined) return String(value ?? '')
  const item = data.find((d: any) => String(d[fieldValue]) === String(value))
  return item ? item[fieldLabel] : String(value)
}

/**
 * 根据 label 查找 value
 */
export function getDictValue(
  dictCode: string,
  label: string,
  fieldLabel = 'item_text',
  fieldValue = 'item_value'
): string {
  const data = dictCache[dictCode]
  if (!data) return ''
  const item = data.find((d: any) => d[fieldLabel] === label)
  return item ? String(item[fieldValue]) : ''
}

/**
 * DictSelect 组件（el-select的字典封装）
 * 
 * 用法：
 * <el-select v-model="form.status">
 *   <DictSelect dict-code="work_order_status" v-model="form.status" />
 * </el-select>
 * 
 * 或直接用：
 * const { options } = useDictData('work_order_status')
 * <el-select :options="options" v-model="form.status" />
 */
export function useDictSelect(dictCode: string) {
  const options = ref<{ label: string; value: any }[]>([])
  const loading = ref(false)

  const load = async () => {
    loading.value = true
    try {
      const data = await useDictData(dictCode)
      options.value = data.map((item: any) => ({
        label: item.item_text,
        value: item.item_value,
        raw: item
      }))
    } finally {
      loading.value = false
    }
  }

  load()

  return { options, loading, reload: () => load() }
}

/**
 * 刷新字典缓存
 * @param dictCode 字典编码，不传则刷新所有
 */
export async function refreshDict(dictCode?: string) {
  if (dictCode) {
    delete dictCache[dictCode]
    await useDictData(dictCode, true)
  } else {
    // 刷新所有
    Object.keys(dictCache).forEach(key => delete dictCache[key])
  }
}

/**
 * 清除所有字典缓存
 */
export function clearDictCache() {
  Object.keys(dictCache).forEach(key => delete dictCache[key])
}

// 颜色映射（用于DictTag）
export const DICT_COLOR_MAP: Record<string, string> = {
  // 通用状态
  '0': 'info',
  '1': 'success',
  '2': 'warning',
  '3': 'danger',
  // 工单状态（示例）
  pending:   'info',
  assigned:  'primary',
  processing:'warning',
  completed: 'success',
  cancelled: 'danger',
}

export function getDictColor(dictCode: string, value: any): string {
  return DICT_COLOR_MAP[value] || 'info'
}
