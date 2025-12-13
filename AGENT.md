# BMI Health Tracker - Multiple EC2 3-Tier Deployment

**⚠️ IMPORTANT: This file contains EVERYTHING needed to deploy the application across multiple EC2 instances!**

---

## Overview

A full-stack 3-tier web application for tracking Body Mass Index (BMI), Basal Metabolic Rate (BMR), and daily calorie requirements. This version is specifically designed for deployment across **three separate Ubuntu EC2 instances** in AWS.

**Deployment Architecture**: 3 EC2 Instances (Frontend + Backend + Database)

---

## Architecture

### Multi-EC2 3-Tier Structure

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │  Public Subnet │
                    │                │
        ┌───────────▼────────────┐   │
        │   FRONTEND EC2         │   │
        │   - Nginx (Port 80)    │   │
        │   - React App (dist)   │   │
        │   - Public IP/Domain   │   │
        └───────────┬────────────┘   │
                    │                 │
                    │ HTTP API        │
                    │ Calls           │
                    │                 │
        ┌───────────▼────────────┐   │
        │  Private Subnet 1       │   │
        │                         │   │
        │   BACKEND EC2           │   │
        │   - Node.js/Express     │   │
        │   - PM2 (Port 3000)     │   │
        │   - Private IP only     │   │
        └───────────┬─────────────┘   │
                    │                  │
                    │ PostgreSQL       │
                    │ Queries          │
                    │                  │
        ┌───────────▼─────────────┐   │
        │  Private Subnet 2        │   │
        │                          │   │
        │   DATABASE EC2           │   │
        │   - PostgreSQL (5432)    │   │
        │   - Private IP only      │   │
        └──────────────────────────┘   │
                                       │
└───────────────────────────────────────┘
```

### EC2 Instances

1. **Frontend EC2 (Public Subnet)**
   - Nginx web server serving React static files
   - Proxies API requests to Backend EC2
   - Has public IP/Elastic IP for internet access
   - Security Group: Allow 80, 443 from internet; 22 from admin

2. **Backend EC2 (Private Subnet)**
   - Node.js Express API server
   - PM2 process manager
   - Connects to Database EC2 via private IP
   - Security Group: Allow 3000 from Frontend SG; 22 from bastion/admin

3. **Database EC2 (Private Subnet)**
   - PostgreSQL database server
   - Configured for remote connections
   - Only accessible from Backend EC2
   - Security Group: Allow 5432 from Backend SG; 22 from bastion/admin

---

## Complete Directory Structure

```
multiple-ec2-3tier-webapp/
│
├── AGENT.md (this file)
├── README.md
├── DEPLOYMENT_GUIDE.md
│
├── frontend-ec2/
│   ├── src/
│   │   ├── components/
│   │   │   ├── MeasurementForm.jsx
│   │   │   └── TrendChart.jsx
│   │   ├── App.jsx
│   │   ├── main.jsx
│   │   ├── api.js
│   │   └── index.css
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   ├── .env.example
│   ├── .gitignore
│   ├── nginx.conf
│   └── deploy-frontend.sh
│
├── backend-ec2/
│   ├── src/
│   │   ├── server.js
│   │   ├── routes.js
│   │   ├── db.js
│   │   └── calculations.js
│   ├── package.json
│   ├── ecosystem.config.js
│   ├── .env.example
│   ├── .gitignore
│   └── deploy-backend.sh
│
└── database-ec2/
    ├── migrations/
    │   └── 001_create_measurements.sql
    ├── setup-database.sh
    └── DATABASE_CONFIG.md
