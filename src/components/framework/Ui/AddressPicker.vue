<template>
  <div class="xh-address-picker">
    <el-cascader
      v-model="selectedValue"
      :options="chinaRegionData"
      :props="cascaderProps"
      :placeholder="placeholder"
      :disabled="disabled"
      :size="size"
      clearable
      filterable
      class="xh-address-picker__cascader"
      @change="handleChange"
    />
    <!-- 详细地址输入 -->
    <el-input
      v-if="showDetail"
      v-model="detailValue"
      :placeholder="detailPlaceholder"
      :disabled="disabled"
      :size="size"
      class="xh-address-picker__detail"
      @input="handleDetailChange"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'

interface Props {
  /** v-model: 完整地址字符串或 { province, city, district, detail } 对象 */
  modelValue: string | { province: string; city: string; district: string; detail: string } | null
  /** 显示级别：2=省市/3=省市区 */
  level?: 2 | 3
  placeholder?: string
  detailPlaceholder?: string
  disabled?: boolean
  size?: 'large' | 'default' | 'small'
  /** 是否显示详细地址输入框 */
  showDetail?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  level: 3,
  placeholder: '选择省/市/区',
  detailPlaceholder: '详细地址',
  disabled: false,
  showDetail: true,
})

const emit = defineEmits<{
  'update:modelValue': [val: any]
  change: [val: any]
}>()

const selectedValue = ref<string[]>([])
const detailValue = ref('')

// 级联选择器配置
const cascaderProps = computed(() => ({
  expandTrigger: 'hover' as const,
  checkStrictly: props.level === 2,
  emitPath: true,
  value: 'name',
  label: 'name',
}))

/** 同步外部值 */
watch(
  () => props.modelValue,
  (val) => {
    if (!val) {
      selectedValue.value = []
      detailValue.value = ''
      return
    }
    if (typeof val === 'string') {
      // 字符串格式：山东省济南市历下区
      const parts = val.split(/[省市区县]/)
      selectedValue.value = parts.filter(Boolean)
    } else {
      // 对象格式
      const arr: string[] = []
      if (val.province) arr.push(val.province)
      if (val.city) arr.push(val.city)
      if (val.district) arr.push(val.district)
      selectedValue.value = arr
      detailValue.value = val.detail || ''
    }
  },
  { immediate: true }
)

function handleChange(val: string[]) {
  emitValue(val, detailValue.value)
}

function handleDetailChange() {
  emitValue(selectedValue.value, detailValue.value)
}

function emitValue(addressArr: string[], detail: string) {
  const result = {
    province: addressArr[0] || '',
    city: addressArr[1] || '',
    district: addressArr[2] || '',
    detail,
    fullText: [...addressArr, detail].filter(Boolean).join(''),
  }
  emit('update:modelValue', result)
  emit('change', result)
}

