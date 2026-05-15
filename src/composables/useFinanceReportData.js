import { ref, computed, watch } from 'vue'
import request from '@/utils/request'

export function useFinanceReportData(filters) {
  const loading = ref(false)
  const stats = ref([])
  const tableData = ref([])
  const revenueChartData = ref([])
  const costChartData = ref([])

  // Default filter values
  const defaultFilters = ref({
    dateRange: [],
    type: 'all'
  })

  const activeFilters = computed(() => ({
    ...defaultFilters.value,
    ...filters.value
  }))

  async function fetchData() {
    loading.value = true
    try {
      const [statsRes, tableRes] = await Promise.all([
        request.get('/finance/report/stats', { params: activeFilters.value }),
        request.get('/finance/report/list', { params: activeFilters.value }),
      ])
      stats.value = statsRes.data || []
      tableData.value = tableRes.data || []
      revenueChartData.value = { xAxis: [], series: [] }
      costChartData.value = []
    } catch (error) {
      console.error('Failed to fetch finance report data:', error)
    } finally {
      loading.value = false
    }
  }

  async function loadMockData() {
    loading.value = true
    try {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 300))
      
      stats.value = [
        { title: '本月收入', value: '¥128,000', color: '#67C23A' },
        { title: '本月支出', value: '¥86,000', color: '#F56C6C' },
        { title: '本月利润', value: '¥42,000', color: '#409EFF' },
        { title: '同比增长', value: '+15.8%', color: '#E6A23C' }
      ]

      tableData.value = [
        { date: '2026-01-08', type: 'income', typeText: '收入', item: '维修服务费', amount: '5,000.00', remark: '工单WO20260108001' },
        { date: '2026-01-08', type: 'expense', typeText: '支出', item: '配件采购', amount: '2,000.00', remark: '压缩机采购' },
        { date: '2026-01-07', type: 'income', typeText: '收入', item: '安装服务费', amount: '3,500.00', remark: '工单WO20260107001' },
        { date: '2026-01-07', type: 'expense', typeText: '支出', item: '员工工资', amount: '15,000.00', remark: '12月工资' }
      ]

      revenueChartData.value = {
        xAxis: ['1月', '2月', '3月', '4月', '5月', '6月'],
        series: [105000, 98000, 115000, 128000, 135000, 128000]
      }

      costChartData.value = [
        { value: 35000, name: '人工成本' },
        { value: 20000, name: '配件成本' },
        { value: 15000, name: '运营成本' },
        { value: 16000, name: '其他成本' }
      ]
    } finally {
      loading.value = false
    }
  }

  // Watch for filter changes and refetch
  if (filters) {
    watch(
      () => filters.value,
      () => fetchData(),
      { deep: true }
    )
  }

  return {
    loading,
    stats,
    tableData,
    revenueChartData,
    costChartData,
    fetchData,
    loadMockData
  }
}
