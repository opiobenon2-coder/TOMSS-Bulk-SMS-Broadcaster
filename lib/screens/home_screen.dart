import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../services/sms_service.dart';
import '../services/database_service.dart';
import 'compose_screen.dart';
import 'contacts_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  final List<Widget> _screens = [
    const ComposeScreen(),
    const ContactsScreen(),
    const LogsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Compose Message',
    'Contacts',
    'Message Logs',
    'Settings',
  ];

  final List<IconData> _icons = [
    Icons.edit,
    Icons.contacts,
    Icons.history,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize SMS service
      final smsInitialized = await SMSService.instance.initialize();
      if (!smsInitialized) {
        _showErrorSnackBar('Failed to initialize SMS service');
      }
    } catch (e) {
      _showErrorSnackBar('Service initialization error: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final dbStats = await DatabaseService.instance.getStatistics();
      final smsStats = await SMSService.instance.getStatistics();
      
      setState(() {
        _statistics = {
          ...dbStats,
          ...smsStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load statistics: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _logout();
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppTheme.errorColor),
                  title: Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Dashboard
          _buildStatisticsDashboard(),
          
          // Main Content
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        items: List.generate(_icons.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index].split(' ').first,
          );
        }),
      ),
    );
  }

  Widget _buildStatisticsDashboard() {
    if (_isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // School Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TORORO MIXED S.S',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Bulk SMS Dashboard',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Statistics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Contacts',
                      '${_statistics['totalContacts'] ?? 0}',
                      Icons.contacts,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Sent',
                      '${_statistics['sentMessages'] ?? 0}',
                      Icons.send,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Failed',
                      '${_statistics['failedMessages'] ?? 0}',
                      Icons.error,
                      AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Success',
                      '${_statistics['successRate'] ?? '0.0'}%',
                      Icons.check_circle,
                      AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About TOMSS Bulk SMS'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TORORO MIXED SECONDARY SCHOOL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Motto: "Onwards and Forward"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Bulk SMS Broadcaster v1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Offline SMS broadcasting system for school communication without third-party APIs.',
              ),
              SizedBox(height: 16),
              Text(
                'Developer Information:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Name: Opio Benon'),
              Text('Slogan: "The Computer Guy"'),
              Text('Email: opiobenon73@gmail.com'),
              Text('Phone: 0754754704 / 0786835338'),
              SizedBox(height: 16),
              Text(
                '© 2024 Tororo Mixed Secondary School',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}