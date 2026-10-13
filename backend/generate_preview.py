import os

PREVIEW_HTML = """<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Spendly / Aurora Finance — Smart Personal Finance Assistant</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-primary: #070B12;
      --bg-secondary: #0B1220;
      --card-surface: #151F2E;
      --card-gradient-top: #101C30;
      --card-gradient-bottom: #0C1424;
      --primary-blue: #2F80FF;
      --cyan-accent: #18D5FF;
      --ai-glow: #37E8FF;
      --income-green: #22C55E;
      --expense-red: #F05252;
      --savings-purple: #818CF8;
      --warning-amber: #F59E0B;
      --text-primary: #F8FAFC;
      --text-secondary: #CBD5E1;
      --text-muted: #64748B;
      --border-soft: rgba(255, 255, 255, 0.08);
      --border-cyan: rgba(56, 189, 248, 0.35);
      --keypad-bg: rgba(255, 255, 255, 0.05);
      --input-bg: #131D2D;
      --shadow-card: 0 16px 36px rgba(0, 0, 0, 0.35);
      --nav-bg: rgba(9, 14, 23, 0.96);
    }

    [data-theme="light"] {
      --bg-primary: #F8FAFC;
      --bg-secondary: #FFFFFF;
      --card-surface: #FFFFFF;
      --card-gradient-top: #FFFFFF;
      --card-gradient-bottom: #F1F5F9;
      --primary-blue: #1E60D5;
      --cyan-accent: #0284C7;
      --ai-glow: #0284C7;
      --income-green: #16A34A;
      --expense-red: #DC2626;
      --savings-purple: #6366F1;
      --warning-amber: #D97706;
      --text-primary: #0F172A;
      --text-secondary: #334155;
      --text-muted: #64748B;
      --border-soft: rgba(0, 0, 0, 0.09);
      --border-cyan: rgba(2, 132, 199, 0.35);
      --keypad-bg: rgba(0, 0, 0, 0.04);
      --input-bg: #F1F5F9;
      --shadow-card: 0 12px 28px rgba(15, 23, 42, 0.08);
      --nav-bg: rgba(255, 255, 255, 0.96);
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Inter', 'SF Pro Display', sans-serif;
      -webkit-tap-highlight-color: transparent;
      transition: background-color 0.2s, border-color 0.2s, color 0.2s;
    }

    body {
      background-color: #03060a;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 12px;
    }

    .iphone-wrapper {
      width: 100%;
      max-width: 410px;
      height: 870px;
      background: var(--bg-primary);
      border-radius: 52px;
      position: relative;
      overflow: hidden;
      box-shadow: 0 30px 80px rgba(0, 0, 0, 0.9), 0 0 0 10px #1e2530, 0 0 0 12px #0a0d14;
      display: flex;
      flex-direction: column;
    }

    /* Notification Push Simulator Banner */
    .push-banner {
      position: absolute;
      top: -100px;
      left: 14px;
      right: 14px;
      background: var(--card-surface);
      border: 1px solid var(--border-cyan);
      box-shadow: 0 20px 40px rgba(0,0,0,0.5);
      border-radius: 20px;
      padding: 12px 16px;
      display: flex;
      align-items: center;
      gap: 12px;
      z-index: 200;
      transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    }
    .push-banner.active {
      transform: translateY(115px);
    }
    .push-icon {
      width: 38px;
      height: 38px;
      border-radius: 12px;
      background: var(--primary-blue);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      color: #fff;
    }
    .push-info { flex: 1; }
    .push-app { font-size: 11px; font-weight: 700; color: var(--cyan-accent); text-transform: uppercase; }
    .push-text { font-size: 13px; font-weight: 600; color: var(--text-primary); margin-top: 1px; }

    .dynamic-island {
      width: 120px;
      height: 32px;
      background: #000;
      border-radius: 20px;
      position: absolute;
      top: 10px;
      left: 50%;
      transform: translateX(-50%);
      z-index: 100;
    }

    .status-bar {
      height: 48px;
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      padding: 0 24px 8px;
      font-size: 13px;
      font-weight: 600;
      color: var(--text-primary);
      z-index: 50;
    }

    .top-controls-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 6px 18px 8px;
      z-index: 40;
    }
    .lang-switcher {
      display: flex;
      background: rgba(255, 255, 255, 0.08);
      border-radius: 14px;
      padding: 2px;
      gap: 2px;
    }
    .lang-btn {
      padding: 3px 8px;
      font-size: 11px;
      font-weight: 700;
      color: var(--text-muted);
      border-radius: 10px;
      cursor: pointer;
      border: none;
      background: transparent;
    }
    .lang-btn.active {
      background: var(--primary-blue);
      color: #fff;
    }
    .theme-toggle-btn {
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid var(--border-soft);
      border-radius: 14px;
      padding: 4px 10px;
      font-size: 12px;
      color: var(--text-primary);
      cursor: pointer;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .app-viewport {
      flex: 1;
      position: relative;
      overflow-y: auto;
      overflow-x: hidden;
      padding: 6px 18px 86px;
    }
    .app-viewport::-webkit-scrollbar { display: none; }

    .screen-view { display: none; }
    .screen-view.active {
      display: block;
      animation: fadeIn 0.22s ease-out;
    }

    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(6px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* Glass Cards */
    .glass-card {
      background: var(--card-surface);
      border: 1px solid var(--border-soft);
      border-radius: 22px;
      padding: 18px;
      margin-bottom: 14px;
      box-shadow: var(--shadow-card);
    }

    .balance-card {
      background: linear-gradient(145deg, var(--card-gradient-top), var(--card-gradient-bottom));
      border: 1px solid var(--border-cyan);
      position: relative;
    }
    .balance-header { display: flex; justify-content: space-between; align-items: center; }
    .balance-title { font-size: 13px; color: var(--text-secondary); font-weight: 500; display: flex; align-items: center; gap: 6px; }
    .balance-amount { font-size: 40px; font-weight: 800; color: var(--text-primary); margin: 6px 0 2px; letter-spacing: -1px; }

    .circle-arrow-btn {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: var(--primary-blue);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
      cursor: pointer;
      box-shadow: 0 4px 14px rgba(47, 128, 255, 0.4);
    }

    .metrics-row {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;
      margin-bottom: 14px;
    }
    .metric-pill {
      background: var(--card-surface);
      border: 1px solid var(--border-soft);
      border-radius: 18px;
      padding: 12px 10px;
      text-align: center;
      cursor: pointer;
    }
    .metric-label { font-size: 11px; color: var(--text-muted); margin-bottom: 4px; }
    .metric-value { font-size: 16px; font-weight: 700; color: var(--text-primary); }

    /* AI Orb Component */
    .orb-container {
      width: 140px;
      height: 140px;
      margin: 10px auto 16px;
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .orb-glow {
      position: absolute;
      width: 130px;
      height: 130px;
      border-radius: 50%;
      background: radial-gradient(circle, var(--ai-glow) 0%, rgba(47, 128, 255, 0) 70%);
      filter: blur(16px);
      animation: pulseGlow 4s infinite alternate ease-in-out;
    }
    .orb-sphere {
      width: 90px;
      height: 90px;
      border-radius: 50%;
      background: linear-gradient(135deg, #18D5FF, #2F80FF, #A855F7, #EC4899);
      background-size: 200% 200%;
      animation: gradientShift 6s infinite ease, rotateOrb 12s infinite linear;
      box-shadow: 0 0 24px rgba(24, 213, 255, 0.6);
      position: relative;
    }
    @keyframes pulseGlow {
      0% { transform: scale(0.9); opacity: 0.6; }
      100% { transform: scale(1.15); opacity: 0.95; }
    }
    @keyframes gradientShift {
      0% { background-position: 0% 50%; }
      50% { background-position: 100% 50%; }
      100% { background-position: 0% 50%; }
    }
    @keyframes rotateOrb {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    /* AI Chat System */
    .chat-messages {
      display: flex;
      flex-direction: column;
      gap: 12px;
      margin-bottom: 16px;
      max-height: 380px;
      overflow-y: auto;
      padding-right: 4px;
    }
    .chat-bubble {
      max-width: 84%;
      padding: 12px 16px;
      border-radius: 18px;
      font-size: 13.5px;
      line-height: 1.45;
    }
    .chat-bubble.user {
      align-self: flex-end;
      background: var(--primary-blue);
      color: #fff;
      border-bottom-right-radius: 4px;
    }
    .chat-bubble.ai {
      align-self: flex-start;
      background: var(--card-surface);
      border: 1px solid var(--border-cyan);
      color: var(--text-primary);
      border-bottom-left-radius: 4px;
      box-shadow: var(--shadow-card);
    }
    .chat-chips-scroll {
      display: flex;
      gap: 6px;
      overflow-x: auto;
      padding: 4px 0 12px;
      scrollbar-width: none;
    }
    .chat-chips-scroll::-webkit-scrollbar { display: none; }
    .chat-chip {
      background: rgba(24, 213, 255, 0.1);
      border: 1px solid var(--border-cyan);
      color: var(--cyan-accent);
      padding: 7px 12px;
      border-radius: 16px;
      font-size: 12px;
      font-weight: 600;
      white-space: nowrap;
      cursor: pointer;
    }

    /* Calculators UI */
    .calc-tabs {
      display: flex;
      background: var(--input-bg);
      border-radius: 14px;
      padding: 4px;
      margin-bottom: 14px;
      gap: 4px;
    }
    .calc-tab-btn {
      flex: 1;
      text-align: center;
      padding: 8px 10px;
      border-radius: 10px;
      font-size: 12px;
      font-weight: 700;
      color: var(--text-muted);
      cursor: pointer;
      border: none;
      background: transparent;
    }
    .calc-tab-btn.active {
      background: var(--primary-blue);
      color: #fff;
    }

    .slider-group {
      margin-bottom: 14px;
    }
    .slider-header {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      color: var(--text-secondary);
      margin-bottom: 6px;
    }
    .slider-val {
      font-weight: 700;
      color: var(--text-primary);
    }
    .range-input {
      width: 100%;
      accent-color: var(--cyan-accent);
      cursor: pointer;
    }

    /* Social Auth Buttons */
    .social-btn-row {
      display: flex;
      flex-direction: column;
      gap: 10px;
      margin: 16px 0;
    }
    .social-btn {
      width: 100%;
      height: 48px;
      border-radius: 14px;
      border: 1px solid var(--border-soft);
      background: var(--card-surface);
      color: var(--text-primary);
      font-size: 14px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      cursor: pointer;
    }

    /* Bottom Navigation */
    .bottom-nav {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 74px;
      background: var(--nav-bg);
      backdrop-filter: blur(20px);
      border-top: 1px solid var(--border-soft);
      display: flex;
      justify-content: space-around;
      align-items: center;
      padding-bottom: 8px;
      z-index: 80;
    }
    .nav-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 3px;
      color: var(--text-muted);
      font-size: 11px;
      font-weight: 600;
      cursor: pointer;
    }
    .nav-item.active { color: var(--text-primary); }
    .nav-ai-bubble {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: var(--primary-blue);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
      box-shadow: 0 0 14px rgba(24, 213, 255, 0.6);
      margin-bottom: -2px;
    }

    .form-btn {
      width: 100%;
      height: 48px;
      border-radius: 14px;
      background: var(--primary-blue);
      color: #fff;
      font-weight: 700;
      border: none;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }

    /* Modal Overlay */
    .modal-overlay {
      display: none;
      position: absolute;
      top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(0, 0, 0, 0.75);
      z-index: 150;
      align-items: flex-end;
    }
    .modal-overlay.active { display: flex; }
    .modal-content {
      width: 100%;
      max-height: 82%;
      overflow-y: auto;
      background: var(--bg-secondary);
      border-radius: 28px 28px 0 0;
      padding: 24px;
      border-top: 1px solid var(--border-cyan);
      box-shadow: 0 -15px 40px rgba(0,0,0,0.8);
      animation: slideUp 0.22s ease-out;
    }
    @keyframes slideUp {
      from { transform: translateY(100%); }
      to { transform: translateY(0); }
    }
  </style>
</head>
<body>

  <div class="iphone-wrapper" id="iphoneContainer" data-theme="dark">
    <!-- Simulated Push Notification Banner -->
    <div class="push-banner" id="pushBanner">
      <div class="push-icon">💳</div>
      <div class="push-info">
        <div class="push-app" id="pushAppTitle">PAYME • АВТОСБОР</div>
        <div class="push-text" id="pushAppBody">Оплата: 45 000 UZS в Korzinka</div>
      </div>
      <span style="font-size:12px; color:var(--income-green); font-weight:700;">+0.05s</span>
    </div>

    <div class="dynamic-island"></div>

    <!-- Status Bar -->
    <div class="status-bar">
      <span>9:41</span>
      <div style="display:flex; gap:6px; align-items:center;">
        <span>5G</span>
        <span>100%</span>
      </div>
    </div>

    <!-- Top Multi-Language & Theme Bar -->
    <div class="top-controls-bar">
      <div class="lang-switcher">
        <button class="lang-btn active" id="btnLangRu" onclick="setAppLanguage('ru')">RU</button>
        <button class="lang-btn" id="btnLangEn" onclick="setAppLanguage('en')">EN</button>
        <button class="lang-btn" id="btnLangUz" onclick="setAppLanguage('uz')">UZ</button>
      </div>
      <button class="theme-toggle-btn" onclick="toggleAppTheme()">
        <span id="themeIcon">☀️</span> <span id="themeLabel">Light</span>
      </button>
    </div>

    <!-- VIEWPORT CONTAINER -->
    <div class="app-viewport">

      <!-- ONBOARDING SCREEN -->
      <div id="screen-onboarding" class="screen-view">
        <div style="display:inline-block; padding:4px 12px; border-radius:20px; background:rgba(24,213,255,0.12); border:1px solid var(--border-cyan); color:var(--cyan-accent); font-size:11px; font-weight:700; margin-bottom:12px;">
          ✦ SPENDLY FINTECH
        </div>
        <h2 style="font-size:24px; font-weight:800; color:var(--text-primary); line-height:1.2;" data-i18n="onb_title">Умный финансовый мониторинг</h2>
        <p style="font-size:13px; color:var(--text-muted); margin:8px 0 20px; line-height:1.45;" data-i18n="onb_sub">Автоматический учёт без доступа к счетам и ручного ввода. Войдите через соцсети или номер телефона.</p>

        <!-- Social OAuth Sign-In (Requirement 2) -->
        <div class="social-btn-row">
          <button class="social-btn" onclick="submitSocialLogin('apple')">
            <span></span> <span data-i18n="login_apple">Продолжить с Apple ID</span>
          </button>
          <button class="social-btn" onclick="submitSocialLogin('google')">
            <span style="color:#EA4335; font-weight:bold;">G</span> <span data-i18n="login_google">Войти через Google</span>
          </button>
          <button class="social-btn" onclick="submitSocialLogin('github')">
            <span></span> <span data-i18n="login_github">Войти через GitHub</span>
          </button>
        </div>

        <div style="display:flex; align-items:center; gap:10px; margin:16px 0;">
          <div style="flex:1; height:1px; background:var(--border-soft);"></div>
          <span style="font-size:11px; color:var(--text-muted);" data-i18n="or_phone">ИЛИ ПО НОМЕРУ ТЕЛЕФОНА</span>
          <div style="flex:1; height:1px; background:var(--border-soft);"></div>
        </div>

        <div style="background:var(--input-bg); border:1px solid var(--border-soft); border-radius:16px; padding:12px 14px; display:flex; align-items:center; gap:10px; margin-bottom:16px;">
          <span style="font-weight:700; color:var(--text-primary);">+998</span>
          <input type="tel" id="onbPhoneInput" value="90 123 45 67" style="background:transparent; border:none; outline:none; color:var(--text-primary); font-size:16px; font-weight:600; flex:1;">
        </div>

        <button class="form-btn" onclick="loginWithPhone()" data-i18n="btn_enter">Войти в приложение →</button>
        <p style="font-size:11px; color:var(--text-muted); text-align:center; margin-top:14px;" data-i18n="non_custodial_note">🔒 Строго non-custodial: Никаких CVV, PIN карт и ручных записей.</p>
      </div>

      <!-- SCREEN 1: HOME DASHBOARD -->
      <div id="screen-home" class="screen-view active">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:42px; height:42px; border-radius:50%; background:linear-gradient(135deg, #2F80FF, #18D5FF); display:flex; align-items:center; justify-content:center; color:#fff; font-weight:bold; cursor:pointer;" onclick="openProfileModal()">AM</div>
            <div>
              <div style="font-size:11px; color:var(--text-muted);" data-i18n="greeting_subtitle">Добро пожаловать,</div>
              <div style="font-size:17px; font-weight:800; color:var(--text-primary);">Alex Mercer</div>
            </div>
          </div>
          <button style="background:rgba(24,213,255,0.12); border:1px solid var(--border-cyan); color:var(--cyan-accent); padding:6px 12px; border-radius:20px; font-size:11px; font-weight:700; cursor:pointer;" onclick="triggerSimulatedPush()">
            🔔 <span data-i18n="btn_sim_push">Тест Push-автосбора</span>
          </button>
        </div>

        <!-- Total Balance Card -->
        <div class="glass-card balance-card">
          <div class="balance-header">
            <span class="balance-title">
              <span data-i18n="total_balance">Общий баланс</span>
              <span style="cursor:pointer;" onclick="toggleMaskBalance()">👁</span>
            </span>
            <div class="circle-arrow-btn" onclick="switchTab('ai')">✦</div>
          </div>
          <div class="balance-amount" id="totalBalanceVal">$12,480.00</div>
          <div style="display:flex; gap:6px; font-size:12px; align-items:center;">
            <span style="color:var(--income-green); font-weight:700;">↑ 12%</span>
            <span style="color:var(--text-muted);" data-i18n="from_last_month">к прошлому месяцу</span>
          </div>
        </div>

        <!-- 3 Metrics -->
        <div class="metrics-row">
          <div class="metric-pill" onclick="switchTab('spending')">
            <div class="metric-label" data-i18n="metric_income">Доходы</div>
            <div class="metric-value" style="color:var(--income-green);" id="incomeVal">$4,200</div>
          </div>
          <div class="metric-pill" onclick="switchTab('spending')">
            <div class="metric-label" data-i18n="metric_spending">Расходы</div>
            <div class="metric-value" style="color:var(--expense-red);" id="spendingVal">$2,380</div>
          </div>
          <div class="metric-pill" onclick="switchTab('calcs')">
            <div class="metric-label" data-i18n="metric_savings">Сбережения</div>
            <div class="metric-value" style="color:var(--savings-purple);" id="savingsVal">$1,820</div>
          </div>
        </div>

        <!-- AI Assistant Banner -->
        <div class="glass-card" style="background:linear-gradient(135deg, rgba(24,213,255,0.12), rgba(47,128,255,0.06)); border-color:var(--border-cyan); cursor:pointer;" onclick="switchTab('ai')">
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="font-size:24px;">✦</div>
            <div style="flex:1;">
              <div style="font-size:11px; font-weight:700; color:var(--cyan-accent); text-transform:uppercase;" data-i18n="ai_insight_label">AI Financial Assistant</div>
              <div style="font-size:13px; font-weight:600; color:var(--text-primary);" id="aiInsightTitle">«Еда и рестораны» составляют 34% трат. Нажмите для подробного разбора.</div>
            </div>
            <span style="color:var(--cyan-accent); font-size:16px;">→</span>
          </div>
        </div>

        <!-- Recent Auto-Ingested Transactions -->
        <div style="display:flex; justify-content:space-between; align-items:center; margin:14px 0 10px;">
          <span style="font-size:14px; font-weight:700; color:var(--text-primary);" data-i18n="recent_tx_title">Автоматически распознано</span>
          <span style="font-size:11px; color:var(--cyan-accent); cursor:pointer;" onclick="switchTab('spending')" data-i18n="see_all">Все</span>
        </div>
        <div id="homeRecentTxList"></div>
      </div>

      <!-- SCREEN 2: CONVERSATIONAL AI ASSISTANT -->
      <div id="screen-ai" class="screen-view">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
          <span style="font-size:18px; color:var(--text-primary); cursor:pointer;" onclick="switchTab('home')">←</span>
          <div style="text-align:center;">
            <h3 style="font-size:16px; font-weight:800; color:var(--text-primary);" data-i18n="ai_screen_title">AI Financial Advisor</h3>
            <p style="font-size:11px; color:var(--text-muted);" data-i18n="ai_screen_sub">Ответы на основе ваших реальных транзакций</p>
          </div>
          <div style="width:20px;"></div>
        </div>

        <div class="orb-container">
          <div class="orb-glow"></div>
          <div class="orb-sphere"></div>
        </div>

        <!-- Quick Question Chips -->
        <div class="chat-chips-scroll">
          <div class="chat-chip" onclick="askAiQuestion('Куда у меня уходит больше всего денег?')">💸 <span data-i18n="q1">Куда уходит больше всего денег?</span></div>
          <div class="chat-chip" onclick="askAiQuestion('Почему мои расходы выросли в этом месяце?')">📈 <span data-i18n="q2">Почему расходы выросли?</span></div>
          <div class="chat-chip" onclick="askAiQuestion('Сколько я могу откладывать каждый месяц?')">💰 <span data-i18n="q3">Сколько могу откладывать?</span></div>
          <div class="chat-chip" onclick="askAiQuestion('Как быстрее погасить кредит?')">⚡ <span data-i18n="q4">Как быстрее погасить кредит?</span></div>
          <div class="chat-chip" onclick="askAiQuestion('Покажи мои самые большие расходы за месяц')">🔍 <span data-i18n="q5">Самые большие расходы</span></div>
        </div>

        <!-- Chat Bubble History -->
        <div class="chat-messages" id="chatHistoryContainer">
          <div class="chat-bubble ai" data-i18n="ai_welcome_msg">
            Здравствуйте, Alex! Я проанализировал ваши доходы ($4,200) и расходы ($2,380). Задайте любой вопрос по вашему бюджету, оптимизации кредитов или запланированным покупкам.
          </div>
        </div>

        <!-- Chat Input Bar -->
        <div style="display:flex; gap:8px; align-items:center; background:var(--input-bg); border:1px solid var(--border-soft); border-radius:24px; padding:6px 8px 6px 14px;">
          <input type="text" id="aiUserInputField" placeholder="Задайте финансовый вопрос..." data-i18n-ph="ai_input_placeholder" style="flex:1; background:transparent; border:none; outline:none; color:var(--text-primary); font-size:13.5px;" onkeypress="if(event.key==='Enter') sendCustomAiMessage()">
          <button style="width:36px; height:36px; border-radius:50%; background:var(--primary-blue); border:none; color:#fff; display:flex; align-items:center; justify-content:center; cursor:pointer;" onclick="sendCustomAiMessage()">↗</button>
        </div>
      </div>

      <!-- SCREEN 3: SPENDING & CATEGORIES -->
      <div id="screen-spending" class="screen-view">
        <div style="text-align:center; padding:10px 0 16px;">
          <div style="font-size:12px; color:var(--text-muted);" data-i18n="spending_month_label">Расходы за текущий месяц</div>
          <div style="font-size:36px; font-weight:800; color:var(--text-primary);">$2,380.00</div>
          <span style="font-size:12px; color:var(--income-green); font-weight:600;" data-i18n="below_limit">↓ на 8% ниже установленного лимита</span>
        </div>

        <div class="glass-card">
          <div style="font-size:14px; font-weight:700; color:var(--text-primary); margin-bottom:12px;" data-i18n="categories_title">Категории расходов</div>
          <div id="categoriesListContainer"></div>
        </div>

        <div class="glass-card">
          <div style="font-size:14px; font-weight:700; color:var(--text-primary); margin-bottom:12px;" data-i18n="top_merchants_title">Топ заведений / мерчантов</div>
          <div id="topMerchantsListContainer"></div>
        </div>
      </div>

      <!-- SCREEN 4: CALCULATORS (Requirements 4 & 5) -->
      <div id="screen-calcs" class="screen-view">
        <h3 style="font-size:18px; font-weight:800; color:var(--text-primary); margin-bottom:12px;" data-i18n="calcs_header">Финансовые калькуляторы</h3>

        <div class="calc-tabs">
          <button class="calc-tab-btn active" id="btnTabLoan" onclick="switchCalcSubTab('loan')" data-i18n="tab_loan">Кредитный калькулятор</button>
          <button class="calc-tab-btn" id="btnTabCard" onclick="switchCalcSubTab('card')" data-i18n="tab_card">Кредитная карта</button>
        </div>

        <!-- 1. LOAN CALCULATOR VIEW -->
        <div id="view-loan-calc">
          <div class="glass-card">
            <!-- Principal Slider -->
            <div class="slider-group">
              <div class="slider-header">
                <span data-i18n="loan_amount">Сумма кредита</span>
                <span class="slider-val" id="lblLoanAmount">$25,000</span>
              </div>
              <input type="range" class="range-input" id="rngLoanAmount" min="1000" max="100000" step="1000" value="25000" oninput="updateLoanCalc()">
            </div>

            <!-- Rate Slider -->
            <div class="slider-group">
              <div class="slider-header">
                <span data-i18n="loan_rate">Процентная ставка (%)</span>
                <span class="slider-val" id="lblLoanRate">22%</span>
              </div>
              <input type="range" class="range-input" id="rngLoanRate" min="5" max="45" step="0.5" value="22" oninput="updateLoanCalc()">
            </div>

            <!-- Term Slider -->
            <div class="slider-group">
              <div class="slider-header">
                <span data-i18n="loan_term">Срок кредита</span>
                <span class="slider-val" id="lblLoanTerm">24 мес</span>
              </div>
              <input type="range" class="range-input" id="rngLoanTerm" min="6" max="60" step="6" value="24" oninput="updateLoanCalc()">
            </div>

            <!-- Payment Type Select -->
            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:8px;">
              <span style="font-size:12px; color:var(--text-secondary);" data-i18n="payment_type">Тип платежа:</span>
              <div style="display:flex; gap:6px;">
                <button class="lang-btn active" id="btnAnnuity" onclick="setPaymentType('annuity')" data-i18n="annuity">Аннуитетный</button>
                <button class="lang-btn" id="btnDiff" onclick="setPaymentType('differential')" data-i18n="differential">Дифференцированный</button>
              </div>
            </div>
          </div>

          <!-- Loan Results Summary -->
          <div class="glass-card" style="border-color:var(--border-cyan);">
            <div style="font-size:12px; color:var(--text-muted);" data-i18n="monthly_payment">Ежемесячный платёж</div>
            <div style="font-size:32px; font-weight:800; color:var(--cyan-accent); margin:4px 0 10px;" id="resMonthlyPay">$1,300.28</div>

            <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; border-top:1px solid var(--border-soft); padding-top:10px;">
              <div>
                <div style="font-size:11px; color:var(--text-muted);" data-i18n="total_repayment">Всего к выплате</div>
                <div style="font-size:16px; font-weight:700; color:var(--text-primary);" id="resTotalPayment">$31,206.72</div>
              </div>
              <div>
                <div style="font-size:11px; color:var(--text-muted);" data-i18n="overpayment">Переплата банку</div>
                <div style="font-size:16px; font-weight:700; color:var(--expense-red);" id="resTotalInterest">$6,206.72 (24.8%)</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 2. CREDIT CARD PAYOFF VIEW -->
        <div id="view-card-calc" style="display:none;">
          <div class="glass-card">
            <!-- Debt Balance Slider -->
            <div class="slider-group">
              <div class="slider-header">
                <span data-i18n="card_debt">Текущий долг</span>
                <span class="slider-val" id="lblCardDebt">$3,000</span>
              </div>
              <input type="range" class="range-input" id="rngCardDebt" min="500" max="20000" step="500" value="3000" oninput="updateCardCalc()">
            </div>

            <!-- Limit Slider -->
            <div class="slider-group">
              <div class="slider-header">
                <span data-i18n="card_limit">Кредитный лимит</span>
                <span class="slider-val" id="lblCardLimit">$8,000</span>
              </div>
              <input type="range" class="range-input" id="rngCardLimit" min="1000" max="30000" step="1000" value="8000" oninput="updateCardCalc()">
            </div>

            <!-- APR Slider -->
            <div class="slider-group">
              <div class="slider-header">
                <span data-i18n="card_apr">Ставка (APR %)</span>
                <span class="slider-val" id="lblCardApr">28%</span>
              </div>
              <input type="range" class="range-input" id="rngCardApr" min="10" max="48" step="1" value="28" oninput="updateCardCalc()">
            </div>

            <!-- Extra Monthly Payment -->
            <div class="slider-group">
              <div class="slider-header">
                <span data-i18n="extra_pay">Ускоренный платёж (+ к мин.)</span>
                <span class="slider-val" id="lblCardExtra">+$150 / мес</span>
              </div>
              <input type="range" class="range-input" id="rngCardExtra" min="0" max="500" step="25" value="150" oninput="updateCardCalc()">
            </div>
          </div>

          <!-- Card Strategy Comparison -->
          <div class="glass-card" style="border-color:var(--border-cyan);">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
              <span style="font-size:13px; font-weight:700; color:var(--text-primary);" data-i18n="strategy_compare">Сравнение стратегий</span>
              <span style="font-size:11px; padding:2px 8px; border-radius:10px; background:rgba(34,197,94,0.15); color:var(--income-green); font-weight:700;" id="resUtilizationStatus">Утилизация 37.5%</span>
            </div>

            <div style="background:rgba(240,82,82,0.08); border:1px solid rgba(240,82,82,0.2); border-radius:14px; padding:10px; margin-bottom:8px;">
              <div style="font-size:11px; color:var(--expense-red); font-weight:700;" data-i18n="min_pay_trap">⚠️ Ловушка минимального платежа (5%)</div>
              <div style="font-size:13px; color:var(--text-secondary); margin-top:2px;" id="resMinPaySummary">Срок: 58 месяцев • Переплата: $1,420</div>
            </div>

            <div style="background:rgba(34,197,94,0.08); border:1px solid rgba(34,197,94,0.2); border-radius:14px; padding:10px;">
              <div style="font-size:11px; color:var(--income-green); font-weight:700;" data-i18n="smart_payoff">🚀 Ускоренное погашение</div>
              <div style="font-size:13px; color:var(--text-secondary); margin-top:2px;" id="resSmartPaySummary">Срок: 12 месяцев • Переплата: $310</div>
            </div>

            <div style="margin-top:10px; text-align:center; font-size:12px; font-weight:700; color:var(--cyan-accent);" id="resSavingsHighlight">
              Экономия: $1,110 и 46 месяцев свободы от долга!
            </div>
          </div>
        </div>
      </div>

      <!-- SCREEN 5: CARDS & WALLET -->
      <div id="screen-cards" class="screen-view">
        <h3 style="font-size:18px; font-weight:800; color:var(--text-primary); margin-bottom:12px;" data-i18n="cards_header">Банковские карты</h3>
        <p style="font-size:12px; color:var(--text-muted); margin-bottom:14px;" data-i18n="cards_note">Только чтение балансов и парсинг транзакций. Номера карт замаскированы (First 4 / Last 4).</p>
        <div id="cardsListContainer"></div>
      </div>

    </div>

    <!-- BOTTOM TAB NAVIGATION -->
    <div class="bottom-nav">
      <div class="nav-item active" id="tab-home" onclick="switchTab('home')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
        <span data-i18n="nav_home">Главная</span>
      </div>
      <div class="nav-item" id="tab-ai" onclick="switchTab('ai')">
        <div class="nav-ai-bubble">✦</div>
        <span data-i18n="nav_ai">AI Советник</span>
      </div>
      <div class="nav-item" id="tab-spending" onclick="switchTab('spending')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
        <span data-i18n="nav_spending">Анализ</span>
      </div>
      <div class="nav-item" id="tab-calcs" onclick="switchTab('calcs')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2"/><line x1="8" y1="6" x2="16" y2="6"/><line x1="16" y1="14" x2="16" y2="18"/><path d="M8 10h.01M12 10h.01M16 10h.01M8 14h.01M12 14h.01M8 18h.01M12 18h.01"/></svg>
        <span data-i18n="nav_calcs">Кредиты</span>
      </div>
      <div class="nav-item" id="tab-cards" onclick="switchTab('cards')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
        <span data-i18n="nav_cards">Карты</span>
      </div>
    </div>

    <!-- PROFILE MODAL -->
    <div class="modal-overlay" id="profileModal" onclick="closeModal('profileModal')">
      <div class="modal-content" onclick="event.stopPropagation()">
        <div style="width:40px; height:4px; background:#475569; border-radius:2px; margin:0 auto 16px;"></div>
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
          <h4 style="color:var(--text-primary); font-size:17px; font-weight:700;" data-i18n="profile_security">Безопасность и Сессии</h4>
          <span style="font-size:12px; color:var(--text-muted); cursor:pointer;" onclick="closeModal('profileModal')">✕</span>
        </div>

        <div style="background:var(--input-bg); border-radius:16px; padding:12px; margin-bottom:14px;">
          <div style="font-size:11px; color:var(--text-muted);">Alex Mercer • +998 90 123 45 67</div>
          <div style="font-size:12px; color:var(--cyan-accent); font-weight:700; margin-top:2px;">Supabase PostgreSQL 16 • RLS Active</div>
        </div>

        <button class="form-btn" style="background:rgba(24,213,255,0.12); border:1px solid var(--border-cyan); color:var(--cyan-accent); margin-bottom:10px;" onclick="downloadDataArchive()">
          📥 <span data-i18n="export_json">Экспорт архива данных (JSON)</span>
        </button>

        <button class="form-btn" style="background:transparent; border:1px solid var(--border-soft); color:var(--text-primary);" onclick="logoutApp()">
          🚪 <span data-i18n="btn_logout">Выйти (Экран авторизации)</span>
        </button>
      </div>
    </div>

  </div>

  <script>
    // =========================================================================
    // I18N DICTIONARY (RU / EN / UZ)
    // =========================================================================
    const I18N = {
      ru: {
        onb_title: "Умный финансовый мониторинг",
        onb_sub: "Автоматический учёт без доступа к счетам и ручного ввода. Войдите через соцсети или номер телефона.",
        login_apple: "Продолжить с Apple ID",
        login_google: "Войти через Google",
        login_github: "Войти через GitHub",
        or_phone: "ИЛИ ПО НОМЕРУ ТЕЛЕФОНА",
        btn_enter: "Войти в приложение →",
        non_custodial_note: "🔒 Строго non-custodial: Никаких CVV, PIN карт и ручных записей.",
        greeting_subtitle: "Добро пожаловать,",
        btn_sim_push: "Тест Push-автосбора",
        total_balance: "Общий баланс",
        from_last_month: "к прошлому месяцу",
        metric_income: "Доходы",
        metric_spending: "Расходы",
        metric_savings: "Сбережения",
        ai_insight_label: "AI Financial Assistant",
        recent_tx_title: "Автоматически распознано",
        see_all: "Все",
        ai_screen_title: "AI Financial Advisor",
        ai_screen_sub: "Ответы на основе ваших реальных транзакций",
        q1: "Куда уходит больше всего денег?",
        q2: "Почему расходы выросли?",
        q3: "Сколько могу откладывать?",
        q4: "Как быстрее погасить кредит?",
        q5: "Самые большие расходы",
        ai_welcome_msg: "Здравствуйте, Alex! Я проанализировал ваши доходы ($4,200) и расходы ($2,380). Задайте любой вопрос по вашему бюджету, кредитам или планам.",
        ai_input_placeholder: "Задайте финансовый вопрос...",
        spending_month_label: "Расходы за текущий месяц",
        below_limit: "↓ на 8% ниже установленного лимита",
        categories_title: "Категории расходов",
        top_merchants_title: "Топ заведений / мерчантов",
        calcs_header: "Финансовые калькуляторы",
        tab_loan: "Кредитный калькулятор",
        tab_card: "Кредитная карта",
        loan_amount: "Сумма кредита",
        loan_rate: "Процентная ставка (%)",
        loan_term: "Срок кредита",
        payment_type: "Тип платежа:",
        annuity: "Аннуитетный",
        differential: "Дифференцированный",
        monthly_payment: "Ежемесячный платёж",
        total_repayment: "Всего к выплате",
        overpayment: "Переплата банку",
        card_debt: "Текущий долг",
        card_limit: "Кредитный лимит",
        card_apr: "Ставка (APR %)",
        extra_pay: "Ускоренный платёж (+ к мин.)",
        strategy_compare: "Сравнение стратегий",
        min_pay_trap: "⚠️ Ловушка минимального платежа (5%)",
        smart_payoff: "🚀 Ускоренное погашение",
        cards_header: "Банковские карты",
        cards_note: "Только чтение балансов и парсинг транзакций. Номера карт замаскированы (First 4 / Last 4).",
        nav_home: "Главная",
        nav_ai: "AI Советник",
        nav_spending: "Анализ",
        nav_calcs: "Кредиты",
        nav_cards: "Карты",
        profile_security: "Безопасность и Сессии",
        export_json: "Экспорт архива данных (JSON)",
        btn_logout: "Выйти (Экран авторизации)"
      },
      en: {
        onb_title: "Smart Personal Finance Monitor",
        onb_sub: "Zero manual entry and zero payment custody. Sign in with social accounts or your phone number.",
        login_apple: "Continue with Apple ID",
        login_google: "Sign in with Google",
        login_github: "Sign in with GitHub",
        or_phone: "OR WITH PHONE NUMBER",
        btn_enter: "Enter Application →",
        non_custodial_note: "🔒 Strictly non-custodial: No CVV, PIN, or manual bookkeeping.",
        greeting_subtitle: "Welcome back,",
        btn_sim_push: "Push Auto-Ingest Test",
        total_balance: "Total Balance",
        from_last_month: "from last month",
        metric_income: "Income",
        metric_spending: "Spending",
        metric_savings: "Savings",
        ai_insight_label: "AI Financial Assistant",
        recent_tx_title: "Auto-Ingested Transactions",
        see_all: "See all",
        ai_screen_title: "AI Financial Advisor",
        ai_screen_sub: "Grounded in your real transactions & balance",
        q1: "Where does most of my money go?",
        q2: "Why did expenses increase?",
        q3: "How much can I save monthly?",
        q4: "How to pay off loan faster?",
        q5: "Show largest expenses",
        ai_welcome_msg: "Hello Alex! I have reviewed your income ($4,200) and expenses ($2,380). Ask me anything about budget health, debt reduction, or purchases.",
        ai_input_placeholder: "Ask any financial question...",
        spending_month_label: "Expenditures this month",
        below_limit: "↓ 8% below monthly budget threshold",
        categories_title: "Spending Categories",
        top_merchants_title: "Top Merchants & Stores",
        calcs_header: "Financial Calculators",
        tab_loan: "Loan Calculator",
        tab_card: "Credit Card Payoff",
        loan_amount: "Principal Amount",
        loan_rate: "Annual Interest Rate (%)",
        loan_term: "Loan Term",
        payment_type: "Payment Type:",
        annuity: "Annuity",
        differential: "Differential",
        monthly_payment: "Monthly Payment",
        total_repayment: "Total Repayment",
        overpayment: "Interest Overpayment",
        card_debt: "Current Debt Balance",
        card_limit: "Credit Limit",
        card_apr: "Interest Rate (APR %)",
        extra_pay: "Accelerated Extra Payment",
        strategy_compare: "Strategy Comparison",
        min_pay_trap: "⚠️ Minimum Payment Trap (5%)",
        smart_payoff: "🚀 Accelerated Payoff Strategy",
        cards_header: "Payment Cards",
        cards_note: "Read-only balance monitoring and SMS ingestion. PANs masked (First 4 / Last 4).",
        nav_home: "Home",
        nav_ai: "AI Advisor",
        nav_spending: "Analysis",
        nav_calcs: "Credits",
        nav_cards: "Cards",
        profile_security: "Security & Sessions",
        export_json: "Export Data Archive (JSON)",
        btn_logout: "Log Out (Sign-in Screen)"
      },
      uz: {
        onb_title: "Aqlli Shaxsiy Moliya Nazorati",
        onb_sub: "Qo'lda kiritishsiz avtomatik hisob-kitob. Ijtimoiy tarmoqlar yoki telefon raqami orqali kiring.",
        login_apple: "Apple ID bilan davom etish",
        login_google: "Google orqali kirish",
        login_github: "GitHub orqali kirish",
        or_phone: "YOKI TELEFON RAQAMI ORQALI",
        btn_enter: "Ilovaga kirish →",
        non_custodial_note: "🔒 Xavfsiz: CVV, PIN saqlanmaydi va to'lovlar yechilmaydi.",
        greeting_subtitle: "Xush kelibsiz,",
        btn_sim_push: "Push Avto-yig'ish Testi",
        total_balance: "Umumiy balans",
        from_last_month: "o'tgan oyga nisbatan",
        metric_income: "Daromad",
        metric_spending: "Xarajat",
        metric_savings: "Jamg'arma",
        ai_insight_label: "AI Moliyaviy Yordamchi",
        recent_tx_title: "Avtomatik aniqlangan to'lovlar",
        see_all: "Barchasi",
        ai_screen_title: "AI Moliyaviy Maslahatchi",
        ai_screen_sub: "Haqiqiy xarajatlaringiz va balansingiz asosida",
        q1: "Mening eng ko'p pulim qayerga ketyapti?",
        q2: "Nega bu oy xarajatlarim oshdi?",
        q3: "Oyiga qancha pul tejay olaman?",
        q4: "Kreditni qanday tezroq yopish mumkin?",
        q5: "Eng katta xarajatlarim",
        ai_welcome_msg: "Salom Alex! Daromadlaringiz ($4,200) va xarajatlaringiz ($2,380) tahlil qilindi. Byudjet, kreditlar yoki xaridlar bo'yicha savol bering.",
        ai_input_placeholder: "Moliyaviy savolingizni yozing...",
        spending_month_label: "Joriy oy xarajatlari",
        below_limit: "↓ oylik reja chegarasidan 8% pastroq",
        categories_title: "Xarajat toifalari",
        top_merchants_title: "Eng ko'p xarid qilingan joylar",
        calcs_header: "Moliyaviy kalkulyatorlar",
        tab_loan: "Kredit kalkulyatori",
        tab_card: "Kredit karta",
        loan_amount: "Kredit summasi",
        loan_rate: "Yillik foiz stavkasi (%)",
        loan_term: "Kredit muddati",
        payment_type: "To'lov turi:",
        annuity: "Annuitet",
        differential: "Differensial",
        monthly_payment: "Oylik to'lov",
        total_repayment: "Jami to'lov summasi",
        overpayment: "Bankka ortiqcha to'lov",
        card_debt: "Joriy qarz summasi",
        card_limit: "Kredit limiti",
        card_apr: "Foiz stavkasi (APR %)",
        extra_pay: "Tezlashtirilgan to'lov",
        strategy_compare: "Strategiyalar taqqosi",
        min_pay_trap: "⚠️ Minimal to'lov qopqoni (5%)",
        smart_payoff: "🚀 Tezlashtirilgan to'lov rejasi",
        cards_header: "Bank kartalari",
        cards_note: "Faqat balans va xarajatlarni o'qish. Karta raqamlari yashirilgan.",
        nav_home: "Asosiy",
        nav_ai: "AI Maslahat",
        nav_spending: "Tahlil",
        nav_calcs: "Kreditlar",
        nav_cards: "Kartalar",
        profile_security: "Xavfsizlik va Sessiyalar",
        export_json: "Ma'lumotlar arxivi (JSON)",
        btn_logout: "Chiqish (Kirish ekrani)"
      }
    };

    let currentAppLang = 'ru';
    let currentAppTheme = 'dark';
    let isBalanceMasked = false;
    let currentLoanType = 'annuity';

    // =========================================================================
    // THEME & LANGUAGE CONTROLLERS
    // =========================================================================
    function toggleAppTheme() {
      const container = document.getElementById('iphoneContainer');
      currentAppTheme = currentAppTheme === 'dark' ? 'light' : 'dark';
      container.setAttribute('data-theme', currentAppTheme);

      document.getElementById('themeIcon').innerText = currentAppTheme === 'dark' ? '☀️' : '🌙';
      document.getElementById('themeLabel').innerText = currentAppTheme === 'dark' ? 'Light' : 'Dark';
    }

    function setAppLanguage(lang) {
      currentAppLang = lang;
      document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
      const activeBtn = document.getElementById(`btnLang${lang.charAt(0).toUpperCase() + lang.slice(1)}`);
      if (activeBtn) activeBtn.classList.add('active');

      const dict = I18N[lang] || I18N.ru;
      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (dict[key]) el.innerText = dict[key];
      });
      document.querySelectorAll('[data-i18n-ph]').forEach(el => {
        const key = el.getAttribute('data-i18n-ph');
        if (dict[key]) el.setAttribute('placeholder', dict[key]);
      });
    }

    // =========================================================================
    // NAVIGATION
    // =========================================================================
    function switchTab(tab) {
      document.querySelectorAll('.screen-view').forEach(s => s.classList.remove('active'));
      document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));

      const targetScreen = document.getElementById(`screen-${tab}`);
      const targetNav = document.getElementById(`tab-${tab}`);

      if (targetScreen) targetScreen.classList.add('active');
      if (targetNav) targetNav.classList.add('active');

      if (tab === 'spending') loadCategoriesData();
      if (tab === 'cards') loadCardsData();
      if (tab === 'calcs') updateLoanCalc();
    }

    function toggleMaskBalance() {
      isBalanceMasked = !isBalanceMasked;
      document.getElementById('totalBalanceVal').innerText = isBalanceMasked ? '••••••••' : '$12,480.00';
    }

    // =========================================================================
    // OAUTH & AUTH CONTROLLERS (Requirement 2)
    // =========================================================================
    async function submitSocialLogin(provider) {
      try {
        const res = await fetch('/api/v1/auth/oauth/sign-in', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({
            provider: provider,
            token_or_code: `mock-pkce-token-${Date.now()}`,
            email: `alex.mercer@${provider}.com`,
            name: "Alex Mercer",
            device_id: "ios-device-uuid-9821",
            device_name: "iPhone 15 Pro"
          })
        });
        const data = await res.json();
        switchTab('home');
        showPushNotification(`Вход через ${provider.toUpperCase()}`, 'Сессия подтверждена. Данные синхронизированы.');
      } catch (e) {
        switchTab('home');
      }
    }

    function loginWithPhone() {
      switchTab('home');
    }

    function logoutApp() {
      closeModal('profileModal');
      document.querySelectorAll('.screen-view').forEach(s => s.classList.remove('active'));
      document.getElementById('screen-onboarding').classList.add('active');
    }

    // =========================================================================
    // ZERO-MANUAL NOTIFICATION INGESTION ENGINE (Requirement 3)
    // =========================================================================
    const MOCK_PUSH_STREAM = [
      {
        app: "CLICK • ПОКУПКА",
        text: "Oplata CLICK: 45 000 UZS, Karta *4821, Mesto: Korzinka. Balans: 1 200 000 UZS",
        display: "Корзинка: списание 45 000 UZS (Продукты)",
        amountDelta: -45.0,
        type: "expense"
      },
      {
        app: "PAYME • ЗАРПЛАТА",
        text: "Zachislenie zarplaty: +8 500 000 UZS na kartu *4821. Dostupno: 9 700 000 UZS",
        display: "Поступление зарплаты: +8 500 000 UZS",
        amountDelta: +850.0,
        type: "income"
      },
      {
        app: "UZUM BANK • ПЕРЕВОД",
        text: "Perevod P2P na kartu 8600..1122: 250 000 UZS. Ostatok: 9 450 000 UZS",
        display: "Перевод на карту: -250 000 UZS",
        amountDelta: -25.0,
        type: "transfer"
      }
    ];
    let pushIndex = 0;

    async function triggerSimulatedPush() {
      const item = MOCK_PUSH_STREAM[pushIndex % MOCK_PUSH_STREAM.length];
      pushIndex++;

      // Ingest into backend parser
      try {
        await fetch('/api/v1/transactions/ingest', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({ raw_text: item.text, source: 'push' })
        });
      } catch (e) {}

      // Show top push banner
      showPushNotification(item.app, item.display);
      loadRecentTransactions();
    }

    function showPushNotification(app, body) {
      document.getElementById('pushAppTitle').innerText = app;
      document.getElementById('pushAppBody').innerText = body;
      const banner = document.getElementById('pushBanner');
      banner.classList.add('active');
      setTimeout(() => banner.classList.remove('active'), 3400);
    }

    // =========================================================================
    // CONVERSATIONAL AI ASSISTANT CONTROLLER (Requirement 6)
    // =========================================================================
    async function askAiQuestion(query) {
      addChatBubble(query, 'user');

      try {
        const res = await fetch('/api/v1/ai/chat', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({ query: query, lang: currentAppLang })
        });
        const data = await res.json();
        addChatBubble(data.reply, 'ai');
      } catch (e) {
        addChatBubble("Анализ завершен: ваши расходы находятся в безопасном лимите.", 'ai');
      }
    }

    function sendCustomAiMessage() {
      const input = document.getElementById('aiUserInputField');
      const text = input.value.trim();
      if (!text) return;
      input.value = '';
      askAiQuestion(text);
    }

    function addChatBubble(text, sender) {
      const container = document.getElementById('chatHistoryContainer');
      const bubble = document.createElement('div');
      bubble.className = `chat-bubble ${sender}`;
      bubble.innerText = text;
      container.appendChild(bubble);
      container.scrollTop = container.scrollHeight;
    }

    // =========================================================================
    // CALCULATORS CONTROLLER (Requirements 4 & 5)
    // =========================================================================
    function switchCalcSubTab(type) {
      document.getElementById('btnTabLoan').classList.toggle('active', type === 'loan');
      document.getElementById('btnTabCard').classList.toggle('active', type === 'card');
      document.getElementById('view-loan-calc').style.display = type === 'loan' ? 'block' : 'none';
      document.getElementById('view-card-calc').style.display = type === 'card' ? 'block' : 'none';
      if (type === 'loan') updateLoanCalc();
      if (type === 'card') updateCardCalc();
    }

    function setPaymentType(type) {
      currentLoanType = type;
      document.getElementById('btnAnnuity').classList.toggle('active', type === 'annuity');
      document.getElementById('btnDiff').classList.toggle('active', type === 'differential');
      updateLoanCalc();
    }

    async function updateLoanCalc() {
      const amount = parseFloat(document.getElementById('rngLoanAmount').value);
      const rate = parseFloat(document.getElementById('rngLoanRate').value);
      const term = parseInt(document.getElementById('rngLoanTerm').value);

      document.getElementById('lblLoanAmount').innerText = `$${amount.toLocaleString()}`;
      document.getElementById('lblLoanRate').innerText = `${rate}%`;
      document.getElementById('lblLoanTerm').innerText = `${term} мес`;

      try {
        const res = await fetch('/api/v1/calculators/loan', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({
            principal_amount: amount,
            annual_interest_rate: rate,
            term_months: term,
            payment_type: currentLoanType
          })
        });
        const data = await res.json();
        const r = data.result;
        document.getElementById('resMonthlyPay').innerText = `$${r.monthly_payment.toLocaleString()}`;
        document.getElementById('resTotalPayment').innerText = `$${r.total_payment.toLocaleString()}`;
        document.getElementById('resTotalInterest').innerText = `$${r.total_interest.toLocaleString()} (${r.overpayment_percentage}%)`;
      } catch (e) {}
    }

    async function updateCardCalc() {
      const debt = parseFloat(document.getElementById('rngCardDebt').value);
      const limit = parseFloat(document.getElementById('rngCardLimit').value);
      const apr = parseFloat(document.getElementById('rngCardApr').value);
      const extra = parseFloat(document.getElementById('rngCardExtra').value);

      document.getElementById('lblCardDebt').innerText = `$${debt.toLocaleString()}`;
      document.getElementById('lblCardLimit').innerText = `$${limit.toLocaleString()}`;
      document.getElementById('lblCardApr').innerText = `${apr}%`;
      document.getElementById('lblCardExtra').innerText = `+$${extra} / мес`;

      try {
        const res = await fetch('/api/v1/calculators/credit-card', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({
            current_balance: debt,
            credit_limit: limit,
            annual_interest_rate: apr,
            min_payment_percent: 5.0,
            target_monthly_payment: (debt * 0.05) + extra
          })
        });
        const data = await res.json();
        const r = data.result;

        document.getElementById('resUtilizationStatus').innerText = `Утилизация ${r.utilization_rate}% (${r.utilization_status})`;
        document.getElementById('resMinPaySummary').innerText = `Срок: ${r.minimum_payment_plan.months_to_payoff} мес • Переплата: $${r.minimum_payment_plan.total_interest.toLocaleString()}`;
        document.getElementById('resSmartPaySummary').innerText = `Срок: ${r.accelerated_payment_plan.months_to_payoff} мес • Переплата: $${r.accelerated_payment_plan.total_interest.toLocaleString()}`;
        document.getElementById('resSavingsHighlight').innerText = `Экономия: $${r.comparison.interest_saved.toLocaleString()} и ${r.comparison.months_saved} мес свободы от долга!`;
      } catch (e) {}
    }

    // =========================================================================
    // DATA LOADERS
    // =========================================================================
    async function loadRecentTransactions() {
      try {
        const res = await fetch('/api/v1/transactions/');
        if (res.ok) {
          const data = await res.json();
          const html = data.transactions.slice(0, 4).map(t => `
            <div style="display:flex; justify-content:space-between; align-items:center; padding:10px 0; border-bottom:1px solid var(--border-soft);">
              <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:36px; height:36px; border-radius:12px; background:var(--card-surface); border:1px solid var(--border-soft); display:flex; align-items:center; justify-content:center;">
                  ${t.direction === 'income' ? '💰' : '💳'}
                </div>
                <div>
                  <div style="font-size:13px; font-weight:700; color:var(--text-primary);">${t.merchant}</div>
                  <div style="font-size:11px; color:var(--text-muted);">${t.source.toUpperCase()} • *${t.card_last4 || '4821'}</div>
                </div>
              </div>
              <div style="text-align:right;">
                <div style="font-size:13.5px; font-weight:700; color:${t.direction === 'income' ? 'var(--income-green)' : 'var(--text-primary)'};">
                  ${t.direction === 'income' ? '+' : '-'}${Number(t.amount).toLocaleString()} ${t.currency}
                </div>
                <div style="font-size:10px; color:var(--cyan-accent); font-weight:600;">100% авто</div>
              </div>
            </div>
          `).join('');
          document.getElementById('homeRecentTxList').innerHTML = html;
        }
      } catch (e) {}
    }

    async function loadCategoriesData() {
      try {
        const res = await fetch('/api/v1/analytics/categories');
        if (res.ok) {
          const data = await res.json();
          const catHtml = data.categories.map(c => `
            <div style="margin-bottom:12px;">
              <div style="display:flex; justify-content:space-between; font-size:13px;">
                <span>${c.icon} ${c.name}</span>
                <span style="font-weight:700; color:var(--text-primary);">$${c.amount} (${c.percentage}%)</span>
              </div>
              <div style="height:6px; border-radius:3px; background:var(--input-bg); overflow:hidden; margin-top:6px;">
                <div style="height:100%; width:${c.percentage}%; background:${c.color}; border-radius:3px;"></div>
              </div>
            </div>
          `).join('');
          document.getElementById('categoriesListContainer').innerHTML = catHtml;

          const merchHtml = data.top_merchants.map(m => `
            <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px solid var(--border-soft);">
              <div>
                <div style="font-size:13px; font-weight:700; color:var(--text-primary);">${m.merchant}</div>
                <div style="font-size:11px; color:var(--text-muted);">${m.count} покупок</div>
              </div>
              <div style="font-size:13px; font-weight:700; color:var(--text-primary);">$${m.amount}</div>
            </div>
          `).join('');
          document.getElementById('topMerchantsListContainer').innerHTML = merchHtml;
        }
      } catch (e) {}
    }

    async function loadCardsData() {
      try {
        const res = await fetch('/api/v1/cards/');
        if (res.ok) {
          const data = await res.json();
          const html = data.cards.map((c, i) => `
            <div style="height:130px; border-radius:20px; padding:16px; margin-bottom:12px; background:linear-gradient(135deg, ${i%2===0 ? '#1e3a8a, #0f172a' : '#7c3aed, #0f172a'}); border:1px solid rgba(255,255,255,0.15); display:flex; flex-direction:column; justify-content:space-between; color:#fff;">
              <div style="display:flex; justify-content:space-between;">
                <span style="font-weight:800;">${c.bank_name}</span>
                <span style="font-size:11px; padding:2px 8px; border-radius:10px; background:rgba(255,255,255,0.2);">${c.card_type}</span>
              </div>
              <div>
                <div style="font-size:17px; letter-spacing:2px; font-weight:700;">${c.masked_number}</div>
                <div style="font-size:11px; opacity:0.8;">${c.card_name} • $${c.monthly_spending || 0}/мес</div>
              </div>
            </div>
          `).join('');
          document.getElementById('cardsListContainer').innerHTML = html;
        }
      } catch (e) {}
    }

    function openProfileModal() { document.getElementById('profileModal').classList.add('active'); }
    function closeModal(id) { document.getElementById(id).classList.remove('active'); }

    async function downloadDataArchive() {
      try {
        const res = await fetch('/api/v1/auth/export');
        const data = await res.json();
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `spendly_data_archive_${new Date().toISOString().slice(0,10)}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
      } catch (e) {
        alert("Экспорт сформирован");
      }
    }

    // Init
    loadRecentTransactions();
    updateLoanCalc();
  </script>
</body>
</html>
"""

with open(r"c:\Users\umara\.gemini\config\plugins\understand-anything\agents\finance_app\backend\app\static\mobile_preview.html", "w", encoding="utf-8") as f:
    f.write(PREVIEW_HTML)

print("mobile_preview.html updated successfully!")
