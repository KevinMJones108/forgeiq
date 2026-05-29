// ForgeIQ Products API Routes
// Session 12 — Product Library
// Sales reps upload product specs before calls
// AI references during conversation

const express = require('express');
const router = express.Router();
const { Pool } = require('pg');

// POST /api/v1/products — Create new product with specs
router.post('/', async (req, res, next) => {
  try {
    const userId = req.auth.sub;
    const { name, category, specs, linked_script_id } = req.body;

    if (!name || !specs || typeof specs !== 'object') {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'name and specs (JSON object) are required'
      });
    }

    const result = await pool.query(
      `INSERT INTO products (user_id, name, category, specs, linked_script_id)
       VALUES (
         (SELECT id FROM users WHERE auth0_sub = $1),
         $2, $3, $4::jsonb, $5
       )
       RETURNING id, name, category, specs, linked_script_id, created_at, updated_at`,
      [userId, name, category || null, JSON.stringify(specs), linked_script_id || null]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      error: null
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/products/:id — Get single product
router.get('/:id', async (req, res, next) => {
  try {
    const userId = req.auth.sub;
    const { id } = req.params;

    const result = await pool.query(
      `SELECT id, name, category, specs, linked_script_id, created_at, updated_at
       FROM products
       WHERE id = $1
         AND user_id = (SELECT id FROM users WHERE auth0_sub = $2)
         AND deleted_at IS NULL`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        data: null,
        error: 'Product not found or does not belong to user'
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
      error: null
    });
  } catch (error) {
    next(error);
  }
});

// PUT /api/v1/products/:id — Update product specs
router.put('/:id', async (req, res, next) => {
  try {
    const userId = req.auth.sub;
    const { id } = req.params;
    const { name, category, specs, linked_script_id } = req.body;

    if (!name && !category && !specs && linked_script_id === undefined) {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'At least one field (name, category, specs, linked_script_id) required'
      });
    }

    // Build dynamic update query
    const updates = [];
    const values = [id, userId];
    let paramCount = 2;

    if (name) {
      paramCount++;
      updates.push(`name = $${paramCount}`);
      values.push(name);
    }
    if (category !== undefined) {
      paramCount++;
      updates.push(`category = $${paramCount}`);
      values.push(category);
    }
    if (specs) {
      paramCount++;
      updates.push(`specs = $${paramCount}::jsonb`);
      values.push(JSON.stringify(specs));
    }
    if (linked_script_id !== undefined) {
      paramCount++;
      updates.push(`linked_script_id = $${paramCount}`);
      values.push(linked_script_id);
    }

    updates.push('updated_at = NOW()');

    const result = await pool.query(
      `UPDATE products
       SET ${updates.join(', ')}
       WHERE id = $1
         AND user_id = (SELECT id FROM users WHERE auth0_sub = $2)
         AND deleted_at IS NULL
       RETURNING id, name, category, specs, linked_script_id, created_at, updated_at`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        data: null,
        error: 'Product not found or does not belong to user'
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
      error: null
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/v1/products/:id — Soft delete product
router.delete('/:id', async (req, res, next) => {
  try {
    const userId = req.auth.sub;
    const { id } = req.params;

    const result = await pool.query(
      `UPDATE products
       SET deleted_at = NOW()
       WHERE id = $1
         AND user_id = (SELECT id FROM users WHERE auth0_sub = $2)
         AND deleted_at IS NULL
       RETURNING id`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        data: null,
        error: 'Product not found or does not belong to user'
      });
    }

    res.json({
      success: true,
      data: { id: result.rows[0].id },
      error: null
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
