import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Motivational Saints'**
  String get appTitle;

  /// No description provided for @inspiringSaints.
  ///
  /// In en, this message translates to:
  /// **'Inspiring Saints of India'**
  String get inspiringSaints;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Antarikshverse is dedicated to spreading spiritual awareness and fostering meaningful interaction with inspiring saints and their timeless literature. Through this app, we aim to help the younger generation connect with the wisdom of saints, find clarity in their doubts, and develop a deeper understanding of spiritual teachings. Our goal is to encourage more time spent in swadhyaya (self-study) and the study of sacred texts. \n\n For feedback or suggestions, please reach out to us at antarikshverse@gmail.com.'**
  String get contactUs;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @setName.
  ///
  /// In en, this message translates to:
  /// **'Set your Name'**
  String get setName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @quotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get quotes;

  /// No description provided for @articles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get articles;

  /// No description provided for @ask.
  ///
  /// In en, this message translates to:
  /// **'Ask - AI Powered'**
  String get ask;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @askAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askAQuestion;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @noPreviousQuestions.
  ///
  /// In en, this message translates to:
  /// **'No previous questions.'**
  String get noPreviousQuestions;

  /// No description provided for @bookmarkedQuotes.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked Quotes'**
  String get bookmarkedQuotes;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'How to use the App'**
  String get aboutApp;

  /// No description provided for @aboutAppInstructions.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Motivational Saints app!\n\nHow to use the app:\n• Browse the list of saints on the home screen. Tap a saint to view their quotes, articles, and ask questions.\n• Use the \'Ask\' tab to ask questions to the selected saint and get motivational answers.\n• View your previous questions and answers in the \'History\' tab.\n• Use the \'Spiritual diary\' from the menu to write and save your personal notes.\n• Change the app language or theme from the menu.\n• Contact the developer from the menu if you have feedback or suggestions.\n\nEnjoy your journey towards inspiration and self-improvement!'**
  String get aboutAppInstructions;

  /// No description provided for @watchOurVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch our video:'**
  String get watchOurVideo;

  /// No description provided for @chooseSpiritualGuide.
  ///
  /// In en, this message translates to:
  /// **'Choose your spiritual guide'**
  String get chooseSpiritualGuide;

  /// No description provided for @askDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Get spiritual guidance from the wisdom of saints. Ask questions about life, spirituality, and finding inner peace.'**
  String get askDisclaimer;

  /// No description provided for @nextEkadashi.
  ///
  /// In en, this message translates to:
  /// **'Next Ekadashi'**
  String get nextEkadashi;

  /// No description provided for @myBooksLibrary.
  ///
  /// In en, this message translates to:
  /// **'My Books Library'**
  String get myBooksLibrary;

  /// No description provided for @rateAndShareApp.
  ///
  /// In en, this message translates to:
  /// **'Rate & Share App'**
  String get rateAndShareApp;

  /// No description provided for @setDailyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Notifications'**
  String get setDailyNotifications;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @spiritualDiary.
  ///
  /// In en, this message translates to:
  /// **'Spiritual Diary'**
  String get spiritualDiary;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy Me A Coffee'**
  String get buyMeACoffee;

  /// No description provided for @quoteOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Quote of the Day'**
  String get quoteOfTheDay;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @supportTextHi.
  ///
  /// In en, this message translates to:
  /// **'स्वाध्याय के मार्ग में विज्ञापन नहीं आना चाहिए, इसलिए यहाँ कोई विज्ञापन नहीं है। यदि आप चाहते हैं कि हमारा सर्वर 24x7 चले और अधिक लोगों तक पहुँचे, तो कृपया इस पहल का समर्थन करें: buymeacoffee.com/Antarikshverse'**
  String get supportTextHi;

  /// No description provided for @supportTextEn.
  ///
  /// In en, this message translates to:
  /// **'Advertisement shouldn\'t come in way of Swadhaya and therefore there are no advertisement here. If you like our server to run 24x7 and reach more people, consider supporting this initiative: buymeacoffee.com/Antarikshverse'**
  String get supportTextEn;

  /// No description provided for @talkToSpiritualAIFriend.
  ///
  /// In en, this message translates to:
  /// **'Talk to spiritual AI friend'**
  String get talkToSpiritualAIFriend;

  /// No description provided for @deleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Question?'**
  String get deleteQuestion;

  /// No description provided for @deleteQuestionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this question and answer? This action cannot be undone.'**
  String get deleteQuestionConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @questionDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Question deleted successfully'**
  String get questionDeletedSuccessfully;

  /// No description provided for @askAIFeatureDisabled.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Feature Disabled'**
  String get askAIFeatureDisabled;

  /// No description provided for @askAINotAvailableForAnandmoyima.
  ///
  /// In en, this message translates to:
  /// **'The Ask AI feature is not available for Anandamayi Ma.'**
  String get askAINotAvailableForAnandmoyima;

  /// No description provided for @askAINotAvailableForBabaNeebKarori.
  ///
  /// In en, this message translates to:
  /// **'The Ask AI feature is not available for Baba Neeb Karori.'**
  String get askAINotAvailableForBabaNeebKarori;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @exploreOtherTabs.
  ///
  /// In en, this message translates to:
  /// **'Please explore their quotes and teachings in the other tabs.'**
  String get exploreOtherTabs;

  /// No description provided for @askYourSpiritualQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask Your Spiritual Question'**
  String get askYourSpiritualQuestion;

  /// No description provided for @typeYourQuestionBelow.
  ///
  /// In en, this message translates to:
  /// **'Type your question below:'**
  String get typeYourQuestionBelow;

  /// No description provided for @questionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., How can I find inner peace? What is the meaning of life?'**
  String get questionPlaceholder;

  /// No description provided for @gettingWisdomFromSaints.
  ///
  /// In en, this message translates to:
  /// **'Getting wisdom from saints...'**
  String get gettingWisdomFromSaints;

  /// No description provided for @askAISpiritualFriend.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Spiritual Friend'**
  String get askAISpiritualFriend;

  /// No description provided for @enterQuestionToAsk.
  ///
  /// In en, this message translates to:
  /// **'Enter question to ask'**
  String get enterQuestionToAsk;

  /// No description provided for @readyToAsk.
  ///
  /// In en, this message translates to:
  /// **'Ready to ask'**
  String get readyToAsk;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @typeYourQuestionFirst.
  ///
  /// In en, this message translates to:
  /// **'Type your question first'**
  String get typeYourQuestionFirst;

  /// No description provided for @flagAsIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Flag as Incorrect'**
  String get flagAsIncorrect;

  /// No description provided for @flagSubmittedThankYou.
  ///
  /// In en, this message translates to:
  /// **'Flag submitted. Thank you!'**
  String get flagSubmittedThankYou;

  /// No description provided for @configurationLoading.
  ///
  /// In en, this message translates to:
  /// **'Configuration is still loading. Please wait and try again.'**
  String get configurationLoading;

  /// No description provided for @serverNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Gradio server is not running. Please try again later.'**
  String get serverNotRunning;

  /// No description provided for @serverTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server timeout. Please try again later.'**
  String get serverTimeout;

  /// No description provided for @serverDownTryLater.
  ///
  /// In en, this message translates to:
  /// **'Apologies, Server is down, Please try later : POST failed: {status}'**
  String serverDownTryLater(Object status);

  /// No description provided for @errorServerNotRespond.
  ///
  /// In en, this message translates to:
  /// **'Error: Server did not respond in time. Please try later.'**
  String get errorServerNotRespond;

  /// No description provided for @noResponseFromServer.
  ///
  /// In en, this message translates to:
  /// **'No response from server. Please try again later.'**
  String get noResponseFromServer;

  /// No description provided for @errorServerDown.
  ///
  /// In en, this message translates to:
  /// **'Error: Server seems to be down. Please try later.'**
  String get errorServerDown;

  /// No description provided for @spreadSpirituality.
  ///
  /// In en, this message translates to:
  /// **'Spread Spirituality'**
  String get spreadSpirituality;

  /// No description provided for @rateShareDialogContent.
  ///
  /// In en, this message translates to:
  /// **'If you like the app and want to feel difference and spirituality in lives of others, please:'**
  String get rateShareDialogContent;

  /// No description provided for @rateUs5Stars.
  ///
  /// In en, this message translates to:
  /// **'Rate us 5 stars ⭐⭐⭐⭐⭐'**
  String get rateUs5Stars;

  /// No description provided for @shareWithFriendsFamily.
  ///
  /// In en, this message translates to:
  /// **'Share with friends & family'**
  String get shareWithFriendsFamily;

  /// No description provided for @helpOthersDiscover.
  ///
  /// In en, this message translates to:
  /// **'🙏 Help others discover the path to inner peace and spiritual growth'**
  String get helpOthersDiscover;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @rate5Star.
  ///
  /// In en, this message translates to:
  /// **'Rate 5⭐'**
  String get rate5Star;

  /// No description provided for @thankYouForRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for rating! 🙏'**
  String get thankYouForRating;

  /// No description provided for @thankYouForSupport.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support! 🙏'**
  String get thankYouForSupport;

  /// No description provided for @thankYouForSharing.
  ///
  /// In en, this message translates to:
  /// **'Thank you for sharing the spiritual journey! 🌟'**
  String get thankYouForSharing;

  /// No description provided for @unableToShare.
  ///
  /// In en, this message translates to:
  /// **'Unable to share at the moment. Please try again.'**
  String get unableToShare;

  /// No description provided for @shareMessageAndroid.
  ///
  /// In en, this message translates to:
  /// **'🙏Talk with Saints on Android & Ios:\n\n I liked the app and recommend this for staying positive with wisdom of saints, hence sharing this divine experience! 🕉️\n\nDiscover wisdom from great saints and transform your spiritual journey with Talk with Saints.\n\nDownload now\n Android: https://play.google.com/store/apps/details?id=com.antarikshverse.talkwithsaints \n iOS : https://apps.apple.com/us/app/talk-with-saints-ai/id6757002070'**
  String get shareMessageAndroid;

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'Discover Saints Speak - Spiritual Wisdom App 🙏'**
  String get shareSubject;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
