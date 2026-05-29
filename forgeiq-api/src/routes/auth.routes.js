const express = require('express');
const router = express.Router();
const { query } = require('../db');
const { checkJwt } = require('../middleware/auth.middleware');
const { success, error } = require('../utils/response');


// POST /api/v1/auth/sync
// First login - create user + subscription if new
router.post('/sync', checkJwt, async (req, res, next) => {
  try {
    const auth0_sub = req.auth.sub;
    const { email, name } = req.body;

    // Check if user exists
    let userResult = await query(
      'SELECT id, email, name FROM users WHERE auth0_sub = $1',
      [auth0_sub]
    );

    let user;
    if (userResult.rows.length === 0) {
      // Create new user
      const insertUser = await query(
        `INSERT INTO users (auth0_sub, email, name)
         VALUES ($1, $2, $3)
         RETURNING id, email, name, created_at`,
        [auth0_sub, email, name]
      );
      user = insertUser.rows[0];

      // Create default subscription (VoiceCore enabled)
      await query(
        `INSERT INTO user_subscriptions (user_id, voice_core_enabled)
         VALUES ($1, true)`,
        [user.id]
      );
    } else {
      user = userResult.rows[0];
    }

    return res.json(success({ user }));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/auth/me
// Return user + subscription + feature flags
router.get('/me', checkJwt, async (req, res, next) => {
  try {
    const auth0_sub = req.auth.sub;

    const result = await query(
      `SELECT
         u.id, u.email, u.name, u.created_at,
         s.voice_core_enabled, s.idea_vault_enabled, s.sigma_vault_enabled,
         s.sales_forge_enabled, s.doe_enabled, s.apex_script_enabled
       FROM users u
       LEFT JOIN user_subscriptions s ON u.id = s.user_id
       WHERE u.auth0_sub = $1`,
      [auth0_sub]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('User not found'));
    }

    return res.json(success({ user: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
