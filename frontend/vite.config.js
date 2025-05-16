// vite.config.js
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      // Proxy WebSocket requests starting with /ws
      "/ws": {
        target: "ws://localhost:8000",
        ws: true,
      },
    },
  },
});
