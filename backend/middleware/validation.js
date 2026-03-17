const { validationResult } = require('express-validator');

/**
 * Express middleware that checks express-validator results and returns 400 if invalid.
 * Add as a middleware in the route chain after validation rules:
 *
 *   router.post('/route', [
 *     body('field').isLength({ min: 1 }),
 *     handleValidationErrors,
 *   ], async (req, res) => { ... });
 */
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
}

module.exports = { handleValidationErrors };
