<template>
  <div class="icon-select">
    <el-input
      v-model="currentValue"
      :placeholder="placeholder"
      readonly
      @click="dialogVisible = true"
    >
      <template #prefix>
        <el-icon v-if="currentIconComponent" style="margin-right:4px">
          <component :is="currentIconComponent" />
        </el-icon>
        <span v-else class="no-icon">无</span>
      </template>
      <template #append>
        <el-button @click.stop="dialogVisible = true">
          <el-icon><MoreFilled /></el-icon>
        </el-button>
      </template>
    </el-input>

    <el-dialog v-model="dialogVisible" title="选择图标" width="720px" destroy-on-close>
      <div class="icon-search">
        <el-input v-model="keyword" placeholder="搜索图标名称" clearable style="width:240px" />
      </div>
      <el-scrollbar height="400px">
        <div v-for="cat in filteredCategories" :key="cat.label" class="icon-category">
          <div class="cat-label">{{ cat.label }}</div>
          <div class="icon-grid">
            <div
              v-for="icon in cat.icons"
              :key="icon"
              class="icon-item"
              :class="{ selected: icon === modelValue }"
              @click="selectIcon(icon)"
              :title="icon"
            >
              <el-icon><component :is="icon" /></el-icon>
              <span class="icon-name">{{ icon }}</span>
            </div>
          </div>
        </div>
        <el-empty v-if="filteredCategories.length === 0" description="未找到图标" />
      </el-scrollbar>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="dialogVisible = false">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { MoreFilled } from '@element-plus/icons-vue'
import * as icons from '@element-plus/icons-vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: { type: String, default: '选择图标' }
})
const emit = defineEmits(['update:modelValue'])

const dialogVisible = ref(false)
const keyword = ref('')
const currentValue = ref(props.modelValue)

const allIconNames = computed(() => Object.keys(icons))

// 静态分类图标（减少动态 import 的包体积）
const iconCategories = [
  {
    label: '方向指示',
    icons: ['Top','Bottom','Back','Right','Plus','Minus','Refresh','RefreshLeft','RefreshRight',
      'ArrowUp','ArrowDown','ArrowLeft','ArrowRight','CaretTop','CaretBottom',
      'CaretLeft','CaretRight','Upload','Download','UploadFilled','DownloadFilled']
  },
  {
    label: '通用操作',
    icons: ['Edit','EditPen','Delete','DeleteFilled','Search','ZoomIn','ZoomOut',
      'View','Hide','Show','Key','Lock','LockFilled','Unlock','Watch','Timer',
      'Help','InfoFilled','WarningFilled','SuccessFilled','CircleCloseFilled',
      'Check','CheckFilled','Close','CloseBold','More','MoreFilled',
      'Setting','Tools','Memo','Position','LocationFilled','Filter','Sort',
      'SortUp','SortDown','Rank','List']
  },
  {
    label: '文件文档',
    icons: ['Document','DocumentAdd','DocumentCopy','DocumentChecked','DocumentDelete',
      'Files','Folder','FolderAdd','FolderOpened','FolderDelete','Tickets',
      'Reading','Notebook','DataAnalysis','Collection','Postcard','OfficeBuilding',
      'FirstAidKit','PriceTag','PriceTags','ShoppingCart','ShoppingCartFull',
      'ShoppingTrolley','Sell','Goods','GoodsFilled','Box','BoxFilled']
  },
  {
    label: '用户通讯',
    icons: ['User','UserFilled','Avatar','AvatarFilled','Users','UserPlus','UserMinus',
      'UserClear','Message','MessageBox','ChatDotRound','ChatLineRound','ChatSquare',
      'ChatLineSquare','ChatRound','Phone','PhoneFilled','Telephone','Bell','BellFilled',
      'Microphone','Call','VideoCamera','VideoCameraFilled','Television','Camera',
      'CameraFilled','Picture','PictureFilled','Service','Headset','Connection',
      'Link','Share','Promotion']
  },
  {
    label: '数据图表',
    icons: ['DataLine','DataBoard','PieChart','Histogram','BarChart','LineChart',
      'TrendCharts','CollectionTag','Grid','Menu','Operation','Compass',
      'MapLocation','Pointer','Aim','Target']
  },
  {
    label: '业务功能',
    icons: ['HomeFilled','House','OfficeBuilding','School','Tourism','Calendar','Clock',
      'Sunrise','Sunset','Moon','Sunny','Cloudy','Lightning','Pouring','HeavyRain',
      'Guide','Promotion','Opera','Music','MusicNote','Wifi','Battery','Plug']
  },
  {
    label: '设备硬件',
    icons: ['Monitor','Keyboard','Mouse','Cpu','Printer','Scanner','Project',
      'Projector','Router','Server','HardDrive','MemoryCard','SDCard','Screen','Cellphone']
  },
  {
    label: '编辑内容',
    icons: ['Brush','MagicStick','Tickets','Bill','CreditCard','Wallet','Coin','Watermelon']
  }
]

const filteredCategories = computed(() => {
  if (!keyword.value) return iconCategories
  const kw = keyword.value.toLowerCase()
  return iconCategories
    .map(cat => ({ ...cat, icons: cat.icons.filter(i => i.toLowerCase().includes(kw)) }))
    .filter(cat => cat.icons.length > 0)
})

const currentIconComponent = computed(() => {
  if (!props.modelValue) return null
  return icons[props.modelValue] || null
})

watch(() => props.modelValue, v => { currentValue.value = v })

function selectIcon(icon) {
  emit('update:modelValue', icon)
  currentValue.value = icon
}
</script>

<style scoped>
.icon-category { margin-bottom: 16px; }
.cat-label { font-size: 13px; color: #999; margin-bottom: 8px; padding-left: 4px; }
.icon-grid { display: flex; flex-wrap: wrap; gap: 4px; }
.icon-item {
  display: flex; flex-direction: column; align-items: center;
  width: 64px; height: 64px; padding: 6px 4px;
  border: 1px solid #e8e8e8; border-radius: 4px; cursor: pointer;
  transition: all 0.15s; font-size: 20px; color: #555;
}
.icon-item:hover { border-color: #409eff; color: #409eff; background: #f0f7ff; }
.icon-item.selected { border-color: #409eff; color: #fff; background: #409eff; }
.icon-name { font-size: 10px; margin-top: 4px; text-align: center; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; width: 100%; }
.no-icon { color: #ccc; font-size: 12px; }
.icon-search { margin-bottom: 12px; }
</style>
