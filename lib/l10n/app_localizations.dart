import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// No description provided for @homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homework;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @fees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get fees;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'CLASS'**
  String get classLabel;

  /// No description provided for @sectionLabel.
  ///
  /// In en, this message translates to:
  /// **'SECTION'**
  String get sectionLabel;

  /// No description provided for @admissionNoLabel.
  ///
  /// In en, this message translates to:
  /// **'ADM. NO'**
  String get admissionNoLabel;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get contactLabel;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'ATTENDANCE'**
  String get attendanceTitle;

  /// No description provided for @todayStatus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Status'**
  String get todayStatus;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @holiday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get holiday;

  /// No description provided for @leaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Leave Details'**
  String get leaveDetails;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @workingDays.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDays;

  /// No description provided for @leaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leaves;

  /// No description provided for @attendancePercentage.
  ///
  /// In en, this message translates to:
  /// **'Attendance %'**
  String get attendancePercentage;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @todayAlerts.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Alerts'**
  String get todayAlerts;

  /// No description provided for @exams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exams;

  /// No description provided for @feeDetails.
  ///
  /// In en, this message translates to:
  /// **'Fee Details'**
  String get feeDetails;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your school account'**
  String get signInSubtitle;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile / Admission No'**
  String get mobileLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get nextButton;

  /// No description provided for @emptyFieldError.
  ///
  /// In en, this message translates to:
  /// **'Enter username and password'**
  String get emptyFieldError;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @schoolIdLabel.
  ///
  /// In en, this message translates to:
  /// **'School ID'**
  String get schoolIdLabel;

  /// No description provided for @sendOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtpButton;

  /// No description provided for @enterYourRegisteredMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered mobile number'**
  String get enterYourRegisteredMobile;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @noHomework.
  ///
  /// In en, this message translates to:
  /// **'No homework found'**
  String get noHomework;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @noDetails.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get noDetails;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get savedTo;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @mediaPermissionReq.
  ///
  /// In en, this message translates to:
  /// **'Media permission is required'**
  String get mediaPermissionReq;

  /// No description provided for @storagePermissionReq.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get storagePermissionReq;

  /// No description provided for @cannotAccessFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot access download folder'**
  String get cannotAccessFolder;

  /// No description provided for @searchNotifications.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchNotifications;

  /// No description provided for @noNoficationFound.
  ///
  /// In en, this message translates to:
  /// **'No notifications found'**
  String get noNoficationFound;

  /// No description provided for @filterNotification.
  ///
  /// In en, this message translates to:
  /// **'Filter Notifications'**
  String get filterNotification;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @allCategory.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategory;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @overdueFees.
  ///
  /// In en, this message translates to:
  /// **'Overdue Fees'**
  String get overdueFees;

  /// No description provided for @dueFees.
  ///
  /// In en, this message translates to:
  /// **'Due Fees'**
  String get dueFees;

  /// No description provided for @pendingFees.
  ///
  /// In en, this message translates to:
  /// **'Pending Fees'**
  String get pendingFees;

  /// No description provided for @overallSummary.
  ///
  /// In en, this message translates to:
  /// **'Overall Summary'**
  String get overallSummary;

  /// No description provided for @feeAmount.
  ///
  /// In en, this message translates to:
  /// **'Fee Amount'**
  String get feeAmount;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Balance Amount'**
  String get balanceAmount;

  /// No description provided for @concessionAmount.
  ///
  /// In en, this message translates to:
  /// **'Concession Amount'**
  String get concessionAmount;

  /// No description provided for @overdueIn.
  ///
  /// In en, this message translates to:
  /// **'Overdue In'**
  String get overdueIn;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @feesDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fees Details'**
  String get feesDetailsTitle;

  /// No description provided for @feesSummaryTab.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get feesSummaryTab;

  /// No description provided for @feesTransactionsTab.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get feesTransactionsTab;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @registerNo.
  ///
  /// In en, this message translates to:
  /// **'Register No'**
  String get registerNo;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @alternateMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Alternate Mobile Number'**
  String get alternateMobileNumber;

  /// No description provided for @enterAlternateNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter alternate number'**
  String get enterAlternateNumber;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid number'**
  String get enterValidNumber;

  /// No description provided for @updateAlternateMobile.
  ///
  /// In en, this message translates to:
  /// **'Update Alternate Mobile'**
  String get updateAlternateMobile;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @leaveManagement.
  ///
  /// In en, this message translates to:
  /// **'Leave Management'**
  String get leaveManagement;

  /// No description provided for @applyForLeave.
  ///
  /// In en, this message translates to:
  /// **'Apply for Leave'**
  String get applyForLeave;

  /// No description provided for @leaveType.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveType;

  /// No description provided for @fullDay.
  ///
  /// In en, this message translates to:
  /// **'FULL DAY'**
  String get fullDay;

  /// No description provided for @halfMorning.
  ///
  /// In en, this message translates to:
  /// **'HALF MORNING'**
  String get halfMorning;

  /// No description provided for @halfAfternoon.
  ///
  /// In en, this message translates to:
  /// **'HALF AFTERNOON'**
  String get halfAfternoon;

  /// No description provided for @moreThanOneDay.
  ///
  /// In en, this message translates to:
  /// **'MORE THAN ONE DAY'**
  String get moreThanOneDay;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason'**
  String get enterReason;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record Audio'**
  String get recordAudio;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @recordingSpeakNow.
  ///
  /// In en, this message translates to:
  /// **'Recording... Speak now!'**
  String get recordingSpeakNow;

  /// No description provided for @submitLeave.
  ///
  /// In en, this message translates to:
  /// **'Submit Leave'**
  String get submitLeave;

  /// No description provided for @noPendingLeaves.
  ///
  /// In en, this message translates to:
  /// **'No pending leaves'**
  String get noPendingLeaves;

  /// No description provided for @pendingLeaves.
  ///
  /// In en, this message translates to:
  /// **'Pending Leaves'**
  String get pendingLeaves;

  /// No description provided for @cancelLeave.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLeave;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get microphonePermissionDenied;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @errorCancellingLeave.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling leave'**
  String get errorCancellingLeave;

  /// No description provided for @examTimetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get examTimetable;

  /// No description provided for @examResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get examResult;

  /// No description provided for @noTimetable.
  ///
  /// In en, this message translates to:
  /// **'No timetable available'**
  String get noTimetable;

  /// No description provided for @noResult.
  ///
  /// In en, this message translates to:
  /// **'No results available'**
  String get noResult;

  /// No description provided for @outOf.
  ///
  /// In en, this message translates to:
  /// **'OUT OF'**
  String get outOf;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @mark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get mark;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
