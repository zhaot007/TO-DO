/**
 * 任务数据统计脚本
 * 用途：在浏览器控制台中查看任务的详细统计信息
 * 使用方法：在浏览器控制台（F12 → Console）中复制粘贴执行
 */

const tasks = JSON.parse(localStorage.getItem('CapacitorStorage.tasks') || '[]');
console.log('=== 任务统计 ===');
console.log('总任务数:', tasks.length);

const stats = {
  categories: {},
  priorities: {},
  types: {},
  statuses: {}
};

tasks.forEach(t => {
  stats.categories[t.category] = (stats.categories[t.category] || 0) + 1;
  stats.priorities[t.priority] = (stats.priorities[t.priority] || 0) + 1;
  stats.types[t.type] = (stats.types[t.type] || 0) + 1;
  stats.statuses[t.status] = (stats.statuses[t.status] || 0) + 1;
});

console.log('分类分布:', stats.categories);
console.log('优先级分布:', stats.priorities);
console.log('类型分布:', stats.types);
console.log('状态分布:', stats.statuses);

console.log('\n=== 前3条任务示例 ===');
tasks.slice(0, 3).forEach((t, i) => {
  console.log(`任务${i+1}:`, {
    名称: t.text,
    描述: t.description?.substring(0, 30),
    分类: t.category,
    优先级: t.priority,
    类型: t.type,
    状态: t.status,
    创建时间: t.created_at,
    周期: t.weekdays
  });
});
