import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../utils/theme.dart';
import '../services/database_service.dart';
import '../models/message_log.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService.instance;
  late TabController _tabController;
  
  List<MessageLog> _allLogs = [];
  List<MessageLog> _filteredLogs = [];
  bool _isLoading = false;
  String _currentFilter = 'all';

  final Map<String, String> _filterTabs = {
    'all': 'All',
    'sent': 'Sent',
    'delivered': 'Delivered',
    'failed': 'Failed',
    'pending': 'Pending',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final filterKey = _filterTabs.keys.elementAt(_tabController.index);
      setState(() {
        _currentFilter = filterKey;
      });
      _filterLogs();
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _db.getAllMessageLogs();
      setState(() {
        _allLogs = logs;
        _isLoading = false;
      });
      _filterLogs();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load message logs: $e');
    }
  }

  void _filterLogs() {
    List<MessageLog> filtered = _allLogs;

    switch (_currentFilter) {
      case 'sent':
        filtered = _allLogs.where((log) => log.status == MessageStatus.sent).toList();
        break;
      case 'delivered':
        filtered = _allLogs.where((log) => log.status == MessageStatus.delivered).toList();
        break;
      case 'failed':
        filtered = _allLogs.where((log) => log.status == MessageStatus.failed).toList();
        break;
      case 'pending':
        filtered = _allLogs.where((log) => log.status == MessageStatus.pending).toList();
        break;
      default:
        filtered = _allLogs;
    }

    setState(() {
      _filteredLogs = filtered;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      
      // Add page with logs
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TORORO MIXED SECONDARY SCHOOL',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'SMS Delivery Report',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Statistics
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary Statistics',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total Messages', _allLogs.length.toString()),
                        _buildStatItem('Sent', _allLogs.where((l) => l.status == MessageStatus.sent).length.toString()),
                        _buildStatItem('Delivered', _allLogs.where((l) => l.status == MessageStatus.delivered).length.toString()),
                        _buildStatItem('Failed', _allLogs.where((l) => l.status == MessageStatus.failed).length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Logs Table
              pw.Text(
                'Message Logs (${_filteredLogs.length} records)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(3),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildTableCell('Recipient', isHeader: true),
                      _buildTableCell('Phone', isHeader: true),
                      _buildTableCell('Status', isHeader: true),
                      _buildTableCell('Sent At', isHeader: true),
                      _buildTableCell('Message', isHeader: true),
                    ],
                  ),
                  
                  // Data rows
                  ..._filteredLogs.take(100).map((log) => pw.TableRow(
                    children: [
                      _buildTableCell(log.recipientName),
                      _buildTableCell(log.recipientPhone),
                      _buildTableCell(log.statusDisplayName),
                      _buildTableCell(DateFormat('dd/MM HH:mm').format(log.sentAt)),
                      _buildTableCell(log.messagePreview),
                    ],
                  )),
                ],
              ),
              
              if (_filteredLogs.length > 100)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text(
                    'Note: Only first 100 records shown. Total: ${_filteredLogs.length}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Divider(),
              pw.Text(
                'Developed by Opio Benon - "The Computer Guy" | opiobenon73@gmail.com',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/TOMSS_SMS_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      _showSuccessSnackBar('Report exported to: ${file.path}');
    } catch (e) {
      _showErrorSnackBar('Failed to export report: $e');
    }
  }

  pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  void _showLogDetails(MessageLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Details - ${log.statusDisplayName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Recipient', log.recipientName),
              _buildDetailRow('Phone', log.recipientPhone),
              _buildDetailRow('Status', log.statusDisplayName),
              _buildDetailRow('Sent At', DateFormat('dd/MM/yyyy HH:mm:ss').format(log.sentAt)),
              if (log.deliveredAt != null)
                _buildDetailRow('Delivered At', DateFormat('dd/MM/yyyy HH:mm:ss').format(log.deliveredAt!)),
              if (log.errorMessage != null)
                _buildDetailRow('Error', log.errorMessage!),
              _buildDetailRow('Retry Count', log.retryCount.toString()),
              const SizedBox(height: 16),
              const Text(
                'Message Content:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  log.messageContent,
                  style: const TextStyle(fontSize: 14),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
      case MessageStatus.delivered:
        return AppTheme.successColor;
      case MessageStatus.failed:
      case MessageStatus.cancelled:
        return AppTheme.errorColor;
      case MessageStatus.pending:
        return AppTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: _filterTabs.values.map((label) => Tab(text: label)).toList(),
          ),
        ),
        
        // Export Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Showing ${_filteredLogs.length} messages',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _filteredLogs.isEmpty ? null : _exportToPDF,
                icon: const Icon(Icons.download),
                label: const Text('Export PDF'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // Logs List
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _allLogs.isEmpty 
                          ? 'No message logs yet' 
                          : 'No ${_currentFilter == 'all' ? '' : _currentFilter} messages',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _allLogs.isEmpty 
                          ? 'Send some messages to see logs here' 
                          : 'Try selecting a different filter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getStatusColor(log.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(log.status).withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              log.statusIcon,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        title: Text(
                          log.recipientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.recipientPhone),
                            const SizedBox(height: 2),
                            Text(
                              log.messagePreview,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(log.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                log.statusDisplayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.formattedSentTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showLogDetails(log),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}