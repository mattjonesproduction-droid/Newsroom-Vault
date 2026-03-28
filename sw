const CACHE = ‘newsroomvault-v1’;
const SHELL = [
‘/’,
‘/index.html’,
‘/manifest.json’,
‘/icon-192.svg’,
‘/icon-512.svg’,
];

// Install: cache the app shell
self.addEventListener(‘install’, e => {
e.waitUntil(
caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())
);
});

// Activate: clean up old caches
self.addEventListener(‘activate’, e => {
e.waitUntil(
caches.keys().then(keys =>
Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
).then(() => self.clients.claim())
);
});

// Fetch: serve from cache first, fall back to network
// Archive.org requests always go to network (no caching — they’re streaming video)
self.addEventListener(‘fetch’, e => {
const url = e.request.url;

// Never cache archive.org or external requests — always fetch live
if(url.includes(‘archive.org’) || url.includes(‘googleapis.com’)){
e.respondWith(fetch(e.request).catch(() => new Response(’’, {status: 503})));
return;
}

// App shell: cache-first
e.respondWith(
caches.match(e.request).then(cached => cached || fetch(e.request).then(res => {
// Cache any successful same-origin responses
if(res.ok && e.request.url.startsWith(self.location.origin)){
const clone = res.clone();
caches.open(CACHE).then(c => c.put(e.request, clone));
}
return res;
}))
);
});