```

---

## Tech Stack

### Frontend EC2
- **Web Server**: Nginx 1.18+
- **Framework**: React 18.2
- **Build Tool**: Vite 5.0
- **HTTP Client**: Axios 1.4
- **Charts**: Chart.js 4.4 + react-chartjs-2 5.2

### Backend EC2
- **Runtime**: Node.js 18+ LTS (via NVM)
- **Framework**: Express.js 4.18
- **Database Client**: pg (node-postgres) 8.10
- **Process Manager**: PM2
- **Middleware**: CORS, body-parser, dotenv

### Database EC2
- **Database**: PostgreSQL 14+
- **Authentication**: MD5
- **Network**: Configured for remote access

---

## Complete File Contents

### Frontend EC2 Files

#### frontend-ec2/package.json
```json
{
  "name": "bmi-health-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.4.0",
    "chart.js": "^4.4.0",
    "react-chartjs-2": "^5.2.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "@vitejs/plugin-react": "^4.2.0"
  }
}
```

#### frontend-ec2/vite.config.js
```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Backend API server URL - Update this with your Backend EC2 IP address
const BACKEND_API_URL = process.env.VITE_BACKEND_URL || 'http://BACKEND_EC2_IP:3000';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: BACKEND_API_URL,
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'terser'
  }
});
```

#### frontend-ec2/.env.example
```env
# Backend API URL (IP address of Backend EC2 instance)
VITE_BACKEND_URL=http://BACKEND_EC2_IP:3000
```

#### frontend-ec2/index.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="BMI and Health Tracker - Track your Body Mass Index, BMR, and daily calorie needs" />
  <title>BMI & Health Tracker</title>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
```

#### frontend-ec2/src/main.jsx
```javascript
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

createRoot(document.getElementById('root')).render(<App />);
```

#### frontend-ec2/src/api.js
```javascript
import axios from 'axios';

// Backend API base URL - will use proxy in development or direct URL in production
const api = axios.create({
  baseURL: import.meta.env.PROD 
    ? `${import.meta.env.VITE_BACKEND_URL}/api` 
    : '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor
api.interceptors.request.use(
  config => {
    return config;
  },
  error => {
    console.error('Request error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response) {
      console.error('API Error:', error.response.status, error.response.data);
    } else if (error.request) {
      console.error('Network Error: No response from server');
    } else {
      console.error('Error:', error.message);
    }
    return Promise.reject(error);
  }
);

export default api;
```

#### frontend-ec2/src/App.jsx
```javascript
import React, { useEffect, useState } from 'react';
import MeasurementForm from './components/MeasurementForm';
import TrendChart from './components/TrendChart';
import api from './api';

export default function App() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.get('/measurements');
      setRows(r.data.rows);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load measurements');
    } finally {
      setLoading(false);
    }
  };
  
  useEffect(() => { load() }, []);
  
  const latestMeasurement = rows[0];
  const totalMeasurements = rows.length;
  
  return (
    <>
      <header className="app-header">
        <h1>BMI & Health Tracker</h1>
        <p className="app-subtitle">Track your health metrics and reach your fitness goals</p>
      </header>

      <div className="container">
        <div className="card">
          <div className="card-header">
            <h2>📝 Add New Measurement</h2>
          </div>
          <MeasurementForm onSaved={load} />
        </div>

        {latestMeasurement && (
          <div className="stats-grid">
            <div className="stat-card">
              <span className="stat-value">{latestMeasurement.bmi}</span>
              <span className="stat-label">Current BMI</span>
            </div>
            <div className="stat-card" style={{ background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)' }}>
              <span className="stat-value">{latestMeasurement.bmr}</span>
              <span className="stat-label">BMR (cal)</span>
            </div>
            <div className="stat-card" style={{ background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)' }}>
              <span className="stat-value">{latestMeasurement.daily_calories}</span>
              <span className="stat-label">Daily Calories</span>
            </div>
            <div className="stat-card" style={{ background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)' }}>
              <span className="stat-value">{totalMeasurements}</span>
              <span className="stat-label">Total Records</span>
            </div>
          </div>
        )}

        <div className="card">
          <div className="card-header">
            <h2>📋 Recent Measurements</h2>
          </div>
          {error && <div className="alert alert-error">{error}</div>}
          {loading ? (
            <div className="loading">Loading your data</div>
          ) : (
            <ul className="measurements-list">
              {rows.length === 0 ? (
                <div className="empty-state">
                  <p>No measurements yet. Add your first one above!</p>
                </div>
              ) : (
                rows.slice(0, 10).map(r => (
                  <li key={r.id} className="measurement-item">
                    <span className="measurement-date">
                      {new Date(r.created_at).toLocaleDateString('en-US', { 
                        month: 'short', day: 'numeric', year: 'numeric' 
                      })}
                    </span>
                    <div className="measurement-data">
                      <span className="measurement-badge badge-bmi">
                        BMI: <strong>{r.bmi}</strong> ({r.bmi_category})
                      </span>
                      <span className="measurement-badge badge-bmr">
                        BMR: <strong>{r.bmr}</strong> cal
                      </span>
                      <span className="measurement-badge badge-calories">
                        Daily: <strong>{r.daily_calories}</strong> cal
                      </span>
                    </div>
                  </li>
                ))
              )}
            </ul>
          )}
        </div>

        <div className="card">
          <div className="card-header">
            <h2>📈 30-Day BMI Trend</h2>
          </div>
          <div className="chart-container">
            <TrendChart />
          </div>
        </div>
      </div>
    </>
  );
}
```

