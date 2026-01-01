const corsOptions = {
  origin: function(origin, callback) {
    const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000,http://localhost:3001').split(',');
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400, // 24 hours
};

console.log('🔒 CORS Configuration:');
console.log(`   Origin: ${corsOptions.origin}`);
console.log(`   Methods: ${corsOptions.methods.join(', ')}`);
console.log(`   Credentials: ${corsOptions.credentials}`);

module.exports = corsOptions;
