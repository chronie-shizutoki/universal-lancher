// 安装PWA提示

  // 存储安装事件
  let deferredPrompt;
  let installAttempts = 0;
  const MAX_INSTALL_ATTEMPTS = 3;
  
  // 声明DOM元素变量
  let installPrompt, installBtn, closeInstallBtn;

  // 检测是否在PWA模式下运行
  function isPwaMode() {
    return window.matchMedia('(display-mode: standalone)').matches || 
           window.navigator.standalone ||
           document.referrer.includes('android-app://') ||
           (window.navigator).standalone === true;
  }

  // 检查是否已经安装
  window.addEventListener('DOMContentLoaded', () => {
    // 获取DOM元素
    installPrompt = document.getElementById('installPrompt');
    installBtn = document.getElementById('installBtn');
    closeInstallBtn = document.getElementById('closeInstallBtn');
    
    // 如果是在独立模式下运行，隐藏安装提示
    if (isPwaMode()) {
      // 找到Safari安装指南并隐藏它
      const safariGuide = document.querySelector('.safari-install-guide');
      if (safariGuide) {
        safariGuide.style.display = 'none';
      }
      if (installPrompt) {
        installPrompt.style.display = 'none';
      }
    }
    
    // 处理快捷方式URL参数
    handleShortcuts();
    
    // 绑定安装按钮点击事件
    if (installBtn) {
      installBtn.addEventListener('click', async () => {
        if (!deferredPrompt) {
          console.log('安装提示不可用，请参考安装指南手动安装');
          return;
        }
        
        console.log('触发安装提示');
        
        try {
          // 显示安装提示
          deferredPrompt.prompt();
          // 等待用户响应
          const { outcome } = await deferredPrompt.userChoice;
          console.log(`用户${outcome === 'accepted' ? '接受' : '拒绝'}了安装`);
          
          // 无论结果如何，重置deferredPrompt变量
          deferredPrompt = null;
          // 隐藏提示
          if (installPrompt) {
            installPrompt.style.display = 'none';
          }
          
          if (outcome === 'accepted') {
            console.log('PWA已成功安装');
          } else {
            // 用户拒绝后增加尝试计数
            installAttempts++;
            if (installAttempts < MAX_INSTALL_ATTEMPTS) {
              // 稍后再次尝试显示安装提示
              setTimeout(() => {
                if (installPrompt) {
                  installPrompt.style.display = 'block';
                }
              }, 10000); // 10秒后重试
            }
          }
        } catch (error) {
          console.error('安装提示失败:', error);
        }
      });
    }
    
    // 绑定关闭按钮点击事件
    if (closeInstallBtn) {
      closeInstallBtn.addEventListener('click', () => {
        if (installPrompt) {
          installPrompt.style.display = 'none';
        }
        installAttempts++;
        
        if (installAttempts < MAX_INSTALL_ATTEMPTS) {
          setTimeout(() => {
            if (installPrompt) {
              installPrompt.style.display = 'block';
            }
          }, 20000); // 20秒后重试
        }
      });
    }
  });

  // 监听beforeinstallprompt事件
  window.addEventListener('beforeinstallprompt', (e) => {
    console.log('捕获到安装提示事件');
    // 阻止Chrome自动显示安装提示
    e.preventDefault();
    // 存储事件以便稍后触发
    deferredPrompt = e;
    // 显示自定义安装按钮
    if (installPrompt) {
      installPrompt.style.display = 'block';
    }
  });

  // 检查是否已经安装
  window.addEventListener('appinstalled', (evt) => {
    console.log('应用已安装');
    if (installPrompt) {
      installPrompt.style.display = 'none';
    }
  });

  // 检查是否可安装并显示提示
  function checkInstallability() {
    // 检查是否在独立模式下运行（已安装）
    if (isPwaMode()) {
      console.log('应用已在PWA模式下运行');
      if (installPrompt) {
        installPrompt.style.display = 'none';
      }
    }
  }
  
  // 监听页面可见性变化
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) {
      checkInstallability();
    }
  });
  
  // 增强的PWA安装检测逻辑
  function detectInstallState() {
    // 延迟检查是否可以触发安装提示
    setTimeout(() => {
      if (!isPwaMode() && !deferredPrompt) {
        console.log('Android Chrome可能需要用户交互才能显示安装提示');
      }
    }, 2000);
  }
  
  // 立即执行安装状态检测
  detectInstallState();
  
  // 注册Service Worker
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      // 使用相对路径确保兼容性
      navigator.serviceWorker.register('./service-worker.js')
        .then(registration => {
          console.log('Service Worker 注册成功:', registration.scope);
          
          // 注册后立即检查安装状态
          checkInstallability();
          
          // 监听Service Worker更新
          registration.addEventListener('updatefound', () => {
            const newWorker = registration.installing;
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                console.log('发现新版本，准备更新');
                // 可以在这里显示更新提示
              }
            });
          });
        })
        .catch(error => {
          console.error('Service Worker 注册失败:', error);
        });
        
      // 监听来自Service Worker的消息
      navigator.serviceWorker.addEventListener('message', (event) => {
        if (event.data && event.data.type === 'CACHE_UPDATED') {
          console.log('缓存已更新，刷新页面以使用新版本');
          // 可以选择自动刷新或提示用户刷新
          // 为避免打断用户体验，这里先提示用户
          if (confirm('发现新版本，是否立即更新？')) {
            window.location.reload();
          }
        }
      });
      
      // 检查控制当前页面的Service Worker是否有更新
      let refreshing = false;
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (refreshing) return;
        refreshing = true;
        console.log('控制器已更改，刷新页面');
        // 可以选择自动刷新，但为了更好的用户体验，建议提示用户
        setTimeout(() => {
          window.location.reload();
        }, 1000);
      });
    });
  } else {
    console.log('当前浏览器不支持Service Worker');
  }