#### frontend-ec2/src/components/MeasurementForm.jsx
```javascript
import React, { useState } from 'react';
import api from '../api';

export default function MF({ onSaved }) {
  const [f, sf] = useState({ weightKg: 70, heightCm: 175, age: 30, sex: 'male', activity: 'moderate' });
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);
  
  const sub = async e => {
    e.preventDefault();
    setError(null);
    setSuccess(false);
    setLoading(true);
    try {
      await api.post('/measurements', f);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
      onSaved && onSaved();
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to save measurement');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <form onSubmit={sub}>
      {error && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-success">Measurement saved successfully!</div>}
      
      <div className="form-row">
        <div className="form-group">
          <label htmlFor="weight">Weight (kg)</label>
          <input 
            id="weight"
            type="number" 
            value={f.weightKg} 
            onChange={e => sf({ ...f, weightKg: +e.target.value })}
            required min="1" max="500" step="0.1" placeholder="70"
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="height">Height (cm)</label>
          <input 
            id="height"
            type="number"
            value={f.heightCm} 
            onChange={e => sf({ ...f, heightCm: +e.target.value })}
            required min="1" max="300" step="0.1" placeholder="175"
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="age">Age (years)</label>
          <input 
            id="age"
            type="number"
            value={f.age} 
            onChange={e => sf({ ...f, age: +e.target.value })}
            required min="1" max="150" placeholder="30"
          />
        </div>
      </div>
      
      <div className="form-row">
        <div className="form-group">
          <label htmlFor="sex">Biological Sex</label>
          <select 
            id="sex"
            value={f.sex} 
            onChange={e => sf({ ...f, sex: e.target.value })}
            required
          >
            <option value="male">Male</option>
            <option value="female">Female</option>
          </select>
        </div>
        
        <div className="form-group">
          <label htmlFor="activity">Activity Level</label>
          <select 
            id="activity"
            value={f.activity} 
            onChange={e => sf({ ...f, activity: e.target.value })}
            required
          >
            <option value="sedentary">Sedentary (Little/No Exercise)</option>
            <option value="light">Light (1-3 days/week)</option>
            <option value="moderate">Moderate (3-5 days/week)</option>
            <option value="active">Active (6-7 days/week)</option>
            <option value="very_active">Very Active (2x per day)</option>
          </select>
        </div>
      </div>
      
      <button type="submit" disabled={loading}>
        {loading ? '⏳ Saving...' : '✓ Save Measurement'}
      </button>
    </form>
  );
}
```

#### frontend-ec2/src/components/TrendChart.jsx
```javascript
import React, { useEffect, useState } from 'react';
import { Line } from 'react-chartjs-2';
import api from '../api';
import { Chart as C, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js';

C.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

export default function TC() {
  const [d, sd] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    setLoading(true);
    api.get('/measurements/trends')
      .then(r => {
        const rows = r.data.rows;
        if (rows && rows.length > 0) {
          sd({
            labels: rows.map(x => new Date(x.day).toLocaleDateString()),
            datasets: [{
              label: 'Average BMI',
              data: rows.map(x => parseFloat(x.avg_bmi)),
              borderColor: 'rgb(75, 192, 192)',
              backgroundColor: 'rgba(75, 192, 192, 0.2)',
              tension: 0.1
            }]
          });
        } else {
          setError(null);
        }
      })
      .catch(err => {
        console.error('Failed to load trends:', err);
        setError('Failed to load trend data');
      })
      .finally(() => setLoading(false));
  }, []);
  
  if (loading) return <div className="loading">Loading chart</div>;
  if (error) return <div className="alert alert-error">{error}</div>;
  if (!d) return <div className="empty-state"><p>No trend data available yet. Add measurements over multiple days to see trends!</p></div>;
  
  return <Line data={d} options={{
    responsive: true,
    plugins: {
      legend: { position: 'top' },
      title: { display: true, text: '30-Day BMI Trend' }
    }
  }} />;
}
```

