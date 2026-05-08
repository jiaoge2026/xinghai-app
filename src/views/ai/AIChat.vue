<template>
  <div class="ai-chat-container">
    <div class="chat-header">
      <el-icon><ChatDotRound /></el-icon>
      <span>AI助手</span>
      <div class="header-right">
        <el-button size="small" plain @click="newChat" style="margin-right:8px">
          <el-icon><Plus /></el-icon> 新建对话
        </el-button>
        <el-select v-model="currentRoleCode" size="small" placeholder="选择助手" style="width:140px" @change="onRoleChange">
          <el-option v-for="r in roles" :key="r.roleCode" :label="r.roleName" :value="r.roleCode" />
        </el-select>
      </div>
    </div>

    <!-- 消息列表 -->
    <div class="chat-messages" ref="messagesRef">
      <div
        v-for="(msg, index) in messages"
        :key="index"
        class="message-item"
        :class="msg.role"
      >
        <div class="message-avatar">
          <el-icon v-if="msg.role === 'user'"><UserFilled /></el-icon>
          <el-icon v-else><Service /></el-icon>
        </div>
        <div class="message-content">
          <div class="message-bubble" v-if="msg.content" v-html="formatContent(msg.content)"></div>
          <div class="message-bubble loading" v-else>
            <span class="loading-dot"></span>
            <span class="loading-dot"></span>
            <span class="loading-dot"></span>
          </div>
          <div class="message-time">{{ msg.time }}</div>
        </div>
      </div>
    </div>

    <!-- 输入区 -->
    <div class="chat-input-area">
      <el-input
        v-model="inputText"
        type="textarea"
        :rows="2"
        placeholder="输入您的问题，AI助手将为您解答... (Ctrl+Enter发送)"
        resize="none"
        @keydown.ctrl.enter.prevent="sendMessage"
        @keydown.meta.enter.prevent="sendMessage"
      />
      <div class="input-actions">
        <span class="hint">Ctrl+Enter 发送</span>
        <el-button type="primary" :loading="sending" @click="sendMessage" :disabled="!inputText.trim()">
          发送
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted } from 'vue'
import { ChatDotRound, UserFilled, Service, Plus } from '@element-plus/icons-vue'

const messagesRef = ref(null)
const inputText = ref('')
const sending = ref(false)
const sessionId = ref('')
const currentRoleCode = ref('FSM_ASSISTANT')
const roles = ref([])

const messages = ref([
  {
    role: 'assistant',
    content: '您好！我是星海ERP的AI助手，可以帮您解答系统使用、业务流程、数据分析等问题。有什么可以帮您的？',
    time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  }
])

const scrollToBottom = () => {
  nextTick(() => {
    if (messagesRef.value) {
      messagesRef.value.scrollTop = messagesRef.value.scrollHeight
    }
  })
}

const formatContent = (content) => {
  // 简单格式化：换行
  return content.replace(/\n/g, '<br/>').replace(/\"/g, '"')
}

const loadRoles = async () => {
  try {
    const res = await fetch('/api/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'admin', password: 'admin123' })
    })
    const login = await res.json()
    const token = login.data?.token
    if (!token) return

    const r = await fetch('/api/ai/roles', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
    const data = await r.json()
    if (data.code === 0 && data.data?.length > 0) {
      roles.value = data.data
      currentRoleCode.value = data.data[0].roleCode
    }
  } catch (e) {
    console.error('Failed to load AI roles:', e)
  }
}

const sendMessage = async () => {
  const text = inputText.value.trim()
  if (!text || sending.value) return

  const userMsg = {
    role: 'user',
    content: text,
    time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  }
  messages.value.push(userMsg)
  inputText.value = ''
  scrollToBottom()

  const assistantMsg = {
    role: 'assistant',
    content: '',
    time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  }
  messages.value.push(assistantMsg)
  sending.value = true

  try {
    // Get token
    const loginRes = await fetch('/api/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'admin', password: 'admin123' })
    })
    const loginData = await loginRes.json()
    const token = loginData.data?.token
    if (!token) {
      assistantMsg.content = '登录失败，请刷新页面重试'
      return
    }

    const res = await fetch('/api/ai/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        roleCode: currentRoleCode.value,
        query: text,
        sessionId: sessionId.value || undefined
      })
    })
    const data = await res.json()

    if (data.code === 0) {
      assistantMsg.content = data.data?.response || '抱歉，未收到有效回复'
      if (data.data?.sessionId) {
        sessionId.value = data.data.sessionId
      }
    } else {
      assistantMsg.content = `错误：${data.message || '请求失败'}`
    }
  } catch (e) {
    console.error('AI chat error:', e)
    assistantMsg.content = '网络错误，请检查后端服务是否运行'
  } finally {
    sending.value = false
    scrollToBottom()
  }
}

const onRoleChange = () => {
  // 换角色时清空会话
  messages.value = [{
    role: 'assistant',
    content: '已切换助手，开始新对话',
    time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  }]
  sessionId.value = ''
}

const newChat = () => {
  messages.value = [{
    role: 'assistant',
    content: '好的，已开始新的对话！请问有什么可以帮您？',
    time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  }]
  sessionId.value = ''
  inputText.value = ''
}

onMounted(() => {
  loadRoles()
  scrollToBottom()
})
</script>

<style scoped>
.ai-chat-container {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 120px);
  background: #f0f2f5;
  border-radius: 8px;
  overflow: hidden;
}

.chat-header {
  background: linear-gradient(135deg, #409EFF, #337ecc);
  color: white;
  padding: 12px 20px;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 15px;
  font-weight: 600;
}

.header-right {
  margin-left: auto;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.message-item {
  display: flex;
  gap: 10px;
  max-width: 80%;
}

.message-item.user {
  align-self: flex-end;
  flex-direction: row-reverse;
}

.message-item.assistant {
  align-self: flex-start;
}

.message-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.message-item.user .message-avatar {
  background: #409EFF;
  color: white;
}

.message-item.assistant .message-avatar {
  background: #67C23A;
  color: white;
}

.message-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.message-bubble {
  background: white;
  padding: 10px 14px;
  border-radius: 12px;
  line-height: 1.6;
  font-size: 14px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.08);
  word-break: break-word;
}

.message-item.user .message-bubble {
  background: #409EFF;
  color: white;
}

.message-bubble.loading {
  display: flex;
  gap: 4px;
  align-items: center;
  padding: 12px 16px;
  min-width: 60px;
}

.loading-dot {
  width: 8px;
  height: 8px;
  background: #409EFF;
  border-radius: 50%;
  animation: bounce 1.2s infinite;
}

.loading-dot:nth-child(2) { animation-delay: 0.2s; }
.loading-dot:nth-child(3) { animation-delay: 0.4s; }

@keyframes bounce {
  0%, 80%, 100% { transform: scale(0.6); opacity: 0.5; }
  40% { transform: scale(1); opacity: 1; }
}

.message-time {
  font-size: 11px;
  color: #999;
  padding: 0 4px;
}

.message-item.user .message-time {
  text-align: right;
}

.chat-input-area {
  background: white;
  padding: 12px 16px;
  border-top: 1px solid #eee;
}

.input-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}

.hint {
  font-size: 12px;
  color: #999;
}
</style>
