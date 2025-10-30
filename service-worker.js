// Service Worker for 统一启动器

// 使用带时间戳的缓存名称，方便更新
const CACHE_VERSION = 'v14'; // 更新此版本号以强制刷新缓存
const CACHE_NAME = `universal-launcher-${CACHE_VERSION}`;
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon.svg',
  '/icons/icon.png',
  './component/*'
];

// 安装Service Worker，预缓存静态资源
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('打开缓存');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => self.skipWaiting())
  );
});

// 激活Service Worker，清理旧缓存并通知客户端刷新
self.addEventListener('activate', (event) => {
  const cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheWhitelist.indexOf(cacheName) === -1) {
            console.log('删除旧缓存:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
    .then(() => {
      // 立即接管所有客户端
      return self.clients.claim();
    })
    .then(() => {
      // 通知所有已打开的客户端刷新页面以使用新版本
      return self.clients.matchAll().then((clients) => {
        clients.forEach((client) => {
          client.postMessage({
            type: 'CACHE_UPDATED',
            version: CACHE_VERSION
          });
        });
      });
    })
  );
});

// 处理请求，使用网络优先策略，确保获取最新内容
self.addEventListener('fetch', (event) => {
  // 对于跨域请求，不使用缓存
  if (!event.request.url.startsWith(self.location.origin)) {
    return fetch(event.request).catch(() => {
      // 跨域请求失败时，返回一个基本的离线页面或错误提示
      if (event.request.mode === 'navigate') {
        return caches.match('/');
      }
      return new Response('网络连接失败', {
        status: 408,
        headers: { 'Content-Type': 'text/plain' }
      });
    });
  }

  // 为导航请求（页面访问）使用网络优先策略
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          // 成功获取网络响应后，更新缓存
          const responseToCache = response.clone();
          caches.open(CACHE_NAME)
            .then((cache) => {
              cache.put(event.request, responseToCache);
            });
          return response;
        })
        .catch(() => {
          // 网络请求失败时，回退到缓存
          return caches.match(event.request) || caches.match('/');
        })
    );
    return;
  }

  // 对于其他请求，使用缓存优先但有条件刷新的策略
  event.respondWith(
    caches.match(event.request)
      .then((cachedResponse) => {
        // 发起网络请求尝试获取最新内容
        const fetchPromise = fetch(event.request)
          .then((networkResponse) => {
            // 检查响应是否有效
            if (!networkResponse || networkResponse.status !== 200 || networkResponse.type !== 'basic') {
              return networkResponse;
            }

            // 更新缓存
            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseToCache);
              });

            return networkResponse;
          })
          .catch(() => {
            // 网络请求失败且没有缓存时，返回一个基本错误
            return new Response('网络连接失败', {
              status: 408,
              headers: { 'Content-Type': 'text/plain' }
            });
          });

        // 如果有缓存，立即返回缓存内容，同时在后台更新缓存
        // 如果没有缓存，等待网络请求完成
        return cachedResponse || fetchPromise;
      })
  );
});

// 处理推送通知
self.addEventListener('push', (event) => {
  if (!event.data) return;

  const data = event.data.json();
  const options = {
    body: data.body || '有新消息',
    icon: '/icons/icon.png',
    badge: '/icons/icon.png',
    vibrate: [100, 50, 100],
    data: {
      url: data.url || '/'
    }
  };

  event.waitUntil(
    self.registration.showNotification(data.title || '统一启动器', options)
  );
});

// 点击通知时打开应用
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  event.waitUntil(
    clients.openWindow(event.notification.data.url)
  );
});