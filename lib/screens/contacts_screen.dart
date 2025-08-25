import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../utils/theme.dart';
import '../services/database_service.dart';
import '../models/contact.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final _searchController = TextEditingController();
  
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  List<String> _groups = [];
  String? _selectedGroup;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _db.getAllContacts();
      final groups = await _db.getAllGroups();

      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _groups = ['All Groups', ...groups];
        _selectedGroup = 'All Groups';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load contacts: $e');
    }
  }

  void _filterContacts() {
    String query = _searchController.text.toLowerCase();
    List<Contact> filtered = _contacts;

    // Filter by group
    if (_selectedGroup != null && _selectedGroup != 'All Groups') {
      filtered = filtered.where((contact) => contact.groupName == _selectedGroup).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
               contact.phone.toLowerCase().contains(query) ||
               (contact.parentName?.toLowerCase().contains(query) ?? false) ||
               (contact.studentName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() {
      _filteredContacts = filtered;
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

  Future<void> _importFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String csvData = await file.readAsString();
        
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
        
        if (csvTable.isEmpty) {
          _showErrorSnackBar('CSV file is empty');
          return;
        }

        // Skip header row if it exists
        List<List<dynamic>> dataRows = csvTable.length > 1 && 
          csvTable[0].any((cell) => cell.toString().toLowerCase().contains('name'))
          ? csvTable.skip(1).toList()
          : csvTable;

        List<Contact> newContacts = [];
        int successCount = 0;
        int errorCount = 0;

        for (var row in dataRows) {
          try {
            if (row.length >= 3) {
              String name = row[0]?.toString().trim() ?? '';
              String phone = row[1]?.toString().trim() ?? '';
              String group = row[2]?.toString().trim() ?? 'Imported';
              String? classLevel = row.length > 3 ? row[3]?.toString().trim() : null;
              String? parentName = row.length > 4 ? row[4]?.toString().trim() : null;
              String? studentName = row.length > 5 ? row[5]?.toString().trim() : null;

              if (name.isNotEmpty && phone.isNotEmpty) {
                Contact contact = Contact(
                  name: name,
                  phone: phone,
                  groupName: group,
                  classLevel: classLevel,
                  parentName: parentName,
                  studentName: studentName,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (contact.isValid) {
                  newContacts.add(contact);
                  successCount++;
                } else {
                  errorCount++;
                }
              } else {
                errorCount++;
              }
            } else {
              errorCount++;
            }
          } catch (e) {
            errorCount++;
          }
        }

        if (newContacts.isNotEmpty) {
          await _db.bulkInsertContacts(newContacts);
          await _loadData();
          _showSuccessSnackBar('Imported $successCount contacts successfully!');
          
          if (errorCount > 0) {
            _showErrorSnackBar('$errorCount rows had errors and were skipped');
          }
        } else {
          _showErrorSnackBar('No valid contacts found in CSV file');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to import CSV: $e');
    }
  }

  Future<void> _addContact() async {
    final result = await showDialog<Contact>(
      context: context,
      builder: (context) => AddContactDialog(groups: _groups.where((g) => g != 'All Groups').toList()),
    );

    if (result != null) {
      try {
        await _db.insertContact(result);
        await _loadData();
        _showSuccessSnackBar('Contact added successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to add contact: $e');
      }
    }
  }

  Future<void> _editContact(Contact contact) async {
    final result = await showDialog<Contact>(
      context: context,
      builder: (context) => AddContactDialog(
        contact: contact,
        groups: _groups.where((g) => g != 'All Groups').toList(),
      ),
    );

    if (result != null) {
      try {
        await _db.updateContact(result);
        await _loadData();
        _showSuccessSnackBar('Contact updated successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to update contact: $e');
      }
    }
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteContact(contact.id!);
        await _loadData();
        _showSuccessSnackBar('Contact deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to delete contact: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Search and Filter Section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search contacts',
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name, phone, or parent name',
                ),
                onChanged: (_) => _filterContacts(),
              ),
              
              const SizedBox(height: 12),
              
              // Filter and Actions Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Group',
                        prefixIcon: Icon(Icons.filter_list),
                      ),
                      items: _groups.map((group) => DropdownMenuItem<String>(
                        value: group,
                        child: Text(group),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup = value;
                        });
                        _filterContacts();
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Action Buttons
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add),
                    onSelected: (value) {
                      switch (value) {
                        case 'add':
                          _addContact();
                          break;
                        case 'import':
                          _importFromCSV();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'add',
                        child: ListTile(
                          leading: Icon(Icons.person_add),
                          title: Text('Add Contact'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'import',
                        child: ListTile(
                          leading: Icon(Icons.upload_file),
                          title: Text('Import CSV'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Contact Count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            'Showing ${_filteredContacts.length} of ${_contacts.length} contacts',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        
        // Contacts List
        Expanded(
          child: _filteredContacts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.contacts,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _contacts.isEmpty 
                        ? 'No contacts yet' 
                        : 'No contacts match your search',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _contacts.isEmpty 
                        ? 'Add contacts manually or import from CSV' 
                        : 'Try adjusting your search or filter',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (_contacts.isEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Contact'),
                      ),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          contact.name.isNotEmpty 
                            ? contact.name[0].toUpperCase() 
                            : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.phone),
                          Text(
                            '${contact.groupName}${contact.classLevel != null ? ' • ${contact.classLevel}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editContact(contact);
                              break;
                            case 'delete':
                              _deleteContact(contact);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: AppTheme.errorColor),
                              title: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

class AddContactDialog extends StatefulWidget {
  final Contact? contact;
  final List<String> groups;

  const AddContactDialog({
    super.key,
    this.contact,
    required this.groups,
  });

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _studentNameController = TextEditingController();
  
  String? _selectedGroup;
  String? _selectedClass;

  final List<String> _classes = ['S.1', 'S.2', 'S.3', 'S.4', 'S.5', 'S.6'];

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phone;
      _parentNameController.text = widget.contact!.parentName ?? '';
      _studentNameController.text = widget.contact!.studentName ?? '';
      _selectedGroup = widget.contact!.groupName;
      _selectedClass = widget.contact!.classLevel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentNameController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (!_formKey.currentState!.validate()) return;

    final contact = Contact(
      id: widget.contact?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      groupName: _selectedGroup!,
      classLevel: _selectedClass,
      parentName: _parentNameController.text.trim().isEmpty 
        ? null 
        : _parentNameController.text.trim(),
      studentName: _studentNameController.text.trim().isEmpty 
        ? null 
        : _studentNameController.text.trim(),
      createdAt: widget.contact?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+256754123456',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  
                  final contact = Contact(
                    name: 'temp',
                    phone: value.trim(),
                    groupName: 'temp',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  if (!contact.isValidPhoneNumber) {
                    return 'Please enter a valid Ugandan phone number';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: 'Group *',
                  prefixIcon: Icon(Icons.group),
                ),
                items: widget.groups.map((group) => DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a group';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class (Optional)',
                  prefixIcon: Icon(Icons.school),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select Class'),
                  ),
                  ..._classes.map((cls) => DropdownMenuItem<String>(
                    value: cls,
                    child: Text(cls),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Parent Name (Optional)',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name (Optional)',
                  prefixIcon: Icon(Icons.child_care),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          child: Text(widget.contact == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}