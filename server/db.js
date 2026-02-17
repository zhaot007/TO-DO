import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dbPath = path.join(__dirname, 'database.sqlite');

let db;

export async function initDB() {
  db = await open({
    filename: dbPath,
    driver: sqlite3.Database
  });

  console.log('Connected to SQLite database.');

  // 创建用户表
  await db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 创建任务表 (SQLite 不支持 ENUM，使用 CHECK 约束)
  await db.exec(`
    CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      text TEXT NOT NULL,
      status TEXT CHECK(status IN ('pending', 'in_progress', 'completed', 'cancelled', 'overdue')) DEFAULT 'pending',
      category TEXT CHECK(category IN ('work', 'study', 'life')) DEFAULT 'work',
      priority TEXT CHECK(priority IN ('high', 'medium', 'low')) DEFAULT 'medium',
      type TEXT CHECK(type IN ('today', 'daily', 'weekly')) DEFAULT 'today',
      weekdays TEXT, -- 存储 JSON 字符串
      is_deleted BOOLEAN DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      last_completed DATETIME,
      completed_at DATETIME,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  console.log('SQLite tables initialized.');
}

export default {
  // 代理方法以适配原有代码
  query: async (sql, params = []) => {
    const normalizedSql = sql.trim().toUpperCase();
    if (normalizedSql.startsWith('SELECT')) {
      const rows = await db.all(sql, params);
      return [rows];
    } else {
      const result = await db.run(sql, params);
      // 适配 mysql2 的 result.insertId
      return [{ insertId: result.lastID, affectedRows: result.changes }];
    }
  }
};