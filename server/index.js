import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pool, { initDB } from './db.js';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// 初始化数据库
initDB();

// 用户登录/注册 (简化逻辑)
app.post('/api/login', async (req, res) => {
  const { username } = req.body;
  if (!username) return res.status(400).json({ error: 'Username is required' });

  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
    let user;
    if (rows.length === 0) {
      const [result] = await pool.query('INSERT INTO users (username) VALUES (?)', [username]);
      user = { id: result.insertId, username };
    } else {
      user = rows[0];
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 获取所有任务 (仅未删除的)
app.get('/api/tasks/:userId', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM tasks WHERE user_id = ? AND is_deleted = 0', [req.params.userId]);
    // 转换 weekdays 从 JSON 字符串到数组 (如果驱动没有自动处理)
    const tasks = rows.map(task => ({
      ...task,
      weekdays: typeof task.weekdays === 'string' ? JSON.parse(task.weekdays) : task.weekdays
    }));
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 获取回收站任务
app.get('/api/tasks/:userId/deleted', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM tasks WHERE user_id = ? AND is_deleted = 1', [req.params.userId]);
    const tasks = rows.map(task => ({
      ...task,
      weekdays: typeof task.weekdays === 'string' ? JSON.parse(task.weekdays) : task.weekdays
    }));
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 添加任务
app.post('/api/tasks', async (req, res) => {
  const { user_id, text, category, priority, type, weekdays } = req.body;
  try {
    const [result] = await pool.query(
      'INSERT INTO tasks (user_id, text, category, priority, type, weekdays) VALUES (?, ?, ?, ?, ?, ?)',
      [user_id, text, category, priority, type, JSON.stringify(weekdays)]
    );
    const [newTask] = await pool.query('SELECT * FROM tasks WHERE id = ?', [result.insertId]);
    res.json({
      ...newTask[0],
      weekdays: typeof newTask[0].weekdays === 'string' ? JSON.parse(newTask[0].weekdays) : newTask[0].weekdays
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 更新任务
app.put('/api/tasks/:id', async (req, res) => {
  const { id } = req.params;
  const updates = req.body;
  
  const fields = [];
  const values = [];
  
  // 允许更新的所有合法字段
  const allowedFields = ['text', 'status', 'category', 'priority', 'type', 'weekdays', 'last_completed', 'completed_at', 'is_deleted'];
  
  for (const [key, value] of Object.entries(updates)) {
    if (allowedFields.includes(key)) {
      fields.push(`"${key}" = ?`);
      // 处理 JSON 字段
      if (key === 'weekdays') {
        values.push(JSON.stringify(value));
      } else if (key === 'is_deleted') {
        values.push(value ? 1 : 0);
      } else {
        values.push(value);
      }
    }
  }

  if (fields.length === 0) return res.status(400).json({ error: 'No valid fields to update' });

  values.push(id);
  
  try {
    const query = `UPDATE tasks SET ${fields.join(', ')} WHERE id = ?`;
    await pool.query(query, values);
    
    const [updatedTask] = await pool.query('SELECT * FROM tasks WHERE id = ?', [id]);
    const task = updatedTask[0];
    
    res.json({
      ...task,
      weekdays: typeof task.weekdays === 'string' ? JSON.parse(task.weekdays) : task.weekdays
    });
  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({ error: error.message });
  }
});

// 逻辑删除任务 (移至回收站)
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    await pool.query('UPDATE tasks SET is_deleted = 1 WHERE id = ?', [req.params.id]);
    res.json({ message: 'Task moved to trash' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 恢复任务
app.post('/api/tasks/:id/restore', async (req, res) => {
  try {
    await pool.query('UPDATE tasks SET is_deleted = 0 WHERE id = ?', [req.params.id]);
    res.json({ message: 'Task restored' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 彻底删除
app.delete('/api/tasks/:id/permanent', async (req, res) => {
  try {
    await pool.query('DELETE FROM tasks WHERE id = ?', [req.params.id]);
    res.json({ message: 'Task deleted permanently' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});