<template>
  <div class="work-order-create">
    <el-card>
      <template #header><span>新建工单</span></template>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="120px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="工单标题" prop="title">
              <el-input v-model="form.title" placeholder="请输入工单标题" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="客户名称" prop="customerName">
              <el-input v-model="form.customerName" placeholder="请输入客户名称" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="联系电话" prop="customerPhone">
              <el-input v-model="form.customerPhone" placeholder="请输入联系电话" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="服务地址" prop="address">
              <el-input v-model="form.address" placeholder="请输入服务地址" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="服务类型" prop="serviceType">
              <el-select v-model="form.serviceType" placeholder="请选择服务类型" style="width: 100%">
                <el-option label="维修" value="repair" />
                <el-option label="安装" value="install" />
                <el-option label="保养" value="maintain" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="预约时间" prop="appointmentTime">
              <el-date-picker v-model="form.appointmentTime" type="datetime" placeholder="选择预约时间" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="工单描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="4" placeholder="请输入工单描述" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSubmit">提交</el-button>
          <el-button @click="$router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

const router = useRouter()
const formRef = ref()

const form = reactive({
  title: '',
  customerName: '',
  customerPhone: '',
  address: '',
  serviceType: '',
  appointmentTime: '',
  description: ''
})

const rules = {
  title: [{ required: true, message: '请输入工单标题', trigger: 'blur' }],
  customerName: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
  customerPhone: [{ required: true, message: '请输入联系电话', trigger: 'blur' }],
  serviceType: [{ required: true, message: '请选择服务类型', trigger: 'change' }]
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  ElMessage.success('提交成功')
  router.push('/fsm/work-orders')
}
</script>