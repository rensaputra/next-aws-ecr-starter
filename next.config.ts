import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Emit a self-contained production build at .next/standalone for slim Docker images.
  output: "standalone",
};

export default nextConfig;