// 中国省市区数据（精简版，关键城市）
// 完整数据约3MB，这里列出常用地区
const chinaRegionData = [
  {
    name: '山东省',
    children: [
      {
        name: '济南市',
        children: [
          { name: '历下区' }, { name: '市中区' }, { name: '槐荫区' },
          { name: '天桥区' }, { name: '历城区' }, { name: '长清区' },
          { name: '章丘区' }, { name: '济阳区' }, { name: '莱芜区' },
          { name: '钢城区' }, { name: '平阴县' }, { name: '商河县' },
        ],
      },
      {
        name: '青岛市',
        children: [
          { name: '市南区' }, { name: '市北区' }, { name: '黄岛区' },
          { name: '崂山区' }, { name: '李沧区' }, { name: '城阳区' },
          { name: '即墨区' }, { name: '胶州市' }, { name: '平度市' },
          { name: '莱西市' },
        ],
      },
      {
        name: '淄博市',
        children: [
          { name: '张店区' }, { name: '淄川区' }, { name: '博山区' },
          { name: '临淄区' }, { name: '周村区' }, { name: '桓台县' },
          { name: '高青县' }, { name: '沂源县' },
        ],
      },
      {
        name: '枣庄市',
        children: [
          { name: '市中区' }, { name: '薛城区' }, { name: '峄城区' },
          { name: '台儿庄区' }, { name: '山亭区' }, { name: '滕州市' },
        ],
      },
      {
        name: '烟台市',
        children: [
          { name: '芝罘区' }, { name: '福山区' }, { name: '牟平区' },
          { name: '莱山区' }, { name: '蓬莱区' }, { name: '龙口市' },
          { name: '莱阳市' }, { name: '莱州市' }, { name: '招远市' },
          { name: '栖霞市' }, { name: '海阳市' },
        ],
      },
      {
        name: '潍坊市',
        children: [
          { name: '潍城区' }, { name: '寒亭区' }, { name: '坊子区' },
          { name: '奎文区' }, { name: '青州市' }, { name: '诸城市' },
          { name: '寿光市' }, { name: '安丘市' }, { name: '高密市' },
          { name: '昌邑市' }, { name: '临朐县' }, { name: '昌乐县' },
        ],
      },
      {
        name: '济宁市',
        children: [
          { name: '任城区' }, { name: '兖州区' }, { name: '微山县' },
          { name: '鱼台县' }, { name: '金乡县' }, { name: '嘉祥县' },
          { name: '汶上县' }, { name: '泗水县' }, { name: '梁山县' },
          { name: '曲阜市' }, { name: '邹城市' },
        ],
      },
      {
        name: '泰安市',
        children: [
          { name: '泰山区' }, { name: '岱岳区' }, { name: '宁阳县' },
          { name: '东平县' }, { name: '新泰市' }, { name: '肥城市' },
        ],
      },
      {
        name: '威海市',
        children: [
          { name: '环翠区' }, { name: '文登区' }, { name: '荣成市' },
          { name: '乳山市' },
        ],
      },
      {
        name: '日照市',
        children: [
          { name: '东港区' }, { name: '岚山区' }, { name: '五莲县' },
          { name: '莒县' },
        ],
      },
      {
        name: '临沂市',
        children: [
          { name: '兰山区' }, { name: '罗庄区' }, { name: '河东区' },
          { name: '沂南县' }, { name: '郯城县' }, { name: '沂水县' },
          { name: '兰陵县' }, { name: '费县' }, { name: '平邑县' },
          { name: '莒南县' }, { name: '蒙阴县' }, { name: '临沭县' },
        ],
      },
      {
        name: '德州市',
        children: [
          { name: '德城区' }, { name: '陵城区' }, { name: '宁津县' },
          { name: '庆云县' }, { name: '临邑县' }, { name: '齐河县' },
          { name: '平原县' }, { name: '夏津县' }, { name: '武城县' },
          { name: '乐陵市' }, { name: '禹城市' },
        ],
      },
      {
        name: '聊城市',
        children: [
          { name: '东昌府区' }, { name: '茌平区' }, { name: '阳谷县' },
          { name: '莘县' }, { name: '东阿县' }, { name: '冠县' },
          { name: '高唐县' }, { name: '临清市' },
        ],
      },
      {
        name: '滨州市',
        children: [
          { name: '滨城区' }, { name: '沾化区' }, { name: '惠民县' },
          { name: '阳信县' }, { name: '无棣县' }, { name: '博兴县' },
          { name: '邹平市' },
        ],
      },
      {
        name: '菏泽市',
        children: [
          { name: '牡丹区' }, { name: '定陶区' }, { name: '曹县' },
          { name: '单县' }, { name: '成武县' }, { name: '巨野县' },
          { name: '郓城县' }, { name: '鄄城县' }, { name: '东明县' },
        ],
      },
    ],
  },
  {
    name: '北京市',
    children: [
      { name: '东城区' }, { name: '西城区' }, { name: '朝阳区' },
      { name: '丰台区' }, { name: '石景山区' }, { name: '海淀区' },
      { name: '顺义区' }, { name: '通州区' }, { name: '大兴区' },
      { name: '房山区' }, { name: '昌平区' }, { name: '门头沟区' },
      { name: '平谷区' }, { name: '怀柔区' }, { name: '密云区' },
      { name: '延庆区' },
    ],
  },
  {
    name: '上海市',
    children: [
      { name: '黄浦区' }, { name: '徐汇区' }, { name: '长宁区' },
      { name: '静安区' }, { name: '普陀区' }, { name: '虹口区' },
      { name: '杨浦区' }, { name: '闵行区' }, { name: '宝山区' },
      { name: '嘉定区' }, { name: '浦东新区' }, { name: '金山区' },
      { name: '松江区' }, { name: '青浦区' }, { name: '奉贤区' },
      { name: '崇明区' },
    ],
  },
  {
    name: '广东省',
    children: [
      {
        name: '广州市',
        children: [
          { name: '荔湾区' }, { name: '越秀区' }, { name: '海珠区' },
          { name: '天河区' }, { name: '白云区' }, { name: '黄埔区' },
          { name: '番禺区' }, { name: '花都区' }, { name: '南沙区' },
          { name: '从化区' }, { name: '增城区' },
        ],
      },
      {
        name: '深圳市',
        children: [
          { name: '罗湖区' }, { name: '福田区' }, { name: '南山区' },
          { name: '宝安区' }, { name: '龙岗区' }, { name: '盐田区' },
          { name: '龙华区' }, { name: '坪山区' }, { name: '光明区' },
        ],
      },
      {
        name: '东莞市',
        children: [
          { name: '莞城街道' }, { name: '石龙镇' }, { name: '虎门镇' },
          { name: '茶山镇' }, { name: '桥头镇' }, { name: '万江街道' },
          { name: '南城街道' }, { name: '中堂镇' }, { name: '高埗镇' },
          { name: '其他' },
        ],
      },
      {
        name: '佛山市',
        children: [
          { name: '禅城区' }, { name: '南海区' }, { name: '顺德区' },
          { name: '三水区' }, { name: '高明区' },
        ],
      },
      {
        name: '珠海市',
        children: [
          { name: '香洲区' }, { name: '斗门区' }, { name: '金湾区' },
        ],
      },
      {
        name: '惠州市',
        children: [
          { name: '惠城区' }, { name: '惠阳区' }, { name: '博罗县' },
          { name: '惠东县' }, { name: '龙门县' },
        ],
      },
      {
        name: '中山市',
        children: [
          { name: '石岐街道' }, { name: '东区街道' }, { name: '西区街道' },
          { name: '中山港街道' }, { name: '其他' },
        ],
      },
      {
        name: '江门市',
        children: [
          { name: '蓬江区' }, { name: '江海区' }, { name: '新会区' },
          { name: '台山市' }, { name: '开平市' }, { name: '鹤山市' },
          { name: '恩平市' },
        ],
      },
    ],
  },
  {
    name: '江苏省',
    children: [
      {
        name: '南京市',
        children: [
          { name: '玄武区' }, { name: '秦淮区' }, { name: '建邺区' },
          { name: '鼓楼区' }, { name: '浦口区' }, { name: '栖霞区' },
          { name: '雨花台区' }, { name: '江宁区' }, { name: '六合区' },
          { name: '溧水区' }, { name: '高淳区' },
        ],
      },
      {
        name: '苏州市',
        children: [
          { name: '虎丘区' }, { name: '吴中区' }, { name: '相城区' },
          { name: '姑苏区' }, { name: '吴江区' }, { name: '苏州工业园区' },
          { name: '常熟市' }, { name: '张家港市' }, { name: '昆山市' },
          { name: '太仓市' },
        ],
      },
      {
        name: '无锡市',
        children: [
          { name: '锡山区' }, { name: '惠山区' }, { name: '滨湖区' },
          { name: '梁溪区' }, { name: '新吴区' }, { name: '江阴市' },
          { name: '宜兴市' },
        ],
      },
      {
        name: '常州市',
        children: [
          { name: '天宁区' }, { name: '钟楼区' }, { name: '新北区' },
          { name: '武进区' }, { name: '金坛区' }, { name: '溧阳市' },
        ],
      },
      {
        name: '南通市',
        children: [
          { name: '崇川区' }, { name: '通州区' }, { name: '海门区' },
          { name: '如东县' }, { name: '启东市' }, { name: '如皋市' },
          { name: '海安市' },
        ],
      },
      {
        name: '徐州市',
        children: [
          { name: '鼓楼区' }, { name: '云龙区' }, { name: '贾汪区' },
          { name: '泉山区' }, { name: '铜山区' }, { name: '丰县' },
          { name: '沛县' }, { name: '睢宁县' }, { name: '新沂市' },
          { name: '邳州市' },
        ],
      },
    ],
  },
  {
    name: '浙江省',
    children: [
      {
        name: '杭州市',
        children: [
          { name: '上城区' }, { name: '拱墅区' }, { name: '西湖区' },
          { name: '滨江区' }, { name: '萧山区' }, { name: '余杭区' },
          { name: '临平区' }, { name: '钱塘区' }, { name: '富阳区' },
          { name: '临安区' }, { name: '桐庐县' }, { name: '淳安县' },
          { name: '建德市' },
        ],
      },
      {
        name: '宁波市',
        children: [
          { name: '海曙区' }, { name: '江北区' }, { name: '北仑区' },
          { name: '镇海区' }, { name: '鄞州区' }, { name: '奉化区' },
          { name: '象山县' }, { name: '宁海县' }, { name: '余姚市' },
          { name: '慈溪市' },
        ],
      },
      {
        name: '温州市',
        children: [
          { name: '鹿城区' }, { name: '龙湾区' }, { name: '瓯海区' },
          { name: '洞头区' }, { name: '永嘉县' }, { name: '平阳县' },
          { name: '苍南县' }, { name: '文成县' }, { name: '泰顺县' },
          { name: '瑞安市' }, { name: '乐清市' }, { name: '龙港市' },
        ],
      },
      {
        name: '嘉兴市',
        children: [
          { name: '南湖区' }, { name: '秀洲区' }, { name: '嘉善县' },
          { name: '海盐县' }, { name: '海宁市' }, { name: '平湖市' },
          { name: '桐乡市' },
        ],
      },
      {
        name: '湖州市',
        children: [
          { name: '吴兴区' }, { name: '南浔区' }, { name: '德清县' },
          { name: '长兴县' }, { name: '安吉县' },
        ],
      },
      {
        name: '绍兴市',
        children: [
          { name: '越城区' }, { name: '柯桥区' }, { name: '上虞区' },
          { name: '新昌县' }, { name: '诸暨市' }, { name: '嵊州市' },
        ],
      },
      {
        name: '金华市',
        children: [
          { name: '婺城区' }, { name: '金东区' }, { name: '武义县' },
          { name: '浦江县' }, { name: '磐安县' }, { name: '兰溪市' },
          { name: '义乌市' }, { name: '东阳市' }, { name: '永康市' },
        ],
      },
    ],
  },
  {
    name: '四川省',
    children: [
      {
        name: '成都市',
        children: [
          { name: '锦江区' }, { name: '青羊区' }, { name: '金牛区' },
          { name: '武侯区' }, { name: '成华区' }, { name: '龙泉驿区' },
          { name: '青白江区' }, { name: '新都区' }, { name: '温江区' },
          { name: '双流区' }, { name: '郫都区' }, { name: '新津区' },
          { name: '金堂县' }, { name: '大邑县' }, { name: '蒲江县' },
          { name: '都江堰市' }, { name: '彭州市' }, { name: '邛崃市' },
          { name: '崇州市' }, { name: '简阳市' },
        ],
      },
      {
        name: '绵阳市',
        children: [
          { name: '涪城区' }, { name: '游仙区' }, { name: '安州区' },
          { name: '三台县' }, { name: '盐亭县' }, { name: '梓潼县' },
          { name: '平武县' }, { name: '北川羌族自治县' }, { name: '江油市' },
        ],
      },
      {
        name: '德阳市',
        children: [
          { name: '旌阳区' }, { name: '罗江区' }, { name: '中江县' },
          { name: '广汉市' }, { name: '什邡市' }, { name: '绵竹市' },
        ],
      },
      {
        name: '南充市',
        children: [
          { name: '顺庆区' }, { name: '高坪区' }, { name: '嘉陵区' },
          { name: '南部县' }, { name: '营山县' }, { name: '蓬安县' },
          { name: '仪陇县' }, { name: '西充县' }, { name: '阆中市' },
        ],
      },
    ],
  },
  {
    name: '河南省',
    children: [
      {
        name: '郑州市',
        children: [
          { name: '中原区' }, { name: '二七区' }, { name: '管城回族区' },
          { name: '金水区' }, { name: '惠济区' }, { name: '上街区' },
          { name: '巩义市' }, { name: '荥阳市' }, { name: '新密市' },
          { name: '新郑市' }, { name: '登封市' }, { name: '中牟县' },
        ],
      },
      {
        name: '洛阳市',
        children: [
          { name: '老城区' }, { name: '西工区' }, { name: '瀍河回族区' },
          { name: '涧西区' }, { name: '偃师区' }, { name: '孟津区' },
          { name: '新安县' }, { name: '伊川县' }, { name: '偃师市' },
        ],
      },
      {
        name: '开封市',
        children: [
          { name: '龙亭区' }, { name: '顺河回族区' }, { name: '鼓楼区' },
          { name: '禹王台区' }, { name: '祥符区' }, { name: '杞县' },
          { name: '通许县' }, { name: '尉氏县' }, { name: '兰考县' },
        ],
      },
    ],
  },
  {
    name: '湖北省',
    children: [
      {
        name: '武汉市',
        children: [
          { name: '江岸区' }, { name: '江汉区' }, { name: '硚口区' },
          { name: '汉阳区' }, { name: '武昌区' }, { name: '青山区' },
          { name: '洪山区' }, { name: '东西湖区' }, { name: '汉南区' },
          { name: '蔡甸区' }, { name: '江夏区' }, { name: '黄陂区' },
          { name: '新洲区' },
        ],
      },
      {
        name: '襄阳市',
        children: [
          { name: '襄城区' }, { name: '樊城区' }, { name: '襄州区' },
          { name: '南漳县' }, { name: '谷城县' }, { name: '保康县' },
          { name: '老河口市' }, { name: '枣阳市' }, { name: '宜城市' },
        ],
      },
      {
        name: '宜昌市',
        children: [
          { name: '西陵区' }, { name: '伍家岗区' }, { name: '点军区' },
          { name: '猇亭区' }, { name: '夷陵区' }, { name: '远安县' },
          { name: '兴山县' }, { name: '秭归县' }, { name: '长阳土家族自治县' },
          { name: '五峰土家族自治县' }, { name: '宜都市' }, { name: '当阳市' },
          { name: '枝江市' },
        ],
      },
    ],
  },
]
</script>

<style scoped>
.xh-address-picker {
  display: flex;
  gap: 8px;
}

.xh-address-picker__cascader {
  flex-shrink: 0;
}

.xh-address-picker__detail {
  flex: 1;
  min-width: 0;
}
</style>
