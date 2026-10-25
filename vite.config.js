import { defineConfig } from 'vite';

// base './' lets the build run from sub-paths (GitHub Pages) and inside Capacitor
export default defineConfig({
  base: './',
  server: { port: 5173, host: true },
});