#### frontend-ec2/src/index.css
```css
:root {
  --primary: #4f46e5;
  --primary-dark: #4338ca;
  --primary-light: #818cf8;
  --secondary: #10b981;
  --danger: #ef4444;
  --warning: #f59e0b;
  --gray-50: #f9fafb;
  --gray-100: #f3f4f6;
  --gray-200: #e5e7eb;
  --gray-300: #d1d5db;
  --gray-600: #4b5563;
  --gray-700: #374151;
  --gray-800: #1f2937;
  --gray-900: #111827;
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  color: var(--gray-800);
  line-height: 1.6;
}

.app-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  padding: 1.5rem 0;
  box-shadow: var(--shadow-md);
  margin-bottom: 2rem;
  border-bottom: 3px solid var(--primary);
}

.app-header h1 {
  color: var(--primary);
  font-size: 2.5rem;
  font-weight: 700;
  text-align: center;
  margin: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
}

.app-header h1::before { content: "💪"; font-size: 2.5rem; }

.app-subtitle {
  text-align: center;
  color: var(--gray-600);
  font-size: 1rem;
  margin-top: 0.5rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1.5rem 3rem;
}

.card {
  background: white;
  border-radius: 16px;
  padding: 2rem;
  box-shadow: var(--shadow-lg);
  margin-bottom: 2rem;
  transition: transform 0.2s, box-shadow 0.2s;
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
}

.card-header {
  border-bottom: 2px solid var(--gray-100);
  padding-bottom: 1rem;
  margin-bottom: 1.5rem;
}

.card-header h2 {
  color: var(--gray-800);
  font-size: 1.5rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

form { display: grid; gap: 1.5rem; }

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
}

.form-group { display: flex; flex-direction: column; gap: 0.5rem; }

label {
  font-weight: 600;
  color: var(--gray-700);
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

input, select {
  padding: 0.75rem 1rem;
  border: 2px solid var(--gray-200);
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.2s;
  background: var(--gray-50);
  font-family: inherit;
}

input:focus, select:focus {
  outline: none;
  border-color: var(--primary);
  background: white;
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
}

input:hover, select:hover { border-color: var(--gray-300); }

button {
  padding: 0.875rem 2rem;
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: var(--shadow);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
  background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
}

button:active:not(:disabled) { transform: translateY(0); }
button:disabled { opacity: 0.6; cursor: not-allowed; }

.alert {
  padding: 1rem 1.25rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-weight: 500;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

.alert-error {
  background-color: #fef2f2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

.alert-error::before { content: "⚠️"; font-size: 1.25rem; }

.alert-success {
  background-color: #f0fdf4;
  color: #166534;
  border: 1px solid #bbf7d0;
}

.alert-success::before { content: "✓"; font-size: 1.25rem; font-weight: bold; }

.loading {
  text-align: center;
  padding: 3rem;
  color: var(--gray-600);
}

.loading::after {
  content: "";
  display: inline-block;
  width: 2rem;
  height: 2rem;
  border: 3px solid var(--gray-200);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-left: 1rem;
  vertical-align: middle;
}

@keyframes spin { to { transform: rotate(360deg); } }

.measurements-list { list-style: none; display: grid; gap: 1rem; }

.measurement-item {
  background: var(--gray-50);
  padding: 1.25rem;
  border-radius: 10px;
  border-left: 4px solid var(--primary);
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 1rem;
  align-items: center;
  transition: all 0.2s;
}

.measurement-item:hover {
  background: white;
  box-shadow: var(--shadow-md);
  transform: translateX(4px);
}

.measurement-date {
  font-weight: 600;
  color: var(--primary);
  font-size: 0.875rem;
}

.measurement-data {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
  align-items: center;
}

.measurement-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.375rem 0.75rem;
  background: white;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 600;
  box-shadow: var(--shadow-sm);
}

.badge-bmi { color: var(--primary); }
.badge-bmr { color: #f59e0b; }
.badge-calories { color: var(--secondary); }

.empty-state {
  text-align: center;
  padding: 3rem;
  color: var(--gray-600);
  background: var(--gray-50);
  border-radius: 12px;
  border: 2px dashed var(--gray-300);
}

.empty-state::before {
  content: "📊";
  display: block;
  font-size: 3rem;
  margin-bottom: 1rem;
}

.chart-container {
  padding: 1.5rem;
  background: var(--gray-50);
  border-radius: 12px;
  min-height: 300px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.stat-card {
  background: linear-gradient(135deg, var(--primary-light) 0%, var(--primary) 100%);
  color: white;
  padding: 1.5rem;
  border-radius: 12px;
  text-align: center;
  box-shadow: var(--shadow);
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  display: block;
  margin-bottom: 0.25rem;
}

.stat-label {
  font-size: 0.875rem;
  opacity: 0.9;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

@media (max-width: 768px) {
  .app-header h1 { font-size: 2rem; }
  .card { padding: 1.5rem; }
  .form-row { grid-template-columns: 1fr; }
  .measurement-item { grid-template-columns: 1fr; text-align: center; }
  .measurement-data { justify-content: center; }
}

@media (max-width: 480px) {
  .container { padding: 0 1rem 2rem; }
  .card { padding: 1rem; border-radius: 12px; }
}
```

