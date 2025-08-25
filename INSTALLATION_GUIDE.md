# TOMSS Bulk SMS Broadcaster - Installation Guide

## 📱 System Requirements

### Minimum Requirements
- **Android Version**: 5.0 (API level 21) or higher
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 100MB free space
- **Network**: SIM card with SMS capability
- **Permissions**: SMS, Phone, Storage access

### Supported Networks
- ✅ MTN Uganda
- ✅ Airtel Uganda  
- ✅ Lyca Mobile
- ✅ Smile Telecom
- ✅ Other Ugandan networks

## 🚀 Installation Steps

### Method 1: Direct APK Installation

1. **Download the APK**
   - Get `TOMSS-Bulk-SMS-v1.0.0.apk` from the releases
   - Or build from source code

2. **Enable Unknown Sources**
   - Go to Settings > Security
   - Enable "Install from Unknown Sources"
   - Or "Allow from this source" for Android 8+

3. **Install the App**
   - Tap the downloaded APK file
   - Follow installation prompts
   - Grant required permissions

4. **First Launch**
   - Open the app
   - Login with default credentials:
     - Username: `TOMSS`
     - Password: `Admin`

### Method 2: Build from Source

1. **Prerequisites**
   ```bash
   # Install Flutter SDK
   flutter --version
   
   # Install Android Studio
   # Setup Android SDK
   ```

2. **Clone Repository**
   ```bash
   git clone https://github.com/opiobenon2-coder/TOMSS-Bulk-SMS-Broadcaster.git
   cd TOMSS-Bulk-SMS-Broadcaster
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Build APK**
   ```bash
   # Debug build
   flutter build apk --debug
   
   # Release build
   flutter build apk --release
   ```

5. **Install on Device**
   ```bash
   flutter install
   ```

## ⚙️ Initial Setup

### 1. Login Configuration
- **Default Username**: `TOMSS`
- **Default Password**: `Admin`
- **Important**: Change password after first login!

### 2. Permissions Setup
The app will request these permissions:
- **SMS**: Send and read SMS messages
- **Phone**: Access phone state and numbers
- **Storage**: Import/export contacts and reports
- **Contacts**: Optional - import phone contacts

### 3. SIM Card Configuration
- Ensure SIM card has sufficient credit
- Test SMS functionality with a single message first
- Check network signal strength

## 📋 Post-Installation Checklist

### ✅ Basic Setup
- [ ] App installed successfully
- [ ] Login with default credentials
- [ ] Change admin password
- [ ] Grant all required permissions
- [ ] Test SMS sending with one contact

### ✅ Contact Management
- [ ] Add test contact manually
- [ ] Import contacts from CSV (optional)
- [ ] Create contact groups (Parents, Staff, etc.)
- [ ] Verify phone number formats

### ✅ Message Testing
- [ ] Send test message to yourself
- [ ] Verify message delivery
- [ ] Check message logs
- [ ] Test different message lengths

### ✅ Advanced Features
- [ ] Create message templates
- [ ] Test bulk SMS with small group
- [ ] Export delivery reports
- [ ] Backup contact data

## 🔧 Troubleshooting

### Common Issues

#### 1. Installation Failed
**Problem**: "App not installed" error
**Solutions**:
- Enable "Install from Unknown Sources"
- Clear storage space (need 100MB+)
- Restart device and try again
- Check Android version compatibility

#### 2. SMS Not Sending
**Problem**: Messages stuck in "Pending" status
**Solutions**:
- Check SIM card credit/balance
- Verify network signal strength
- Restart the app
- Check SMS permissions granted
- Try different SIM slot (dual SIM phones)

#### 3. Permission Denied
**Problem**: App crashes or features don't work
**Solutions**:
- Go to Settings > Apps > TOMSS Bulk SMS > Permissions
- Enable all required permissions
- Restart the app

#### 4. Contact Import Issues
**Problem**: CSV import fails
**Solutions**:
- Check CSV format: Name, Phone, Group, Class, Parent, Student
- Ensure phone numbers are in correct format (+256...)
- Remove special characters from names
- Save CSV with UTF-8 encoding

#### 5. Database Errors
**Problem**: App crashes on startup
**Solutions**:
- Clear app data (Settings > Apps > TOMSS > Storage > Clear Data)
- Reinstall the app
- Restore from backup if available

### Performance Optimization

#### For Large Contact Lists (500+ contacts)
- Import contacts in batches of 100
- Use message scheduling for large broadcasts
- Monitor device memory usage
- Close other apps during bulk sending

#### For Better Delivery Rates
- Send during business hours (8AM - 6PM)
- Add 2-3 second delays between messages
- Monitor failed messages and retry
- Keep messages under 160 characters when possible

## 📞 Support Information

### Technical Support
- **Developer**: Opio Benon
- **Email**: opiobenon73@gmail.com
- **Phone**: 0754754704 / 0786835338
- **Slogan**: "The Computer Guy"

### School Contact
- **Institution**: Tororo Mixed Secondary School
- **Motto**: "Onwards and Forward"

### Getting Help
1. Check this installation guide first
2. Review the troubleshooting section
3. Contact technical support with:
   - Device model and Android version
   - Error messages or screenshots
   - Steps to reproduce the issue
   - Network provider information

## 🔄 Updates and Maintenance

### Regular Maintenance
- **Weekly**: Check message logs and delivery rates
- **Monthly**: Export and backup contact data
- **Quarterly**: Review and update contact groups
- **Annually**: Change admin password

### Update Process
1. Download new APK version
2. Install over existing app (data preserved)
3. Test functionality after update
4. Report any issues to developer

### Backup Recommendations
- Export contacts to CSV monthly
- Save message templates
- Keep delivery reports for records
- Document any custom settings

---

**© 2024 Tororo Mixed Secondary School**  
**Developed by Opio Benon - "The Computer Guy"**