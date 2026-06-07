const CACHE_NAME = 'qr-scanner-v1';
const ASSETS = [
    '/premium-qr-scanner',
    '/premium-qr-scanner/index.html',
    '/premium-qr-scanner/manifest.json',
    '/premium-qr-scanner/icon.png',
    'https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js'
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => cache.addAll(ASSETS))
    );
});

self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request)
            .then((response) => response || fetch(event.request))
    );
});
