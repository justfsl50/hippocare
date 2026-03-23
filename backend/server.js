require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const authRoutes = require('./routes/authRoutes');
const doctorRoutes = require('./routes/doctorRoutes');
const patientRoutes = require('./routes/patientRoutes');
const appointmentRoutes = require('./routes/appointmentRoutes');
const geminiRoutes = require('./routes/geminiRoutes');
const chatRoutes = require('./routes/chatRoutes');

const app = express();

app.use(cors({
  origin:[
    process.env.FRONTEND_URL || 'http://localhost:5173/',
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials:true
}
));
app.use(express.json());

/* ==============================
   Supabase Connection
============================== */

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testSupabaseConnection() {
  try {
    const { data, error } = await supabase
      .from('doctors')
      .select('*')
      .limit(1);

    if (error) {
      console.log('❌ Supabase connection failed:', error.message);
    } else {
      console.log('✅ Supabase connected successfully');
    }
  } catch (err) {
    console.log('❌ Supabase error:', err.message);
  }
}

/* ==============================
   Routes
============================== */

app.use('/api/auth', authRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/gemini', geminiRoutes);
app.use('/api', chatRoutes);

/* ==============================
   Test Route
============================== */

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Hippocare Hospital Management Backend Running'
  });
});

/* ==============================
   Start Server
============================== */

const PORT = process.env.PORT || 5000;

app.listen(PORT, async () => {
  console.log(`🚀 Server running on port ${PORT}`);
  await testSupabaseConnection();
});