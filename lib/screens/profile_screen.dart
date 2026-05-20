import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';
import '../models/user_profile.dart';
import 'main_dashboard_screen.dart'; // Для перезагрузки после сброса

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _notificationsEnabled = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final hiveService = HiveService();
    final profile = hiveService.getProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _notificationsEnabled = profile.notificationsEnabled;
      });
    }
  }

  void _saveProfile() {
    final hiveService = HiveService();
    final newProfile = _profile!.copyWith(
      name: _nameController.text.trim().isEmpty ? 'Аноним' : _nameController.text.trim(),
      notificationsEnabled: _notificationsEnabled,
    );
    hiveService.saveProfile(newProfile);
    setState(() => _profile = newProfile);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль сохранен'), backgroundColor: Colors.green),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Полное удаление данных'),
        content: const Text('Вы уверены? Это удалит все лекарства, симптомы и настройки безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await HiveService().clearAllData();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Удалить всё', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Аватарка (заглушка)
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFE8A4B8).withOpacity(0.2),
                child: const Icon(Icons.person, size: 50, color: Color(0xFFE8A4B8)),
              ),
            ),
            const SizedBox(height: 20),

            // ✏️ Поле имени
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Ваше имя или псевдоним',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => _saveProfile(),
            ),
            
            const SizedBox(height: 20),

            // 🔔 Переключатель уведомлений
            Card(
              child: SwitchListTile(
                title: const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Напоминания о приеме лекарств'),
                value: _notificationsEnabled,
                activeColor: const Color(0xFFE8A4B8),
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _saveProfile();
                },
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // ⚙️ Кнопка сброса
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Очистить все данные', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Удалить историю, лекарства и настройки'),
              onTap: _clearAllData,
            ),

            const SizedBox(height: 40),

            // ⚖️ Юридический блок (Privacy)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      Text('Конфиденциальность', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Все ваши данные (лекарства, симптомы, цикл) хранятся исключительно на этом устройстве в зашифрованном виде. Мы не собираем, не обрабатываем и не передаем ваши персональные данные третьим лицам или на сервер.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Версия приложения: 1.0.0 (Beta)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}