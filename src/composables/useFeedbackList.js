import { ref, reactive, computed } from 'vue'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'
import { QA_FEEDBACK_STATUS, QA_FEEDBACK_TYPE } from '@/constants/maps'

// API base path for QA feedback
const API_BASE = '/qa/feedback'

export function useFeedbackList() {
  // Loading state
  const loading = ref(false)
  const submitLoading = ref(false)

  // Table data
  const tableData = ref([])
  const pagination = reactive({
    page: 1,
    pageSize: 10,
    total: 0
  })

  // Query form
  const queryForm = reactive({
    customerName: '',
    feedbackType: '',
    status: ''
  })
  const dateRange = ref([])

  // Detail dialog
  const detailVisible = ref(false)
  const currentRow = ref(null)

  // Handle dialog
  const handleVisible = ref(false)
  const handleFormRef = ref(null)
  const handleForm = reactive({
    status: '',
    handlerId: '',
    remark: ''
  })
  const handleRules = {
    status: [{ required: true, message: '请选择处理状态', trigger: 'change' }],
    handlerId: [{ required: true, message: '请选择处理人', trigger: 'change' }]
  }

  // Employee list for handler selection
  const employeeList = ref([])

  // Computed getters using constants
  const getStatusType = (status) => {
    const found = QA_FEEDBACK_STATUS[status]
    return found?.type || 'info'
  }

  const getStatusText = (status) => {
    const found = QA_FEEDBACK_STATUS[status]
    return found?.label || '未知'
  }

  const getFeedbackTypeTag = (type) => {
    const found = QA_FEEDBACK_TYPE[type]
    return found?.type || 'info'
  }

  const getFeedbackTypeText = (type) => {
    const found = QA_FEEDBACK_TYPE[type]
    return found?.label || '未知'
  }

  // Build query params
  const buildQueryParams = () => ({
    page: pagination.page,
    pageSize: pagination.pageSize,
    customerName: queryForm.customerName,
    feedbackType: queryForm.feedbackType,
    status: queryForm.status,
    startDate: dateRange.value?.[0] || '',
    endDate: dateRange.value?.[1] || ''
  })

  // Load feedback list
  const loadData = async () => {
    loading.value = true
    try {
      const res = await request.get(API_BASE, { params: buildQueryParams() })
      tableData.value = res.data?.list || []
      pagination.total = res.data?.total || 0
    } catch (e) {
      ElMessage.error('加载数据失败')
    } finally {
      loading.value = false
    }
  }

  // Search
  const handleSearch = () => {
    pagination.page = 1
    loadData()
  }

  // Reset
  const handleReset = () => {
    queryForm.customerName = ''
    queryForm.feedbackType = ''
    queryForm.status = ''
    dateRange.value = []
    pagination.page = 1
    loadData()
  }

  // Pagination handlers
  const handleSizeChange = (size) => {
    pagination.pageSize = size
    pagination.page = 1
    loadData()
  }

  const handleCurrentChange = () => {
    loadData()
  }

  // Open detail dialog
  const openDetail = async (row) => {
    currentRow.value = { ...row, records: [] }
    detailVisible.value = true
    try {
      const res = await request.get(`${API_BASE}/${row.id}`)
      if (res.data) {
        currentRow.value = { ...currentRow.value, ...res.data }
      }
    } catch (e) {
      // Use local data on error
    }
  }

  // Open handle dialog
  const openHandle = async (row) => {
    currentRow.value = row
    handleForm.status = String(row.status)
    handleForm.handlerId = ''
    handleForm.remark = ''
    handleVisible.value = true

    // Load employee list if not cached
    if (!employeeList.value.length) {
      try {
        const res = await request.get('/hr/employees')
        employeeList.value = res.data?.list || res.data || []
      } catch (e) {
        employeeList.value = []
      }
    }
  }

  // Submit handle form
  const submitHandle = async () => {
    const valid = await handleFormRef.value?.validate().catch(() => false)
    if (!valid) return

    submitLoading.value = true
    try {
      await request.put(`${API_BASE}/${currentRow.value.id}`, {
        status: Number(handleForm.status),
        handlerId: handleForm.handlerId,
        remark: handleForm.remark
      })
      ElMessage.success('处理成功')
      handleVisible.value = false
      loadData()
    } catch (e) {
      ElMessage.error('处理失败')
    } finally {
      submitLoading.value = false
    }
  }

  return {
    // State
    loading,
    submitLoading,
    tableData,
    pagination,
    queryForm,
    dateRange,
    detailVisible,
    currentRow,
    handleVisible,
    handleFormRef,
    handleForm,
    handleRules,
    employeeList,

    // Methods
    getStatusType,
    getStatusText,
    getFeedbackTypeTag,
    getFeedbackTypeText,
    loadData,
    handleSearch,
    handleReset,
    handleSizeChange,
    handleCurrentChange,
    openDetail,
    openHandle,
    submitHandle
  }
}
