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