---

### Backend EC2 Files

#### backend-ec2/package.json
```json
{
  "name": "bmi-health-backend",
  "version": "1.0.0",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.0.0",
    "express": "^4.18.2",
    "pg": "^8.10.0",
    "body-parser": "^1.20.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

#### backend-ec2/src/server.js
```javascript
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// CORS configuration - Allow requests from Frontend EC2
const corsOptions = {
  origin: NODE_ENV === 'production' 
    ? process.env.FRONTEND_URL || '*'
    : ['http://localhost:5173', 'http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
app.use(bodyParser.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    environment: NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

// API routes
app.use('/api', routes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server - Listen on all interfaces for EC2
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Environment: ${NODE_ENV}`);
  console.log(`🔗 API available at: http://0.0.0.0:${PORT}/api`);
});
```

#### backend-ec2/.env.example
```env
# Backend Environment Variables
PORT=3000
NODE_ENV=production

# Database EC2 Connection String
# Format: postgresql://username:password@database-ec2-private-ip:5432/database_name
DATABASE_URL=postgresql://bmi_user:YOUR_PASSWORD@DATABASE_EC2_PRIVATE_IP:5432/bmidb

# Frontend EC2 URL (for CORS)
# Use Frontend EC2 Public IP or Domain
FRONTEND_URL=http://FRONTEND_EC2_PUBLIC_IP
```

#### backend-ec2/src/routes.js
```javascript
const express = require('express');
const router = express.Router();
const db = require('./db');
const { calculateMetrics } = require('./calculations');

// POST /api/measurements - Create new measurement
router.post('/measurements', async (req, res) => {
  try {
    const { weightKg, heightCm, age, sex, activity } = req.body;
    
    if (!weightKg || !heightCm || !age || !sex) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
      return res.status(400).json({ error: 'Invalid values: must be positive numbers' });
    }
    
    const m = calculateMetrics({ weightKg, heightCm, age, sex, activity });
    const q = `INSERT INTO measurements (weight_kg,height_cm,age,sex,activity_level,bmi,bmi_category,bmr,daily_calories,created_at)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,now()) RETURNING *`;
    const v = [weightKg, heightCm, age, sex, activity, m.bmi, m.bmiCategory, m.bmr, m.dailyCalories];
    const r = await db.query(q, v);
    res.status(201).json({ measurement: r.rows[0] });
  } catch (e) {
    console.error('Error creating measurement:', e);
    res.status(500).json({ error: e.message || 'Failed to create measurement' });
  }
});

// GET /api/measurements - Get all measurements
router.get('/measurements', async (req, res) => {
  try {
    const r = await db.query('SELECT * FROM measurements ORDER BY created_at DESC');
    res.json({ rows: r.rows });
  } catch (e) {
    console.error('Error fetching measurements:', e);
    res.status(500).json({ error: 'Failed to fetch measurements' });
  }
});

// GET /api/measurements/trends - Get 30-day BMI trends
router.get('/measurements/trends', async (req, res) => {
  try {
    const q = `SELECT date_trunc('day',created_at) AS day, AVG(bmi) AS avg_bmi 
    FROM measurements
    WHERE created_at > now() - interval '30 days' 
    GROUP BY day 
    ORDER BY day`;
    const r = await db.query(q);
    res.json({ rows: r.rows });
  } catch (e) {
    console.error('Error fetching trends:', e);
    res.status(500).json({ error: 'Failed to fetch trends' });
  }
});

module.exports = router;
```

#### backend-ec2/src/db.js
```javascript
const { Pool } = require('pg');

// PostgreSQL connection pool configuration
// Connects to Database EC2 instance
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Handle pool errors
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle PostgreSQL client:', err);
  process.exit(-1);
});

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Database connection failed:', err.message);
    console.error('Make sure Database EC2 is running and accessible');
    process.exit(1);
  } else {
    console.log('✅ Database connected successfully at:', res.rows[0].now);
  }
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool
};
```

#### backend-ec2/src/calculations.js
```javascript
function bmiCategory(b) {
  if (b < 18.5) return 'Underweight';
  if (b < 25) return 'Normal';
  if (b < 30) return 'Overweight';
  return 'Obese';
}

