/**
 * 根据后端菜单数据动态生成 Vue Router 路由
 * menus 来自 userStore.menus（后端 /api/v1/system/menus/nav 返回的叶子节点）
 * 每个节点结构：{ id, name, path, icon, componentPath, ... }
 */
export function generateRoutesFromMenus(menus) {
  const routes = []
  for (const menu of menus) {
    const { path, name, componentPath } = menu
    if (!path || !componentPath) continue
    // 跳过公开路由（已在静态路由中定义）
    if (path === '/login') continue

    // 将 componentPath 转为动态 import
    // '@/views/xxx/YYY.vue' → () => import('@/views/xxx/YYY.vue')
    const component = () => import(/* webpackChunkName: "[request]" */ `@/${componentPath.replace('@/', '')}`)

    routes.push({
      path,
      name: name.replace(/\s+/g, ''),  // 去掉空格：'工单列表' → '工单列表'（有些name带空格）
      component,
      meta: { title: name, menuId: menu.id }
    })
  }
  return routes
}

/**
 * 向 router 动态注册路由
 * 调用时机：用户登录后，router guard 中
 */
export function registerDynamicRoutes(router, menus) {
  const dynamicRoutes = generateRoutesFromMenus(menus)
  for (const route of dynamicRoutes) {
    // 避免重复注册
    const exists = router.getRoutes().some(r => r.path === route.path)
    if (!exists) {
      router.addRoute(route)
    }
  }
  return dynamicRoutes
}
