/**
 * 权限Hook — 对标JeecgBoot的usePermission
 * 
 * JeecgBoot: src/hooks/web/usePermission.ts
 * 
 * 功能：
 * 1. 判断当前用户是否有某个权限
 * 2. 判断是否有任意一个权限
 * 3. 判断是否拥有所有权限
 * 4. 权限码自动注册到路由守卫
 */

import { computed } from 'vue'
import { useUserStore } from '@/stores/user'

export function usePermission() {
  const userStore = useUserStore()

  /**
   * 判断是否有指定权限
   * @param permission 权限码，如 'fsm:workorder:edit'
   */
  const hasPermission = (permission: string): boolean => {
    return userStore.permissions.includes(permission)
  }

  /**
   * 判断是否有任意一个权限（OR）
   * @param permissionList 权限码数组
   */
  const hasAnyPermission = (permissionList: string[]): boolean => {
    return permissionList.some(p => userStore.permissions.includes(p))
  }

  /**
   * 判断是否拥有所有权限（AND）
   * @param permissionList 权限码数组
   */
  const hasAllPermissions = (permissionList: string[]): boolean => {
    return permissionList.every(p => userStore.permissions.includes(p))
  }

  /**
   * 判断是否是超级管理员
   */
  const isAdmin = computed(() => {
    return userStore.userInfo?.username === 'admin' || hasPermission('*')
  })

  /**
   * 获取用户在某个模块的权限列表
   */
  const getPermissionsByModule = (module: string): string[] => {
    return userStore.permissions.filter(p => p.startsWith(`${module}:`))
  }

  return {
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
    isAdmin,
    getPermissionsByModule,
    permissions: computed(() => userStore.permissions)
  }
}

/**
 * 权限指令 v-auth="'permission:code'"
 * 用法：
 *   <el-button v-auth="'fsm:workorder:edit'">编辑</el-button>
 *   <el-button v-auth="['fsm:workorder:edit', 'fsm:workorder:delete']">操作</el-button>
 * 
 * 导出后在 main.ts 注册：
 *   import { authDirective } from '@/composables/usePermission'
 *   app.directive('auth', authDirective)
 */
export const authDirective = {
  mounted(el: HTMLElement, binding: any) {
    const { hasPermission, hasAnyPermission } = usePermission()
    const value = binding.value

    let allowed = false
    if (!value) {
      // 没有传值，不限制
      allowed = true
    } else if (Array.isArray(value)) {
      // 数组：拥有任意一个即可
      allowed = hasAnyPermission(value)
    } else {
      // 字符串：精确匹配
      allowed = hasPermission(value)
    }

    if (!allowed) {
      // 无权限，移除元素
      el.parentNode?.removeChild(el)
    }
  }
}

/**
 * 权限指令（禁用模式）
 * 用法：<el-button v-auth-disable="'fsm:workorder:edit'">编辑</el-button>
 * 无权限时按钮变灰并禁用
 */
export const authDisableDirective = {
  mounted(el: HTMLElement, binding: any) {
    const { hasPermission } = usePermission()
    const value = binding.value

    if (value && !hasPermission(value)) {
      el.setAttribute('disabled', 'true')
      el.classList.add('is-disabled')
      el.addEventListener('click', (e: Event) => e.stopImmediatePropagation(), true)
    }
  }
}
