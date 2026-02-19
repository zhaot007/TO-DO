/**
 * 清理本地数据脚本
 * 用途：清空浏览器中的所有任务数据（包括回收站）
 * 使用方法：在浏览器控制台（F12 → Console）中复制粘贴执行
 */

// 清空任务数据
localStorage.setItem('CapacitorStorage.tasks', '[]');
localStorage.setItem('CapacitorStorage.deletedTasks', '[]');

// 刷新页面
location.reload();

console.log('✅ 已清空所有任务数据，页面即将刷新...');
