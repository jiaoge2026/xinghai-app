import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'

// ─── Constants ────────────────────────────────────────────────────────────────
export const INSPECTION_TYPE = { PATROL: 1, SAMPLE: 2, FULL: 3 }
export const INSPECTION_TYPE_LABEL = { [INSPECTION_TYPE.PATROL]: '巡检', [INSPECTION_TYPE.SAMPLE]: '抽检', [INSPECTION_TYPE.FULL]: '全检' }
export const RESULT_PASS = 1
export const RESULT_FAIL = 2
export const RESULT_LABEL = { [RESULT_PASS]: '合格', [RESULT_FAIL]: '不合格' }

// ─── Composable ───────────────────────────────────────────────────────────────
export function useInspectionList() {
  // ── State ──────────────────────────────────────────────────────────────────
  const loading = ref(false)
  const submitting = ref(false)
  const tableData = ref([])
  const total = ref(0)

  const query = reactive({ page: 1, pageSize: 20, inspectionNo: '', type: null, result: null })

  const formRef = ref()
  const isEdit = ref(false)
  const form = reactive({
    id: null,
    type: INSPECTION_TYPE.PATROL,
    itemName: '',
    quantity: 1,
    result: RESULT_PASS,
    defectCount: 0,
    defectDesc: '',
    inspectionDate: '',
    remark: ''
  })

  const viewData = ref({})
  const dialogVisible = ref(false)
  const viewVisible = ref(false)
  const dialogTitle = computed(() => isEdit.value ? '编辑质检' : '新建质检')

  const rules = {
    type: [{ required: true, message: '请选择质检类型', trigger: 'change' }],
    itemName: [{ required: true, message: '请输入检品名称', trigger: 'blur' }],
    quantity: [{ required: true, message: '请输入数量', trigger: 'blur' }],
    result: [{ required: true, message: '请选择结果', trigger: 'change' }]
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  function getDefaultForm() {
    return {
      id: null,
      type: INSPECTION_TYPE.PATROL,
      itemName: '',
      quantity: 1,
      result: RESULT_PASS,
      defectCount: 0,
      defectDesc: '',
      inspectionDate: '',
      remark: ''
    }
  }

  function resetForm() {
    Object.assign(form, getDefaultForm())
    formRef.value?.clearValidate()
  }

  // ── Data fetching ───────────────────────────────────────────────────────────
  async function fetchData() {
    loading.value = true
    try {
      const res = await request.get('/qa/inspections', { params: query })
      // Response interceptor already unwraps { code, data }. res is { data: { list, total } }
      tableData.value = res.data?.list ?? []
      total.value = res.data?.total ?? 0
    } catch (err) {
      console.error('[useInspectionList] fetchData failed:', err)
      tableData.value = []
      total.value = 0
    } finally {
      loading.value = false
    }
  }

  function resetQuery() {
    Object.assign(query, { inspectionNo: '', type: null, result: null, page: 1 })
    fetchData()
  }

  // ── Dialog actions ─────────────────────────────────────────────────────────
  function handleAdd() {
    isEdit.value = false
    resetForm()
    dialogVisible.value = true
  }

  function handleEdit(row) {
    isEdit.value = true
    Object.assign(form, { ...row })
    dialogVisible.value = true
  }

  function handleView(row) {
    viewData.value = { ...row }
    viewVisible.value = true
  }

  async function handleDelete(row) {
    try {
      await request.delete(`/qa/inspections/${row.id}`)
      ElMessage.success('删除成功')
      fetchData()
    } catch (err) {
      console.error('[useInspectionList] handleDelete failed:', err)
    }
  }

  async function handleSubmit() {
    const valid = await formRef.value?.validate().catch(() => false)
    if (!valid) return

    submitting.value = true
    try {
      if (isEdit.value) {
        await request.put(`/qa/inspections/${form.id}`, form)
        ElMessage.success('编辑成功')
      } else {
        await request.post('/qa/inspections', form)
        ElMessage.success('新建成功')
      }
      dialogVisible.value = false
      fetchData()
    } catch (err) {
      console.error('[useInspectionList] handleSubmit failed:', err)
    } finally {
      submitting.value = false
    }
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  function handleSizeChange() { query.page = 1; fetchData() }
  function handleCurrentChange() { fetchData() }

  onMounted(fetchData)

  return {
    // State
    loading, submitting, tableData, total, query,
    formRef, form, rules, dialogVisible, viewVisible, viewData, dialogTitle,
    // Helpers
    resetForm,
    // Actions
    fetchData, resetQuery, handleAdd, handleEdit, handleView, handleDelete, handleSubmit,
    handleSizeChange, handleCurrentChange
  }
}
