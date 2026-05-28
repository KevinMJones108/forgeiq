const express = require('express');
const router = express.Router();
const { query } = require('../db');
const { checkJwt } = require('../middleware/auth.middleware');
const { success, error } = require('../utils/response');

// GET /api/v1/scripts
// List all scripts for current user (non-deleted)
router.get('/scripts', checkJwt, async (req, res, next) => {
  try {
    const user_id = req.auth.sub;

    const result = await query(
      `SELECT id, user_id, title, product_name, talking_points, created_at
       FROM scripts
       WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC`,
      [user_id]
    );

    return res.json(success({ scripts: result.rows }));
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/scripts
// Create new script
router.post('/scripts', checkJwt, async (req, res, next) => {
  try {
    const user_id = req.auth.sub;
    const { title, product_name, talking_points } = req.body;

    if (!title || !Array.isArray(talking_points) || talking_points.length === 0) {
      return res.status(400).json(error('Missing required fields: title, talking_points (array)'));
    }

    const result = await query(
      `INSERT INTO scripts (user_id, title, product_name, talking_points)
       VALUES ($1, $2, $3, $4)
       RETURNING id, user_id, title, product_name, talking_points, created_at`,
      [user_id, title, product_name || null, JSON.stringify(talking_points)]
    );

    return res.json(success({ script: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/scripts/:id
// Get single script
router.get('/scripts/:id', checkJwt, async (req, res, next) => {
  try {
    const user_id = req.auth.sub;
    const { id } = req.params;

    const result = await query(
      `SELECT id, user_id, title, product_name, talking_points, created_at
       FROM scripts
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('Script not found'));
    }

    return res.json(success({ script: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// PUT /api/v1/scripts/:id
// Update script
router.put('/scripts/:id', checkJwt, async (req, res, next) => {
  try {
    const user_id = req.auth.sub;
    const { id } = req.params;
    const { title, product_name, talking_points } = req.body;

    if (!title || !Array.isArray(talking_points)) {
      return res.status(400).json(error('Missing required fields: title, talking_points'));
    }

    const result = await query(
      `UPDATE scripts
       SET title = $1, product_name = $2, talking_points = $3
       WHERE id = $4 AND user_id = $5 AND deleted_at IS NULL
       RETURNING id, user_id, title, product_name, talking_points, created_at`,
      [title, product_name || null, JSON.stringify(talking_points), id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('Script not found'));
    }

    return res.json(success({ script: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/scripts/:id
// Soft delete script
router.delete('/scripts/:id', checkJwt, async (req, res, next) => {
  try {
    const user_id = req.auth.sub;
    const { id } = req.params;

    const result = await query(
      `UPDATE scripts
       SET deleted_at = NOW()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING id`,
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('Script not found'));
    }

    return res.json(success({ message: 'Script deleted' }));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