function calculateMetrics({ weightKg, heightCm, age, sex, activity }) {
  const h = heightCm / 100;
  const bmi = +(weightKg / (h * h)).toFixed(1);
  
  let bmr = sex === 'male'
    ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
    : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  
  const mult = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    very_active: 1.9
  }[activity] || 1.2;
  
  return {
    bmi,
    bmiCategory: bmiCategory(bmi),
    bmr: Math.round(bmr),
    dailyCalories: Math.round(bmr * mult)
  };
}

module.exports = { calculateMetrics };
```

#### backend-ec2/ecosystem.config.js
```javascript
module.exports = {
  apps: [{
    name: 'bmi-backend',
    script: './src/server.js',
    cwd: '/home/ubuntu/backend-ec2',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
```

---

### Frontend EC2 Configuration Files

#### frontend-ec2/nginx.conf
```nginx
# Nginx Configuration for BMI Health Tracker Frontend
# File: /etc/nginx/sites-available/bmi-frontend

server {
    listen 80;
    server_name YOUR_FRONTEND_DOMAIN_OR_IP;

    root /var/www/bmi-health-tracker;
    index index.html;

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to Backend EC2
    location /api/ {
        proxy_pass http://BACKEND_EC2_PRIVATE_IP:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Logging
    access_log /var/log/nginx/bmi-frontend-access.log;
    error_log /var/log/nginx/bmi-frontend-error.log;
}
```

---

### Database EC2 Files

#### database-ec2/migrations/001_create_measurements.sql
```sql
-- BMI Health Tracker Database Migration
-- Version: 001
-- Description: Create measurements table
-- Date: 2025-12-13

-- Create measurements table
CREATE TABLE IF NOT EXISTS measurements (
  id SERIAL PRIMARY KEY,
  weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg > 0 AND weight_kg < 1000),
  height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm > 0 AND height_cm < 300),
  age INTEGER NOT NULL CHECK (age > 0 AND age < 150),
  sex VARCHAR(10) NOT NULL CHECK (sex IN ('male', 'female')),
  activity_level VARCHAR(30) CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  bmi NUMERIC(4,1) NOT NULL,
  bmi_category VARCHAR(30),
  bmr INTEGER,
  daily_calories INTEGER,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_measurements_created_at ON measurements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_measurements_bmi ON measurements(bmi);

-- Add comments for documentation
COMMENT ON TABLE measurements IS 'Stores user health measurements including BMI, BMR, and calorie data';

-- Display confirmation
SELECT 'Migration 001 completed successfully - measurements table created' AS status;
```

---

## Deployment Order

**IMPORTANT**: Deploy in this exact order:

1. **Database EC2** - Setup PostgreSQL first
2. **Backend EC2** - Configure to connect to Database
3. **Frontend EC2** - Configure to connect to Backend

---

## Step-by-Step Deployment Guide

### Prerequisites

- AWS Account with EC2 access
- 3 Ubuntu EC2 instances (t2.micro or larger)
- VPC with public and private subnets configured
- Security Groups properly configured
- SSH key pair for EC2 access

### Step 1: Database EC2 Setup

1. **Launch Database EC2**:
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: t2.micro (min)
   - Subnet: Private Subnet
   - Security Group: Allow 5432 from Backend SG, 22 from admin

2. **Connect via SSH**:
   ```bash
   ssh -i your-key.pem ubuntu@DATABASE_EC2_IP
   ```

3. **Upload files**:
   ```bash
   scp -i your-key.pem -r database-ec2/ ubuntu@DATABASE_EC2_IP:~/
   ```

4. **Run setup script**:
   ```bash
   cd database-ec2
   chmod +x setup-database.sh
   ./setup-database.sh
   ```

5. **Note the connection string** provided at the end

### Step 2: Backend EC2 Setup

1. **Launch Backend EC2**:
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: t2.micro (min)
   - Subnet: Private Subnet
   - Security Group: Allow 3000 from Frontend SG, 22 from admin, 5432 outbound to Database SG

2. **Connect via SSH**:
   ```bash
   ssh -i your-key.pem ubuntu@BACKEND_EC2_IP
   ```

3. **Upload files**:
   ```bash
   scp -i your-key.pem -r backend-ec2/ ubuntu@BACKEND_EC2_IP:~/
   ```

4. **Configure environment**:
   ```bash
   cd backend-ec2
   cp .env.example .env
   nano .env
   # Update DATABASE_URL with Database EC2 private IP and password
   # Update FRONTEND_URL with Frontend EC2 public IP
   ```

5. **Run deployment script**:
   ```bash
   chmod +x deploy-backend.sh
   ./deploy-backend.sh
   ```

### Step 3: Frontend EC2 Setup

1. **Launch Frontend EC2**:
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: t2.micro (min)
   - Subnet: Public Subnet
   - Assign/Associate Elastic IP
   - Security Group: Allow 80, 443 from internet, 22 from admin, 3000 outbound to Backend SG

2. **Connect via SSH**:
   ```bash
   ssh -i your-key.pem ubuntu@FRONTEND_EC2_PUBLIC_IP
   ```

3. **Upload files**:
   ```bash
   scp -i your-key.pem -r frontend-ec2/ ubuntu@FRONTEND_EC2_PUBLIC_IP:~/
   ```

4. **Configure environment**:
   ```bash
   cd frontend-ec2
   cp .env.example .env
   nano .env
   # Update VITE_BACKEND_URL with Backend EC2 private IP
   ```

5. **Run deployment script**:
   ```bash
   chmod +x deploy-frontend.sh
   ./deploy-frontend.sh
   ```

---

## Security Groups Configuration

### Frontend EC2 Security Group

**Inbound Rules**:
- Type: HTTP, Port: 80, Source: 0.0.0.0/0
- Type: HTTPS, Port: 443, Source: 0.0.0.0/0
- Type: SSH, Port: 22, Source: YOUR_IP

**Outbound Rules**:
- Type: Custom TCP, Port: 3000, Destination: Backend SG
- Type: HTTP/HTTPS, Port: 80/443, Destination: 0.0.0.0/0

### Backend EC2 Security Group

**Inbound Rules**:
- Type: Custom TCP, Port: 3000, Source: Frontend SG
- Type: SSH, Port: 22, Source: YOUR_IP

**Outbound Rules**:
- Type: PostgreSQL, Port: 5432, Destination: Database SG
- Type: HTTP/HTTPS, Port: 80/443, Destination: 0.0.0.0/0 (for package installation)

### Database EC2 Security Group

**Inbound Rules**:
- Type: PostgreSQL, Port: 5432, Source: Backend SG
- Type: SSH, Port: 22, Source: YOUR_IP

**Outbound Rules**:
- Type: All traffic, Destination: 0.0.0.0/0 (or restrict as needed)

---

## Testing and Verification

### Test Database EC2
```bash
# From Database EC2
sudo systemctl status postgresql
psql -U bmi_user -d bmidb -h localhost -c "SELECT 1"
```

### Test Backend EC2
```bash
# From Backend EC2
curl http://localhost:3000/health
pm2 status
pm2 logs bmi-backend

# Test database connection
psql postgresql://bmi_user:PASSWORD@DATABASE_PRIVATE_IP:5432/bmidb -c "SELECT 1"
```

### Test Frontend EC2
```bash
# From Frontend EC2
sudo nginx -t
sudo systemctl status nginx
curl http://localhost

# Check API proxy
curl http://localhost/api/measurements
```

### End-to-End Test
1. Open browser: `http://FRONTEND_EC2_PUBLIC_IP`
2. Add a measurement
3. Verify it appears in the list
4. Check the 30-day trend chart

---

## Monitoring and Logs

### Frontend EC2
```bash
# Nginx access logs
sudo tail -f /var/log/nginx/bmi-frontend-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/bmi-frontend-error.log
```

### Backend EC2
```bash
# PM2 logs
pm2 logs bmi-backend

# PM2 monitoring
pm2 monit
```

### Database EC2
```bash
# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*-main.log

# Active connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity WHERE datname = 'bmidb'"
```

---

## Troubleshooting

### Frontend cannot reach Backend

**Check**:
1. Backend EC2 is running: `pm2 status`
2. Security Group allows Frontend → Backend on port 3000
3. Nginx proxy configuration has correct Backend IP
4. Test from Frontend EC2: `curl http://BACKEND_PRIVATE_IP:3000/health`

### Backend cannot reach Database

**Check**:
1. Database EC2 PostgreSQL is running
2. Security Group allows Backend → Database on port 5432
3. DATABASE_URL in backend .env is correct
4. Test from Backend EC2: `psql $DATABASE_URL -c "SELECT 1"`

### Application not accessible from internet

**Check**:
1. Frontend EC2 has Elastic IP assigned
2. Security Group allows HTTP (80) from 0.0.0.0/0
3. Nginx is running: `sudo systemctl status nginx`
4. Firewall allows port 80: `sudo ufw status`

---

## Cost Optimization

### AWS Free Tier
- 3 × t2.micro instances: Free for 750 hours/month (first year)
- Total: Under $20/month after free tier

### Recommendations
1. Use Reserved Instances for long-term deployments
2. Stop instances when not in use (development)
3. Use Elastic IPs wisely (charged when unassociated)
4. Monitor CloudWatch for usage patterns

---

## Scaling Considerations

### Horizontal Scaling
- Add Load Balancer for Frontend EC2
- Deploy multiple Backend EC2 instances
- Use RDS PostgreSQL instead of EC2 for database

### Vertical Scaling
- Upgrade instance types (t2.small → t2.medium)
- Increase PM2 instances for Backend
- Tune PostgreSQL configuration

---

## Backup and Recovery

### Database Backup
```bash
# On Database EC2
pg_dump -U bmi_user -d bmidb > backup_$(date +%Y%m%d).sql

# Store in S3
aws s3 cp backup_$(date +%Y%m%d).sql s3://your-bucket/backups/
```

### Automated Backups
Create a cron job on Database EC2:
```bash
crontab -e
# Add: 0 2 * * * /path/to/backup-script.sh
```

---

## Security Best Practices

1. ✅ Database in private subnet (no internet access)
2. ✅ Backend in private subnet
3. ✅ Strong database passwords
4. ✅ Security Groups with principle of least privilege
5. ✅ Regular security updates: `sudo apt update && sudo apt upgrade`
6. ✅ Use IAM roles instead of access keys where possible
7. ✅ Enable CloudWatch logging
8. ✅ Regular backups

---

**Last Updated**: December 13, 2025  
**Version**: 1.0 - Multi-EC2 3-Tier Architecture  
**Status**: ✅ Production Ready
