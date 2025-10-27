// 添加String.prototype.padStart的polyfill，确保在老式浏览器中兼容
if (!String.prototype.padStart) {
  String.prototype.padStart = function(targetLength, padString) {
    targetLength = targetLength >> 0; // 转换为整数
    padString = String(padString || ' ');
    if (this.length >= targetLength) {
      return String(this);
    }
    targetLength = targetLength - this.length;
    if (targetLength > padString.length) {
      padString += padString.repeat(targetLength / padString.length);
    }
    return padString.slice(0, targetLength) + String(this);
  };
}

function App() {
  // 状态变量
  var amount = '';
  var source = '';
  var incomes = [];
  var totalIncome = 0;
  var loading = false;

  var API_BASE_URL = 'http://192.168.0.197:3001/api';
  
  // 获取浏览器信息
  function getBrowserInfo() {
    var ua = navigator.userAgent;
    var browserInfo = '';
    
    // 检测主要浏览器
    if (ua.indexOf('Chrome') > -1) {
      browserInfo = 'Chrome（Chromium）';
    } 
    else if (ua.indexOf('Firefox') > -1) {
      browserInfo = 'Firefox';
    } else if (ua.indexOf('Safari') > -1) {
      browserInfo = 'Safari';
    } 
    else if (ua.indexOf('MSIE') > -1 || ua.indexOf('Trident') > -1) {
      browserInfo = 'Internet Explorer（不支持，请升级至非IE浏览器）';
    }
     else {
      browserInfo = 'Unknown Browser';
    }
    
    // 获取浏览器版本
    var version = ua.match(/(Chrome|Firefox|Safari|MSIE|rv:)\/?\s*(\d+)/i);
    if (version && version[2]) {
      browserInfo += ' ' + version[2];
    }
    
    return browserInfo;
  }
  
  // 获取当前日期时间
  function getCurrentDateTime() {
    var now = new Date();
    var year = now.getFullYear();
    var month = String(now.getMonth() + 1).padStart(2, '0');
    var day = String(now.getDate()).padStart(2, '0');
    var hours = String(now.getHours()).padStart(2, '0');
    var minutes = String(now.getMinutes()).padStart(2, '0');
    var seconds = String(now.getSeconds()).padStart(2, '0');
    
    return year + '-' + month + '-' + day + ' ' + hours + ':' + minutes + ':' + seconds;
  }

  // 创建兼容的 XHR 对象
  function createXHR() {
    if (typeof XMLHttpRequest !== 'undefined') {
      return new XMLHttpRequest();
    } else if (window.ActiveXObject) {
      try {
        return new ActiveXObject("Msxml2.XMLHTTP");
      } catch (e) {
        try {
          return new ActiveXObject("Microsoft.XMLHTTP");
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  // 简单的 JSON 解析（仅适用于简单结构）
  function parseJSON(text) {
    try {
      return eval('(' + text + ')');
    } catch (e) {
      // 备用解析方案
      try {
        var obj = {};
        text = text.replace(/^{|}$/g, '').split(',');
        for (var i = 0; i < text.length; i++) {
          var pair = text[i].split(':');
          var key = pair[0].replace(/^"|"$/g, '');
          var value = pair[1].replace(/^"|"$/g, '');
          obj[key] = isNaN(value) ? value : parseFloat(value);
        }
        return obj;
      } catch (e2) {
        alert('数据解析错误');
        return {};
      }
    }
  }

  // 获取所有收入记录
  function fetchIncomes() {
    loading = true;
    renderApp();

    var xhr = createXHR();
    if (!xhr) {
      alert('您的浏览器不支持此功能');
      return;
    }

    xhr.open('GET', API_BASE_URL + '/incomes', true);
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
          try {
            incomes = parseJSON(xhr.responseText);
          } catch (e) {
            alert('获取收入记录失败');
          }
        } else {
          alert('获取收入记录失败，状态码: ' + xhr.status);
        }
        loading = false;
        renderApp();
      }
    };
    xhr.send();
  }

  // 获取总收入
  function fetchTotalIncome() {
    var xhr = createXHR();
    if (!xhr) return;

    xhr.open('GET', API_BASE_URL + '/incomes/total', true);
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4 && xhr.status === 200) {
        try {
          var data = parseJSON(xhr.responseText);
          totalIncome = data.total || 0;
          renderApp();
        } catch (e) {
          // 静默失败
        }
      }
    };
    xhr.send();
  }

  // 初始化
  function init() {
    fetchIncomes();
    fetchTotalIncome();
  }

  // 添加收入记录
  function addIncome() {
    if (!amount || !source) {
      alert('请填写金额和来源');
      return;
    }

    var xhr = createXHR();
    if (!xhr) return;

    xhr.open('POST', API_BASE_URL + '/incomes', true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        if (xhr.status === 200 || xhr.status === 201) {
          // 清空输入框
          amount = '';
          source = '';
          // 重新获取数据
          fetchIncomes();
          fetchTotalIncome();
          // 注意：renderApp() 会在 fetchIncomes 和 fetchTotalIncome 完成后自动调用
        } else {
          alert('添加失败，状态码: ' + xhr.status);
        }
      }
    };
    
    // 使用表单编码而不是 JSON
    var data = 'amount=' + encodeURIComponent(parseFloat(amount)) + 
               '&source=' + encodeURIComponent(source);
    xhr.send(data);
  }

  // 删除收入记录
  function deleteIncome(id) {
    if (!confirm('确定要删除这条记录吗？')) return;

    var xhr = createXHR();
    if (!xhr) return;

    xhr.open('DELETE', API_BASE_URL + '/incomes/' + id, true);
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        if (xhr.status === 200 || xhr.status === 204) {
          fetchIncomes();
          fetchTotalIncome();
        }
      }
    };
    xhr.send();
  }

  // 渲染函数（保持不变）
  function renderApp() {
    var container = document.getElementById('root');
    if (!container) return;

    var html = '';
    html += '<div class="container">';
    html += '<h1>收入记录</h1>';

    // 表单部分
    html += '<div class="form">';
    html += '<input type="text" placeholder="金额" value="' + amount + '" onchange="window.updateAmount(this.value)" class="input" />';
    html += '<input type="text" placeholder="来源" value="' + source + '" onchange="window.updateSource(this.value)" class="input" />';
    html += '<button onclick="window.addIncome()" class="button" ' + (loading ? 'disabled' : '') + '>';
    html += loading ? '添加中...' : '添加';
    html += '</button>';
    html += '</div>';

    // 总收入
    html += '<div class="total">';
    html += '总收入: ¥' + (totalIncome ? totalIncome.toFixed(2) : '0.00');
    html += '</div>';

    // 收入列表
    html += '<div class="list">';
    if (loading) {
      html += '<p class="empty">加载中...</p>';
    } else if (incomes.length === 0) {
      html += '<p class="empty">暂无记录</p>';
    } else {
      for (var i = 0; i < incomes.length; i++) {
        var income = incomes[i];
        html += '<div class="item">';
        html += '<div class="item-content">';
        html += '<span class="source">' + (income.source || '') + '</span>';
        html += '<span class="date">' + (income.date || '') + '</span>';
        html += '</div>';
        html += '<div class="item-actions">';
        html += '<span class="amount">¥' + (income.amount ? income.amount.toFixed(2) : '0.00') + '</span>';
        html += '<button onclick="window.deleteIncome(' + income.id + ')" class="delete-button">删除</button>';
        html += '</div>';
        html += '</div>';
      }
    }
    html += '</div>';
    
    // 添加底部信息
    html += '<div class="footer">';
    html += getCurrentDateTime() + ' | ' + getBrowserInfo();
    html += '</div>';
    
    html += '</div>';
    container.innerHTML = html;
    
    // 设置定时器，每秒更新时间
    if (window.timeUpdateTimer) {
      clearInterval(window.timeUpdateTimer);
    }
    window.timeUpdateTimer = setInterval(renderApp, 1000);
  }

  // 暴露函数到全局
  window.updateAmount = function (val) {
    amount = val;
  };
  window.updateSource = function (val) {
    source = val;
  };
  window.addIncome = addIncome;
  window.deleteIncome = deleteIncome;

  // 初始化应用
  if (window.attachEvent) {
    window.attachEvent('onload', init);
  } else {
    window.onload = init;
  }

  // 初始渲染
  renderApp();
}

// 启动应用
App();