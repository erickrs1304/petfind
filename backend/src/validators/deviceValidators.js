const { z } = require('zod');

const deviceTokenSchema = z.object({
  token: z.string().min(20).max(512),
});

module.exports = { deviceTokenSchema };
