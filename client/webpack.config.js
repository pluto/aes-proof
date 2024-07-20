const path = require("path");
const fs = require("fs");
const CopyPlugin = require("copy-webpack-plugin");

const dist = path.resolve(__dirname, "dist");

module.exports = {
  module: {
    rules: [
      {
        test: /\.m?js$/,
        resolve: {
          fullySpecified: false,
        },
      },
    ],
  },
  mode: "production",
  entry: {
    index: "./js/index.js",
  },
  output: {
    path: dist,
    filename: "[name].js",
  },
  devServer: {
    headers: {
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cross-Origin-Opener-Policy": "same-origin",
    },
    server: {
      type: "https",
      options: {
        key: fs.readFileSync("./certs/server-key.pem"),
        cert: fs.readFileSync("./certs/server-cert.pem"),
        ca: fs.readFileSync("./certs/ca-cert.pem"),
      },
    },
  },
  performance: {
    hints: false,
  },
  plugins: [
    new CopyPlugin([path.resolve(__dirname, "static")]),
  ],
};
