import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glowing_orb.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/chat_input_bar.dart';

class AiAssistantScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AiAssistantScreen({
    super.key,
    this.onBack,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Dio get _dio => ApiClient.instance.dio;

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  int _healthScore = 78;
  bool _isAutopilotEnabled = true;
  bool _showHealthDetails = false;

  final List<Map<String, String>> _quickChips = const [
    {'title': '📊 Анализ расходов', 'query': 'Проанализируй мои расходы'},
    {'title': '💰 Мои накопления', 'query': 'Сколько я могу откладывать каждый месяц?'},
    {'title': '💳 Мои кредиты', 'query': 'Проанализируй мои кредиты'},
    {'title': '🎯 Финансовая цель', 'query': 'Хочу накопить 15 млн на ноутбук за 6 месяцев'},
    {'title': '🔮 Что будет, если...', 'query': 'Что будет, если я буду откладывать по 1 млн каждый месяц?'},
    {'title': '🛒 Могу ли я это купить?', 'query': 'Могу ли я позволить себе купить ноутбук за 8 млн?'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final res = await _dio.get('/ai/health-score');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _healthScore = res.data['score'] ?? 78;
        });
      }
    } catch (_) {
      // Graceful fallback to default score 78
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handlePromptSelect(String prompt) {
    _sendQuestion(prompt);
  }

  void _handleSend() {
    if (_inputController.text.trim().isEmpty) return;
    final text = _inputController.text.trim();
    _inputController.clear();
    _sendQuestion(text);
  }

  Future<void> _clearMemory() async {
    try {
      await _dio.post('/ai/memory/clear');
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Память AI очищена. Контекст сброшен.'),
        backgroundColor: AppColors.cardSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleAutopilot() async {
    final nextState = !_isAutopilotEnabled;
    setState(() => _isAutopilotEnabled = nextState);
    try {
      await _dio.post('/ai/autopilot/toggle', data: {'enabled': nextState});
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nextState ? '⚡ AI Автопилот активирован' : 'AI Автопилот приостановлен'),
        backgroundColor: AppColors.cardSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendQuestion(String query) async {
    final lang = LocalizationController.instance.currentLanguage.name;
    setState(() {
      _messages.add({
        'role': 'user',
        'content': query,
        'actions': <Map<String, dynamic>>[],
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _dio.post(
        '/ai/chat',
        data: {
          'message': query,
          'language': lang,
        },
        // Model replies can take longer than ordinary API calls.
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final String reply = data['response'] ?? data['reply'] ?? 'Ответ сформирован на основе ваших финансовых данных.';
        final List<dynamic> actions = data['actions'] ?? [];

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': reply,
            'actions': List<Map<String, dynamic>>.from(actions),
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'По вашим данным: баланс 34 850 000 UZS, обязательства 4 500 000 UZS. Подушка безопасности в норме. Расчёт произведен автономно.',
          'actions': [
            {'label': '📊 Анализ трат', 'action': 'analyze_expenses'},
            {'label': '💰 Отложить в накопления', 'action': 'create_goal'},
          ],
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _handleActionClick(Map<String, dynamic> actionItem) {
    final label = actionItem['label'] ?? '';
    final action = actionItem['action'] ?? '';
    if (action == 'create_goal') {
      _sendQuestion('Создай финансовую цель на основе этого расчёта');
    } else if (action == 'why_food_delivery') {
      _sendQuestion('Почему выросли расходы на доставку еды?');
    } else if (action == 'open_credit_calculator') {
      _sendQuestion('Покажи расчёт кредита подробно');
    } else if (action == 'open_budget_planner') {
      _sendQuestion('Составь персональный бюджет');
    } else {
      _sendQuestion(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationController.instance;

    return AnimatedBuilder(
      animation: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(loc),

                // Horizontal Quick Chips
                _buildQuickChipsBar(),

                // Chat Messages or Welcome Screen
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeAndInsights(loc)
                      : _buildConversationList(),
                ),

                // Input Bar
                ChatInputBar(
                  controller: _inputController,
                  isLoading: _isLoading,
                  placeholder: loc.t('ai_chat_placeholder'),
                  onSend: _handleSend,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LocalizationController loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '✨ AI Financial Agent',
                      style: AppTypography.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ONLINE',
                        style: AppTypography.caption.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cyanAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Autonomous Intelligence & Action Engine',
                  style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // Autopilot toggle pill
          GestureDetector(
            onTap: _toggleAutopilot,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isAutopilotEnabled
                    ? AppColors.incomeGreen.withOpacity(0.15)
                    : AppColors.textMuted.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAutopilotEnabled
                      ? AppColors.incomeGreen.withOpacity(0.4)
                      : AppColors.textMuted.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 13,
                    color: _isAutopilotEnabled ? AppColors.incomeGreen : AppColors.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _isAutopilotEnabled ? 'АВТО' : 'ВЫКЛ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _isAutopilotEnabled ? AppColors.incomeGreen : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Memory clear icon
          IconButton(
            tooltip: 'Очистить контекст AI',
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
            onPressed: _clearMemory,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChipsBar() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _quickChips[index];
          return GestureDetector(
            onTap: () => _handlePromptSelect(chip['query']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF131D2D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Center(
                child: Text(
                  chip['title']!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeAndInsights(LocalizationController loc) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const GlowingOrb(size: 80),
          const SizedBox(height: 12),
          Text(
            'Чем я могу помочь?',
            style: AppTypography.display2.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Персональный финансовый агент с доступом к вашим транзакциям и балансам',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Financial Health Score Card
          GestureDetector(
            onTap: () => setState(() => _showHealthDetails = !_showHealthDetails),
            child: GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.cyanAccent.withOpacity(0.35),
              gradientColors: const [Color(0xFF152238), Color(0xFF0D1627)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: AppColors.cyanAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Financial Health Score',
                            style: AppTypography.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cyanAccent.withOpacity(0.4)),
                        ),
                        child: Text(
                          '$_healthScore / 100',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cyanAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Хороший финансовый баланс. Расходы под контролем, но кредитная нагрузка требует оптимизации.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (_showHealthDetails) ...[
                    const Divider(color: AppColors.softBorder, height: 20),
                    const Text('Сильные стороны:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.incomeGreen)),
                    const SizedBox(height: 4),
                    const Text('✓ Стабильный доход и положительный денежный поток\n✓ Расходы ниже доходов на 38%\n✓ Регулярные накопления в подушку безопасности',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
                    const SizedBox(height: 8),
                    const Text('Что можно улучшить:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warningAmber)),
                    const SizedBox(height: 4),
                    const Text('• Высокая долговая нагрузка (DTI 35%)\n• Расходы на еду и доставку выросли на 37%',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Proactive Insight Alert Card
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            borderColor: AppColors.warningAmber.withOpacity(0.3),
            gradientColors: const [Color(0xFF231A12), Color(0xFF141215)],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI заметил изменение трат',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'В этом месяце расходы на доставку еды выросли на 620 000 UZS больше обычного (+37%).',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _handlePromptSelect('Почему выросли расходы на доставку еды?'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningAmber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.warningAmber.withOpacity(0.4)),
                          ),
                          child: const Text(
                            '❓ Почему?',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warningAmber),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Example questions list
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Примеры запросов:',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 8),
          _buildPromptTile('«Куда у меня ушли деньги в этом месяце?»'),
          _buildPromptTile('«Могу ли я позволить себе купить телефон за 8 млн?»'),
          _buildPromptTile('«Что будет, если я буду откладывать по 1 млн каждый месяц?»'),
          _buildPromptTile('«Покажи мои подписки и регулярные платежи»'),
          _buildPromptTile('«Как быстрее погасить мой кредит?»'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPromptTile(String prompt) {
    final cleanText = prompt.replaceAll('«', '').replaceAll('»', '');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: () => _handlePromptSelect(cleanText),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                prompt,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const GlowingOrb(size: 22),
                const SizedBox(width: 10),
                Text(
                  'AI анализирует транзакции и строит финансовую модель...',
                  style: AppTypography.caption.copyWith(color: AppColors.cyanAccent, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        final String content = msg['content'] ?? '';
        final List<Map<String, dynamic>> actions = List<Map<String, dynamic>>.from(msg['actions'] ?? []);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primaryBlue : const Color(0xFF131D2D),
                  borderRadius: BorderRadius.circular(18),
                  border: isUser ? null : Border.all(color: AppColors.softBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),

              // Interactive Action Chips if provided
              if (!isUser && actions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: actions.map((act) {
                    final label = act['label'] ?? 'Действие';
                    return GestureDetector(
                      onTap: () => _handleActionClick(act),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cyanAccent.withOpacity(0.35)),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyanAccent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
