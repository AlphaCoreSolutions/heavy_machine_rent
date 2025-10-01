const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const APP = 'http://127.0.0.1:56294';
const API = 'https://sr.visioncit.com';
const PORT = 5173;

const app = express();

app.use('/', createProxyMiddleware({
    target: APP,
    changeOrigin: true,
    ws: true,
    autoRewrite: true,
    hostRewrite: '127.0.0.1:' + PORT,
    protocolRewrite: 'http',
    onProxyRes(proxyRes) {
        const loc = proxyRes.headers['location'];
        if (loc && (loc.includes('localhost:56294') || loc.includes('127.0.0.1:56294'))) {
            proxyRes.headers['location'] = loc
                .replace('localhost:56294', `127.0.0.1:${PORT}`)
                .replace('127.0.0.1:56294', `127.0.0.1:${PORT}`);
        }
    },
}));

app.use('/', createProxyMiddleware({ target: APP, changeOrigin: true, ws: true }));

app.listen(PORT, () => console.log(`Dev proxy http://127.0.0.1:${PORT}`));
