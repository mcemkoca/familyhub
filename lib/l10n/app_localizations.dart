import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_tr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('fr'),
    Locale('nl'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub'**
  String get appTitle;

  /// No description provided for @family.
  ///
  /// In tr, this message translates to:
  /// **'Ailem'**
  String get family;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kaydol'**
  String get register;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (Tekrar)'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @send.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get send;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @success.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @chat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get chat;

  /// No description provided for @calendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendar;

  /// No description provided for @tasks.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get tasks;

  /// No description provided for @safety.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get safety;

  /// No description provided for @healthCard.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Kartı'**
  String get healthCard;

  /// No description provided for @shopping.
  ///
  /// In tr, this message translates to:
  /// **'Market Listesi'**
  String get shopping;

  /// No description provided for @budget.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe'**
  String get budget;

  /// No description provided for @hub.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get hub;

  /// No description provided for @mutfak.
  ///
  /// In tr, this message translates to:
  /// **'Mutfak'**
  String get mutfak;

  /// No description provided for @navMerkez.
  ///
  /// In tr, this message translates to:
  /// **'Merkez'**
  String get navMerkez;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @more.
  ///
  /// In tr, this message translates to:
  /// **'Daha Fazla'**
  String get more;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get next;

  /// No description provided for @done.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get done;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @welcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ailenizin dijital merkezine hoş geldiniz'**
  String get welcomeSubtitle;

  /// No description provided for @emailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi gerekli'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordTooShort;

  /// No description provided for @invalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz e-posta adresi'**
  String get invalidEmail;

  /// No description provided for @loginFailed.
  ///
  /// In tr, this message translates to:
  /// **'Giriş başarısız'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başarısız'**
  String get registerFailed;

  /// No description provided for @noAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı?'**
  String get haveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreni mi unuttun?'**
  String get forgotPassword;

  /// No description provided for @members.
  ///
  /// In tr, this message translates to:
  /// **'Üyeler'**
  String get members;

  /// No description provided for @online.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi'**
  String get online;

  /// No description provided for @admin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get admin;

  /// No description provided for @child.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk'**
  String get child;

  /// No description provided for @parent.
  ///
  /// In tr, this message translates to:
  /// **'Ebeveyn'**
  String get parent;

  /// No description provided for @role.
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @removeMember.
  ///
  /// In tr, this message translates to:
  /// **'Üyeyi Çıkar'**
  String get removeMember;

  /// No description provided for @roleChangeSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Rol başarıyla güncellendi'**
  String get roleChangeSuccess;

  /// No description provided for @removeConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu üyeyi çıkarmak istediğinize emin misiniz?'**
  String get removeConfirm;

  /// No description provided for @leaveFamilyConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Aileden ayrılmak istediğinize emin misiniz?'**
  String get leaveFamilyConfirm;

  /// No description provided for @typeMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz...'**
  String get typeMessage;

  /// No description provided for @image.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf'**
  String get image;

  /// No description provided for @location.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get location;

  /// No description provided for @event.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik'**
  String get event;

  /// No description provided for @poll.
  ///
  /// In tr, this message translates to:
  /// **'Anket'**
  String get poll;

  /// No description provided for @voiceMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sesli Mesaj'**
  String get voiceMessage;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @noEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik bulunamadı'**
  String get noEvents;

  /// No description provided for @addEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Ekle'**
  String get addEvent;

  /// No description provided for @eventTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Başlığı'**
  String get eventTitle;

  /// No description provided for @startTime.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get endTime;

  /// No description provided for @allDay.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Gün'**
  String get allDay;

  /// No description provided for @reminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı'**
  String get reminder;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @taskTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görev Başlığı'**
  String get taskTitle;

  /// No description provided for @dueDate.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Tarihi'**
  String get dueDate;

  /// No description provided for @priority.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get priority;

  /// No description provided for @high.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get low;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get pending;

  /// No description provided for @emergency.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum'**
  String get emergency;

  /// No description provided for @emergencyButton.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum Butonu'**
  String get emergencyButton;

  /// No description provided for @emergencyInfo.
  ///
  /// In tr, this message translates to:
  /// **'Butona 3 saniye basılı tutarak acil durum bildirimi gönderebilirsin.'**
  String get emergencyInfo;

  /// No description provided for @emergencySent.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum bildirimi ailene gönderildi ve konumun paylaşıldı.'**
  String get emergencySent;

  /// No description provided for @call112.
  ///
  /// In tr, this message translates to:
  /// **'112\'yi Ara'**
  String get call112;

  /// No description provided for @healthInfo.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Bilgileri'**
  String get healthInfo;

  /// No description provided for @bloodType.
  ///
  /// In tr, this message translates to:
  /// **'Kan Grubu'**
  String get bloodType;

  /// No description provided for @allergies.
  ///
  /// In tr, this message translates to:
  /// **'Alerjiler'**
  String get allergies;

  /// No description provided for @medications.
  ///
  /// In tr, this message translates to:
  /// **'İlaçlar'**
  String get medications;

  /// No description provided for @chronicConditions.
  ///
  /// In tr, this message translates to:
  /// **'Kronik Hastalıklar'**
  String get chronicConditions;

  /// No description provided for @emergencyContact.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum Kişisi'**
  String get emergencyContact;

  /// No description provided for @doctor.
  ///
  /// In tr, this message translates to:
  /// **'Doktor'**
  String get doctor;

  /// No description provided for @organDonor.
  ///
  /// In tr, this message translates to:
  /// **'Organ Bağışı'**
  String get organDonor;

  /// No description provided for @notes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get notes;

  /// No description provided for @qrShare.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Kartı QR'**
  String get qrShare;

  /// No description provided for @privacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik: Yalnızca aile üyeleri tarafından okunabilir'**
  String get privacyNote;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In tr, this message translates to:
  /// **'Aydınlık'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get system;

  /// No description provided for @fontSize.
  ///
  /// In tr, this message translates to:
  /// **'Yazı Boyutu'**
  String get fontSize;

  /// No description provided for @small.
  ///
  /// In tr, this message translates to:
  /// **'Küçük'**
  String get small;

  /// No description provided for @normal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @large.
  ///
  /// In tr, this message translates to:
  /// **'Büyük'**
  String get large;

  /// No description provided for @premium.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @upgradeToPremium.
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a Yükselt'**
  String get upgradeToPremium;

  /// No description provided for @premiumFeatures.
  ///
  /// In tr, this message translates to:
  /// **'Premium Özellikler'**
  String get premiumFeatures;

  /// No description provided for @subscriptionActive.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliğiniz aktif'**
  String get subscriptionActive;

  /// No description provided for @subscriptionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliğiniz sona erdi'**
  String get subscriptionExpired;

  /// No description provided for @noInternet.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok'**
  String get noInternet;

  /// No description provided for @sessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süreniz doldu. Lütfen tekrar giriş yapın.'**
  String get sessionExpired;

  /// No description provided for @serverError.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu hatası. Lütfen tekrar deneyin.'**
  String get serverError;

  /// No description provided for @tryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get tryAgain;

  /// No description provided for @pullToRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenilemek için çekin'**
  String get pullToRefresh;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noData;

  /// No description provided for @select.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get select;

  /// No description provided for @camera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get gallery;

  /// No description provided for @file.
  ///
  /// In tr, this message translates to:
  /// **'Dosya'**
  String get file;

  /// No description provided for @cancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal edildi'**
  String get cancelled;

  /// No description provided for @permissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'İzin reddedildi'**
  String get permissionDenied;

  /// No description provided for @locationPermission.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi. Ayarlardan izin vermeniz gerekiyor.'**
  String get locationPermission;

  /// No description provided for @locationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. GPS açık olduğundan emin olun.'**
  String get locationUnavailable;

  /// No description provided for @invitationSent.
  ///
  /// In tr, this message translates to:
  /// **'Davet gönderildi'**
  String get invitationSent;

  /// No description provided for @invitationCode.
  ///
  /// In tr, this message translates to:
  /// **'Davet Kodu'**
  String get invitationCode;

  /// No description provided for @copy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @copied.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get copied;

  /// No description provided for @memberCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} üye'**
  String memberCount(Object count);

  /// No description provided for @childCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} çocuk'**
  String childCount(Object count);

  /// No description provided for @onlineCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} çevrimiçi'**
  String onlineCount(Object count);

  /// No description provided for @adminCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} yönetici'**
  String adminCount(Object count);

  /// No description provided for @pinnedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlenmiş mesaj'**
  String get pinnedMessage;

  /// No description provided for @messageDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj silindi'**
  String get messageDeleted;

  /// No description provided for @reactionAdded.
  ///
  /// In tr, this message translates to:
  /// **'Tepki eklendi'**
  String get reactionAdded;

  /// No description provided for @callStarted.
  ///
  /// In tr, this message translates to:
  /// **'Arama başlatıldı'**
  String get callStarted;

  /// No description provided for @callEnded.
  ///
  /// In tr, this message translates to:
  /// **'Arama sona erdi'**
  String get callEnded;

  /// No description provided for @missedCall.
  ///
  /// In tr, this message translates to:
  /// **'Cevapsız arama'**
  String get missedCall;

  /// No description provided for @incomingCall.
  ///
  /// In tr, this message translates to:
  /// **'Gelen arama'**
  String get incomingCall;

  /// No description provided for @newMessage.
  ///
  /// In tr, this message translates to:
  /// **'Yeni mesaj'**
  String get newMessage;

  /// No description provided for @markAsRead.
  ///
  /// In tr, this message translates to:
  /// **'Okundu olarak işaretle'**
  String get markAsRead;

  /// No description provided for @markAllRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü okundu işaretle'**
  String get markAllRead;

  /// No description provided for @deleteAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü sil'**
  String get deleteAll;

  /// No description provided for @archive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivden çıkar'**
  String get unarchive;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get inactive;

  /// No description provided for @unknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// No description provided for @notSet.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmemiş'**
  String get notSet;

  /// No description provided for @optional.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe Bağlı'**
  String get optional;

  /// No description provided for @genc.
  ///
  /// In tr, this message translates to:
  /// **'Genç'**
  String get genc;

  /// No description provided for @kullanici.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get kullanici;

  /// No description provided for @geriYukle.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get geriYukle;

  /// No description provided for @ozelSoru.
  ///
  /// In tr, this message translates to:
  /// **'Özel soru...'**
  String get ozelSoru;

  /// No description provided for @aileBilgisiBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Aile bilgisi bulunamadı'**
  String get aileBilgisiBulunamadi;

  /// No description provided for @ailedenAyril.
  ///
  /// In tr, this message translates to:
  /// **'Aileden Ayrıl'**
  String get ailedenAyril;

  /// No description provided for @uye.
  ///
  /// In tr, this message translates to:
  /// **'Üye'**
  String get uye;

  /// No description provided for @acik.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get acik;

  /// No description provided for @fotograf.
  ///
  /// In tr, this message translates to:
  /// **'📷 Fotoğraf'**
  String get fotograf;

  /// No description provided for @guvenliVaris.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli Varış'**
  String get guvenliVaris;

  /// No description provided for @isLabel.
  ///
  /// In tr, this message translates to:
  /// **'İş'**
  String get isLabel;

  /// No description provided for @ozel.
  ///
  /// In tr, this message translates to:
  /// **'Özel'**
  String get ozel;

  /// No description provided for @aiOnerileri.
  ///
  /// In tr, this message translates to:
  /// **'AI Önerileri'**
  String get aiOnerileri;

  /// No description provided for @aileOnerileri.
  ///
  /// In tr, this message translates to:
  /// **'Aile Önerileri'**
  String get aileOnerileri;

  /// No description provided for @cocukGirisi.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Girişi'**
  String get cocukGirisi;

  /// No description provided for @enAz8KarakterBuyukkucukHarfRakamVeOzelKarakter.
  ///
  /// In tr, this message translates to:
  /// **'En az 8 karakter, büyük/küçük harf, rakam ve özel karakter'**
  String get enAz8KarakterBuyukkucukHarfRakamVeOzelKarakter;

  /// No description provided for @egitim.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim'**
  String get egitim;

  /// No description provided for @diger.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get diger;

  /// No description provided for @bildirimAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Ayarları'**
  String get bildirimAyarlari;

  /// No description provided for @konumumuPaylas.
  ///
  /// In tr, this message translates to:
  /// **'Konumumu Paylaş'**
  String get konumumuPaylas;

  /// No description provided for @gorevlerim.
  ///
  /// In tr, this message translates to:
  /// **'Görevlerim'**
  String get gorevlerim;

  /// No description provided for @car.
  ///
  /// In tr, this message translates to:
  /// **'Çar'**
  String get car;

  /// No description provided for @cocukHesaplari.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Hesapları'**
  String get cocukHesaplari;

  /// No description provided for @cocukEkle.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Ekle'**
  String get cocukEkle;

  /// No description provided for @isim.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get isim;

  /// No description provided for @tur.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get tur;

  /// No description provided for @canliKonum.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Konum'**
  String get canliKonum;

  /// No description provided for @baslat.
  ///
  /// In tr, this message translates to:
  /// **'Başlat'**
  String get baslat;

  /// No description provided for @baslik.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get baslik;

  /// No description provided for @ayril.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıl'**
  String get ayril;

  /// No description provided for @gorev.
  ///
  /// In tr, this message translates to:
  /// **'Görev'**
  String get gorev;

  /// No description provided for @baglantiyiKes.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı Kes'**
  String get baglantiyiKes;

  /// No description provided for @telefonUygulamasiAcilamiyor.
  ///
  /// In tr, this message translates to:
  /// **'Telefon uygulaması açılamıyor'**
  String get telefonUygulamasiAcilamiyor;

  /// No description provided for @guncel.
  ///
  /// In tr, this message translates to:
  /// **'Güncel'**
  String get guncel;

  /// No description provided for @guvenliBolgeler.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli Bölgeler'**
  String get guvenliBolgeler;

  /// No description provided for @yesil.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil'**
  String get yesil;

  /// No description provided for @kirmizi.
  ///
  /// In tr, this message translates to:
  /// **'Kırmızı'**
  String get kirmizi;

  /// No description provided for @izinlerVeRoller.
  ///
  /// In tr, this message translates to:
  /// **'İzinler ve Roller'**
  String get izinlerVeRoller;

  /// No description provided for @turkiye.
  ///
  /// In tr, this message translates to:
  /// **'Türkiye'**
  String get turkiye;

  /// No description provided for @hesabiSil.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get hesabiSil;

  /// No description provided for @pinEnAz4HaneliOlmali.
  ///
  /// In tr, this message translates to:
  /// **'PIN en az 4 haneli olmalı'**
  String get pinEnAz4HaneliOlmali;

  /// No description provided for @tumAlanlariDoldurun.
  ///
  /// In tr, this message translates to:
  /// **'Tüm alanları doldurun'**
  String get tumAlanlariDoldurun;

  /// No description provided for @sifrelerEslesmiyor.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get sifrelerEslesmiyor;

  /// No description provided for @cevabiniziYazin.
  ///
  /// In tr, this message translates to:
  /// **'Cevabınızı yazın'**
  String get cevabiniziYazin;

  /// No description provided for @yeniSifre.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre'**
  String get yeniSifre;

  /// No description provided for @ulasim.
  ///
  /// In tr, this message translates to:
  /// **'Ulaşım'**
  String get ulasim;

  /// No description provided for @saglik.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get saglik;

  /// No description provided for @eglence.
  ///
  /// In tr, this message translates to:
  /// **'Eğlence'**
  String get eglence;

  /// No description provided for @islemiSil.
  ///
  /// In tr, this message translates to:
  /// **'İşlemi Sil'**
  String get islemiSil;

  /// No description provided for @guncelle.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get guncelle;

  /// No description provided for @aileUyesi.
  ///
  /// In tr, this message translates to:
  /// **'Aile Üyesi'**
  String get aileUyesi;

  /// No description provided for @yeniGorev.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Görev'**
  String get yeniGorev;

  /// No description provided for @akilliRotasyon.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Rotasyon'**
  String get akilliRotasyon;

  /// No description provided for @gelisim.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim'**
  String get gelisim;

  /// No description provided for @yeniGorevEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Görev Ekle'**
  String get yeniGorevEkle;

  /// No description provided for @gunlukSeri.
  ///
  /// In tr, this message translates to:
  /// **'günlük seri'**
  String get gunlukSeri;

  /// No description provided for @haftalikGorunum.
  ///
  /// In tr, this message translates to:
  /// **'HAFTALIK GÖRÜNÜM'**
  String get haftalikGorunum;

  /// No description provided for @olustur.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get olustur;

  /// No description provided for @aileUyelerineBildirildi.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyelerine bildirildi'**
  String get aileUyelerineBildirildi;

  /// No description provided for @acilKontaklaraSmsGonderildi.
  ///
  /// In tr, this message translates to:
  /// **'Acil kontaklara SMS gönderildi'**
  String get acilKontaklaraSmsGonderildi;

  /// No description provided for @araniyor.
  ///
  /// In tr, this message translates to:
  /// **'112 aranıyor...'**
  String get araniyor;

  /// No description provided for @konumPaylasimiAktif.
  ///
  /// In tr, this message translates to:
  /// **'Konum paylaşımı aktif'**
  String get konumPaylasimiAktif;

  /// No description provided for @detayliRapor.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Rapor'**
  String get detayliRapor;

  /// No description provided for @yanlisAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış alarm'**
  String get yanlisAlarm;

  /// No description provided for @raporIndir.
  ///
  /// In tr, this message translates to:
  /// **'Rapor İndir'**
  String get raporIndir;

  /// No description provided for @yukseltmeZinciri.
  ///
  /// In tr, this message translates to:
  /// **'YÜKSELTME ZİNCİRİ'**
  String get yukseltmeZinciri;

  /// No description provided for @sosAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'SOS Ayarları'**
  String get sosAyarlari;

  /// No description provided for @varsayilanaSifirlandi.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılana sıfırlandı'**
  String get varsayilanaSifirlandi;

  /// No description provided for @buAiledenAyrilmakIstediginizeEminMisiniz.
  ///
  /// In tr, this message translates to:
  /// **'Bu aileden ayrılmak istediğinize emin misiniz?'**
  String get buAiledenAyrilmakIstediginizeEminMisiniz;

  /// No description provided for @cikar.
  ///
  /// In tr, this message translates to:
  /// **'Çıkar'**
  String get cikar;

  /// No description provided for @anilar.
  ///
  /// In tr, this message translates to:
  /// **'Anılar'**
  String get anilar;

  /// No description provided for @tumunuGor.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get tumunuGor;

  /// No description provided for @istanbul.
  ///
  /// In tr, this message translates to:
  /// **'İstanbul'**
  String get istanbul;

  /// No description provided for @duragan.
  ///
  /// In tr, this message translates to:
  /// **'Durağan'**
  String get duragan;

  /// No description provided for @yuruyus.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş'**
  String get yuruyus;

  /// No description provided for @arac.
  ///
  /// In tr, this message translates to:
  /// **'Araç'**
  String get arac;

  /// No description provided for @ilkAdim.
  ///
  /// In tr, this message translates to:
  /// **'İlk Adım'**
  String get ilkAdim;

  /// No description provided for @albumler.
  ///
  /// In tr, this message translates to:
  /// **'Albümler'**
  String get albumler;

  /// No description provided for @aniYaz.
  ///
  /// In tr, this message translates to:
  /// **'Anı Yaz'**
  String get aniYaz;

  /// No description provided for @sonYazanKazanir.
  ///
  /// In tr, this message translates to:
  /// **'Son yazan kazanır'**
  String get sonYazanKazanir;

  /// No description provided for @ciftYonlu.
  ///
  /// In tr, this message translates to:
  /// **'Çift yönlü'**
  String get ciftYonlu;

  /// No description provided for @azOnce.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get azOnce;

  /// No description provided for @gorevBasligiBosOlamaz.
  ///
  /// In tr, this message translates to:
  /// **'Görev başlığı boş olamaz'**
  String get gorevBasligiBosOlamaz;

  /// No description provided for @atananKisi.
  ///
  /// In tr, this message translates to:
  /// **'Atanan Kişi'**
  String get atananKisi;

  /// No description provided for @davranis.
  ///
  /// In tr, this message translates to:
  /// **'🧠 Davranış'**
  String get davranis;

  /// No description provided for @yakinlikDerecesi.
  ///
  /// In tr, this message translates to:
  /// **'Yakınlık Derecesi'**
  String get yakinlikDerecesi;

  /// No description provided for @konumAliniyor.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor...'**
  String get konumAliniyor;

  /// No description provided for @hizliIslemler.
  ///
  /// In tr, this message translates to:
  /// **'HIZLI İŞLEMLER'**
  String get hizliIslemler;

  /// No description provided for @saglikKartim.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Kartım'**
  String get saglikKartim;

  /// No description provided for @yeniVarisPlanla.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Varış Planla'**
  String get yeniVarisPlanla;

  /// No description provided for @hakkinda.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get hakkinda;

  /// No description provided for @cokBuyuk.
  ///
  /// In tr, this message translates to:
  /// **'Çok Büyük'**
  String get cokBuyuk;

  /// No description provided for @verilerGeriYuklendi.
  ///
  /// In tr, this message translates to:
  /// **'✅ Veriler geri yüklendi'**
  String get verilerGeriYuklendi;

  /// No description provided for @googleHesabiBagla.
  ///
  /// In tr, this message translates to:
  /// **'Google Hesabı Bağla'**
  String get googleHesabiBagla;

  /// No description provided for @simdiYedekle.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Yedekle'**
  String get simdiYedekle;

  /// No description provided for @isimsiz.
  ///
  /// In tr, this message translates to:
  /// **'İsimsiz'**
  String get isimsiz;

  /// No description provided for @aileYonetimi.
  ///
  /// In tr, this message translates to:
  /// **'Aile Yönetimi'**
  String get aileYonetimi;

  /// No description provided for @yeniAileOlustur.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Aile Oluştur'**
  String get yeniAileOlustur;

  /// No description provided for @davetKoduIleKatil.
  ///
  /// In tr, this message translates to:
  /// **'Davet Kodu ile Katıl'**
  String get davetKoduIleKatil;

  /// No description provided for @oturumAcikDegil.
  ///
  /// In tr, this message translates to:
  /// **'Oturum açık değil'**
  String get oturumAcikDegil;

  /// No description provided for @dilVeBolge.
  ///
  /// In tr, this message translates to:
  /// **'Dil ve Bölge'**
  String get dilVeBolge;

  /// No description provided for @kapali.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get kapali;

  /// No description provided for @bildirimler.
  ///
  /// In tr, this message translates to:
  /// **'BİLDİRİMLER'**
  String get bildirimler;

  /// No description provided for @ucretsiz.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get ucretsiz;

  /// No description provided for @aileUyesi1.
  ///
  /// In tr, this message translates to:
  /// **'4 aile üyesi'**
  String get aileUyesi1;

  /// No description provided for @aileUyesi2.
  ///
  /// In tr, this message translates to:
  /// **'8 aile üyesi'**
  String get aileUyesi2;

  /// No description provided for @gizlilikPolitikasi.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get gizlilikPolitikasi;

  /// No description provided for @hesabiniziSilmekGeriAlinamazTumVerilerinizKaliciOlarakSilinecek.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı silmek geri alınamaz. Tüm verileriniz kalıcı olarak silinecek.'**
  String get hesabiniziSilmekGeriAlinamazTumVerilerinizKaliciOlarakSilinecek;

  /// No description provided for @tumVerilerinizKaliciOlarakSilinecek.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileriniz kalıcı olarak silinecek'**
  String get tumVerilerinizKaliciOlarakSilinecek;

  /// No description provided for @profiliDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get profiliDuzenle;

  /// No description provided for @ekranSuresi.
  ///
  /// In tr, this message translates to:
  /// **'Ekran Süresi'**
  String get ekranSuresi;

  /// No description provided for @guvenlikSorulari.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Soruları'**
  String get guvenlikSorulari;

  /// No description provided for @guvenlikSorusununCevabi.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik sorusunun cevabı'**
  String get guvenlikSorusununCevabi;

  /// No description provided for @sifreDegistir.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get sifreDegistir;

  /// No description provided for @onbellegiTemizle.
  ///
  /// In tr, this message translates to:
  /// **'Önbelleği Temizle'**
  String get onbellegiTemizle;

  /// No description provided for @henuzYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yok'**
  String get henuzYok;

  /// No description provided for @sistemVarsayilani.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Varsayılanı'**
  String get sistemVarsayilani;

  /// No description provided for @kullanimKilavuzu.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Kılavuzu'**
  String get kullanimKilavuzu;

  /// No description provided for @kullanimKosullari.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get kullanimKosullari;

  /// No description provided for @tumOdevlerTamamlandi.
  ///
  /// In tr, this message translates to:
  /// **'Tüm ödevler tamamlandı! 🎉'**
  String get tumOdevlerTamamlandi;

  /// No description provided for @yarin.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get yarin;

  /// No description provided for @cocukGirisiIcinOnceEbeveynHesabiylaGirisYapmalisiniz.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk girişi için önce ebeveyn hesabıyla giriş yapmalısınız.'**
  String get cocukGirisiIcinOnceEbeveynHesabiylaGirisYapmalisiniz;

  /// No description provided for @aileBilgisiBulunamadiLutfenOnceAileOlusturun.
  ///
  /// In tr, this message translates to:
  /// **'Aile bilgisi bulunamadı. Lütfen önce aile oluşturun.'**
  String get aileBilgisiBulunamadiLutfenOnceAileOlusturun;

  /// No description provided for @lutfenBirCocukSecin.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir çocuk seçin'**
  String get lutfenBirCocukSecin;

  /// No description provided for @isminiSecVePininiGir.
  ///
  /// In tr, this message translates to:
  /// **'İsmini seç ve PINini gir'**
  String get isminiSecVePininiGir;

  /// No description provided for @henuzCocukHesabiEklenmemisnebeveynGirisiYaparakEkleyebilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Henüz çocuk hesabı eklenmemiş.\\nEbeveyn girişi yaparak ekleyebilirsiniz.'**
  String get henuzCocukHesabiEklenmemisnebeveynGirisiYaparakEkleyebilirsiniz;

  /// No description provided for @cocukSec.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Seç'**
  String get cocukSec;

  /// No description provided for @buEpostaAdresiyleKayitliBirHesapBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta adresiyle kayıtlı bir hesap bulunamadı'**
  String get buEpostaAdresiyleKayitliBirHesapBulunamadi;

  /// No description provided for @herIkiGuvenlikSorusunuDaCevaplayin.
  ///
  /// In tr, this message translates to:
  /// **'Her iki güvenlik sorusunu da cevaplayın'**
  String get herIkiGuvenlikSorusunuDaCevaplayin;

  /// No description provided for @guvenlikSorularininCevaplariHatali.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik sorularının cevapları hatalı'**
  String get guvenlikSorularininCevaplariHatali;

  /// No description provided for @sifreSifirlamaBaglantisiEpostaAdresinizeGonderildi.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi'**
  String get sifreSifirlamaBaglantisiEpostaAdresinizeGonderildi;

  /// No description provided for @sifremiUnuttum.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get sifremiUnuttum;

  /// No description provided for @sifreniziMiUnuttunuz.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi mi unuttunuz?'**
  String get sifreniziMiUnuttunuz;

  /// No description provided for @girisEkraninaDon.
  ///
  /// In tr, this message translates to:
  /// **'Giriş ekranına dön'**
  String get girisEkraninaDon;

  /// No description provided for @guvenlikDogrulamasi.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Doğrulaması'**
  String get guvenlikDogrulamasi;

  /// No description provided for @hesabiniziKorumakIcinLutfenKayitliGuvenlikSorulariniziCevaplayin.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı korumak için lütfen kayıtlı güvenlik sorularınızı cevaplayın.'**
  String get hesabiniziKorumakIcinLutfenKayitliGuvenlikSorulariniziCevaplayin;

  /// No description provided for @dogrulaVeDevamEt.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula ve Devam Et'**
  String get dogrulaVeDevamEt;

  /// No description provided for @yeniSifreBelirle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre Belirle'**
  String get yeniSifreBelirle;

  /// No description provided for @guvenlikDogrulamanizBasariliLutfenYeniSifreniziBelirleyin.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik doğrulamanız başarılı. Lütfen yeni şifrenizi belirleyin.'**
  String get guvenlikDogrulamanizBasariliLutfenYeniSifreniziBelirleyin;

  /// No description provided for @sifremiDegistir.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Değiştir'**
  String get sifremiDegistir;

  /// No description provided for @sifrenizGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz Güncellendi!'**
  String get sifrenizGuncellendi;

  /// No description provided for @biyometrikKimlikDogrulamaDesteklenmiyor.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik kimlik doğrulama desteklenmiyor'**
  String get biyometrikKimlikDogrulamaDesteklenmiyor;

  /// No description provided for @onceEpostaVeSifreIleGirisYapmalisiniz.
  ///
  /// In tr, this message translates to:
  /// **'Önce e-posta ve şifre ile giriş yapmalısınız'**
  String get onceEpostaVeSifreIleGirisYapmalisiniz;

  /// No description provided for @sifremiunuttum1.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get sifremiunuttum1;

  /// No description provided for @googleSigninSuAnKullanilamiyor.
  ///
  /// In tr, this message translates to:
  /// **'Google Sign-In şu an kullanılamıyor. '**
  String get googleSigninSuAnKullanilamiyor;

  /// No description provided for @lutfenEpostaVeSifreIleGirisYapin.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen e-posta ve şifre ile giriş yapın.'**
  String get lutfenEpostaVeSifreIleGirisYapin;

  /// No description provided for @googleIleGirisYap.
  ///
  /// In tr, this message translates to:
  /// **'Google ile Giriş Yap'**
  String get googleIleGirisYap;

  /// No description provided for @parmakIziIleGiris.
  ///
  /// In tr, this message translates to:
  /// **'Parmak İzi ile Giriş'**
  String get parmakIziIleGiris;

  /// No description provided for @hesabinYokMu.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? '**
  String get hesabinYokMu;

  /// No description provided for @kayitOl.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get kayitOl;

  /// No description provided for @guvendeKalin.
  ///
  /// In tr, this message translates to:
  /// **'Güvende Kalın'**
  String get guvendeKalin;

  /// No description provided for @canliKonumPaylasimiVeAcilDurumButonuIleAileniziKoruyun.
  ///
  /// In tr, this message translates to:
  /// **'Canlı konum paylaşımı ve acil durum butonu ile ailenizi koruyun.'**
  String get canliKonumPaylasimiVeAcilDurumButonuIleAileniziKoruyun;

  /// No description provided for @tumAileUyeleriniziTekBirYerdenYonetinOrganizeOlun.
  ///
  /// In tr, this message translates to:
  /// **'Tüm aile üyelerinizi tek bir yerden yönetin, organize olun.'**
  String get tumAileUyeleriniziTekBirYerdenYonetinOrganizeOlun;

  /// No description provided for @gorevlerTakvimEtkinlikleriVeAlisverisListeleriIleHayatiKolaylastirin.
  ///
  /// In tr, this message translates to:
  /// **'Görevler, takvim etkinlikleri ve alışveriş listeleri ile hayatı kolaylaştırın.'**
  String
  get gorevlerTakvimEtkinlikleriVeAlisverisListeleriIleHayatiKolaylastirin;

  /// No description provided for @basla.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get basla;

  /// No description provided for @simdiGec.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Geç'**
  String get simdiGec;

  /// No description provided for @ailenizinKalbiBuradaAtiyor.
  ///
  /// In tr, this message translates to:
  /// **'Ailenizin kalbi burada atıyor'**
  String get ailenizinKalbiBuradaAtiyor;

  /// No description provided for @aileButcesi.
  ///
  /// In tr, this message translates to:
  /// **'Aile Bütçesi'**
  String get aileButcesi;

  /// No description provided for @islemler.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get islemler;

  /// No description provided for @dahaFazlaVeriToplandikcaKisisellestirilmisOnerilerSunacagiz.
  ///
  /// In tr, this message translates to:
  /// **'💡 Daha fazla veri toplandıkça kişiselleştirilmiş öneriler sunacağız.'**
  String get dahaFazlaVeriToplandikcaKisisellestirilmisOnerilerSunacagiz;

  /// No description provided for @aiButceAnalizi.
  ///
  /// In tr, this message translates to:
  /// **'AI Bütçe Analizi'**
  String get aiButceAnalizi;

  /// No description provided for @enYuksekKategori.
  ///
  /// In tr, this message translates to:
  /// **'En Yüksek Kategori'**
  String get enYuksekKategori;

  /// No description provided for @aionerileri1.
  ///
  /// In tr, this message translates to:
  /// **'💡 AI Önerileri'**
  String get aionerileri1;

  /// No description provided for @islemiDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'İşlemi Düzenle'**
  String get islemiDuzenle;

  /// No description provided for @yeniIslemEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni İşlem Ekle'**
  String get yeniIslemEkle;

  /// No description provided for @herYil.
  ///
  /// In tr, this message translates to:
  /// **'Her Yıl'**
  String get herYil;

  /// No description provided for @aylikHarcama.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Harcama'**
  String get aylikHarcama;

  /// No description provided for @aiIleButceAnalizi.
  ///
  /// In tr, this message translates to:
  /// **'AI ile Bütçe Analizi'**
  String get aiIleButceAnalizi;

  /// No description provided for @harcamaAliskanliklariniziAnalizEdinTasarrufOnerileriAlin.
  ///
  /// In tr, this message translates to:
  /// **'Harcama alışkanlıklarınızı analiz edin, tasarruf önerileri alın.'**
  String get harcamaAliskanliklariniziAnalizEdinTasarrufOnerileriAlin;

  /// No description provided for @son7GunTrendi.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 Gün Trendi'**
  String get son7GunTrendi;

  /// No description provided for @kategoriButceleri.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Bütçeleri'**
  String get kategoriButceleri;

  /// No description provided for @kategoriLimitleriniDuzenlemekIcinHerhangiBirKategoriyeDokunun.
  ///
  /// In tr, this message translates to:
  /// **'Kategori limitlerini düzenlemek için herhangi bir kategoriye dokunun'**
  String get kategoriLimitleriniDuzenlemekIcinHerhangiBirKategoriyeDokunun;

  /// No description provided for @aramaHazirlaniyor.
  ///
  /// In tr, this message translates to:
  /// **'Arama Hazırlanıyor'**
  String get aramaHazirlaniyor;

  /// No description provided for @sesliAramaOzelligiSuAndaKullanilamiyorLutfenDahaSonraTekrarDeneyin.
  ///
  /// In tr, this message translates to:
  /// **'Sesli arama özelliği şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.'**
  String get sesliAramaOzelligiSuAndaKullanilamiyorLutfenDahaSonraTekrarDeneyin;

  /// No description provided for @aileUyesiAra.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyesi ara...'**
  String get aileUyesiAra;

  /// No description provided for @henuzAranabilecekAileUyesiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aranabilecek aile üyesi yok'**
  String get henuzAranabilecekAileUyesiYok;

  /// No description provided for @aramaSonlandirildi.
  ///
  /// In tr, this message translates to:
  /// **'Arama sonlandırıldı'**
  String get aramaSonlandirildi;

  /// No description provided for @baglaniyor.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanıyor...'**
  String get baglaniyor;

  /// No description provided for @caliyor.
  ///
  /// In tr, this message translates to:
  /// **'Çalıyor...'**
  String get caliyor;

  /// No description provided for @sonlandiriliyor.
  ///
  /// In tr, this message translates to:
  /// **'Sonlandırılıyor...'**
  String get sonlandiriliyor;

  /// No description provided for @iptalEt.
  ///
  /// In tr, this message translates to:
  /// **'İptal Et'**
  String get iptalEt;

  /// No description provided for @sesiAc.
  ///
  /// In tr, this message translates to:
  /// **'Sesi Aç'**
  String get sesiAc;

  /// No description provided for @hoparlor.
  ///
  /// In tr, this message translates to:
  /// **'Hoparlör'**
  String get hoparlor;

  /// No description provided for @kulaklik.
  ///
  /// In tr, this message translates to:
  /// **'Kulaklık'**
  String get kulaklik;

  /// No description provided for @yoldayimEve10Dakika.
  ///
  /// In tr, this message translates to:
  /// **'Yoldayım, eve 10 dakika.'**
  String get yoldayimEve10Dakika;

  /// No description provided for @anketOzelligiYakindaGeliyor.
  ///
  /// In tr, this message translates to:
  /// **'Anket özelliği yakında geliyor'**
  String get anketOzelligiYakindaGeliyor;

  /// No description provided for @sesKaydiBaslatmakIcinMesajAlanindakiMikrofonaBasiliTutun.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı başlatmak için mesaj alanındaki mikrofona basılı tutun'**
  String get sesKaydiBaslatmakIcinMesajAlanindakiMikrofonaBasiliTutun;

  /// No description provided for @dosyaPaylasimiYakindaGeliyor.
  ///
  /// In tr, this message translates to:
  /// **'Dosya paylaşımı yakında geliyor'**
  String get dosyaPaylasimiYakindaGeliyor;

  /// No description provided for @sohbetiArsivle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti Arşivle'**
  String get sohbetiArsivle;

  /// No description provided for @kisi.
  ///
  /// In tr, this message translates to:
  /// **'Kişi'**
  String get kisi;

  /// No description provided for @bugunNasilHissediyorsun.
  ///
  /// In tr, this message translates to:
  /// **'Bugün nasıl hissediyorsun?'**
  String get bugunNasilHissediyorsun;

  /// No description provided for @gorevBasligiGerekli.
  ///
  /// In tr, this message translates to:
  /// **'Görev başlığı gerekli'**
  String get gorevBasligiGerekli;

  /// No description provided for @gorevEklendi.
  ///
  /// In tr, this message translates to:
  /// **'✅ Görev eklendi'**
  String get gorevEklendi;

  /// No description provided for @mikrofonIzniVerilmemis.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni verilmemiş'**
  String get mikrofonIzniVerilmemis;

  /// No description provided for @ornOdayiTopla.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Odayı topla'**
  String get ornOdayiTopla;

  /// No description provided for @gorevHakkindaDetaylar.
  ///
  /// In tr, this message translates to:
  /// **'Görev hakkında detaylar...'**
  String get gorevHakkindaDetaylar;

  /// No description provided for @sonTarihSec.
  ///
  /// In tr, this message translates to:
  /// **'Son tarih seç'**
  String get sonTarihSec;

  /// No description provided for @gorevEkle.
  ///
  /// In tr, this message translates to:
  /// **'Görev Ekle'**
  String get gorevEkle;

  /// No description provided for @hizliAksiyon.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Aksiyon'**
  String get hizliAksiyon;

  /// No description provided for @mesajGonder.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj Gönder'**
  String get mesajGonder;

  /// No description provided for @gorevlerimeGit.
  ///
  /// In tr, this message translates to:
  /// **'Görevlerime Git'**
  String get gorevlerimeGit;

  /// No description provided for @dersProgramim.
  ///
  /// In tr, this message translates to:
  /// **'Ders Programım'**
  String get dersProgramim;

  /// No description provided for @cocukDetayi.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Detayı'**
  String get cocukDetayi;

  /// No description provided for @cocukBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk bulunamadı'**
  String get cocukBulunamadi;

  /// No description provided for @odevler.
  ///
  /// In tr, this message translates to:
  /// **'Ödevler'**
  String get odevler;

  /// No description provided for @gorevSil.
  ///
  /// In tr, this message translates to:
  /// **'Görev Sil'**
  String get gorevSil;

  /// No description provided for @henuzGorevAtanmamis.
  ///
  /// In tr, this message translates to:
  /// **'Henüz görev atanmamış'**
  String get henuzGorevAtanmamis;

  /// No description provided for @yeniGorevEklemekIcinButonaBas.
  ///
  /// In tr, this message translates to:
  /// **'Yeni görev eklemek için butona bas'**
  String get yeniGorevEklemekIcinButonaBas;

  /// No description provided for @yeniOdevEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Ödev Ekle'**
  String get yeniOdevEkle;

  /// No description provided for @odevBasligi.
  ///
  /// In tr, this message translates to:
  /// **'Ödev Başlığı'**
  String get odevBasligi;

  /// No description provided for @teslimTarihiSec.
  ///
  /// In tr, this message translates to:
  /// **'Teslim Tarihi Seç'**
  String get teslimTarihiSec;

  /// No description provided for @odevEkle.
  ///
  /// In tr, this message translates to:
  /// **'Ödev Ekle'**
  String get odevEkle;

  /// No description provided for @odevEklendi.
  ///
  /// In tr, this message translates to:
  /// **'Ödev eklendi'**
  String get odevEklendi;

  /// No description provided for @odevSil.
  ///
  /// In tr, this message translates to:
  /// **'Ödev Sil'**
  String get odevSil;

  /// No description provided for @buOdeviSilmekIstiyorMusun.
  ///
  /// In tr, this message translates to:
  /// **'Bu ödevi silmek istiyor musun?'**
  String get buOdeviSilmekIstiyorMusun;

  /// No description provided for @henuzOdevEklenmemis.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ödev eklenmemiş'**
  String get henuzOdevEklenmemis;

  /// No description provided for @yeniOdevEklemekIcinButonunaBas.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ödev eklemek için + butonuna bas'**
  String get yeniOdevEklemekIcinButonunaBas;

  /// No description provided for @dersAdi.
  ///
  /// In tr, this message translates to:
  /// **'Ders Adı'**
  String get dersAdi;

  /// No description provided for @gun.
  ///
  /// In tr, this message translates to:
  /// **'Gün'**
  String get gun;

  /// No description provided for @henuzDersEklenmemis.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ders eklenmemiş'**
  String get henuzDersEklenmemis;

  /// No description provided for @yeniDersEklemekIcinButonunaBas.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ders eklemek için + butonuna bas'**
  String get yeniDersEklemekIcinButonunaBas;

  /// No description provided for @yeniGelisimKaydi.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Gelişim Kaydı'**
  String get yeniGelisimKaydi;

  /// No description provided for @deger.
  ///
  /// In tr, this message translates to:
  /// **'Değer'**
  String get deger;

  /// No description provided for @kayitSil.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Sil'**
  String get kayitSil;

  /// No description provided for @buKaydiSilmekIstiyorMusun.
  ///
  /// In tr, this message translates to:
  /// **'Bu kaydı silmek istiyor musun?'**
  String get buKaydiSilmekIstiyorMusun;

  /// No description provided for @kazanim.
  ///
  /// In tr, this message translates to:
  /// **'Kazanım'**
  String get kazanim;

  /// No description provided for @henuzGelisimKaydiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz gelişim kaydı yok'**
  String get henuzGelisimKaydiYok;

  /// No description provided for @yeniKayitEklemekIcinButonunaBas.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kayıt eklemek için + butonuna bas'**
  String get yeniKayitEklemekIcinButonunaBas;

  /// No description provided for @cocukHenuzKonumPaylasmamis.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk henüz konum paylaşmamış'**
  String get cocukHenuzKonumPaylasmamis;

  /// No description provided for @cocugunaYeniBirGorevAta.
  ///
  /// In tr, this message translates to:
  /// **'Çocuğuna yeni bir görev ata'**
  String get cocugunaYeniBirGorevAta;

  /// No description provided for @cocukHesabiniSil.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Hesabını Sil'**
  String get cocukHesabiniSil;

  /// No description provided for @cocukHesabiSilindi.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk hesabı silindi'**
  String get cocukHesabiSilindi;

  /// No description provided for @aileBilgisiBulunamadiLutfenSayfayiYenileyin.
  ///
  /// In tr, this message translates to:
  /// **'Aile bilgisi bulunamadı. Lütfen sayfayı yenileyin.'**
  String get aileBilgisiBulunamadiLutfenSayfayiYenileyin;

  /// No description provided for @henuzCocukHesabiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz çocuk hesabı yok'**
  String get henuzCocukHesabiYok;

  /// No description provided for @aileBilgisiEksikLutfenSayfayiYenileyin.
  ///
  /// In tr, this message translates to:
  /// **'Aile bilgisi eksik. Lütfen sayfayı yenileyin.'**
  String get aileBilgisiEksikLutfenSayfayiYenileyin;

  /// No description provided for @isimEnAz2KarakterOlmali.
  ///
  /// In tr, this message translates to:
  /// **'İsim en az 2 karakter olmalı'**
  String get isimEnAz2KarakterOlmali;

  /// No description provided for @lerEslesmiyor.
  ///
  /// In tr, this message translates to:
  /// **'ler eşleşmiyor'**
  String get lerEslesmiyor;

  /// No description provided for @cocukHesabiniDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Hesabını Düzenle'**
  String get cocukHesabiniDuzenle;

  /// No description provided for @yeniCocukHesabi.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Çocuk Hesabı'**
  String get yeniCocukHesabi;

  /// No description provided for @arkadas.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş'**
  String get arkadas;

  /// No description provided for @kisiyiDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Kişiyi Düzenle'**
  String get kisiyiDuzenle;

  /// No description provided for @yeniKisi.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kişi'**
  String get yeniKisi;

  /// No description provided for @kisiyiSil.
  ///
  /// In tr, this message translates to:
  /// **'Kişiyi Sil'**
  String get kisiyiSil;

  /// No description provided for @kisiTelefonRehberindeBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Kişi telefon rehberinde bulunamadı'**
  String get kisiTelefonRehberindeBulunamadi;

  /// No description provided for @telefondanIceAktar.
  ///
  /// In tr, this message translates to:
  /// **'Telefondan İçe Aktar'**
  String get telefondanIceAktar;

  /// No description provided for @henuzKisiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kişi yok'**
  String get henuzKisiYok;

  /// No description provided for @alarmiKapat.
  ///
  /// In tr, this message translates to:
  /// **'Alarmı Kapat'**
  String get alarmiKapat;

  /// No description provided for @konumGuncelle.
  ///
  /// In tr, this message translates to:
  /// **'Konum Güncelle'**
  String get konumGuncelle;

  /// No description provided for @kazaTespitEdildi.
  ///
  /// In tr, this message translates to:
  /// **'KAZA TESPİT EDİLDİ'**
  String get kazaTespitEdildi;

  /// No description provided for @aracHareketiAniDurdu.
  ///
  /// In tr, this message translates to:
  /// **'Araç hareketi ani durdu'**
  String get aracHareketiAniDurdu;

  /// No description provided for @yuvarlanmaAlgilandi.
  ///
  /// In tr, this message translates to:
  /// **'Yuvarlanma algılandı'**
  String get yuvarlanmaAlgilandi;

  /// No description provided for @geriSayim.
  ///
  /// In tr, this message translates to:
  /// **'GERİ SAYIM'**
  String get geriSayim;

  /// No description provided for @sosOtomatikBaslayacak.
  ///
  /// In tr, this message translates to:
  /// **'SOS otomatik başlayacak...'**
  String get sosOtomatikBaslayacak;

  /// No description provided for @iyiyim.
  ///
  /// In tr, this message translates to:
  /// **'İYİYİM'**
  String get iyiyim;

  /// No description provided for @aileyiAra.
  ///
  /// In tr, this message translates to:
  /// **'AİLEYİ ARA'**
  String get aileyiAra;

  /// No description provided for @acilDurumBildirimi.
  ///
  /// In tr, this message translates to:
  /// **'🚨 ACİL DURUM BİLDİRİMİ'**
  String get acilDurumBildirimi;

  /// No description provided for @durumAracHareketsiz.
  ///
  /// In tr, this message translates to:
  /// **'Durum: Araç hareketsiz'**
  String get durumAracHareketsiz;

  /// No description provided for @haritadaGor.
  ///
  /// In tr, this message translates to:
  /// **'Haritada Gör'**
  String get haritadaGor;

  /// No description provided for @saglikKartiPaylasildi.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık kartı paylaşıldı'**
  String get saglikKartiPaylasildi;

  /// No description provided for @yardimCagir.
  ///
  /// In tr, this message translates to:
  /// **'YARDIM ÇAĞIR'**
  String get yardimCagir;

  /// No description provided for @aileyiBilgilendir.
  ///
  /// In tr, this message translates to:
  /// **'AİLEYİ BİLGİLENDİR'**
  String get aileyiBilgilendir;

  /// No description provided for @azonce1.
  ///
  /// In tr, this message translates to:
  /// **'az önce'**
  String get azonce1;

  /// No description provided for @kazaGecmisi.
  ///
  /// In tr, this message translates to:
  /// **'Kaza Geçmişi'**
  String get kazaGecmisi;

  /// No description provided for @gercekKaza.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek kaza'**
  String get gercekKaza;

  /// No description provided for @son30Gun0Olay.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün: 0 olay'**
  String get son30Gun0Olay;

  /// No description provided for @detayliIstatistik.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı İstatistik'**
  String get detayliIstatistik;

  /// No description provided for @olayListesi.
  ///
  /// In tr, this message translates to:
  /// **'OLAY LİSTESİ'**
  String get olayListesi;

  /// No description provided for @tumRaporlariIndir.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Raporları İndir'**
  String get tumRaporlariIndir;

  /// No description provided for @gercekkaza1.
  ///
  /// In tr, this message translates to:
  /// **'GERÇEK KAZA'**
  String get gercekkaza1;

  /// No description provided for @arandi.
  ///
  /// In tr, this message translates to:
  /// **'112 arandı'**
  String get arandi;

  /// No description provided for @kullaniciIyiyimDedi.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı \"İyiyim\" dedi'**
  String get kullaniciIyiyimDedi;

  /// No description provided for @kazaTespitiAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Kaza Tespiti Ayarları'**
  String get kazaTespitiAyarlari;

  /// No description provided for @yuksekDahaHassasDahaFazlaYanlisAlarmOlabilir.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek: Daha hassas, daha fazla yanlış alarm olabilir'**
  String get yuksekDahaHassasDahaFazlaYanlisAlarmOlabilir;

  /// No description provided for @ozelEsikDegerleri.
  ///
  /// In tr, this message translates to:
  /// **'ÖZEL EŞİK DEĞERLERİ'**
  String get ozelEsikDegerleri;

  /// No description provided for @maxHizDususu.
  ///
  /// In tr, this message translates to:
  /// **'Max hız düşüşü'**
  String get maxHizDususu;

  /// No description provided for @yuvarlanmaEsigi.
  ///
  /// In tr, this message translates to:
  /// **'Yuvarlanma eşiği'**
  String get yuvarlanmaEsigi;

  /// No description provided for @dogrulamaSuresi.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama süresi'**
  String get dogrulamaSuresi;

  /// No description provided for @aileUyeleriniOtomatikBilgilendir.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyelerini otomatik bilgilendir'**
  String get aileUyeleriniOtomatikBilgilendir;

  /// No description provided for @acilKontaklaraSmsGonder.
  ///
  /// In tr, this message translates to:
  /// **'Acil kontaklara SMS gönder'**
  String get acilKontaklaraSmsGonder;

  /// No description provided for @yasalSorumlulukBildirimiYanlisAramaCezasiKullaniciSorumlulugundadir.
  ///
  /// In tr, this message translates to:
  /// **'⚠️ Yasal sorumluluk bildirimi: Yanlış arama cezası kullanıcı sorumluluğundadır.'**
  String
  get yasalSorumlulukBildirimiYanlisAramaCezasiKullaniciSorumlulugundadir;

  /// No description provided for @konumPaylasimiAktifEt.
  ///
  /// In tr, this message translates to:
  /// **'Konum paylaşımı aktif et'**
  String get konumPaylasimiAktifEt;

  /// No description provided for @saglikKartiniPaylas.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık kartını paylaş'**
  String get saglikKartiniPaylas;

  /// No description provided for @acilKontaklariDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Acil Kontakları Düzenle'**
  String get acilKontaklariDuzenle;

  /// No description provided for @bildirimAyarlari1.
  ///
  /// In tr, this message translates to:
  /// **'BİLDİRİM AYARLARI'**
  String get bildirimAyarlari1;

  /// No description provided for @sesliAlarmCal.
  ///
  /// In tr, this message translates to:
  /// **'Sesli alarm çal'**
  String get sesliAlarmCal;

  /// No description provided for @duzSes.
  ///
  /// In tr, this message translates to:
  /// **'Düz ses'**
  String get duzSes;

  /// No description provided for @titresim.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim'**
  String get titresim;

  /// No description provided for @nabiz.
  ///
  /// In tr, this message translates to:
  /// **'Nabız'**
  String get nabiz;

  /// No description provided for @ekranFlas.
  ///
  /// In tr, this message translates to:
  /// **'Ekran flaş'**
  String get ekranFlas;

  /// No description provided for @rahatsizEtmeModunuGec.
  ///
  /// In tr, this message translates to:
  /// **'Rahatsız etme modunu geç'**
  String get rahatsizEtmeModunuGec;

  /// No description provided for @sonTest15Mart2025Basarili.
  ///
  /// In tr, this message translates to:
  /// **'Son test: 15 Mart 2025 - BAŞARILI'**
  String get sonTest15Mart2025Basarili;

  /// No description provided for @simulasyonTestiBaslat.
  ///
  /// In tr, this message translates to:
  /// **'Simülasyon Testi Başlat'**
  String get simulasyonTestiBaslat;

  /// No description provided for @telefonuSallayarakKazaSimulasyonunuBaslatin.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu sallayarak kaza simülasyonunu başlatın.'**
  String get telefonuSallayarakKazaSimulasyonunuBaslatin;

  /// No description provided for @belgeYuklendiVeOcrTamamlandi.
  ///
  /// In tr, this message translates to:
  /// **'Belge yüklendi ve OCR tamamlandı'**
  String get belgeYuklendiVeOcrTamamlandi;

  /// No description provided for @belgeFotografiCek.
  ///
  /// In tr, this message translates to:
  /// **'Belge Fotoğrafı Çek'**
  String get belgeFotografiCek;

  /// No description provided for @galeridenBelgeSec.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden Belge Seç'**
  String get galeridenBelgeSec;

  /// No description provided for @henuzBelgeYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz belge yok'**
  String get henuzBelgeYok;

  /// No description provided for @yuklemekIcinButonunaBasin.
  ///
  /// In tr, this message translates to:
  /// **'Yüklemek için + butonuna basın'**
  String get yuklemekIcinButonunaBasin;

  /// No description provided for @gorevOlustur.
  ///
  /// In tr, this message translates to:
  /// **'Görev Oluştur'**
  String get gorevOlustur;

  /// No description provided for @sosAktif.
  ///
  /// In tr, this message translates to:
  /// **'SOS AKTİF'**
  String get sosAktif;

  /// No description provided for @otomatikYardimCagrisiDevamEdiyor.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik yardım çağrısı devam ediyor'**
  String get otomatikYardimCagrisiDevamEdiyor;

  /// No description provided for @acilDurumDetaylari.
  ///
  /// In tr, this message translates to:
  /// **'ACİL DURUM DETAYLARI'**
  String get acilDurumDetaylari;

  /// No description provided for @yuksekSiddetliCarpmaTespitEdildi.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek şiddetli çarpma tespit edildi'**
  String get yuksekSiddetliCarpmaTespitEdildi;

  /// No description provided for @baslangic143215.
  ///
  /// In tr, this message translates to:
  /// **'⏰ Başlangıç: 14:32:15'**
  String get baslangic143215;

  /// No description provided for @seviyeYuksek.
  ///
  /// In tr, this message translates to:
  /// **'🎯 Seviye: YÜKSEK 🔴'**
  String get seviyeYuksek;

  /// No description provided for @otomatikYanitDurumu.
  ///
  /// In tr, this message translates to:
  /// **'OTOMATİK YANIT DURUMU'**
  String get otomatikYanitDurumu;

  /// No description provided for @sesKaydiBasladi.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı başladı'**
  String get sesKaydiBasladi;

  /// No description provided for @sure3Dk12Sn.
  ///
  /// In tr, this message translates to:
  /// **'Süre: 3 dk 12 sn'**
  String get sure3Dk12Sn;

  /// No description provided for @iyiyimSistemiDurdur.
  ///
  /// In tr, this message translates to:
  /// **'İYİYİM - SİSTEMİ DURDUR'**
  String get iyiyimSistemiDurdur;

  /// No description provided for @yardimTalebiHizlandirildi.
  ///
  /// In tr, this message translates to:
  /// **'Yardım talebi hızlandırıldı'**
  String get yardimTalebiHizlandirildi;

  /// No description provided for @acilDurumSos.
  ///
  /// In tr, this message translates to:
  /// **'🆘 ACİL DURUM SOS'**
  String get acilDurumSos;

  /// No description provided for @hizliSosKategorileri.
  ///
  /// In tr, this message translates to:
  /// **'HIZLI SOS KATEGORİLERİ'**
  String get hizliSosKategorileri;

  /// No description provided for @saglik1.
  ///
  /// In tr, this message translates to:
  /// **'SAĞLIK'**
  String get saglik1;

  /// No description provided for @guvenlik.
  ///
  /// In tr, this message translates to:
  /// **'GÜVENLİK'**
  String get guvenlik;

  /// No description provided for @dogalAfet.
  ///
  /// In tr, this message translates to:
  /// **'DOĞAL AFET'**
  String get dogalAfet;

  /// No description provided for @diger1.
  ///
  /// In tr, this message translates to:
  /// **'DİĞER'**
  String get diger1;

  /// No description provided for @sonSosGecmisi.
  ///
  /// In tr, this message translates to:
  /// **'SON SOS GEÇMİŞİ'**
  String get sonSosGecmisi;

  /// No description provided for @subat20250815.
  ///
  /// In tr, this message translates to:
  /// **'2 Şubat 2025 - 08:15'**
  String get subat20250815;

  /// No description provided for @gercekAcilDurum.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek acil durum'**
  String get gercekAcilDurum;

  /// No description provided for @testModuYakinda.
  ///
  /// In tr, this message translates to:
  /// **'Test modu yakında'**
  String get testModuYakinda;

  /// No description provided for @tetikleyiciler.
  ///
  /// In tr, this message translates to:
  /// **'TETİKLEYİCİLER'**
  String get tetikleyiciler;

  /// No description provided for @uzunSureHareketsizlik.
  ///
  /// In tr, this message translates to:
  /// **'Uzun süre hareketsizlik'**
  String get uzunSureHareketsizlik;

  /// No description provided for @saglikAciliyeti.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık aciliyeti'**
  String get saglikAciliyeti;

  /// No description provided for @akilliSaatEntegrasyonu.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı saat entegrasyonu'**
  String get akilliSaatEntegrasyonu;

  /// No description provided for @yanlisAlarmOnleme.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış alarm önleme'**
  String get yanlisAlarmOnleme;

  /// No description provided for @otomatikMesajlar.
  ///
  /// In tr, this message translates to:
  /// **'OTOMATİK MESAJLAR'**
  String get otomatikMesajlar;

  /// No description provided for @smsGonder.
  ///
  /// In tr, this message translates to:
  /// **'SMS gönder'**
  String get smsGonder;

  /// No description provided for @otomatikAramalar.
  ///
  /// In tr, this message translates to:
  /// **'OTOMATİK ARAMALAR'**
  String get otomatikAramalar;

  /// No description provided for @yasalUyariYanlisAramaCezasiKullaniciSorumlulugundadir.
  ///
  /// In tr, this message translates to:
  /// **'⚠️ Yasal uyarı: Yanlış arama cezası kullanıcı sorumluluğundadır.'**
  String get yasalUyariYanlisAramaCezasiKullaniciSorumlulugundadir;

  /// No description provided for @aileUyeleriniAra.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyelerini ara'**
  String get aileUyeleriniAra;

  /// No description provided for @konumPaylasimi.
  ///
  /// In tr, this message translates to:
  /// **'KONUM PAYLAŞIMI'**
  String get konumPaylasimi;

  /// No description provided for @anlikKonumPaylas.
  ///
  /// In tr, this message translates to:
  /// **'Anlık konum paylaş'**
  String get anlikKonumPaylas;

  /// No description provided for @rotaGecmisiniEkle.
  ///
  /// In tr, this message translates to:
  /// **'Rota geçmişini ekle'**
  String get rotaGecmisiniEkle;

  /// No description provided for @otomatikSesKaydi.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik ses kaydı'**
  String get otomatikSesKaydi;

  /// No description provided for @bulutaYukle.
  ///
  /// In tr, this message translates to:
  /// **'Buluta yükle'**
  String get bulutaYukle;

  /// No description provided for @adimEklemeYakindaGeliyor.
  ///
  /// In tr, this message translates to:
  /// **'Adım ekleme yakında geliyor'**
  String get adimEklemeYakindaGeliyor;

  /// No description provided for @adimEkle.
  ///
  /// In tr, this message translates to:
  /// **'Adım Ekle'**
  String get adimEkle;

  /// No description provided for @duzenlemeYakinda.
  ///
  /// In tr, this message translates to:
  /// **'Düzenleme yakında'**
  String get duzenlemeYakinda;

  /// No description provided for @silmeYakinda.
  ///
  /// In tr, this message translates to:
  /// **'Silme yakında'**
  String get silmeYakinda;

  /// No description provided for @sosAyarlariKaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'SOS ayarları kaydedildi'**
  String get sosAyarlariKaydedildi;

  /// No description provided for @acilDurumMesajSablonu.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum Mesaj Şablonu'**
  String get acilDurumMesajSablonu;

  /// No description provided for @smsSablonu.
  ///
  /// In tr, this message translates to:
  /// **'SMS ŞABLONU'**
  String get smsSablonu;

  /// No description provided for @smsMesaji.
  ///
  /// In tr, this message translates to:
  /// **'SMS mesajı...'**
  String get smsMesaji;

  /// No description provided for @pushBildirimSablonu.
  ///
  /// In tr, this message translates to:
  /// **'PUSH BİLDİRİM ŞABLONU'**
  String get pushBildirimSablonu;

  /// No description provided for @icerik.
  ///
  /// In tr, this message translates to:
  /// **'İçerik'**
  String get icerik;

  /// No description provided for @sesliMesajSablonu.
  ///
  /// In tr, this message translates to:
  /// **'SESLİ MESAJ ŞABLONU'**
  String get sesliMesajSablonu;

  /// No description provided for @onizleme.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get onizleme;

  /// No description provided for @kullanilabilirDegiskenler.
  ///
  /// In tr, this message translates to:
  /// **'KULLANILABİLİR DEĞİŞKENLER'**
  String get kullanilabilirDegiskenler;

  /// No description provided for @sablonKaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'Şablon kaydedildi'**
  String get sablonKaydedildi;

  /// No description provided for @birdenFazlaFotografVeyaVideo.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla fotoğraf veya video'**
  String get birdenFazlaFotografVeyaVideo;

  /// No description provided for @fotografCek.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Çek'**
  String get fotografCek;

  /// No description provided for @bugununAnilari.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün Anıları'**
  String get bugununAnilari;

  /// No description provided for @yilOnceBugun.
  ///
  /// In tr, this message translates to:
  /// **'1 Yıl Önce Bugün'**
  String get yilOnceBugun;

  /// No description provided for @gecenHaftaSonu.
  ///
  /// In tr, this message translates to:
  /// **'Geçen Hafta Sonu'**
  String get gecenHaftaSonu;

  /// No description provided for @son30Gun.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 Gün'**
  String get son30Gun;

  /// No description provided for @videolarimiz.
  ///
  /// In tr, this message translates to:
  /// **'Videolarımız'**
  String get videolarimiz;

  /// No description provided for @ilkAnilar.
  ///
  /// In tr, this message translates to:
  /// **'İlk Anılar'**
  String get ilkAnilar;

  /// No description provided for @henuzFotografYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz fotoğraf yok'**
  String get henuzFotografYok;

  /// No description provided for @telefonGalerisindenSecmekIcinButonunaBasin.
  ///
  /// In tr, this message translates to:
  /// **'Telefon galerisinden seçmek için + butonuna basın'**
  String get telefonGalerisindenSecmekIcinButonunaBasin;

  /// No description provided for @henuzAniOlusmadi.
  ///
  /// In tr, this message translates to:
  /// **'Henüz anı oluşmadı'**
  String get henuzAniOlusmadi;

  /// No description provided for @dahaFazlaFotografEkledikceAnilarOlusacak.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla fotoğraf ekledikçe anılar oluşacak'**
  String get dahaFazlaFotografEkledikceAnilarOlusacak;

  /// No description provided for @yaklasanEtkinlikler.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan Etkinlikler'**
  String get yaklasanEtkinlikler;

  /// No description provided for @yaklasanEtkinlikYok.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan etkinlik yok'**
  String get yaklasanEtkinlikYok;

  /// No description provided for @bekleyenGorevYok.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen görev yok'**
  String get bekleyenGorevYok;

  /// No description provided for @henuzRuhHaliPaylasilmamis.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ruh hali paylaşılmamış'**
  String get henuzRuhHaliPaylasilmamis;

  /// No description provided for @ruhHaliniPaylas.
  ///
  /// In tr, this message translates to:
  /// **'Ruh Halini Paylaş'**
  String get ruhHaliniPaylas;

  /// No description provided for @bataryaAnalitigi.
  ///
  /// In tr, this message translates to:
  /// **'Batarya Analitiği'**
  String get bataryaAnalitigi;

  /// No description provided for @gunlukOrtalama18.
  ///
  /// In tr, this message translates to:
  /// **'Günlük ortalama: %18'**
  String get gunlukOrtalama18;

  /// No description provided for @sali.
  ///
  /// In tr, this message translates to:
  /// **'Salı'**
  String get sali;

  /// No description provided for @carsamba.
  ///
  /// In tr, this message translates to:
  /// **'Çarşamba'**
  String get carsamba;

  /// No description provided for @persembe.
  ///
  /// In tr, this message translates to:
  /// **'Perşembe'**
  String get persembe;

  /// No description provided for @profilKullanimi.
  ///
  /// In tr, this message translates to:
  /// **'PROFİL KULLANIMI'**
  String get profilKullanimi;

  /// No description provided for @kosu.
  ///
  /// In tr, this message translates to:
  /// **'Koşu'**
  String get kosu;

  /// No description provided for @verimlilikMetrikleri.
  ///
  /// In tr, this message translates to:
  /// **'VERİMLİLİK METRİKLERİ'**
  String get verimlilikMetrikleri;

  /// No description provided for @optimalProfilOrani.
  ///
  /// In tr, this message translates to:
  /// **'Optimal profil oranı'**
  String get optimalProfilOrani;

  /// No description provided for @yanlisProfilGecisi.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış profil geçişi'**
  String get yanlisProfilGecisi;

  /// No description provided for @gun1.
  ///
  /// In tr, this message translates to:
  /// **'12/gün'**
  String get gun1;

  /// No description provided for @gun2.
  ///
  /// In tr, this message translates to:
  /// **'<5/gün'**
  String get gun2;

  /// No description provided for @aiOptimizasyonOnerileri.
  ///
  /// In tr, this message translates to:
  /// **'🤖 AI OPTİMİZASYON ÖNERİLERİ'**
  String get aiOptimizasyonOnerileri;

  /// No description provided for @canliKonumTakibi.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Konum Takibi'**
  String get canliKonumTakibi;

  /// No description provided for @guncelleme.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme'**
  String get guncelleme;

  /// No description provided for @saglayici.
  ///
  /// In tr, this message translates to:
  /// **'Sağlayıcı'**
  String get saglayici;

  /// No description provided for @iyi.
  ///
  /// In tr, this message translates to:
  /// **'İyi'**
  String get iyi;

  /// No description provided for @gunIciOzet.
  ///
  /// In tr, this message translates to:
  /// **'GÜN İÇİ ÖZET'**
  String get gunIciOzet;

  /// No description provided for @aktifSure.
  ///
  /// In tr, this message translates to:
  /// **'Aktif süre'**
  String get aktifSure;

  /// No description provided for @duraganSure.
  ///
  /// In tr, this message translates to:
  /// **'Durağan süre'**
  String get duraganSure;

  /// No description provided for @konumKaydi.
  ///
  /// In tr, this message translates to:
  /// **'Konum kaydı'**
  String get konumKaydi;

  /// No description provided for @bataryaKullanimi.
  ///
  /// In tr, this message translates to:
  /// **'Batarya kullanımı'**
  String get bataryaKullanimi;

  /// No description provided for @konumPaylas.
  ///
  /// In tr, this message translates to:
  /// **'Konum Paylaş'**
  String get konumPaylas;

  /// No description provided for @konumTakipAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Konum Takip Ayarları'**
  String get konumTakipAyarlari;

  /// No description provided for @aiOptimizasyonuYakindaGeliyor.
  ///
  /// In tr, this message translates to:
  /// **'AI optimizasyonu yakında geliyor'**
  String get aiOptimizasyonuYakindaGeliyor;

  /// No description provided for @oncelik1.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik:'**
  String get oncelik1;

  /// No description provided for @tahminiKalanSure.
  ///
  /// In tr, this message translates to:
  /// **'58% - Tahmini kalan süre:'**
  String get tahminiKalanSure;

  /// No description provided for @detayliAnaliz.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Analiz'**
  String get detayliAnaliz;

  /// No description provided for @hareketProfilleri.
  ///
  /// In tr, this message translates to:
  /// **'HAREKET PROFİLLERİ'**
  String get hareketProfilleri;

  /// No description provided for @gelismisAyarlar.
  ///
  /// In tr, this message translates to:
  /// **'GELİŞMİŞ AYARLAR'**
  String get gelismisAyarlar;

  /// No description provided for @adaptifEkranParlakligi.
  ///
  /// In tr, this message translates to:
  /// **'Adaptif ekran parlaklığı'**
  String get adaptifEkranParlakligi;

  /// No description provided for @agIstekleriniToplama.
  ///
  /// In tr, this message translates to:
  /// **'Ağ isteklerini toplama'**
  String get agIstekleriniToplama;

  /// No description provided for @konumOnbellekleme.
  ///
  /// In tr, this message translates to:
  /// **'Konum önbellekleme'**
  String get konumOnbellekleme;

  /// No description provided for @yardimciIslemciKullanimi.
  ///
  /// In tr, this message translates to:
  /// **'Yardımcı işlemci kullanımı'**
  String get yardimciIslemciKullanimi;

  /// No description provided for @oncelikMaksimumPilOmruTahmini23GunKonumTakibi.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik: Maksimum pil ömrü. Tahmini: 2-3 gün konum takibi.'**
  String get oncelikMaksimumPilOmruTahmini23GunKonumTakibi;

  /// No description provided for @oncelikDogruKonumPilTahmini12GunKonumTakibi.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik: Doğru konum + pil. Tahmini: 1-2 gün konum takibi.'**
  String get oncelikDogruKonumPilTahmini12GunKonumTakibi;

  /// No description provided for @oncelikEnDogruKonumTahmini812SaatKonumTakibi.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik: En doğru konum. Tahmini: 8-12 saat konum takibi.'**
  String get oncelikEnDogruKonumTahmini812SaatKonumTakibi;

  /// No description provided for @guncellemeAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'GÜNCELLEME AYARLARI'**
  String get guncellemeAyarlari;

  /// No description provided for @snArasi.
  ///
  /// In tr, this message translates to:
  /// **'5-60 sn arası'**
  String get snArasi;

  /// No description provided for @konumDegismedenGuncellemeYok.
  ///
  /// In tr, this message translates to:
  /// **'Konum değişmeden güncelleme yok'**
  String get konumDegismedenGuncellemeYok;

  /// No description provided for @zamanlayiciYedek.
  ///
  /// In tr, this message translates to:
  /// **'Zamanlayıcı yedek'**
  String get zamanlayiciYedek;

  /// No description provided for @konumDegismeseBileZorunluGuncelleme.
  ///
  /// In tr, this message translates to:
  /// **'Konum değişmese bile zorunlu güncelleme'**
  String get konumDegismeseBileZorunluGuncelleme;

  /// No description provided for @hassasiyet.
  ///
  /// In tr, this message translates to:
  /// **'HASSASİYET'**
  String get hassasiyet;

  /// No description provided for @gpsKalitesiDusukse.
  ///
  /// In tr, this message translates to:
  /// **'GPS kalitesi düşükse:'**
  String get gpsKalitesiDusukse;

  /// No description provided for @gucYonetimi.
  ///
  /// In tr, this message translates to:
  /// **'GÜÇ YÖNETİMİ'**
  String get gucYonetimi;

  /// No description provided for @gpsAcikKalmaSuresiniSinirla.
  ///
  /// In tr, this message translates to:
  /// **'GPS açık kalma süresini sınırla'**
  String get gpsAcikKalmaSuresiniSinirla;

  /// No description provided for @hareketAlgilayiciIleTetikle.
  ///
  /// In tr, this message translates to:
  /// **'Hareket algılayıcı ile tetikle'**
  String get hareketAlgilayiciIleTetikle;

  /// No description provided for @telefonSallanincaAktifOl.
  ///
  /// In tr, this message translates to:
  /// **'Telefon sallanınca aktif ol'**
  String get telefonSallanincaAktifOl;

  /// No description provided for @gecisKurallari.
  ///
  /// In tr, this message translates to:
  /// **'GEÇİŞ KURALLARI'**
  String get gecisKurallari;

  /// No description provided for @buProfileGecis.
  ///
  /// In tr, this message translates to:
  /// **'Bu profile geçiş:'**
  String get buProfileGecis;

  /// No description provided for @hizEsigi.
  ///
  /// In tr, this message translates to:
  /// **'Hız eşiği'**
  String get hizEsigi;

  /// No description provided for @buProfildenCikis.
  ///
  /// In tr, this message translates to:
  /// **'Bu profilden çıkış:'**
  String get buProfildenCikis;

  /// No description provided for @buSureBoyuncaHareketsizKalincaDusukProfil.
  ///
  /// In tr, this message translates to:
  /// **'Bu süre boyunca hareketsiz kalınca düşük profil'**
  String get buSureBoyuncaHareketsizKalincaDusukProfil;

  /// No description provided for @album.
  ///
  /// In tr, this message translates to:
  /// **'Albüm'**
  String get album;

  /// No description provided for @cocukGelisimi.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Gelişimi'**
  String get cocukGelisimi;

  /// No description provided for @kilometreTaslari.
  ///
  /// In tr, this message translates to:
  /// **'Kilometre Taşları'**
  String get kilometreTaslari;

  /// No description provided for @ilkKelime.
  ///
  /// In tr, this message translates to:
  /// **'İlk Kelime'**
  String get ilkKelime;

  /// No description provided for @ilkDis.
  ///
  /// In tr, this message translates to:
  /// **'İlk Diş'**
  String get ilkDis;

  /// No description provided for @inDogumGunu.
  ///
  /// In tr, this message translates to:
  /// **'ın Doğum Günü'**
  String get inDogumGunu;

  /// No description provided for @sonAnilar.
  ///
  /// In tr, this message translates to:
  /// **'Son Anılar'**
  String get sonAnilar;

  /// No description provided for @miracBugunIlkAdiminiAtti.
  ///
  /// In tr, this message translates to:
  /// **'Mirac bugün ilk adımını attı...'**
  String get miracBugunIlkAdiminiAtti;

  /// No description provided for @yilbasi2026.
  ///
  /// In tr, this message translates to:
  /// **'Yılbaşı 2026'**
  String get yilbasi2026;

  /// No description provided for @tumAileBirAradaydik.
  ///
  /// In tr, this message translates to:
  /// **'Tüm aile bir aradaydık...'**
  String get tumAileBirAradaydik;

  /// No description provided for @bugunAilenleYasadiginGuzelBirAniYaz.
  ///
  /// In tr, this message translates to:
  /// **'Bugün ailenle yaşadığın güzel bir anı yaz...'**
  String get bugunAilenleYasadiginGuzelBirAniYaz;

  /// No description provided for @tumEtkinlikler.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Etkinlikler'**
  String get tumEtkinlikler;

  /// No description provided for @fotograftanEtkinlik.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraftan Etkinlik'**
  String get fotograftanEtkinlik;

  /// No description provided for @buGunIcinPlanlanmisEtkinlikYok.
  ///
  /// In tr, this message translates to:
  /// **'Bu gün için planlanmış etkinlik yok'**
  String get buGunIcinPlanlanmisEtkinlikYok;

  /// No description provided for @takvimErisimIzniGerekli.
  ///
  /// In tr, this message translates to:
  /// **'Takvim Erişim İzni Gerekli'**
  String get takvimErisimIzniGerekli;

  /// No description provided for @takvimErisimIzniGerekliAyarlardanIzinVerin.
  ///
  /// In tr, this message translates to:
  /// **'Takvim erişim izni gerekli. Ayarlardan izin verin.'**
  String get takvimErisimIzniGerekliAyarlardanIzinVerin;

  /// No description provided for @takvimleriniziSenkronizeEtmekIcinTakvimErisimIzniVermenizGerekiyor.
  ///
  /// In tr, this message translates to:
  /// **'Takvimlerinizi senkronize etmek için takvim erişim izni vermeniz gerekiyor.'**
  String get takvimleriniziSenkronizeEtmekIcinTakvimErisimIzniVermenizGerekiyor;

  /// No description provided for @ayarlariAc.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Aç'**
  String get ayarlariAc;

  /// No description provided for @izinVer.
  ///
  /// In tr, this message translates to:
  /// **'İzin Ver'**
  String get izinVer;

  /// No description provided for @bagliTakvimler.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı Takvimler'**
  String get bagliTakvimler;

  /// No description provided for @henuzTakvimBaglantisiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz takvim bağlantısı yok'**
  String get henuzTakvimBaglantisiYok;

  /// No description provided for @henuzSenkronizeEdilmedi.
  ///
  /// In tr, this message translates to:
  /// **'🔄 Henüz senkronize edilmedi'**
  String get henuzSenkronizeEdilmedi;

  /// No description provided for @simdiSenkronize.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Senkronize'**
  String get simdiSenkronize;

  /// No description provided for @senkronizasyonIstatistikleri.
  ///
  /// In tr, this message translates to:
  /// **'Senkronizasyon İstatistikleri'**
  String get senkronizasyonIstatistikleri;

  /// No description provided for @guncellenen.
  ///
  /// In tr, this message translates to:
  /// **'🔄 Güncellenen'**
  String get guncellenen;

  /// No description provided for @senkronizasyonSikligi.
  ///
  /// In tr, this message translates to:
  /// **'Senkronizasyon sıklığı'**
  String get senkronizasyonSikligi;

  /// No description provided for @cakismaCozumu.
  ///
  /// In tr, this message translates to:
  /// **'Çakışma çözümü'**
  String get cakismaCozumu;

  /// No description provided for @senkronizasyonYonu.
  ///
  /// In tr, this message translates to:
  /// **'Senkronizasyon yönü'**
  String get senkronizasyonYonu;

  /// No description provided for @senkronizasyonyonu1.
  ///
  /// In tr, this message translates to:
  /// **'Senkronizasyon Yönü'**
  String get senkronizasyonyonu1;

  /// No description provided for @cakismacozumu1.
  ///
  /// In tr, this message translates to:
  /// **'Çakışma Çözümü'**
  String get cakismacozumu1;

  /// No description provided for @familyhubDisari.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub → Dışarı'**
  String get familyhubDisari;

  /// No description provided for @disariFamilyhub.
  ///
  /// In tr, this message translates to:
  /// **'Dışarı → FamilyHub'**
  String get disariFamilyhub;

  /// No description provided for @birlestir.
  ///
  /// In tr, this message translates to:
  /// **'Birleştir'**
  String get birlestir;

  /// No description provided for @kaynakOnceligi.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak önceliği'**
  String get kaynakOnceligi;

  /// No description provided for @alisverisListesi.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş Listesi'**
  String get alisverisListesi;

  /// No description provided for @listeBos.
  ///
  /// In tr, this message translates to:
  /// **'Liste boş'**
  String get listeBos;

  /// No description provided for @yeniUrunEklemekIcinButonunaBas.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ürün eklemek için + butonuna bas'**
  String get yeniUrunEklemekIcinButonunaBas;

  /// No description provided for @urunEkle.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Ekle'**
  String get urunEkle;

  /// No description provided for @urunAdi.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Adı'**
  String get urunAdi;

  /// No description provided for @akilliGorevRotasyonu.
  ///
  /// In tr, this message translates to:
  /// **'🤖 Akıllı Görev Rotasyonu'**
  String get akilliGorevRotasyonu;

  /// No description provided for @adaletKurallari.
  ///
  /// In tr, this message translates to:
  /// **'Adalet Kuralları'**
  String get adaletKurallari;

  /// No description provided for @internetBaglantiniziKontrolEdinVeTekrarDeneyin.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantınızı kontrol edin ve tekrar deneyin.'**
  String get internetBaglantiniziKontrolEdinVeTekrarDeneyin;

  /// No description provided for @oturumSurenizDolmusOlabilirLutfenTekrarGirisYapin.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süreniz dolmuş olabilir. Lütfen tekrar giriş yapın.'**
  String get oturumSurenizDolmusOlabilirLutfenTekrarGirisYapin;

  /// No description provided for @verilerYuklenirkenBirSorunOlustuLutfenTekrarDeneyin.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.'**
  String get verilerYuklenirkenBirSorunOlustuLutfenTekrarDeneyin;

  /// No description provided for @verilerYuklenemedi.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yüklenemedi'**
  String get verilerYuklenemedi;

  /// No description provided for @akilligorevrotasyonu1.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Görev Rotasyonu'**
  String get akilligorevrotasyonu1;

  /// No description provided for @otomatikDagitimAdaletAlgoritmasi.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik dağıtım + Adalet algoritması'**
  String get otomatikDagitimAdaletAlgoritmasi;

  /// No description provided for @aiOptimizasyonuCalisiyor.
  ///
  /// In tr, this message translates to:
  /// **'AI optimizasyonu çalışıyor...'**
  String get aiOptimizasyonuCalisiyor;

  /// No description provided for @yenidenDagit.
  ///
  /// In tr, this message translates to:
  /// **'🔄 YENİDEN DAĞIT'**
  String get yenidenDagit;

  /// No description provided for @adaletAlgoritmasiGorevleriDagitiyor.
  ///
  /// In tr, this message translates to:
  /// **'Adalet algoritması görevleri dağıtıyor...'**
  String get adaletAlgoritmasiGorevleriDagitiyor;

  /// No description provided for @genetikOptimizasyonEsitYukDengelemesi.
  ///
  /// In tr, this message translates to:
  /// **'Genetik optimizasyon + Eşit yük dengelemesi'**
  String get genetikOptimizasyonEsitYukDengelemesi;

  /// No description provided for @henuzDagitimYapilmadi.
  ///
  /// In tr, this message translates to:
  /// **'Henüz dağıtım yapılmadı'**
  String get henuzDagitimYapilmadi;

  /// No description provided for @yenidenDagitButonunaBasarakAi.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Dağıt butonuna basarak AI\\'**
  String get yenidenDagitButonunaBasarakAi;

  /// No description provided for @beceriEslesme.
  ///
  /// In tr, this message translates to:
  /// **'Beceri Eşleşme'**
  String get beceriEslesme;

  /// No description provided for @atandi.
  ///
  /// In tr, this message translates to:
  /// **'Atandı'**
  String get atandi;

  /// No description provided for @adaletKurallariAgirliklar.
  ///
  /// In tr, this message translates to:
  /// **'Adalet Kuralları & Ağırlıklar'**
  String get adaletKurallariAgirliklar;

  /// No description provided for @esitZamanDagilimi.
  ///
  /// In tr, this message translates to:
  /// **'Eşit Zaman Dağılımı'**
  String get esitZamanDagilimi;

  /// No description provided for @herkesEsitSureCalissin.
  ///
  /// In tr, this message translates to:
  /// **'Herkes eşit süre çalışsın'**
  String get herkesEsitSureCalissin;

  /// No description provided for @beceriEslestirmesi.
  ///
  /// In tr, this message translates to:
  /// **'Beceri Eşleştirmesi'**
  String get beceriEslestirmesi;

  /// No description provided for @dogruKisiDogruIs.
  ///
  /// In tr, this message translates to:
  /// **'Doğru kişi, doğru iş'**
  String get dogruKisiDogruIs;

  /// No description provided for @yorgunKisiyeAzGorev.
  ///
  /// In tr, this message translates to:
  /// **'Yorgun kişiye az görev'**
  String get yorgunKisiyeAzGorev;

  /// No description provided for @kisiselTercihler.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Tercihler'**
  String get kisiselTercihler;

  /// No description provided for @sevdigiIsleriYapsin.
  ///
  /// In tr, this message translates to:
  /// **'Sevdiği işleri yapsın'**
  String get sevdigiIsleriYapsin;

  /// No description provided for @ozelKurallar.
  ///
  /// In tr, this message translates to:
  /// **'Özel Kurallar'**
  String get ozelKurallar;

  /// No description provided for @odulSistemi.
  ///
  /// In tr, this message translates to:
  /// **'Ödül Sistemi'**
  String get odulSistemi;

  /// No description provided for @gorevBasinaPuan.
  ///
  /// In tr, this message translates to:
  /// **'Görev başına puan'**
  String get gorevBasinaPuan;

  /// No description provided for @alisveris.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş'**
  String get alisveris;

  /// No description provided for @bakim.
  ///
  /// In tr, this message translates to:
  /// **'Bakım'**
  String get bakim;

  /// No description provided for @idari.
  ///
  /// In tr, this message translates to:
  /// **'İdari'**
  String get idari;

  /// No description provided for @subat.
  ///
  /// In tr, this message translates to:
  /// **'Şubat'**
  String get subat;

  /// No description provided for @mayis.
  ///
  /// In tr, this message translates to:
  /// **'Mayıs'**
  String get mayis;

  /// No description provided for @agustos.
  ///
  /// In tr, this message translates to:
  /// **'Ağustos'**
  String get agustos;

  /// No description provided for @eylul.
  ///
  /// In tr, this message translates to:
  /// **'Eylül'**
  String get eylul;

  /// No description provided for @kasim.
  ///
  /// In tr, this message translates to:
  /// **'Kasım'**
  String get kasim;

  /// No description provided for @aralik.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get aralik;

  /// No description provided for @goreveklendi1.
  ///
  /// In tr, this message translates to:
  /// **'Görev eklendi'**
  String get goreveklendi1;

  /// No description provided for @goreviDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Görevi Düzenle'**
  String get goreviDuzenle;

  /// No description provided for @bitisTarihiSec.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Tarihi Seç'**
  String get bitisTarihiSec;

  /// No description provided for @gorevGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Görev güncellendi'**
  String get gorevGuncellendi;

  /// No description provided for @gorevleriniziOrganizeEdin.
  ///
  /// In tr, this message translates to:
  /// **'Görevlerinizi organize edin'**
  String get gorevleriniziOrganizeEdin;

  /// No description provided for @aileIlerlemesi.
  ///
  /// In tr, this message translates to:
  /// **'Aile İlerlemesi'**
  String get aileIlerlemesi;

  /// No description provided for @tumu.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get tumu;

  /// No description provided for @henuzGorevYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz görev yok'**
  String get henuzGorevYok;

  /// No description provided for @buFiltreyeUygunGorevYok.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtreye uygun görev yok'**
  String get buFiltreyeUygunGorevYok;

  /// No description provided for @ailenizIcinGorevlerOlusturunHerkesKatkidaBulunsun.
  ///
  /// In tr, this message translates to:
  /// **'Aileniz için görevler oluşturun, herkes katkıda bulunsun.'**
  String get ailenizIcinGorevlerOlusturunHerkesKatkidaBulunsun;

  /// No description provided for @farkliBirFiltreyeGozAtinVeyaYeniGorevEkleyin.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir filtreye göz atın veya yeni görev ekleyin.'**
  String get farkliBirFiltreyeGozAtinVeyaYeniGorevEkleyin;

  /// No description provided for @ilkGoreviOlustur.
  ///
  /// In tr, this message translates to:
  /// **'İlk Görevi Oluştur'**
  String get ilkGoreviOlustur;

  /// No description provided for @akilliDagitimYap.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Dağıtım Yap'**
  String get akilliDagitimYap;

  /// No description provided for @bilesik.
  ///
  /// In tr, this message translates to:
  /// **'🔗 Bileşik'**
  String get bilesik;

  /// No description provided for @akilliHatirlaticilar.
  ///
  /// In tr, this message translates to:
  /// **'🧠 Akıllı Hatırlatıcılar'**
  String get akilliHatirlaticilar;

  /// No description provided for @yeniHatirlatici.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Hatırlatıcı'**
  String get yeniHatirlatici;

  /// No description provided for @basari.
  ///
  /// In tr, this message translates to:
  /// **'Başarı'**
  String get basari;

  /// No description provided for @cocukOkuldanGelinceSuIcir.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk okuldan gelince su içir'**
  String get cocukOkuldanGelinceSuIcir;

  /// No description provided for @lokasyonOkulCikisiPattern.
  ///
  /// In tr, this message translates to:
  /// **'Lokasyon: Okul çıkışı pattern'**
  String get lokasyonOkulCikisiPattern;

  /// No description provided for @aksamYemegindenOnce1SaatHazirlik.
  ///
  /// In tr, this message translates to:
  /// **'Akşam yemeğinden önce 1 saat hazırlık'**
  String get aksamYemegindenOnce1SaatHazirlik;

  /// No description provided for @zaman1700GorevYemek.
  ///
  /// In tr, this message translates to:
  /// **'Zaman: 17:00, Görev: Yemek'**
  String get zaman1700GorevYemek;

  /// No description provided for @hatirlaticiyiSil.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcıyı Sil'**
  String get hatirlaticiyiSil;

  /// No description provided for @baslikGirilmeli.
  ///
  /// In tr, this message translates to:
  /// **'Başlık girilmeli'**
  String get baslikGirilmeli;

  /// No description provided for @girisYapmalisiniz.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapmalısınız'**
  String get girisYapmalisiniz;

  /// No description provided for @hatirlaticiOlusturuldu.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı oluşturuldu!'**
  String get hatirlaticiOlusturuldu;

  /// No description provided for @testHatirlatici.
  ///
  /// In tr, this message translates to:
  /// **'Test Hatırlatıcı'**
  String get testHatirlatici;

  /// No description provided for @yeniAkilliHatirlatici.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Akıllı Hatırlatıcı'**
  String get yeniAkilliHatirlatici;

  /// No description provided for @marketAlisverisi.
  ///
  /// In tr, this message translates to:
  /// **'Market alışverişi'**
  String get marketAlisverisi;

  /// No description provided for @sutVeEkmekAl.
  ///
  /// In tr, this message translates to:
  /// **'Süt ve ekmek al...'**
  String get sutVeEkmekAl;

  /// No description provided for @yerAdi.
  ///
  /// In tr, this message translates to:
  /// **'Yer Adı'**
  String get yerAdi;

  /// No description provided for @davranisTuru.
  ///
  /// In tr, this message translates to:
  /// **'Davranış Türü'**
  String get davranisTuru;

  /// No description provided for @bilesikMantik.
  ///
  /// In tr, this message translates to:
  /// **'Bileşik Mantık'**
  String get bilesikMantik;

  /// No description provided for @baglamHassasiyeti.
  ///
  /// In tr, this message translates to:
  /// **'🧠 Bağlam Hassasiyeti'**
  String get baglamHassasiyeti;

  /// No description provided for @sessizSaatlereSaygiGoster.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz saatlere saygı göster'**
  String get sessizSaatlereSaygiGoster;

  /// No description provided for @arasiSessiz.
  ///
  /// In tr, this message translates to:
  /// **'22:00-08:00 arası sessiz'**
  String get arasiSessiz;

  /// No description provided for @rahatsizEtmeModunaSaygi.
  ///
  /// In tr, this message translates to:
  /// **'Rahatsız etme moduna saygı'**
  String get rahatsizEtmeModunaSaygi;

  /// No description provided for @kisisellestirme.
  ///
  /// In tr, this message translates to:
  /// **'🎨 Kişiselleştirme'**
  String get kisisellestirme;

  /// No description provided for @baglamEkle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlam ekle'**
  String get baglamEkle;

  /// No description provided for @hedefKisiler.
  ///
  /// In tr, this message translates to:
  /// **'👥 Hedef Kişiler'**
  String get hedefKisiler;

  /// No description provided for @enYakinMusaitUygunYetkinlik.
  ///
  /// In tr, this message translates to:
  /// **'En yakın, müsait, uygun yetkinlik'**
  String get enYakinMusaitUygunYetkinlik;

  /// No description provided for @manuelSecim.
  ///
  /// In tr, this message translates to:
  /// **'Manuel seçim'**
  String get manuelSecim;

  /// No description provided for @cikinca.
  ///
  /// In tr, this message translates to:
  /// **'Çıkınca'**
  String get cikinca;

  /// No description provided for @yaklasinca.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşınca'**
  String get yaklasinca;

  /// No description provided for @evdenCikinca.
  ///
  /// In tr, this message translates to:
  /// **'Evden çıkınca'**
  String get evdenCikinca;

  /// No description provided for @iseVarinca.
  ///
  /// In tr, this message translates to:
  /// **'İşe varınca'**
  String get iseVarinca;

  /// No description provided for @goreliZaman.
  ///
  /// In tr, this message translates to:
  /// **'Göreli zaman'**
  String get goreliZaman;

  /// No description provided for @akilliPencere.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı pencere'**
  String get akilliPencere;

  /// No description provided for @appAcilinca.
  ///
  /// In tr, this message translates to:
  /// **'App açılınca'**
  String get appAcilinca;

  /// No description provided for @gorevTamamlaninca.
  ///
  /// In tr, this message translates to:
  /// **'Görev tamamlanınca'**
  String get gorevTamamlaninca;

  /// No description provided for @sosyalBaglam.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal bağlam'**
  String get sosyalBaglam;

  /// No description provided for @havaDegisimi.
  ///
  /// In tr, this message translates to:
  /// **'Hava değişimi'**
  String get havaDegisimi;

  /// No description provided for @alisverisNiyeti.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş niyeti'**
  String get alisverisNiyeti;

  /// No description provided for @arkadasca.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşça'**
  String get arkadasca;

  /// No description provided for @hatirlaticiAciklamasi.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı açıklaması...'**
  String get hatirlaticiAciklamasi;

  /// No description provided for @bildirimOnizleme.
  ///
  /// In tr, this message translates to:
  /// **'📱 Bildirim Önizleme'**
  String get bildirimOnizleme;

  /// No description provided for @basariMetrikleri.
  ///
  /// In tr, this message translates to:
  /// **'📊 Başarı Metrikleri'**
  String get basariMetrikleri;

  /// No description provided for @basariOrani.
  ///
  /// In tr, this message translates to:
  /// **'Başarı Oranı'**
  String get basariOrani;

  /// No description provided for @ortCevapSuresi.
  ///
  /// In tr, this message translates to:
  /// **'Ort. Cevap Süresi'**
  String get ortCevapSuresi;

  /// No description provided for @zamanDagilimi.
  ///
  /// In tr, this message translates to:
  /// **'📈 Zaman Dağılımı'**
  String get zamanDagilimi;

  /// No description provided for @lokasyonDagilimi.
  ///
  /// In tr, this message translates to:
  /// **'🗺️ Lokasyon Dağılımı'**
  String get lokasyonDagilimi;

  /// No description provided for @arasiBasari95AkilliPencereyiDaralt.
  ///
  /// In tr, this message translates to:
  /// **'17:00-19:00 arası başarı %95, akıllı pencereyi daralt'**
  String get arasiBasari95AkilliPencereyiDaralt;

  /// No description provided for @a101DisindaBasariDusukSadeceA101.
  ///
  /// In tr, this message translates to:
  /// **'A101 dışında başarı düşük, sadece A101\\'**
  String get a101DisindaBasariDusukSadeceA101;

  /// No description provided for @ertelemeOraniYuksekNazikTonDeneyin.
  ///
  /// In tr, this message translates to:
  /// **'Erteleme oranı yüksek, nazik ton deneyin'**
  String get ertelemeOraniYuksekNazikTonDeneyin;

  /// No description provided for @aiOgrenmeOnerileri.
  ///
  /// In tr, this message translates to:
  /// **'🤖 AI Öğrenme Önerileri'**
  String get aiOgrenmeOnerileri;

  /// No description provided for @modeliYenidenEgit.
  ///
  /// In tr, this message translates to:
  /// **'Modeli Yeniden Eğit'**
  String get modeliYenidenEgit;

  /// No description provided for @aksam.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get aksam;

  /// No description provided for @haftalik.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get haftalik;

  /// No description provided for @gunlukRutinler.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Rutinler'**
  String get gunlukRutinler;

  /// No description provided for @aktifRutin.
  ///
  /// In tr, this message translates to:
  /// **'AKTİF RUTİN'**
  String get aktifRutin;

  /// No description provided for @planlandi.
  ///
  /// In tr, this message translates to:
  /// **'Planlandı'**
  String get planlandi;

  /// No description provided for @duraklatildi.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get duraklatildi;

  /// No description provided for @tumAdimlar.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Adımlar'**
  String get tumAdimlar;

  /// No description provided for @ilerleme.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get ilerleme;

  /// No description provided for @toplamSure.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Süre'**
  String get toplamSure;

  /// No description provided for @rutinTamamlandi.
  ///
  /// In tr, this message translates to:
  /// **'🎉 Rutin Tamamlandı!'**
  String get rutinTamamlandi;

  /// No description provided for @tumAdimlariBasariylaTamamladiniz.
  ///
  /// In tr, this message translates to:
  /// **'Tüm adımları başarıyla tamamladınız.'**
  String get tumAdimlariBasariylaTamamladiniz;

  /// No description provided for @suAnkiAdim.
  ///
  /// In tr, this message translates to:
  /// **'ŞU ANKİ ADIM'**
  String get suAnkiAdim;

  /// No description provided for @kayitBaslat.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Başlat'**
  String get kayitBaslat;

  /// No description provided for @telefonu3KezSallayincaKayitBaslar.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu 3 kez sallayınca kayıt başlar'**
  String get telefonu3KezSallayincaKayitBaslar;

  /// No description provided for @ekrandakiButonaBasarakBaslat.
  ///
  /// In tr, this message translates to:
  /// **'Ekrandaki butona basarak başlat'**
  String get ekrandakiButonaBasarakBaslat;

  /// No description provided for @aileBilgisiBulunamadiLutfenTekrarGirisYapin.
  ///
  /// In tr, this message translates to:
  /// **'Aile bilgisi bulunamadı. Lütfen tekrar giriş yapın.'**
  String get aileBilgisiBulunamadiLutfenTekrarGirisYapin;

  /// No description provided for @acilDurumButonuIleGonderildi.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum butonu ile gönderildi'**
  String get acilDurumButonuIleGonderildi;

  /// No description provided for @fenerAcik.
  ///
  /// In tr, this message translates to:
  /// **'Fener Açık'**
  String get fenerAcik;

  /// No description provided for @fenerKapali.
  ///
  /// In tr, this message translates to:
  /// **'Fener Kapalı'**
  String get fenerKapali;

  /// No description provided for @dokunAckapatSosButonuMorseKodu.
  ///
  /// In tr, this message translates to:
  /// **'Dokun: Aç/Kapat  |  SOS butonu: Morse kodu'**
  String get dokunAckapatSosButonuMorseKodu;

  /// No description provided for @acilSosBaslat.
  ///
  /// In tr, this message translates to:
  /// **'ACİL SOS BAŞLAT'**
  String get acilSosBaslat;

  /// No description provided for @saglikKartiKaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık kartı kaydedildi'**
  String get saglikKartiKaydedildi;

  /// No description provided for @acilDurumKisisiOtomatikSecildi.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum kişisi otomatik seçildi'**
  String get acilDurumKisisiOtomatikSecildi;

  /// No description provided for @aileUyesiBulunamadiLutfenManuelGirin.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyesi bulunamadı, lütfen manuel girin'**
  String get aileUyesiBulunamadiLutfenManuelGirin;

  /// No description provided for @saglikKartiniDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Kartını Düzenle'**
  String get saglikKartiniDuzenle;

  /// No description provided for @timiBilgiler.
  ///
  /// In tr, this message translates to:
  /// **'Tımi Bilgiler'**
  String get timiBilgiler;

  /// No description provided for @ornARh.
  ///
  /// In tr, this message translates to:
  /// **'Örn: A Rh+'**
  String get ornARh;

  /// No description provided for @virgulleAyirinFindikPolen.
  ///
  /// In tr, this message translates to:
  /// **'Virgülle ayırın: fındık, polen, ...'**
  String get virgulleAyirinFindikPolen;

  /// No description provided for @virgulleAyirinAstimSeker.
  ///
  /// In tr, this message translates to:
  /// **'Virgülle ayırın: astım, şeker, ...'**
  String get virgulleAyirinAstimSeker;

  /// No description provided for @ilacAdi.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Adı'**
  String get ilacAdi;

  /// No description provided for @orn500mg.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 500mg'**
  String get orn500mg;

  /// No description provided for @siklik.
  ///
  /// In tr, this message translates to:
  /// **'Sıklık'**
  String get siklik;

  /// No description provided for @ornGunde2Kez.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Günde 2 kez'**
  String get ornGunde2Kez;

  /// No description provided for @ilacEkle.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Ekle'**
  String get ilacEkle;

  /// No description provided for @ornEsAnneKardes.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Eş, Anne, Kardeş'**
  String get ornEsAnneKardes;

  /// No description provided for @aileUyesindenOtomatikSec.
  ///
  /// In tr, this message translates to:
  /// **'Aile Üyesinden Otomatik Seç'**
  String get aileUyesindenOtomatikSec;

  /// No description provided for @doktorAdi.
  ///
  /// In tr, this message translates to:
  /// **'Doktor Adı'**
  String get doktorAdi;

  /// No description provided for @saglikKartiniKaydet.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Kartını Kaydet'**
  String get saglikKartiniKaydet;

  /// No description provided for @acilDurumlardaKullanilabilirBilgiler.
  ///
  /// In tr, this message translates to:
  /// **'Acil durumlarda kullanılabilir bilgiler'**
  String get acilDurumlardaKullanilabilirBilgiler;

  /// No description provided for @saglikKarti.
  ///
  /// In tr, this message translates to:
  /// **'SAĞLIK KARTI'**
  String get saglikKarti;

  /// No description provided for @qrKodIlePaylas.
  ///
  /// In tr, this message translates to:
  /// **'QR Kod ile Paylaş'**
  String get qrKodIlePaylas;

  /// No description provided for @yalnizcaAileUyeleriTarafindanOkunabilir.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca aile üyeleri tarafından okunabilir'**
  String get yalnizcaAileUyeleriTarafindanOkunabilir;

  /// No description provided for @dogruluk.
  ///
  /// In tr, this message translates to:
  /// **'Doğruluk'**
  String get dogruluk;

  /// No description provided for @aileUyeleri.
  ///
  /// In tr, this message translates to:
  /// **'Aile Üyeleri'**
  String get aileUyeleri;

  /// No description provided for @aileUyesiBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyesi bulunamadı'**
  String get aileUyesiBulunamadi;

  /// No description provided for @konumPaylasimiKapali.
  ///
  /// In tr, this message translates to:
  /// **'Konum paylaşımı kapalı'**
  String get konumPaylasimiKapali;

  /// No description provided for @konumPaylasiminiDurdur.
  ///
  /// In tr, this message translates to:
  /// **'Konum Paylaşımını Durdur'**
  String get konumPaylasiminiDurdur;

  /// No description provided for @canliKonumPaylas.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Konum Paylaş'**
  String get canliKonumPaylas;

  /// No description provided for @ailenizinKorumaKalkani.
  ///
  /// In tr, this message translates to:
  /// **'Ailenizin koruma kalkanı'**
  String get ailenizinKorumaKalkani;

  /// No description provided for @butona3SaniyeBasiliTutun.
  ///
  /// In tr, this message translates to:
  /// **'Butona 3 saniye basılı tutun'**
  String get butona3SaniyeBasiliTutun;

  /// No description provided for @canliKonumAktif.
  ///
  /// In tr, this message translates to:
  /// **'Canlı konum aktif'**
  String get canliKonumAktif;

  /// No description provided for @canliKonumGonder.
  ///
  /// In tr, this message translates to:
  /// **'Canlı konum gönder'**
  String get canliKonumGonder;

  /// No description provided for @acilCagriMerkezi.
  ///
  /// In tr, this message translates to:
  /// **'Acil çağrı merkezi'**
  String get acilCagriMerkezi;

  /// No description provided for @alerjiVeIlacBilgileri.
  ///
  /// In tr, this message translates to:
  /// **'Alerji ve ilaç bilgileri'**
  String get alerjiVeIlacBilgileri;

  /// No description provided for @evOkulIsIcinGeofence.
  ///
  /// In tr, this message translates to:
  /// **'Ev, okul, iş için geofence'**
  String get evOkulIsIcinGeofence;

  /// No description provided for @belirliSuredeVarisKontrolu.
  ///
  /// In tr, this message translates to:
  /// **'Belirli sürede varış kontrolü'**
  String get belirliSuredeVarisKontrolu;

  /// No description provided for @acilDurumdaSesKaydi.
  ///
  /// In tr, this message translates to:
  /// **'Acil durumda ses kaydı'**
  String get acilDurumdaSesKaydi;

  /// No description provided for @telefonFeneriniAc.
  ///
  /// In tr, this message translates to:
  /// **'Telefon fenerini aç'**
  String get telefonFeneriniAc;

  /// No description provided for @aileUyeleriYukleniyorLutfenBekleyin.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyeleri yükleniyor, lütfen bekleyin...'**
  String get aileUyeleriYukleniyorLutfenBekleyin;

  /// No description provided for @sure.
  ///
  /// In tr, this message translates to:
  /// **'Süre:'**
  String get sure;

  /// No description provided for @aktifMonitorler.
  ///
  /// In tr, this message translates to:
  /// **'AKTİF MONİTÖRLER'**
  String get aktifMonitorler;

  /// No description provided for @gecmis.
  ///
  /// In tr, this message translates to:
  /// **'GEÇMİŞ'**
  String get gecmis;

  /// No description provided for @vardi.
  ///
  /// In tr, this message translates to:
  /// **'Vardı'**
  String get vardi;

  /// No description provided for @henuzVarisPlaniYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz varış planı yok'**
  String get henuzVarisPlaniYok;

  /// No description provided for @yeniBirVarisPlanlamakIcinButonaBas.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir varış planlamak için butona bas'**
  String get yeniBirVarisPlanlamakIcinButonaBas;

  /// No description provided for @geofenceAktifBolgeleriniziYonetinVeKonumDurumunuKontrolEdin.
  ///
  /// In tr, this message translates to:
  /// **'Geofence aktif bölgelerinizi yönetin ve konum durumunu kontrol edin.'**
  String get geofenceAktifBolgeleriniziYonetinVeKonumDurumunuKontrolEdin;

  /// No description provided for @icerde.
  ///
  /// In tr, this message translates to:
  /// **'İçerde'**
  String get icerde;

  /// No description provided for @disarda.
  ///
  /// In tr, this message translates to:
  /// **'Dışarda'**
  String get disarda;

  /// No description provided for @yeniBolge.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Bölge'**
  String get yeniBolge;

  /// No description provided for @yeniBolgeEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Bölge Ekle'**
  String get yeniBolgeEkle;

  /// No description provided for @gelistirici.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici'**
  String get gelistirici;

  /// No description provided for @familyhubIncntumHaklariSaklidir.
  ///
  /// In tr, this message translates to:
  /// **'© 2026 FamilyHub Inc.\\nTüm hakları saklıdır.'**
  String get familyhubIncntumHaklariSaklidir;

  /// No description provided for @gorunumAyarlariKaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm ayarları kaydedildi'**
  String get gorunumAyarlariKaydedildi;

  /// No description provided for @gorunum.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get gorunum;

  /// No description provided for @yedeklemeTamamlandi.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme tamamlandı'**
  String get yedeklemeTamamlandi;

  /// No description provided for @onceGoogleDriveHesabiniziBaglayin.
  ///
  /// In tr, this message translates to:
  /// **'Önce Google Drive hesabınızı bağlayın'**
  String get onceGoogleDriveHesabiniziBaglayin;

  /// No description provided for @geriYuklenecekYedekBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklenecek yedek bulunamadı'**
  String get geriYuklenecekYedekBulunamadi;

  /// No description provided for @yedeklemeAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme Ayarları'**
  String get yedeklemeAyarlari;

  /// No description provided for @hesapBagliDegil.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Bağlı Değil'**
  String get hesapBagliDegil;

  /// No description provided for @googleDriveBaglantisiKesildi.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive bağlantısı kesildi'**
  String get googleDriveBaglantisiKesildi;

  /// No description provided for @yedegiSil.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği Sil'**
  String get yedegiSil;

  /// No description provided for @yedeklemeGecmisi.
  ///
  /// In tr, this message translates to:
  /// **'YEDEKLEME GEÇMİŞİ'**
  String get yedeklemeGecmisi;

  /// No description provided for @henuzYedeklemeYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yedekleme yok'**
  String get henuzYedeklemeYok;

  /// No description provided for @simdiYedekleButonunaBasarakBaslayabilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Yedekle butonuna basarak başlayabilirsiniz'**
  String get simdiYedekleButonunaBasarakBaslayabilirsiniz;

  /// No description provided for @isimsizCocuk.
  ///
  /// In tr, this message translates to:
  /// **'İsimsiz Çocuk'**
  String get isimsizCocuk;

  /// No description provided for @roluDegistir.
  ///
  /// In tr, this message translates to:
  /// **'Rolü Değiştir'**
  String get roluDegistir;

  /// No description provided for @konumunuGor.
  ///
  /// In tr, this message translates to:
  /// **'Konumunu Gör'**
  String get konumunuGor;

  /// No description provided for @ebeveynlerVeYetiskinler.
  ///
  /// In tr, this message translates to:
  /// **'Ebeveynler ve Yetişkinler'**
  String get ebeveynlerVeYetiskinler;

  /// No description provided for @cocuklar.
  ///
  /// In tr, this message translates to:
  /// **'Çocuklar'**
  String get cocuklar;

  /// No description provided for @yeniUyeDavetEt.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Üye Davet Et'**
  String get yeniUyeDavetEt;

  /// No description provided for @cocukHesabiEkle.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Hesabı Ekle'**
  String get cocukHesabiEkle;

  /// No description provided for @henuzBirAilenizYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir aileniz yok'**
  String get henuzBirAilenizYok;

  /// No description provided for @yeniBirAileOlusturunVeyaDavetKoduIleKatilin.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir aile oluşturun veya davet kodu ile katılın.'**
  String get yeniBirAileOlusturunVeyaDavetKoduIleKatilin;

  /// No description provided for @katil.
  ///
  /// In tr, this message translates to:
  /// **'Katıl'**
  String get katil;

  /// No description provided for @aileyeKatilimBasarili.
  ///
  /// In tr, this message translates to:
  /// **'Aileye katılım başarılı'**
  String get aileyeKatilimBasarili;

  /// No description provided for @gecersizDavetKodu.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz davet kodu'**
  String get gecersizDavetKodu;

  /// No description provided for @simdi.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi'**
  String get simdi;

  /// No description provided for @uyeYonetimi.
  ///
  /// In tr, this message translates to:
  /// **'Üye Yönetimi'**
  String get uyeYonetimi;

  /// No description provided for @ayarlariDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Düzenle'**
  String get ayarlariDuzenle;

  /// No description provided for @butceGoruntuleme.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Görüntüleme'**
  String get butceGoruntuleme;

  /// No description provided for @yedeklemeYonetimi.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme Yönetimi'**
  String get yedeklemeYonetimi;

  /// No description provided for @icerikSilme.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Silme'**
  String get icerikSilme;

  /// No description provided for @buEkranaErisimYetkinizYok.
  ///
  /// In tr, this message translates to:
  /// **'Bu ekrana erişim yetkiniz yok'**
  String get buEkranaErisimYetkinizYok;

  /// No description provided for @yoneticiOlarakUyelerinRolleriniVeYetkileriniDuzenleyebilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici olarak üyelerin rollerini ve yetkilerini düzenleyebilirsiniz.'**
  String get yoneticiOlarakUyelerinRolleriniVeYetkileriniDuzenleyebilirsiniz;

  /// No description provided for @gunlukAileAktiviteleriSaglikEgitimVeDahaFazlasi.
  ///
  /// In tr, this message translates to:
  /// **'Günlük aile aktiviteleri, sağlık, eğitim ve daha fazlası'**
  String get gunlukAileAktiviteleriSaglikEgitimVeDahaFazlasi;

  /// No description provided for @kategoriler.
  ///
  /// In tr, this message translates to:
  /// **'KATEGORİLER'**
  String get kategoriler;

  /// No description provided for @gunlukOneriSayisi.
  ///
  /// In tr, this message translates to:
  /// **'GÜNLÜK ÖNERİ SAYISI'**
  String get gunlukOneriSayisi;

  /// No description provided for @yeniOnerilerHazirOldugundaBildirimGonder.
  ///
  /// In tr, this message translates to:
  /// **'Yeni öneriler hazır olduğunda bildirim gönder'**
  String get yeniOnerilerHazirOldugundaBildirimGonder;

  /// No description provided for @istatistikler.
  ///
  /// In tr, this message translates to:
  /// **'İSTATİSTİKLER'**
  String get istatistikler;

  /// No description provided for @toplamOneri.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Öneri'**
  String get toplamOneri;

  /// No description provided for @gunluk.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get gunluk;

  /// No description provided for @aileBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Aile bulunamadı'**
  String get aileBulunamadi;

  /// No description provided for @kodKopyalandi.
  ///
  /// In tr, this message translates to:
  /// **'Kod kopyalandı'**
  String get kodKopyalandi;

  /// No description provided for @yeniUyeleriDavetEtmekIcinBirKodOlusturunKod24SaatGecerlidir.
  ///
  /// In tr, this message translates to:
  /// **'Yeni üyeleri davet etmek için bir kod oluşturun. Kod 24 saat geçerlidir.'**
  String get yeniUyeleriDavetEtmekIcinBirKodOlusturunKod24SaatGecerlidir;

  /// No description provided for @kodOlustur.
  ///
  /// In tr, this message translates to:
  /// **'Kod Oluştur'**
  String get kodOlustur;

  /// No description provided for @yeniKodOlustur.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kod Oluştur'**
  String get yeniKodOlustur;

  /// No description provided for @uygulamaDili.
  ///
  /// In tr, this message translates to:
  /// **'UYGULAMA DİLİ'**
  String get uygulamaDili;

  /// No description provided for @bolge.
  ///
  /// In tr, this message translates to:
  /// **'BÖLGE'**
  String get bolge;

  /// No description provided for @tarihFormati.
  ///
  /// In tr, this message translates to:
  /// **'TARİH FORMATI'**
  String get tarihFormati;

  /// No description provided for @saatFormati.
  ///
  /// In tr, this message translates to:
  /// **'SAAT FORMATI'**
  String get saatFormati;

  /// No description provided for @haftaninIlkGunu.
  ///
  /// In tr, this message translates to:
  /// **'HAFTANIN İLK GÜNÜ'**
  String get haftaninIlkGunu;

  /// No description provided for @olcuBirimi.
  ///
  /// In tr, this message translates to:
  /// **'ÖLÇÜ BİRİMİ'**
  String get olcuBirimi;

  /// No description provided for @sicaklikBirimi.
  ///
  /// In tr, this message translates to:
  /// **'Sıcaklık Birimi'**
  String get sicaklikBirimi;

  /// No description provided for @sifirlama.
  ///
  /// In tr, this message translates to:
  /// **'SIFIRLAMA'**
  String get sifirlama;

  /// No description provided for @ulkeBolge.
  ///
  /// In tr, this message translates to:
  /// **'ÜLKE / BÖLGE'**
  String get ulkeBolge;

  /// No description provided for @cihazDiliOtomatik.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz Dili (Otomatik)'**
  String get cihazDiliOtomatik;

  /// No description provided for @sistemDili.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili: {lang}'**
  String sistemDili(Object lang);

  /// No description provided for @kaydet.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get kaydet;

  /// No description provided for @kaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi'**
  String get kaydedildi;

  /// No description provided for @saat24.
  ///
  /// In tr, this message translates to:
  /// **'24 saat'**
  String get saat24;

  /// No description provided for @saat12.
  ///
  /// In tr, this message translates to:
  /// **'12 saat (AM/PM)'**
  String get saat12;

  /// No description provided for @pazartesi.
  ///
  /// In tr, this message translates to:
  /// **'Pazartesi'**
  String get pazartesi;

  /// No description provided for @pazar.
  ///
  /// In tr, this message translates to:
  /// **'Pazar'**
  String get pazar;

  /// No description provided for @metrik.
  ///
  /// In tr, this message translates to:
  /// **'Metrik (kg, cm)'**
  String get metrik;

  /// No description provided for @imperyal.
  ///
  /// In tr, this message translates to:
  /// **'İmperyal (lb, in)'**
  String get imperyal;

  /// No description provided for @celsius.
  ///
  /// In tr, this message translates to:
  /// **'Celsius (°C)'**
  String get celsius;

  /// No description provided for @fahrenheit.
  ///
  /// In tr, this message translates to:
  /// **'Fahrenheit (°F)'**
  String get fahrenheit;

  /// No description provided for @vazgec.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get vazgec;

  /// No description provided for @sifirla.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get sifirla;

  /// No description provided for @dilTercihiniSifirla.
  ///
  /// In tr, this message translates to:
  /// **'Dil tercihini sıfırla'**
  String get dilTercihiniSifirla;

  /// No description provided for @dilTercihiniSifirlaAcik.
  ///
  /// In tr, this message translates to:
  /// **'Dil seçimini temizler, cihaz diline döner. Verileriniz silinmez.'**
  String get dilTercihiniSifirlaAcik;

  /// No description provided for @bolgeAyarlariniSifirla.
  ///
  /// In tr, this message translates to:
  /// **'Bölge ayarlarını varsayılana döndür'**
  String get bolgeAyarlariniSifirla;

  /// No description provided for @bolgeAyarlariniSifirlaAcik.
  ///
  /// In tr, this message translates to:
  /// **'Tarih/saat/birim biçimlerini varsayılana alır. Verileriniz silinmez.'**
  String get bolgeAyarlariniSifirlaAcik;

  /// No description provided for @dilTercihiniSifirlaOnay.
  ///
  /// In tr, this message translates to:
  /// **'Dil seçiminiz temizlenecek ve uygulama cihazınızın sistem diline dönecek. Aile, sağlık, bütçe gibi verileriniz SİLİNMEZ.'**
  String get dilTercihiniSifirlaOnay;

  /// No description provided for @bolgeAyarlariniSifirlaOnay.
  ///
  /// In tr, this message translates to:
  /// **'Tarih, saat, ölçü ve sıcaklık biçimleri varsayılana dönecek. Verileriniz SİLİNMEZ.'**
  String get bolgeAyarlariniSifirlaOnay;

  /// No description provided for @dilBolgeKaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'Dil ve bölge ayarları kaydedildi'**
  String get dilBolgeKaydedildi;

  /// No description provided for @dilTercihiSifirlandi.
  ///
  /// In tr, this message translates to:
  /// **'Dil tercihi sıfırlandı'**
  String get dilTercihiSifirlandi;

  /// No description provided for @bolgeAyarlariSifirlandi.
  ///
  /// In tr, this message translates to:
  /// **'Bölge ayarları varsayılana döndürüldü'**
  String get bolgeAyarlariSifirlandi;

  /// No description provided for @ulkeSecimiBilgi.
  ///
  /// In tr, this message translates to:
  /// **'Ülke seçimi; para birimi, ev gideri ve market içeriğini belirler.'**
  String get ulkeSecimiBilgi;

  /// No description provided for @shoppingEkle.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get shoppingEkle;

  /// No description provided for @shoppingListeyeEkle.
  ///
  /// In tr, this message translates to:
  /// **'Listeye Ekle'**
  String get shoppingListeyeEkle;

  /// No description provided for @shoppingUrunAdi.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı'**
  String get shoppingUrunAdi;

  /// No description provided for @shoppingAdetOpsiyonel.
  ///
  /// In tr, this message translates to:
  /// **'Adet (isteğe bağlı)'**
  String get shoppingAdetOpsiyonel;

  /// No description provided for @shoppingKategori.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get shoppingKategori;

  /// No description provided for @shoppingBekleyen.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get shoppingBekleyen;

  /// No description provided for @shoppingTamamlanan.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get shoppingTamamlanan;

  /// No description provided for @shoppingHizliEkle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Ekle'**
  String get shoppingHizliEkle;

  /// No description provided for @shoppingListenBos.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş listen boş'**
  String get shoppingListenBos;

  /// No description provided for @shoppingBosAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Ürün ekle, tarife göre otomatik doldur ya da AI ile hızlı liste oluştur.'**
  String get shoppingBosAciklama;

  /// No description provided for @shoppingTariften.
  ///
  /// In tr, this message translates to:
  /// **'Tariften'**
  String get shoppingTariften;

  /// No description provided for @shoppingAiListe.
  ///
  /// In tr, this message translates to:
  /// **'AI Liste'**
  String get shoppingAiListe;

  /// No description provided for @shoppingKatMarket.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get shoppingKatMarket;

  /// No description provided for @shoppingKatEczane.
  ///
  /// In tr, this message translates to:
  /// **'Eczane'**
  String get shoppingKatEczane;

  /// No description provided for @shoppingKatKirtasiye.
  ///
  /// In tr, this message translates to:
  /// **'Kırtasiye'**
  String get shoppingKatKirtasiye;

  /// No description provided for @shoppingKatEv.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get shoppingKatEv;

  /// No description provided for @shoppingKatDiger.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get shoppingKatDiger;

  /// No description provided for @shoppingAdet.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{{count} adet} other{{count} adet}}'**
  String shoppingAdet(int count);

  /// No description provided for @shoppingTamamlandiOran.
  ///
  /// In tr, this message translates to:
  /// **'{done} / {total} tamamlandı'**
  String shoppingTamamlandiOran(Object done, Object total);

  /// No description provided for @shoppingGeriAl.
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get shoppingGeriAl;

  /// No description provided for @shoppingSilindi.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" silindi'**
  String shoppingSilindi(Object name);

  /// No description provided for @shoppingZatenListede.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" zaten listede'**
  String shoppingZatenListede(Object name);

  /// No description provided for @shoppingGecerliMiktar.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir miktar girin (1 veya üzeri)'**
  String get shoppingGecerliMiktar;

  /// No description provided for @shoppingYuklenemedi.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş listeniz şu anda yüklenemedi. Lütfen tekrar deneyin.'**
  String get shoppingYuklenemedi;

  /// No description provided for @shoppingTekrarDene.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get shoppingTekrarDene;

  /// No description provided for @shoppingTipYakinMarket.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki Marketler (Harita)'**
  String get shoppingTipYakinMarket;

  /// No description provided for @shoppingTipMarketKatalogu.
  ///
  /// In tr, this message translates to:
  /// **'Market Kataloğu'**
  String get shoppingTipMarketKatalogu;

  /// No description provided for @shoppingTipAiMarket.
  ///
  /// In tr, this message translates to:
  /// **'AI Market Listesi'**
  String get shoppingTipAiMarket;

  /// No description provided for @shoppingTipTarifeGore.
  ///
  /// In tr, this message translates to:
  /// **'Tarife Göre Ekle'**
  String get shoppingTipTarifeGore;

  /// No description provided for @shoppingMalzemeEklendi.
  ///
  /// In tr, this message translates to:
  /// **'{title} için {count} malzeme eklendi'**
  String shoppingMalzemeEklendi(Object title, Object count);

  /// No description provided for @shoppingListeyeEklendi.
  ///
  /// In tr, this message translates to:
  /// **'{name} listeye eklendi'**
  String shoppingListeyeEklendi(Object name);

  /// No description provided for @shoppingTumUrunlerEklendi.
  ///
  /// In tr, this message translates to:
  /// **'Tüm ürünler listeye eklendi'**
  String get shoppingTumUrunlerEklendi;

  /// No description provided for @shoppingKonumAliniyor.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor…'**
  String get shoppingKonumAliniyor;

  /// No description provided for @shoppingKonumIzniYok.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi. Ayarlardan izin verin.'**
  String get shoppingKonumIzniYok;

  /// No description provided for @shoppingKonumBulundu.
  ///
  /// In tr, this message translates to:
  /// **'Konumun: {coords} — harita açılıyor'**
  String shoppingKonumBulundu(Object coords);

  /// No description provided for @shoppingKonumAlinamadi.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Lütfen tekrar deneyin.'**
  String get shoppingKonumAlinamadi;

  /// No description provided for @shoppingAiHazirlaniyor.
  ///
  /// In tr, this message translates to:
  /// **'AI market listesi hazırlanıyor…'**
  String get shoppingAiHazirlaniyor;

  /// No description provided for @shoppingListeOlusturulamadi.
  ///
  /// In tr, this message translates to:
  /// **'Liste oluşturulamadı. İnternet bağlantısını kontrol edin.'**
  String get shoppingListeOlusturulamadi;

  /// No description provided for @shoppingAiMarketBaslik.
  ///
  /// In tr, this message translates to:
  /// **'AI Market Listesi'**
  String get shoppingAiMarketBaslik;

  /// No description provided for @shoppingDokunEkle.
  ///
  /// In tr, this message translates to:
  /// **'Ürüne dokunarak listene ekle.'**
  String get shoppingDokunEkle;

  /// No description provided for @shoppingTumunuEkle.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Ekle'**
  String get shoppingTumunuEkle;

  /// No description provided for @shoppingTarifeGoreBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Tarife Göre Alışveriş'**
  String get shoppingTarifeGoreBaslik;

  /// No description provided for @shoppingTarifSayisi.
  ///
  /// In tr, this message translates to:
  /// **'{count} tarif'**
  String shoppingTarifSayisi(Object count);

  /// No description provided for @shoppingTarifAra.
  ///
  /// In tr, this message translates to:
  /// **'Tarif ara...'**
  String get shoppingTarifAra;

  /// No description provided for @shoppingTarifMeta.
  ///
  /// In tr, this message translates to:
  /// **'{time} dk · {count} malzeme'**
  String shoppingTarifMeta(Object time, Object count);

  /// No description provided for @shoppingFiyatGuncellenemedi.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat güncellenemedi (AI kotası dolu olabilir)'**
  String get shoppingFiyatGuncellenemedi;

  /// No description provided for @shoppingFiyatBasarisiz.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat güncelleme başarısız'**
  String get shoppingFiyatBasarisiz;

  /// No description provided for @shoppingFiyatlariGuncelle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatları Güncelle (AI)'**
  String get shoppingFiyatlariGuncelle;

  /// No description provided for @shoppingGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi: {date}'**
  String shoppingGuncellendi(Object date);

  /// No description provided for @shoppingMarketKatalogu.
  ///
  /// In tr, this message translates to:
  /// **'Market Kataloğu'**
  String get shoppingMarketKatalogu;

  /// No description provided for @shoppingHaftaninFirsatlari.
  ///
  /// In tr, this message translates to:
  /// **'Bu Haftanın Fırsatları'**
  String get shoppingHaftaninFirsatlari;

  /// No description provided for @shoppingTumu.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get shoppingTumu;

  /// No description provided for @unitPiece.
  ///
  /// In tr, this message translates to:
  /// **'adet'**
  String get unitPiece;

  /// No description provided for @unitPack.
  ///
  /// In tr, this message translates to:
  /// **'paket'**
  String get unitPack;

  /// No description provided for @unitBox.
  ///
  /// In tr, this message translates to:
  /// **'kutu'**
  String get unitBox;

  /// No description provided for @unitBottle.
  ///
  /// In tr, this message translates to:
  /// **'şişe'**
  String get unitBottle;

  /// No description provided for @unitJar.
  ///
  /// In tr, this message translates to:
  /// **'kavanoz'**
  String get unitJar;

  /// No description provided for @unitLiter.
  ///
  /// In tr, this message translates to:
  /// **'L'**
  String get unitLiter;

  /// No description provided for @unitMilliliter.
  ///
  /// In tr, this message translates to:
  /// **'mL'**
  String get unitMilliliter;

  /// No description provided for @unitKilogram.
  ///
  /// In tr, this message translates to:
  /// **'kg'**
  String get unitKilogram;

  /// No description provided for @unitGram.
  ///
  /// In tr, this message translates to:
  /// **'g'**
  String get unitGram;

  /// No description provided for @unitBunch.
  ///
  /// In tr, this message translates to:
  /// **'demet'**
  String get unitBunch;

  /// No description provided for @unitDozen.
  ///
  /// In tr, this message translates to:
  /// **'düzine'**
  String get unitDozen;

  /// No description provided for @unitPortion.
  ///
  /// In tr, this message translates to:
  /// **'porsiyon'**
  String get unitPortion;

  /// No description provided for @shoppingBirim.
  ///
  /// In tr, this message translates to:
  /// **'Birim'**
  String get shoppingBirim;

  /// No description provided for @legalBenefitsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yasal Haklar ve Avantajlar'**
  String get legalBenefitsTitle;

  /// No description provided for @legalBenefitsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{country} · ailenizi ilgilendiren haklar ve destekler'**
  String legalBenefitsSubtitle(Object country);

  /// No description provided for @legalSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Hak veya avantaj ara...'**
  String get legalSearchHint;

  /// No description provided for @legalSavedOnly.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilenler'**
  String get legalSavedOnly;

  /// No description provided for @legalAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get legalAll;

  /// No description provided for @legalOfficialSource.
  ///
  /// In tr, this message translates to:
  /// **'Resmî kaynak'**
  String get legalOfficialSource;

  /// No description provided for @legalOpenSource.
  ///
  /// In tr, this message translates to:
  /// **'Resmî kaynağı aç'**
  String get legalOpenSource;

  /// No description provided for @legalSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get legalSave;

  /// No description provided for @legalSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi'**
  String get legalSaved;

  /// No description provided for @legalExpired.
  ///
  /// In tr, this message translates to:
  /// **'Süresi geçmiş'**
  String get legalExpired;

  /// No description provided for @legalStale.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama tarihi eski'**
  String get legalStale;

  /// No description provided for @legalLastVerified.
  ///
  /// In tr, this message translates to:
  /// **'Son doğrulama: {date}'**
  String legalLastVerified(Object date);

  /// No description provided for @legalPossibleEligibility.
  ///
  /// In tr, this message translates to:
  /// **'Profilinize göre uygun olabilirsiniz. Şartları resmî kaynaktan doğrulayın.'**
  String get legalPossibleEligibility;

  /// No description provided for @legalDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgiler genel bilgilendirme amaçlıdır, hukuki danışmanlık değildir. Kurallar değişebilir; nihai uygunluk ilgili kurum tarafından belirlenir.'**
  String get legalDisclaimer;

  /// No description provided for @legalEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get legalEmptyTitle;

  /// No description provided for @legalEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Arama veya filtreyi değiştirmeyi deneyin.'**
  String get legalEmptyDesc;

  /// No description provided for @legalCatFamilySupport.
  ///
  /// In tr, this message translates to:
  /// **'Aile destekleri'**
  String get legalCatFamilySupport;

  /// No description provided for @legalCatChildBenefits.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk yardımları'**
  String get legalCatChildBenefits;

  /// No description provided for @legalCatHealthRights.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık hakları'**
  String get legalCatHealthRights;

  /// No description provided for @legalCatEducationSupport.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim destekleri'**
  String get legalCatEducationSupport;

  /// No description provided for @legalCatTaxBenefits.
  ///
  /// In tr, this message translates to:
  /// **'Vergi avantajları'**
  String get legalCatTaxBenefits;

  /// No description provided for @legalCatHousingSupport.
  ///
  /// In tr, this message translates to:
  /// **'Konut destekleri'**
  String get legalCatHousingSupport;

  /// No description provided for @legalCatEmployeeRights.
  ///
  /// In tr, this message translates to:
  /// **'Çalışan hakları'**
  String get legalCatEmployeeRights;

  /// No description provided for @legalCatParentalLeave.
  ///
  /// In tr, this message translates to:
  /// **'Doğum ve ebeveyn izni'**
  String get legalCatParentalLeave;

  /// No description provided for @legalCatResidencyRights.
  ///
  /// In tr, this message translates to:
  /// **'Oturum hakları'**
  String get legalCatResidencyRights;

  /// No description provided for @legalCatDisabilitySupport.
  ///
  /// In tr, this message translates to:
  /// **'Engellilik destekleri'**
  String get legalCatDisabilitySupport;

  /// No description provided for @legalCatSocialAid.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal yardımlar'**
  String get legalCatSocialAid;

  /// No description provided for @legalCatOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get legalCatOther;

  /// No description provided for @legalRegionFederal.
  ///
  /// In tr, this message translates to:
  /// **'Federal'**
  String get legalRegionFederal;

  /// No description provided for @legalRegionFlanders.
  ///
  /// In tr, this message translates to:
  /// **'Flaman Bölgesi'**
  String get legalRegionFlanders;

  /// No description provided for @legalRegionWallonia.
  ///
  /// In tr, this message translates to:
  /// **'Valon Bölgesi'**
  String get legalRegionWallonia;

  /// No description provided for @legalRegionBrussels.
  ///
  /// In tr, this message translates to:
  /// **'Brüksel-Başkent'**
  String get legalRegionBrussels;

  /// No description provided for @legalRegionMunicipality.
  ///
  /// In tr, this message translates to:
  /// **'Belediye'**
  String get legalRegionMunicipality;

  /// No description provided for @legalRegionOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get legalRegionOther;

  /// No description provided for @legalRemind.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlat'**
  String get legalRemind;

  /// No description provided for @kitchenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Mutfağı'**
  String get kitchenTitle;

  /// No description provided for @privacyAiSection.
  ///
  /// In tr, this message translates to:
  /// **'AI VERİ İZİNLERİ'**
  String get privacyAiSection;

  /// No description provided for @privacyAiDesc.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub AI hangi verilere erişebilir; hassas veriler varsayılan kapalı'**
  String get privacyAiDesc;

  /// No description provided for @privacySensitive.
  ///
  /// In tr, this message translates to:
  /// **'Hassas'**
  String get privacySensitive;

  /// No description provided for @privacyModCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get privacyModCalendar;

  /// No description provided for @privacyModTasks.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get privacyModTasks;

  /// No description provided for @privacyModShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş'**
  String get privacyModShopping;

  /// No description provided for @privacyModKitchen.
  ///
  /// In tr, this message translates to:
  /// **'Mutfak'**
  String get privacyModKitchen;

  /// No description provided for @privacyModHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get privacyModHealth;

  /// No description provided for @privacyModFinance.
  ///
  /// In tr, this message translates to:
  /// **'Finans'**
  String get privacyModFinance;

  /// No description provided for @privacyModChild.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk'**
  String get privacyModChild;

  /// No description provided for @privacyModLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get privacyModLocation;

  /// No description provided for @kitchenRecipeCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} tarif · haftalık plan'**
  String kitchenRecipeCount(Object count);

  /// No description provided for @kitchenAddRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Tarif'**
  String get kitchenAddRecipe;

  /// No description provided for @kitchenTabRecipes.
  ///
  /// In tr, this message translates to:
  /// **'Tarifler'**
  String get kitchenTabRecipes;

  /// No description provided for @kitchenTabWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get kitchenTabWeekly;

  /// No description provided for @kitchenTabShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş'**
  String get kitchenTabShopping;

  /// No description provided for @kitchenSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Tarif ara...'**
  String get kitchenSearchHint;

  /// No description provided for @kitchenFillWeeklyFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce Haftalık Plan sekmesini doldur'**
  String get kitchenFillWeeklyFirst;

  /// No description provided for @kitchenAutoIngredientList.
  ///
  /// In tr, this message translates to:
  /// **'Malzeme listesi otomatik oluşturulur'**
  String get kitchenAutoIngredientList;

  /// No description provided for @kitchenAddAllToShopping.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Alışveriş Listesine Ekle'**
  String get kitchenAddAllToShopping;

  /// No description provided for @legalReminderSet.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma kuruldu'**
  String get legalReminderSet;

  /// No description provided for @legalReminderRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma kaldırıldı'**
  String get legalReminderRemoved;

  /// No description provided for @legalReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne zaman hatırlatılsın?'**
  String get legalReminderTitle;

  /// No description provided for @legalRemindIn1Day.
  ///
  /// In tr, this message translates to:
  /// **'1 gün sonra'**
  String get legalRemindIn1Day;

  /// No description provided for @legalRemindIn7Days.
  ///
  /// In tr, this message translates to:
  /// **'7 gün sonra'**
  String get legalRemindIn7Days;

  /// No description provided for @legalRemindIn30Days.
  ///
  /// In tr, this message translates to:
  /// **'30 gün sonra'**
  String get legalRemindIn30Days;

  /// No description provided for @legalReminderNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yasal hak hatırlatması'**
  String get legalReminderNotifTitle;

  /// No description provided for @legalReminderNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'{title} — resmî kaynaktan güncel bilgileri kontrol et.'**
  String legalReminderNotifBody(Object title);

  /// No description provided for @familyIntelligenceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Zekası'**
  String get familyIntelligenceTitle;

  /// No description provided for @familyIntelligenceSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ailen için bugünün öncelikleri'**
  String get familyIntelligenceSubtitle;

  /// No description provided for @fiPriorityCritical.
  ///
  /// In tr, this message translates to:
  /// **'Kritik'**
  String get fiPriorityCritical;

  /// No description provided for @fiPriorityHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get fiPriorityHigh;

  /// No description provided for @fiPriorityNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get fiPriorityNormal;

  /// No description provided for @fiPriorityInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi'**
  String get fiPriorityInfo;

  /// No description provided for @fiWhyShown.
  ///
  /// In tr, this message translates to:
  /// **'Neden gösterildi?'**
  String get fiWhyShown;

  /// No description provided for @fiRuleBasedNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu özet, aile verilerinden kural tabanlı olarak üretildi.'**
  String get fiRuleBasedNote;

  /// No description provided for @fiEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu an öne çıkan bir şey yok'**
  String get fiEmptyTitle;

  /// No description provided for @fiEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Aile verilerin güncel. Yeni öncelikler burada görünecek.'**
  String get fiEmptyDesc;

  /// No description provided for @fiInsightOverdueTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geciken görevler'**
  String get fiInsightOverdueTitle;

  /// No description provided for @fiInsightOverdueBody.
  ///
  /// In tr, this message translates to:
  /// **'{count} görevin süresi geçmiş. Gözden geçir.'**
  String fiInsightOverdueBody(Object count);

  /// No description provided for @fiReasonOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş tarihi geçmiş ve tamamlanmamış görevler var.'**
  String get fiReasonOverdue;

  /// No description provided for @fiInsightPaymentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan ödeme'**
  String get fiInsightPaymentTitle;

  /// No description provided for @fiInsightPaymentBody.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün içinde bir ödeme var.'**
  String fiInsightPaymentBody(Object days);

  /// No description provided for @fiReasonPayment.
  ///
  /// In tr, this message translates to:
  /// **'Bütçende yaklaşan bir ödeme tarihi bulundu.'**
  String get fiReasonPayment;

  /// No description provided for @fiInsightTodayEventsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü etkinlikler'**
  String get fiInsightTodayEventsTitle;

  /// No description provided for @fiInsightTodayEventsBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {count} planlı etkinliğin var.'**
  String fiInsightTodayEventsBody(Object count);

  /// No description provided for @fiReasonTodayEvents.
  ///
  /// In tr, this message translates to:
  /// **'Takviminde bugüne ait etkinlikler var.'**
  String get fiReasonTodayEvents;

  /// No description provided for @fiInsightShoppingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş listesi'**
  String get fiInsightShoppingTitle;

  /// No description provided for @fiInsightShoppingBody.
  ///
  /// In tr, this message translates to:
  /// **'Listende {count} bekleyen ürün var.'**
  String fiInsightShoppingBody(Object count);

  /// No description provided for @fiReasonShopping.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanmamış alışveriş öğeleri birikmiş.'**
  String get fiReasonShopping;

  /// No description provided for @fiInsightPendingTasksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen görevler'**
  String get fiInsightPendingTasksTitle;

  /// No description provided for @fiInsightPendingTasksBody.
  ///
  /// In tr, this message translates to:
  /// **'{count} görevin seni bekliyor.'**
  String fiInsightPendingTasksBody(Object count);

  /// No description provided for @fiReasonPendingTasks.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanmamış görevlerin var.'**
  String get fiReasonPendingTasks;

  /// No description provided for @fiInsightAllClearTitle.
  ///
  /// In tr, this message translates to:
  /// **'Her şey yolunda'**
  String get fiInsightAllClearTitle;

  /// No description provided for @fiInsightAllClearBody.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen görev veya alışveriş yok. Harika!'**
  String get fiInsightAllClearBody;

  /// No description provided for @fiReasonAllClear.
  ///
  /// In tr, this message translates to:
  /// **'Geciken görev, bekleyen görev ve alışveriş öğesi bulunmadı.'**
  String get fiReasonAllClear;

  /// No description provided for @fiInsightBusyDayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yoğun bir gün'**
  String get fiInsightBusyDayTitle;

  /// No description provided for @fiInsightBusyDayBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {events} etkinlik ve {tasks} görev var. Görevleri paylaşmayı düşün.'**
  String fiInsightBusyDayBody(Object events, Object tasks);

  /// No description provided for @fiReasonBusyDay.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü etkinlik sayısı ve bekleyen görevler birlikte yüksek.'**
  String get fiReasonBusyDay;

  /// No description provided for @fiInsightShareShoppingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alışverişi paylaş'**
  String get fiInsightShareShoppingTitle;

  /// No description provided for @fiInsightShareShoppingBody.
  ///
  /// In tr, this message translates to:
  /// **'Listende {count} ürün var. Bir aile üyesiyle paylaşabilirsin.'**
  String fiInsightShareShoppingBody(Object count);

  /// No description provided for @fiReasonShareShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş listesi dolu ve ailede birden fazla üye var.'**
  String get fiReasonShareShopping;

  /// No description provided for @fiNotifyTop.
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkanı bildir'**
  String get fiNotifyTop;

  /// No description provided for @fiNotified.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim gönderildi'**
  String get fiNotified;

  /// No description provided for @fiDailySummary.
  ///
  /// In tr, this message translates to:
  /// **'Günlük özet bildirimi'**
  String get fiDailySummary;

  /// No description provided for @fiDailySummaryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Her gün belirlediğin saatte öne çıkanları bildir'**
  String get fiDailySummaryDesc;

  /// No description provided for @fiDailySummaryOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık · her gün {hour}:00'**
  String fiDailySummaryOn(Object hour);

  /// No description provided for @fiDailySummaryNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Zekası'**
  String get fiDailySummaryNotifTitle;

  /// No description provided for @fiDailySummaryNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün öncelikleri hazır. Görmek için dokun.'**
  String get fiDailySummaryNotifBody;

  /// No description provided for @fiPickHour.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get fiPickHour;

  /// No description provided for @fiQuietHours.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz saatlerdesin — bildirim gönderilmedi'**
  String get fiQuietHours;

  /// No description provided for @fiPreparingDay.
  ///
  /// In tr, this message translates to:
  /// **'Bugünü senin için hazırlıyorum…'**
  String get fiPreparingDay;

  /// No description provided for @googleErrCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Giriş iptal edildi'**
  String get googleErrCancelled;

  /// No description provided for @googleErrConfig.
  ///
  /// In tr, this message translates to:
  /// **'Google bağlantısı şu an yapılandırılamadı. Lütfen daha sonra tekrar deneyin.'**
  String get googleErrConfig;

  /// No description provided for @googleErrNetwork.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantınızı kontrol edip tekrar deneyin.'**
  String get googleErrNetwork;

  /// No description provided for @googleErrScope.
  ///
  /// In tr, this message translates to:
  /// **'Gerekli Google Drive izni verilmedi.'**
  String get googleErrScope;

  /// No description provided for @googleErrDrive.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive şu anda kullanılamıyor.'**
  String get googleErrDrive;

  /// No description provided for @googleErrUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Google\'a bağlanılamadı. Lütfen tekrar deneyin.'**
  String get googleErrUnknown;

  /// No description provided for @familyHubAITitle.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub AI'**
  String get familyHubAITitle;

  /// No description provided for @familyHubAISubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ailen için akıllı asistan'**
  String get familyHubAISubtitle;

  /// No description provided for @fhaSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün bağlamı'**
  String get fhaSummaryTitle;

  /// No description provided for @fhaQuickActionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı aksiyonlar'**
  String get fhaQuickActionsTitle;

  /// No description provided for @fhaQuickReviewTasks.
  ///
  /// In tr, this message translates to:
  /// **'Görevleri gözden geçir'**
  String get fhaQuickReviewTasks;

  /// No description provided for @fhaQuickShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş listesini aç'**
  String get fhaQuickShopping;

  /// No description provided for @fhaQuickPlanDay.
  ///
  /// In tr, this message translates to:
  /// **'Bugünü planla'**
  String get fhaQuickPlanDay;

  /// No description provided for @fhaQuickBudget.
  ///
  /// In tr, this message translates to:
  /// **'Bütçeyi özetle'**
  String get fhaQuickBudget;

  /// No description provided for @fhaQuickLegal.
  ///
  /// In tr, this message translates to:
  /// **'Yasal hakları göster'**
  String get fhaQuickLegal;

  /// No description provided for @fhaContextInfo.
  ///
  /// In tr, this message translates to:
  /// **'Öneriler yalnızca sayısal aile özetinden üretilir; isim, sağlık ve finans detayları AI\'ya gönderilmez.'**
  String get fhaContextInfo;

  /// No description provided for @fhaDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub AI önerileri bilgilendirme amaçlıdır; sağlık, hukuk veya finans konusunda kesin tavsiye değildir. Kritik işlemler onayınızla yapılır.'**
  String get fhaDisclaimer;

  /// No description provided for @fhaChatComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Doğal dil sohbeti yakında. Şimdilik bağlamsal hızlı aksiyonları kullanabilirsin.'**
  String get fhaChatComingSoon;

  /// No description provided for @fhaConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlemi onaylıyor musun?'**
  String get fhaConfirmTitle;

  /// No description provided for @fhaConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get fhaConfirm;

  /// No description provided for @fhaPin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitle'**
  String get fhaPin;

  /// No description provided for @fhaUnpin.
  ///
  /// In tr, this message translates to:
  /// **'Sabiti kaldır'**
  String get fhaUnpin;

  /// No description provided for @fhaEditSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi düzenle'**
  String get fhaEditSuggestion;

  /// No description provided for @fhaDeleteSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi sil'**
  String get fhaDeleteSuggestion;

  /// No description provided for @fhaHideSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi gizle'**
  String get fhaHideSuggestion;

  /// No description provided for @fhaAddSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Özel öneri ekle'**
  String get fhaAddSuggestion;

  /// No description provided for @fhaSuggestionHint.
  ///
  /// In tr, this message translates to:
  /// **'Öneri metnini yaz…'**
  String get fhaSuggestionHint;

  /// No description provided for @fhaCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get fhaCancel;

  /// No description provided for @fhaPreviewAddItems.
  ///
  /// In tr, this message translates to:
  /// **'Şu ürünler alışveriş listene eklenecek:'**
  String get fhaPreviewAddItems;

  /// No description provided for @fhaAddedItems.
  ///
  /// In tr, this message translates to:
  /// **'{count} ürün listeye eklendi'**
  String fhaAddedItems(Object count);

  /// No description provided for @fhaQuickAddItems.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen ürünleri ekle'**
  String get fhaQuickAddItems;

  /// No description provided for @fhaActionFailed.
  ///
  /// In tr, this message translates to:
  /// **'İşlem yapılamadı'**
  String get fhaActionFailed;

  /// No description provided for @fhaActionUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için ilgili modülü kullan'**
  String get fhaActionUnsupported;

  /// No description provided for @fhaQuickRemindTasks.
  ///
  /// In tr, this message translates to:
  /// **'Yarın görevleri hatırlat'**
  String get fhaQuickRemindTasks;

  /// No description provided for @fhaRemindTasksNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görev hatırlatması'**
  String get fhaRemindTasksNotifTitle;

  /// No description provided for @fhaRemindTasksNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Geciken görevlerini gözden geçir.'**
  String get fhaRemindTasksNotifBody;

  /// No description provided for @fhaReminderPreview.
  ///
  /// In tr, this message translates to:
  /// **'Yarın için bir hatırlatma kurulacak:'**
  String get fhaReminderPreview;

  /// No description provided for @fhaReminderSet.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma kuruldu'**
  String get fhaReminderSet;

  /// No description provided for @henuzVeriYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz veri yok'**
  String get henuzVeriYok;

  /// No description provided for @konumAlinamadiIzinleriKontrolEdin.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. İzinleri kontrol edin.'**
  String get konumAlinamadiIzinleriKontrolEdin;

  /// No description provided for @konumSec.
  ///
  /// In tr, this message translates to:
  /// **'Konum Seç'**
  String get konumSec;

  /// No description provided for @adresAraniyor.
  ///
  /// In tr, this message translates to:
  /// **'Adres aranıyor...'**
  String get adresAraniyor;

  /// No description provided for @etkinlikHatirlatmalari.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Hatırlatmaları'**
  String get etkinlikHatirlatmalari;

  /// No description provided for @yaklasanEtkinliklerIcinBildirimler.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan etkinlikler için bildirimler'**
  String get yaklasanEtkinliklerIcinBildirimler;

  /// No description provided for @gorevBildirimleri.
  ///
  /// In tr, this message translates to:
  /// **'Görev Bildirimleri'**
  String get gorevBildirimleri;

  /// No description provided for @atananVeYaklasanGorevler.
  ///
  /// In tr, this message translates to:
  /// **'Atanan ve yaklaşan görevler'**
  String get atananVeYaklasanGorevler;

  /// No description provided for @acilDurumUyarilari.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum Uyarıları'**
  String get acilDurumUyarilari;

  /// No description provided for @panikButonuVeGuvenlikBildirimleri.
  ///
  /// In tr, this message translates to:
  /// **'Panik butonu ve güvenlik bildirimleri'**
  String get panikButonuVeGuvenlikBildirimleri;

  /// No description provided for @guvenliBolgeGiriscikisUyarilari.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli bölge giriş/çıkış uyarıları'**
  String get guvenliBolgeGiriscikisUyarilari;

  /// No description provided for @yuksekOncelik.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek Öncelik'**
  String get yuksekOncelik;

  /// No description provided for @temelGorevler.
  ///
  /// In tr, this message translates to:
  /// **'Temel görevler'**
  String get temelGorevler;

  /// No description provided for @gelismisButce.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş bütçe'**
  String get gelismisButce;

  /// No description provided for @ozelTemalar.
  ///
  /// In tr, this message translates to:
  /// **'Özel temalar'**
  String get ozelTemalar;

  /// No description provided for @aileUyesi3.
  ///
  /// In tr, this message translates to:
  /// **'20 aile üyesi'**
  String get aileUyesi3;

  /// No description provided for @sinirsizDepolama.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız depolama'**
  String get sinirsizDepolama;

  /// No description provided for @oncelikliDestek.
  ///
  /// In tr, this message translates to:
  /// **'Öncelikli destek'**
  String get oncelikliDestek;

  /// No description provided for @apiErisimi.
  ///
  /// In tr, this message translates to:
  /// **'API erişimi'**
  String get apiErisimi;

  /// No description provided for @adminHesabiPremiumAktif.
  ///
  /// In tr, this message translates to:
  /// **'Admin hesabı — Premium aktif!'**
  String get adminHesabiPremiumAktif;

  /// No description provided for @testModuPremiumAktiflestirildi.
  ///
  /// In tr, this message translates to:
  /// **'Test modu: Premium aktifleştirildi'**
  String get testModuPremiumAktiflestirildi;

  /// No description provided for @odemeBilgisiAlinamadi.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme bilgisi alınamadı'**
  String get odemeBilgisiAlinamadi;

  /// No description provided for @premiumAktiflestirildi.
  ///
  /// In tr, this message translates to:
  /// **'Premium aktifleştirildi!'**
  String get premiumAktiflestirildi;

  /// No description provided for @enPopuler.
  ///
  /// In tr, this message translates to:
  /// **'En Popüler'**
  String get enPopuler;

  /// No description provided for @yukselt.
  ///
  /// In tr, this message translates to:
  /// **'Yükselt'**
  String get yukselt;

  /// No description provided for @planlarYuklenemedi.
  ///
  /// In tr, this message translates to:
  /// **'Planlar yüklenemedi'**
  String get planlarYuklenemedi;

  /// No description provided for @veriKullanimi.
  ///
  /// In tr, this message translates to:
  /// **'2. Veri Kullanımı'**
  String get veriKullanimi;

  /// No description provided for @cocuklarinGizliligi.
  ///
  /// In tr, this message translates to:
  /// **'4. Çocukların Gizliliği'**
  String get cocuklarinGizliligi;

  /// No description provided for @haklariniz.
  ///
  /// In tr, this message translates to:
  /// **'5. Haklarınız'**
  String get haklariniz;

  /// No description provided for @veriIndirmeHazirlaniyor.
  ///
  /// In tr, this message translates to:
  /// **'Veri indirme hazırlanıyor...'**
  String get veriIndirmeHazirlaniyor;

  /// No description provided for @hesabinizSilindiUygulamaKapatilacak.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız silindi. Uygulama kapatılacak.'**
  String get hesabinizSilindiUygulamaKapatilacak;

  /// No description provided for @veriPaylasimi.
  ///
  /// In tr, this message translates to:
  /// **'VERİ PAYLAŞIMI'**
  String get veriPaylasimi;

  /// No description provided for @konumPaylasimi1.
  ///
  /// In tr, this message translates to:
  /// **'Konum Paylaşımı'**
  String get konumPaylasimi1;

  /// No description provided for @aileUyeleriKonumunuzuGorebilsin.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyeleri konumunuzu görebilsin'**
  String get aileUyeleriKonumunuzuGorebilsin;

  /// No description provided for @profilGorunurlugu.
  ///
  /// In tr, this message translates to:
  /// **'Profil Görünürlüğü'**
  String get profilGorunurlugu;

  /// No description provided for @profilinizDigerUyelereGorunur.
  ///
  /// In tr, this message translates to:
  /// **'Profiliniz diğer üyelere görünür'**
  String get profilinizDigerUyelereGorunur;

  /// No description provided for @cevrimiciDurumunuzuGoster.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi durumunuzu göster'**
  String get cevrimiciDurumunuzuGoster;

  /// No description provided for @analitik.
  ///
  /// In tr, this message translates to:
  /// **'ANALİTİK'**
  String get analitik;

  /// No description provided for @kullanimAnalitigi.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Analitiği'**
  String get kullanimAnalitigi;

  /// No description provided for @anonimKullanimVerisiGonder.
  ///
  /// In tr, this message translates to:
  /// **'Anonim kullanım verisi gönder'**
  String get anonimKullanimVerisiGonder;

  /// No description provided for @verilerimiIndir.
  ///
  /// In tr, this message translates to:
  /// **'Verilerimi İndir'**
  String get verilerimiIndir;

  /// No description provided for @gdprKapsamindaTumVerileriniz.
  ///
  /// In tr, this message translates to:
  /// **'GDPR kapsamında tüm verileriniz'**
  String get gdprKapsamindaTumVerileriniz;

  /// No description provided for @hesabimiSil.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı Sil'**
  String get hesabimiSil;

  /// No description provided for @profilFotografiGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Profil fotoğrafı güncellendi'**
  String get profilFotografiGuncellendi;

  /// No description provided for @epostaDegistir.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Değiştir'**
  String get epostaDegistir;

  /// No description provided for @epostaDegisikligiIcinOnayBaglantisiGonderilecektir.
  ///
  /// In tr, this message translates to:
  /// **'E-posta değişikliği için onay bağlantısı gönderilecektir.'**
  String get epostaDegisikligiIcinOnayBaglantisiGonderilecektir;

  /// No description provided for @baglantiYok.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı yok'**
  String get baglantiYok;

  /// No description provided for @onayBaglantisiYeniEpostaAdresinizeGonderildi.
  ///
  /// In tr, this message translates to:
  /// **'Onay bağlantısı yeni e-posta adresinize gönderildi'**
  String get onayBaglantisiYeniEpostaAdresinizeGonderildi;

  /// No description provided for @kisiselBilgiler.
  ///
  /// In tr, this message translates to:
  /// **'KİŞİSEL BİLGİLER'**
  String get kisiselBilgiler;

  /// No description provided for @adiniziGirin.
  ///
  /// In tr, this message translates to:
  /// **'Adınızı girin'**
  String get adiniziGirin;

  /// No description provided for @telefonNumarasi.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası'**
  String get telefonNumarasi;

  /// No description provided for @degistir.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get degistir;

  /// No description provided for @ekranSuresiGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Ekran süresi güncellendi'**
  String get ekranSuresiGuncellendi;

  /// No description provided for @ebeveynTarafindanUzaktanKilitlendi.
  ///
  /// In tr, this message translates to:
  /// **'Ebeveyn tarafından uzaktan kilitlendi'**
  String get ebeveynTarafindanUzaktanKilitlendi;

  /// No description provided for @buCihaziHemenKilitleyinCocukGirisYapamayacak.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazı hemen kilitleyin. Çocuk giriş yapamayacak.'**
  String get buCihaziHemenKilitleyinCocukGirisYapamayacak;

  /// No description provided for @ornOdevZamani.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Ödev zamanı'**
  String get ornOdevZamani;

  /// No description provided for @gunlukEkranSuresi.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Ekran Süresi'**
  String get gunlukEkranSuresi;

  /// No description provided for @cocukUyelerIcinGunlukEkranSuresiLimitleriBelirleyin.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk üyeler için günlük ekran süresi limitleri belirleyin.'**
  String get cocukUyelerIcinGunlukEkranSuresiLimitleriBelirleyin;

  /// No description provided for @henuzCocukHesabiEklenmemisncocukHesaplariBolumundenEkleyebilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Henüz çocuk hesabı eklenmemiş.\\nÇocuk Hesapları bölümünden ekleyebilirsiniz.'**
  String
  get henuzCocukHesabiEklenmemisncocukHesaplariBolumundenEkleyebilirsiniz;

  /// No description provided for @ekranSuresiLimiti.
  ///
  /// In tr, this message translates to:
  /// **'Ekran Süresi Limiti'**
  String get ekranSuresiLimiti;

  /// No description provided for @sureyiAyarla.
  ///
  /// In tr, this message translates to:
  /// **'Süreyi Ayarla'**
  String get sureyiAyarla;

  /// No description provided for @cihaziUzaktanKilitle.
  ///
  /// In tr, this message translates to:
  /// **'Cihazı uzaktan kilitle'**
  String get cihaziUzaktanKilitle;

  /// No description provided for @ilkEvcilHayvaninizinAdiNedir.
  ///
  /// In tr, this message translates to:
  /// **'İlk evcil hayvanınızın adı nedir?'**
  String get ilkEvcilHayvaninizinAdiNedir;

  /// No description provided for @anneKizlikSoyadiNedir.
  ///
  /// In tr, this message translates to:
  /// **'Anne kızlık soyadı nedir?'**
  String get anneKizlikSoyadiNedir;

  /// No description provided for @enSevdiginizCocuklukArkadasinizinAdiNedir.
  ///
  /// In tr, this message translates to:
  /// **'En sevdiğiniz çocukluk arkadaşınızın adı nedir?'**
  String get enSevdiginizCocuklukArkadasinizinAdiNedir;

  /// No description provided for @ilkokulOgretmeninizinAdiNedir.
  ///
  /// In tr, this message translates to:
  /// **'İlkokul öğretmeninizin adı nedir?'**
  String get ilkokulOgretmeninizinAdiNedir;

  /// No description provided for @enSevdiginizKitabinAdiNedir.
  ///
  /// In tr, this message translates to:
  /// **'En sevdiğiniz kitabın adı nedir?'**
  String get enSevdiginizKitabinAdiNedir;

  /// No description provided for @dogdugunuzSehirNedir.
  ///
  /// In tr, this message translates to:
  /// **'Doğduğunuz şehir nedir?'**
  String get dogdugunuzSehirNedir;

  /// No description provided for @enSevdiginizYemekNedir.
  ///
  /// In tr, this message translates to:
  /// **'En sevdiğiniz yemek nedir?'**
  String get enSevdiginizYemekNedir;

  /// No description provided for @babanizinOrtaAdiNedir.
  ///
  /// In tr, this message translates to:
  /// **'Babanızın orta adı nedir?'**
  String get babanizinOrtaAdiNedir;

  /// No description provided for @lutfenHerIkiGuvenlikSorusunuDaSecin.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen her iki güvenlik sorusunu da seçin'**
  String get lutfenHerIkiGuvenlikSorusunuDaSecin;

  /// No description provided for @ikiGuvenlikSorusuFarkliOlmalidir.
  ///
  /// In tr, this message translates to:
  /// **'İki güvenlik sorusu farklı olmalıdır'**
  String get ikiGuvenlikSorusuFarkliOlmalidir;

  /// No description provided for @lutfenHerIkiCevabiDaGirin.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen her iki cevabı da girin'**
  String get lutfenHerIkiCevabiDaGirin;

  /// No description provided for @cevaplarEnAz2KarakterOlmalidir.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplar en az 2 karakter olmalıdır'**
  String get cevaplarEnAz2KarakterOlmalidir;

  /// No description provided for @guvenlikSorularinizKaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik sorularınız kaydedildi'**
  String get guvenlikSorularinizKaydedildi;

  /// No description provided for @birSoruSecin.
  ///
  /// In tr, this message translates to:
  /// **'Bir soru seçin'**
  String get birSoruSecin;

  /// No description provided for @kendiSorunuzuYazin.
  ///
  /// In tr, this message translates to:
  /// **'Kendi sorunuzu yazın'**
  String get kendiSorunuzuYazin;

  /// No description provided for @buCihazBiyometrikKimlikDogrulamayiDesteklemiyor.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz biyometrik kimlik doğrulamayı desteklemiyor'**
  String get buCihazBiyometrikKimlikDogrulamayiDesteklemiyor;

  /// No description provided for @aGirisYapmakIcinKimliginiziDogrulayin.
  ///
  /// In tr, this message translates to:
  /// **'a giriş yapmak için kimliğinizi doğrulayın'**
  String get aGirisYapmakIcinKimliginiziDogrulayin;

  /// No description provided for @kimlikDogrulamaBasarisiz.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik doğrulama başarısız'**
  String get kimlikDogrulamaBasarisiz;

  /// No description provided for @biyometrikGirisEtkinlestirildi.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş etkinleştirildi'**
  String get biyometrikGirisEtkinlestirildi;

  /// No description provided for @biyometrikGirisDevreDisiBirakildi.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş devre dışı bırakıldı'**
  String get biyometrikGirisDevreDisiBirakildi;

  /// No description provided for @mevcutSifre.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Şifre'**
  String get mevcutSifre;

  /// No description provided for @sifrenizguncellendi1.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz güncellendi'**
  String get sifrenizguncellendi1;

  /// No description provided for @sifreYonetimi.
  ///
  /// In tr, this message translates to:
  /// **'ŞİFRE YÖNETİMİ'**
  String get sifreYonetimi;

  /// No description provided for @mevcutSifreniziGuncelleyin.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifrenizi güncelleyin'**
  String get mevcutSifreniziGuncelleyin;

  /// No description provided for @sifreUnutmaDurumundaKullanilacak2Soru.
  ///
  /// In tr, this message translates to:
  /// **'Şifre unutma durumunda kullanılacak 2 soru'**
  String get sifreUnutmaDurumundaKullanilacak2Soru;

  /// No description provided for @girisSecenekleri.
  ///
  /// In tr, this message translates to:
  /// **'GİRİŞ SEÇENEKLERİ'**
  String get girisSecenekleri;

  /// No description provided for @biyometrikGiris.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik Giriş'**
  String get biyometrikGiris;

  /// No description provided for @parmakIziVeyaYuzTanimaIleGiris.
  ///
  /// In tr, this message translates to:
  /// **'Parmak izi veya yüz tanıma ile giriş'**
  String get parmakIziVeyaYuzTanimaIleGiris;

  /// No description provided for @cihazinizBiyometrigiDesteklemiyor.
  ///
  /// In tr, this message translates to:
  /// **'Cihazınız biyometriği desteklemiyor'**
  String get cihazinizBiyometrigiDesteklemiyor;

  /// No description provided for @tehlikeBolgesi.
  ///
  /// In tr, this message translates to:
  /// **'TEHLİKE BÖLGESİ'**
  String get tehlikeBolgesi;

  /// No description provided for @tumVerilerinizKaliciOlarakSilinecekBuIslemGeriAlinamaz.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz.'**
  String get tumVerilerinizKaliciOlarakSilinecekBuIslemGeriAlinamaz;

  /// No description provided for @geciciDosyalarSilinecekUygulamaBirazDahaYavasBaslayabilir.
  ///
  /// In tr, this message translates to:
  /// **'Geçici dosyalar silinecek. Uygulama biraz daha yavaş başlayabilir.'**
  String get geciciDosyalarSilinecekUygulamaBirazDahaYavasBaslayabilir;

  /// No description provided for @canliDestek.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Destek'**
  String get canliDestek;

  /// No description provided for @baglan.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get baglan;

  /// No description provided for @degerlendirmeSayfasiAciliyor.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme sayfası açılıyor...'**
  String get degerlendirmeSayfasiAciliyor;

  /// No description provided for @ailedenAyrildiniz.
  ///
  /// In tr, this message translates to:
  /// **'Aileden ayrıldınız'**
  String get ailedenAyrildiniz;

  /// No description provided for @tumVerilerSilindi.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriler silindi'**
  String get tumVerilerSilindi;

  /// No description provided for @onbellekTemizlendi.
  ///
  /// In tr, this message translates to:
  /// **'Önbellek temizlendi'**
  String get onbellekTemizlendi;

  /// No description provided for @familyhubiniziYonetin.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub\'ınızı yönetin'**
  String get familyhubiniziYonetin;

  /// No description provided for @gorunum1.
  ///
  /// In tr, this message translates to:
  /// **'GÖRÜNÜM'**
  String get gorunum1;

  /// No description provided for @uygulamaGorunumunuAyarla.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama görünümünü ayarla'**
  String get uygulamaGorunumunuAyarla;

  /// No description provided for @temaSecin.
  ///
  /// In tr, this message translates to:
  /// **'Tema Seçin'**
  String get temaSecin;

  /// No description provided for @uygulamaVurguRenginiDegistir.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama vurgu rengini değiştir'**
  String get uygulamaVurguRenginiDegistir;

  /// No description provided for @etkinlikGorevAcilDurumVeDahaFazlasi.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik, görev, acil durum ve daha fazlası'**
  String get etkinlikGorevAcilDurumVeDahaFazlasi;

  /// No description provided for @aile.
  ///
  /// In tr, this message translates to:
  /// **'AİLE'**
  String get aile;

  /// No description provided for @uyeleriGoruntuleRolleriDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Üyeleri görüntüle, rolleri düzenle'**
  String get uyeleriGoruntuleRolleriDuzenle;

  /// No description provided for @davetKoduOlustur.
  ///
  /// In tr, this message translates to:
  /// **'Davet Kodu Oluştur'**
  String get davetKoduOlustur;

  /// No description provided for @yeniUyeleriAileyeDavetEt.
  ///
  /// In tr, this message translates to:
  /// **'Yeni üyeleri aileye davet et'**
  String get yeniUyeleriAileyeDavetEt;

  /// No description provided for @herUyeIcinYetkiAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Her üye için yetki ayarları'**
  String get herUyeIcinYetkiAyarlari;

  /// No description provided for @pinIleCocukGirisleriYonetin.
  ///
  /// In tr, this message translates to:
  /// **'PIN ile çocuk girişleri yönetin'**
  String get pinIleCocukGirisleriYonetin;

  /// No description provided for @cocukUyelerIcinKullanimLimitleri.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk üyeler için kullanım limitleri'**
  String get cocukUyelerIcinKullanimLimitleri;

  /// No description provided for @gunlukAktiviteSaglikVeEgitimOnerileri.
  ///
  /// In tr, this message translates to:
  /// **'Günlük aktivite, sağlık ve eğitim önerileri'**
  String get gunlukAktiviteSaglikVeEgitimOnerileri;

  /// No description provided for @buAiledenCikisYap.
  ///
  /// In tr, this message translates to:
  /// **'Bu aileden çıkış yap'**
  String get buAiledenCikisYap;

  /// No description provided for @adFotografTelefonNumarasi.
  ///
  /// In tr, this message translates to:
  /// **'Ad, fotoğraf, telefon numarası'**
  String get adFotografTelefonNumarasi;

  /// No description provided for @sifreIkiFaktorBiyometrikGiris.
  ///
  /// In tr, this message translates to:
  /// **'Şifre, iki faktör, biyometrik giriş'**
  String get sifreIkiFaktorBiyometrikGiris;

  /// No description provided for @guvenli.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli'**
  String get guvenli;

  /// No description provided for @veriPaylasimiKonumIzinleri.
  ///
  /// In tr, this message translates to:
  /// **'Veri paylaşımı, konum izinleri'**
  String get veriPaylasimiKonumIzinleri;

  /// No description provided for @uygulamaDiliVeTarihFormati.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili ve tarih formatı'**
  String get uygulamaDiliVeTarihFormati;

  /// No description provided for @acilDurumBilgileriAlerjilerIlaclar.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum bilgileri, alerjiler, ilaçlar'**
  String get acilDurumBilgileriAlerjilerIlaclar;

  /// No description provided for @havaDurumuAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Hava Durumu Ayarları'**
  String get havaDurumuAyarlari;

  /// No description provided for @sehirBirimVeKonumTercihleri.
  ///
  /// In tr, this message translates to:
  /// **'Şehir, birim ve konum tercihleri'**
  String get sehirBirimVeKonumTercihleri;

  /// No description provided for @veriVeDepolama.
  ///
  /// In tr, this message translates to:
  /// **'VERİ VE DEPOLAMA'**
  String get veriVeDepolama;

  /// No description provided for @oncekiYedektenVeriKurtarin.
  ///
  /// In tr, this message translates to:
  /// **'Önceki yedekten veri kurtarın'**
  String get oncekiYedektenVeriKurtarin;

  /// No description provided for @tumVerileriniziKaliciOlarakSilin.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verilerinizi kalıcı olarak silin'**
  String get tumVerileriniziKaliciOlarakSilin;

  /// No description provided for @geciciDosyalariTemizleyin.
  ///
  /// In tr, this message translates to:
  /// **'Geçici dosyaları temizleyin'**
  String get geciciDosyalariTemizleyin;

  /// No description provided for @temelOzellikler.
  ///
  /// In tr, this message translates to:
  /// **'Temel özellikler'**
  String get temelOzellikler;

  /// No description provided for @sinirsizFotografDepolama.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız fotoğraf depolama'**
  String get sinirsizFotografDepolama;

  /// No description provided for @gelismisGuvenlik.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş güvenlik'**
  String get gelismisGuvenlik;

  /// No description provided for @yonet.
  ///
  /// In tr, this message translates to:
  /// **'Yönet'**
  String get yonet;

  /// No description provided for @iNasilKullanacaginiziOgrenin.
  ///
  /// In tr, this message translates to:
  /// **'ı nasıl kullanacağınızı öğrenin'**
  String get iNasilKullanacaginiziOgrenin;

  /// No description provided for @destekIleIletisim.
  ///
  /// In tr, this message translates to:
  /// **'Destek ile İletişim'**
  String get destekIleIletisim;

  /// No description provided for @sorulariniziVeOnerileriniziPaylasin.
  ///
  /// In tr, this message translates to:
  /// **'Sorularınızı ve önerilerinizi paylaşın'**
  String get sorulariniziVeOnerileriniziPaylasin;

  /// No description provided for @karsilastiginizSorunuRaporlayin.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştığınız sorunu raporlayın'**
  String get karsilastiginizSorunuRaporlayin;

  /// No description provided for @biziDegerlendirin.
  ///
  /// In tr, this message translates to:
  /// **'Bizi Değerlendirin'**
  String get biziDegerlendirin;

  /// No description provided for @verilerinizNasilKorunuyor.
  ///
  /// In tr, this message translates to:
  /// **'Verileriniz nasıl korunuyor'**
  String get verilerinizNasilKorunuyor;

  /// No description provided for @hizmetSartlariVeSorumluluklar.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet şartları ve sorumluluklar'**
  String get hizmetSartlariVeSorumluluklar;

  /// No description provided for @surum210FamilyhubInc.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm 2.1.0 · FamilyHub Inc.'**
  String get surum210FamilyhubInc;

  /// No description provided for @hizmetKapsami.
  ///
  /// In tr, this message translates to:
  /// **'1. Hizmet Kapsamı'**
  String get hizmetKapsami;

  /// No description provided for @kullanimKosullari1.
  ///
  /// In tr, this message translates to:
  /// **'2. Kullanım Koşulları'**
  String get kullanimKosullari1;

  /// No description provided for @hesapVeGuvenlik.
  ///
  /// In tr, this message translates to:
  /// **'3. Hesap ve Güvenlik'**
  String get hesapVeGuvenlik;

  /// No description provided for @degisiklikler.
  ///
  /// In tr, this message translates to:
  /// **'5. Değişiklikler'**
  String get degisiklikler;

  /// No description provided for @iKesfedin.
  ///
  /// In tr, this message translates to:
  /// **'ı Keşfedin'**
  String get iKesfedin;

  /// No description provided for @aileAktiviteleriHavaDurumuVeHizliErisimKartlari.
  ///
  /// In tr, this message translates to:
  /// **'Aile aktiviteleri, hava durumu ve hızlı erişim kartları.'**
  String get aileAktiviteleriHavaDurumuVeHizliErisimKartlari;

  /// No description provided for @sagUsttekiHavaDurumuChip.
  ///
  /// In tr, this message translates to:
  /// **'Sağ üstteki hava durumu chip\\'**
  String get sagUsttekiHavaDurumuChip;

  /// No description provided for @etkinlikOlusturma.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Oluşturma'**
  String get etkinlikOlusturma;

  /// No description provided for @takvimdeEtkinlikEkleyinHatirlaticilarAyarlayin.
  ///
  /// In tr, this message translates to:
  /// **'Takvimde etkinlik ekleyin, hatırlatıcılar ayarlayın.'**
  String get takvimdeEtkinlikEkleyinHatirlaticilarAyarlayin;

  /// No description provided for @altMenudenPlanSekmesineVeyaHub.
  ///
  /// In tr, this message translates to:
  /// **'Alt menüden \"Plan\" sekmesine veya Hub\\'**
  String get altMenudenPlanSekmesineVeyaHub;

  /// No description provided for @sagAlttakiButonunaBasarakYeniEtkinlikEkleyin.
  ///
  /// In tr, this message translates to:
  /// **'Sağ alttaki \"+\" butonuna basarak yeni etkinlik ekleyin.'**
  String get sagAlttakiButonunaBasarakYeniEtkinlikEkleyin;

  /// No description provided for @etkinlikBasligiTarihsaatKonumVeAciklamaGirin.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik başlığı, tarih/saat, konum ve açıklama girin.'**
  String get etkinlikBasligiTarihsaatKonumVeAciklamaGirin;

  /// No description provided for @hatirlaticiAyarlayin15Dk1Saat1GunOnceBildirimAlabilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı ayarlayın: 15 dk, 1 saat, 1 gün önce bildirim alabilirsiniz.'**
  String get hatirlaticiAyarlayin15Dk1Saat1GunOnceBildirimAlabilirsiniz;

  /// No description provided for @katilimcilariEkleyerekEtkinligiAileUyelerineAtayin.
  ///
  /// In tr, this message translates to:
  /// **'Katılımcıları ekleyerek etkinliği aile üyelerine atayın.'**
  String get katilimcilariEkleyerekEtkinligiAileUyelerineAtayin;

  /// No description provided for @gorevAtama.
  ///
  /// In tr, this message translates to:
  /// **'Görev Atama'**
  String get gorevAtama;

  /// No description provided for @aileUyelerineGorevAtayinVeIlerlemeyiTakipEdin.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyelerine görev atayın ve ilerlemeyi takip edin.'**
  String get aileUyelerineGorevAtayinVeIlerlemeyiTakipEdin;

  /// No description provided for @dakiGorevlerKartinaVeyaMerkezMenudenGorevler.
  ///
  /// In tr, this message translates to:
  /// **'daki \"Görevler\" kartına veya merkez menüden \"Görevler\"\\'**
  String get dakiGorevlerKartinaVeyaMerkezMenudenGorevler;

  /// No description provided for @yeniGorevOlusturmakIcinButonunaBasin.
  ///
  /// In tr, this message translates to:
  /// **'Yeni görev oluşturmak için \"+\" butonuna basın.'**
  String get yeniGorevOlusturmakIcinButonunaBasin;

  /// No description provided for @goreviBirAileUyesineAtayinAtananKisiyeBildirimGider.
  ///
  /// In tr, this message translates to:
  /// **'Görevi bir aile üyesine atayın. Atanan kişiye bildirim gider.'**
  String get goreviBirAileUyesineAtayinAtananKisiyeBildirimGider;

  /// No description provided for @gorevTamamlandigindaYanindakiKutucugaDokunarakIsaretleyin.
  ///
  /// In tr, this message translates to:
  /// **'Görev tamamlandığında yanındaki kutucuğa dokunarak işaretleyin.'**
  String get gorevTamamlandigindaYanindakiKutucugaDokunarakIsaretleyin;

  /// No description provided for @tamamlananGorevlerOtomatikOlarakTamamlandiBolumuneTasinir.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan görevler otomatik olarak \"Tamamlandı\" bölümüne taşınır.'**
  String get tamamlananGorevlerOtomatikOlarakTamamlandiBolumuneTasinir;

  /// No description provided for @streakSistemiSayesindeHerGunGorevTamamlayarakSeriOlusturabilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Streak sistemi sayesinde her gün görev tamamlayarak seri oluşturabilirsiniz.'**
  String
  get streakSistemiSayesindeHerGunGorevTamamlayarakSeriOlusturabilirsiniz;

  /// No description provided for @grupSohbetiDuyurularVeDuyguPaylasimi.
  ///
  /// In tr, this message translates to:
  /// **'Grup sohbeti, duyurular ve duygu paylaşımı.'**
  String get grupSohbetiDuyurularVeDuyguPaylasimi;

  /// No description provided for @altMenudenSohbetSekmesineDokunun.
  ///
  /// In tr, this message translates to:
  /// **'Alt menüden \"Sohbet\" sekmesine dokunun.'**
  String get altMenudenSohbetSekmesineDokunun;

  /// No description provided for @aileGrubundaMetinMesajlariFotograflarVeSesliMesajlarGonderebilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Aile grubunda metin mesajları, fotoğraflar ve sesli mesajlar gönderebilirsiniz.'**
  String
  get aileGrubundaMetinMesajlariFotograflarVeSesliMesajlarGonderebilirsiniz;

  /// No description provided for @duyuruOlusturmakIcinMesajKutusununYanindakiMegafonSimgesineDokunun.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru oluşturmak için mesaj kutusunun yanındaki megafon simgesine dokunun.'**
  String get duyuruOlusturmakIcinMesajKutusununYanindakiMegafonSimgesineDokunun;

  /// No description provided for @duyurularTumAileUyelerineYuksekOncelikliBildirimOlarakGider.
  ///
  /// In tr, this message translates to:
  /// **'Duyurular tüm aile üyelerine yüksek öncelikli bildirim olarak gider.'**
  String get duyurularTumAileUyelerineYuksekOncelikliBildirimOlarakGider;

  /// No description provided for @guvenlikOzellikleri.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Özellikleri'**
  String get guvenlikOzellikleri;

  /// No description provided for @sosButonuKonumPaylasimiVeAcilDurumKarti.
  ///
  /// In tr, this message translates to:
  /// **'SOS butonu, konum paylaşımı ve acil durum kartı.'**
  String get sosButonuKonumPaylasimiVeAcilDurumKarti;

  /// No description provided for @altMenudenGuvenlikSekmesineDokunun.
  ///
  /// In tr, this message translates to:
  /// **'Alt menüden \"Güvenlik\" sekmesine dokunun.'**
  String get altMenudenGuvenlikSekmesineDokunun;

  /// No description provided for @canliKonumPaylasimiAileUyelerinizinAnlikKonumunuHaritadaGorun.
  ///
  /// In tr, this message translates to:
  /// **'Canlı konum paylaşımı: Aile üyelerinizin anlık konumunu haritada görün.'**
  String get canliKonumPaylasimiAileUyelerinizinAnlikKonumunuHaritadaGorun;

  /// No description provided for @anilarVeAlbumler.
  ///
  /// In tr, this message translates to:
  /// **'Anılar ve Albümler'**
  String get anilarVeAlbumler;

  /// No description provided for @fotografYukleyinBuyumeTakibiYapin.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yükleyin, büyüme takibi yapın.'**
  String get fotografYukleyinBuyumeTakibiYapin;

  /// No description provided for @altMenudenAnilarSekmesineVeyaHubMenusundenAlbumler.
  ///
  /// In tr, this message translates to:
  /// **'Alt menüden \"Anılar\" sekmesine veya Hub menüsünden \"Albümler\"\\'**
  String get altMenudenAnilarSekmesineVeyaHubMenusundenAlbumler;

  /// No description provided for @fotografaDokunarakBuyutunKaydedinVeyaPaylasin.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafa dokunarak büyütün, kaydedin veya paylaşın.'**
  String get fotografaDokunarakBuyutunKaydedinVeyaPaylasin;

  /// No description provided for @premiumUyelerSinirsizFotografDepolamaVe4kVideoYuklemeYapabilir.
  ///
  /// In tr, this message translates to:
  /// **'Premium üyeler sınırsız fotoğraf depolama ve 4K video yükleme yapabilir.'**
  String get premiumUyelerSinirsizFotografDepolamaVe4kVideoYuklemeYapabilir;

  /// No description provided for @konumIzniVerilmediSehirSecimiVeyaHaritadanKonumSecimiKullanilabilir.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi. Şehir seçimi veya haritadan konum seçimi kullanılabilir.'**
  String
  get konumIzniVerilmediSehirSecimiVeyaHaritadanKonumSecimiKullanilabilir;

  /// No description provided for @konumIzniGerekli.
  ///
  /// In tr, this message translates to:
  /// **'Konum İzni Gerekli'**
  String get konumIzniGerekli;

  /// No description provided for @havaDurumuAyarlariKaydedildi.
  ///
  /// In tr, this message translates to:
  /// **'Hava durumu ayarları kaydedildi'**
  String get havaDurumuAyarlariKaydedildi;

  /// No description provided for @haritadanKonumSec.
  ///
  /// In tr, this message translates to:
  /// **'Haritadan Konum Seç'**
  String get haritadanKonumSec;

  /// No description provided for @openstreetmapHaritasindanIstediginizNoktayiSecin.
  ///
  /// In tr, this message translates to:
  /// **'OpenStreetMap haritasından istediğiniz noktayı seçin'**
  String get openstreetmapHaritasindanIstediginizNoktayiSecin;

  /// No description provided for @haritayiAc.
  ///
  /// In tr, this message translates to:
  /// **'Haritayı Aç'**
  String get haritayiAc;

  /// No description provided for @konumSecilmezseSehirListesindenKullanilir.
  ///
  /// In tr, this message translates to:
  /// **'Konum seçilmezse şehir listesinden kullanılır'**
  String get konumSecilmezseSehirListesindenKullanilir;

  /// No description provided for @havaDurumuAlinamadi.
  ///
  /// In tr, this message translates to:
  /// **'Hava durumu alınamadı'**
  String get havaDurumuAlinamadi;

  /// No description provided for @gunlukTahmin.
  ///
  /// In tr, this message translates to:
  /// **'7 Günlük Tahmin'**
  String get gunlukTahmin;

  /// No description provided for @ruzgar.
  ///
  /// In tr, this message translates to:
  /// **'Rüzgar'**
  String get ruzgar;

  /// No description provided for @basinc.
  ///
  /// In tr, this message translates to:
  /// **'Basınç'**
  String get basinc;

  /// No description provided for @enIyi.
  ///
  /// In tr, this message translates to:
  /// **'En İyi'**
  String get enIyi;

  /// No description provided for @tumGirisler.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Girişler'**
  String get tumGirisler;

  /// No description provided for @devamEtmekIcinKullanimKosullariniKabulEtmelisiniz.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için kullanım koşullarını kabul etmelisiniz'**
  String get devamEtmekIcinKullanimKosullariniKabulEtmelisiniz;

  /// No description provided for @lutfenAileKodunuGirin.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen aile kodunu girin'**
  String get lutfenAileKodunuGirin;

  /// No description provided for @lutfenAileAdiniGirin.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen aile adını girin'**
  String get lutfenAileAdiniGirin;

  /// No description provided for @familyhubHesabiniziOlusturun.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub hesabınızı oluşturun'**
  String get familyhubHesabiniziOlusturun;

  /// No description provided for @aileyeKatil.
  ///
  /// In tr, this message translates to:
  /// **'Aileye Katıl'**
  String get aileyeKatil;

  /// No description provided for @ornFh123456.
  ///
  /// In tr, this message translates to:
  /// **'Örn: FH-123456'**
  String get ornFh123456;

  /// No description provided for @aileAdi.
  ///
  /// In tr, this message translates to:
  /// **'Aile Adı'**
  String get aileAdi;

  /// No description provided for @ornYilmazAilesi.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Yılmaz Ailesi'**
  String get ornYilmazAilesi;

  /// No description provided for @kullanimKosullariniVeGizlilikPolitikasiniOkudumVeKabulEdiyorum.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım koşullarını ve gizlilik politikasını okudum ve kabul ediyorum.'**
  String get kullanimKosullariniVeGizlilikPolitikasiniOkudumVeKabulEdiyorum;

  /// No description provided for @hesapOlustur.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get hesapOlustur;

  /// No description provided for @isimGirin.
  ///
  /// In tr, this message translates to:
  /// **'İsim girin'**
  String get isimGirin;

  /// No description provided for @pinEnAz4HaneOlmali.
  ///
  /// In tr, this message translates to:
  /// **'PIN en az 4 hane olmalı'**
  String get pinEnAz4HaneOlmali;

  /// No description provided for @pinlerEslesmiyor.
  ///
  /// In tr, this message translates to:
  /// **'PINler eşleşmiyor'**
  String get pinlerEslesmiyor;

  /// No description provided for @acilDurumdaAranacakKisi.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durumda Aranacak Kişi'**
  String get acilDurumdaAranacakKisi;

  /// No description provided for @ornEsAnneBaba.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Eş, Anne, Baba'**
  String get ornEsAnneBaba;

  /// No description provided for @aileRolu.
  ///
  /// In tr, this message translates to:
  /// **'Aile Rolü'**
  String get aileRolu;

  /// No description provided for @ailedekiRolunuzuVeGorunumunuzuSecin.
  ///
  /// In tr, this message translates to:
  /// **'Ailedeki rolünüzü ve görünümünüzü seçin'**
  String get ailedekiRolunuzuVeGorunumunuzuSecin;

  /// No description provided for @rolunuz.
  ///
  /// In tr, this message translates to:
  /// **'Rolünüz'**
  String get rolunuz;

  /// No description provided for @ailedeGorunenAdiniz.
  ///
  /// In tr, this message translates to:
  /// **'Ailede Görünen Adınız'**
  String get ailedeGorunenAdiniz;

  /// No description provided for @ornAnneBabaMehmet.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Anne, Baba, Mehmet'**
  String get ornAnneBabaMehmet;

  /// No description provided for @renkSecimi.
  ///
  /// In tr, this message translates to:
  /// **'Renk Seçimi'**
  String get renkSecimi;

  /// No description provided for @telefonnumarasi1.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get telefonnumarasi1;

  /// No description provided for @dogumTarihi.
  ///
  /// In tr, this message translates to:
  /// **'Doğum Tarihi'**
  String get dogumTarihi;

  /// No description provided for @secilmedi.
  ///
  /// In tr, this message translates to:
  /// **'Seçilmedi'**
  String get secilmedi;

  /// No description provided for @bolgeEkle.
  ///
  /// In tr, this message translates to:
  /// **'Bölge Ekle'**
  String get bolgeEkle;

  /// No description provided for @guvenliBolgeEkle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli Bölge Ekle'**
  String get guvenliBolgeEkle;

  /// No description provided for @bolgeAdi.
  ///
  /// In tr, this message translates to:
  /// **'Bölge Adı'**
  String get bolgeAdi;

  /// No description provided for @bolgeTipi.
  ///
  /// In tr, this message translates to:
  /// **'Bölge Tipi'**
  String get bolgeTipi;

  /// No description provided for @aileSohbetineIlkMesajiSenGonder.
  ///
  /// In tr, this message translates to:
  /// **'Aile sohbetine ilk mesajı sen gönder! 💬'**
  String get aileSohbetineIlkMesajiSenGonder;

  /// No description provided for @mesajlarinBuradaGorunecek.
  ///
  /// In tr, this message translates to:
  /// **'Mesajların burada görünecek.'**
  String get mesajlarinBuradaGorunecek;

  /// No description provided for @gunaydin.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get gunaydin;

  /// No description provided for @iyiGunler.
  ///
  /// In tr, this message translates to:
  /// **'İyi günler'**
  String get iyiGunler;

  /// No description provided for @iyiAksamlar.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get iyiAksamlar;

  /// No description provided for @bugunNelerYapacaginaBirBakalim.
  ///
  /// In tr, this message translates to:
  /// **'Bugün neler yapacağına bir bakalım.'**
  String get bugunNelerYapacaginaBirBakalim;

  /// No description provided for @gunlukGorevler.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Görevler'**
  String get gunlukGorevler;

  /// No description provided for @bugunGorevinYok.
  ///
  /// In tr, this message translates to:
  /// **'Bugün görevin yok! 🌟'**
  String get bugunGorevinYok;

  /// No description provided for @hadiBaslayalim.
  ///
  /// In tr, this message translates to:
  /// **'Hadi başlayalım!'**
  String get hadiBaslayalim;

  /// No description provided for @bekleyenGorev.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Görev'**
  String get bekleyenGorev;

  /// No description provided for @bekleyenOdev.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Ödev'**
  String get bekleyenOdev;

  /// No description provided for @gunStreak.
  ///
  /// In tr, this message translates to:
  /// **'Gün Streak'**
  String get gunStreak;

  /// No description provided for @bugunkuDerslerim.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü Derslerim'**
  String get bugunkuDerslerim;

  /// No description provided for @bugunDersYokKeyfiniCikar.
  ///
  /// In tr, this message translates to:
  /// **'Bugün ders yok! Keyfini çıkar.'**
  String get bugunDersYokKeyfiniCikar;

  /// No description provided for @yaklasanOdevler.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan Ödevler'**
  String get yaklasanOdevler;

  /// No description provided for @henuzAiOnerisiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz AI önerisi yok'**
  String get henuzAiOnerisiYok;

  /// No description provided for @dahaFazlaAktiviteKaydiOlusuncaOnerilerGelecek.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla aktivite kaydı oluşunca öneriler gelecek.'**
  String get dahaFazlaAktiviteKaydiOlusuncaOnerilerGelecek;

  /// No description provided for @hizliErisim.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Erişim'**
  String get hizliErisim;

  /// No description provided for @cocukAcilDurumButonunaBasti.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk acil durum butonuna bastı!'**
  String get cocukAcilDurumButonunaBasti;

  /// No description provided for @konumunAilenePaylasildi.
  ///
  /// In tr, this message translates to:
  /// **'📍 Konumun ailene paylaşıldı'**
  String get konumunAilenePaylasildi;

  /// No description provided for @konumPaylasilamadi.
  ///
  /// In tr, this message translates to:
  /// **'Konum paylaşılamadı'**
  String get konumPaylasilamadi;

  /// No description provided for @butona3SaniyeBasiliTut.
  ///
  /// In tr, this message translates to:
  /// **'Butona 3 saniye basılı tut'**
  String get butona3SaniyeBasiliTut;

  /// No description provided for @basiliTut.
  ///
  /// In tr, this message translates to:
  /// **'Basılı Tut'**
  String get basiliTut;

  /// No description provided for @sonKonumPaylasildi.
  ///
  /// In tr, this message translates to:
  /// **'Son konum paylaşıldı'**
  String get sonKonumPaylasildi;

  /// No description provided for @canliKonumunAileneGonder.
  ///
  /// In tr, this message translates to:
  /// **'Canlı konumun ailene gönder'**
  String get canliKonumunAileneGonder;

  /// No description provided for @aileVarisPlanlariniGor.
  ///
  /// In tr, this message translates to:
  /// **'Aile varış planlarını gör'**
  String get aileVarisPlanlariniGor;

  /// No description provided for @aktifUyarilar.
  ///
  /// In tr, this message translates to:
  /// **'AKTİF UYARILAR'**
  String get aktifUyarilar;

  /// No description provided for @aktif.
  ///
  /// In tr, this message translates to:
  /// **'AKTİF'**
  String get aktif;

  /// No description provided for @saglikKartiYakindaGeliyor.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık kartı yakında geliyor'**
  String get saglikKartiYakindaGeliyor;

  /// No description provided for @alerjiVeSaglikBilgilerin.
  ///
  /// In tr, this message translates to:
  /// **'Alerji ve sağlık bilgilerin'**
  String get alerjiVeSaglikBilgilerin;

  /// No description provided for @dersProgrami.
  ///
  /// In tr, this message translates to:
  /// **'Ders Programı'**
  String get dersProgrami;

  /// No description provided for @bugunDersYok.
  ///
  /// In tr, this message translates to:
  /// **'Bugün ders yok 😊'**
  String get bugunDersYok;

  /// No description provided for @odevlerim.
  ///
  /// In tr, this message translates to:
  /// **'Ödevlerim'**
  String get odevlerim;

  /// No description provided for @gorevTamamlandi.
  ///
  /// In tr, this message translates to:
  /// **'🎉 Görev tamamlandı!'**
  String get gorevTamamlandi;

  /// No description provided for @henuzGorevinYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz görevin yok! 🌟'**
  String get henuzGorevinYok;

  /// No description provided for @gorevlerinEklendigindeBuradaGorunecek.
  ///
  /// In tr, this message translates to:
  /// **'Görevlerin eklendiğinde burada görünecek.'**
  String get gorevlerinEklendigindeBuradaGorunecek;

  /// No description provided for @planBasic.
  ///
  /// In tr, this message translates to:
  /// **'Temel'**
  String get planBasic;

  /// No description provided for @planPlus.
  ///
  /// In tr, this message translates to:
  /// **'Plus'**
  String get planPlus;

  /// No description provided for @planComplete.
  ///
  /// In tr, this message translates to:
  /// **'Complete'**
  String get planComplete;

  /// No description provided for @planBasicTagline.
  ///
  /// In tr, this message translates to:
  /// **'Aileni yönetmeye başla'**
  String get planBasicTagline;

  /// No description provided for @planPlusTagline.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı özellikler + daha fazla alan'**
  String get planPlusTagline;

  /// No description provided for @planCompleteTagline.
  ///
  /// In tr, this message translates to:
  /// **'Tam otomasyon ve sınırsız'**
  String get planCompleteTagline;

  /// No description provided for @planFeatCore.
  ///
  /// In tr, this message translates to:
  /// **'Takvim, görevler, alışveriş, bütçe'**
  String get planFeatCore;

  /// No description provided for @planFeatPlusIntel.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş Aile Zekası'**
  String get planFeatPlusIntel;

  /// No description provided for @planFeatLegal.
  ///
  /// In tr, this message translates to:
  /// **'Yasal Haklar & yardımlar'**
  String get planFeatLegal;

  /// No description provided for @planFeatExport.
  ///
  /// In tr, this message translates to:
  /// **'PDF/CSV dışa aktarma'**
  String get planFeatExport;

  /// No description provided for @planFeatProactive.
  ///
  /// In tr, this message translates to:
  /// **'Proaktif zeka & otomasyon'**
  String get planFeatProactive;

  /// No description provided for @planFeatRoutines.
  ///
  /// In tr, this message translates to:
  /// **'Aile rutinleri'**
  String get planFeatRoutines;

  /// No description provided for @planFeatGuest.
  ///
  /// In tr, this message translates to:
  /// **'Misafir erişimi & roller'**
  String get planFeatGuest;

  /// No description provided for @planFeatUnlimitedHistory.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız geçmiş'**
  String get planFeatUnlimitedHistory;

  /// No description provided for @planFeatStorage.
  ///
  /// In tr, this message translates to:
  /// **'{size} depolama'**
  String planFeatStorage(Object size);

  /// No description provided for @planFeatHistory.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün geçmiş'**
  String planFeatHistory(Object days);

  /// No description provided for @plansTitle.
  ///
  /// In tr, this message translates to:
  /// **'Planlar'**
  String get plansTitle;

  /// No description provided for @plansMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get plansMonthly;

  /// No description provided for @plansYearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get plansYearly;

  /// No description provided for @plansFree.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get plansFree;

  /// No description provided for @plansPopular.
  ///
  /// In tr, this message translates to:
  /// **'POPÜLER'**
  String get plansPopular;

  /// No description provided for @plansCurrent.
  ///
  /// In tr, this message translates to:
  /// **'MEVCUT'**
  String get plansCurrent;

  /// No description provided for @plansComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma yakında etkinleşecek.'**
  String get plansComingSoon;

  /// No description provided for @plansSave.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} tasarruf'**
  String plansSave(Object percent);

  /// No description provided for @plansChoose.
  ///
  /// In tr, this message translates to:
  /// **'{plan} seç'**
  String plansChoose(Object plan);

  /// No description provided for @gateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu özellik kilitli'**
  String get gateTitle;

  /// No description provided for @gateBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu özellik {plan} planında açılır.'**
  String gateBody(Object plan);

  /// No description provided for @gatePerMonth.
  ///
  /// In tr, this message translates to:
  /// **'/ay'**
  String get gatePerMonth;

  /// No description provided for @gatePerYear.
  ///
  /// In tr, this message translates to:
  /// **'/yıl'**
  String get gatePerYear;

  /// No description provided for @gateSeePlans.
  ///
  /// In tr, this message translates to:
  /// **'Planları gör'**
  String get gateSeePlans;

  /// No description provided for @gateNotNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get gateNotNow;

  /// No description provided for @exportCsvTooltip.
  ///
  /// In tr, this message translates to:
  /// **'CSV olarak dışa aktar'**
  String get exportCsvTooltip;

  /// No description provided for @exportShopping.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub alışveriş listesi'**
  String get exportShopping;

  /// No description provided for @exportEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarılacak öğe yok.'**
  String get exportEmpty;

  /// No description provided for @exportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarma başarısız.'**
  String get exportFailed;

  /// No description provided for @exportColName.
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get exportColName;

  /// No description provided for @exportColQty.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get exportColQty;

  /// No description provided for @exportColUnit.
  ///
  /// In tr, this message translates to:
  /// **'Birim'**
  String get exportColUnit;

  /// No description provided for @exportColCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get exportColCategory;

  /// No description provided for @exportColDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get exportColDone;

  /// No description provided for @pinSection.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama PIN\'i'**
  String get pinSection;

  /// No description provided for @pinSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik başarısız olursa PIN ile giriş'**
  String get pinSubtitle;

  /// No description provided for @pinSet.
  ///
  /// In tr, this message translates to:
  /// **'PIN belirle'**
  String get pinSet;

  /// No description provided for @pinChange.
  ///
  /// In tr, this message translates to:
  /// **'PIN\'i değiştir'**
  String get pinChange;

  /// No description provided for @pinRemove.
  ///
  /// In tr, this message translates to:
  /// **'PIN\'i kaldır'**
  String get pinRemove;

  /// No description provided for @pinRemoveConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama PIN\'i kaldırılsın mı?'**
  String get pinRemoveConfirm;

  /// No description provided for @pinRemoved.
  ///
  /// In tr, this message translates to:
  /// **'PIN kaldırıldı'**
  String get pinRemoved;

  /// No description provided for @pinLabel.
  ///
  /// In tr, this message translates to:
  /// **'PIN (4-6 hane)'**
  String get pinLabel;

  /// No description provided for @pinConfirmLabel.
  ///
  /// In tr, this message translates to:
  /// **'PIN (tekrar)'**
  String get pinConfirmLabel;

  /// No description provided for @pinTooShort.
  ///
  /// In tr, this message translates to:
  /// **'PIN en az 4 hane olmalı'**
  String get pinTooShort;

  /// No description provided for @pinMismatch.
  ///
  /// In tr, this message translates to:
  /// **'PIN\'ler eşleşmiyor'**
  String get pinMismatch;

  /// No description provided for @pinSaved.
  ///
  /// In tr, this message translates to:
  /// **'PIN kaydedildi'**
  String get pinSaved;

  /// No description provided for @setAccount.
  ///
  /// In tr, this message translates to:
  /// **'HESAP'**
  String get setAccount;

  /// No description provided for @setProfileInfo.
  ///
  /// In tr, this message translates to:
  /// **'Profil Bilgileri'**
  String get setProfileInfo;

  /// No description provided for @setPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get setPrivacy;

  /// No description provided for @setSecure.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli'**
  String get setSecure;

  /// No description provided for @setWeatherSection.
  ///
  /// In tr, this message translates to:
  /// **'HAVA DURUMU'**
  String get setWeatherSection;

  /// No description provided for @setBackupRestore.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme ve Geri Yükleme'**
  String get setBackupRestore;

  /// No description provided for @setBackupRestoreDesc.
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizi buluta yedekleyin veya kurtarın'**
  String get setBackupRestoreDesc;

  /// No description provided for @setDeleteData.
  ///
  /// In tr, this message translates to:
  /// **'Verileri Sil'**
  String get setDeleteData;

  /// No description provided for @setPremiumSection.
  ///
  /// In tr, this message translates to:
  /// **'PREMIUM'**
  String get setPremiumSection;

  /// No description provided for @setPremiumTier.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get setPremiumTier;

  /// No description provided for @setFreeTier.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get setFreeTier;

  /// No description provided for @setActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get setActive;

  /// No description provided for @setFeatUnlimitedPhotos.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız fotoğraf depolama'**
  String get setFeatUnlimitedPhotos;

  /// No description provided for @setFeat8Members.
  ///
  /// In tr, this message translates to:
  /// **'8 aile üyesi'**
  String get setFeat8Members;

  /// No description provided for @setFeatAI.
  ///
  /// In tr, this message translates to:
  /// **'AI asistan'**
  String get setFeatAI;

  /// No description provided for @setFeatAdvSecurity.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş güvenlik'**
  String get setFeatAdvSecurity;

  /// No description provided for @setFeatBasic.
  ///
  /// In tr, this message translates to:
  /// **'Temel özellikler'**
  String get setFeatBasic;

  /// No description provided for @setFeat4Members.
  ///
  /// In tr, this message translates to:
  /// **'4 aile üyesi'**
  String get setFeat4Members;

  /// No description provided for @setFeat1GB.
  ///
  /// In tr, this message translates to:
  /// **'1 GB depolama'**
  String get setFeat1GB;

  /// No description provided for @setHelpSection.
  ///
  /// In tr, this message translates to:
  /// **'YARDIM'**
  String get setHelpSection;

  /// No description provided for @setUserGuideDesc.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub\'ı nasıl kullanacağınızı öğrenin'**
  String get setUserGuideDesc;

  /// No description provided for @setLegalSection.
  ///
  /// In tr, this message translates to:
  /// **'YASAL'**
  String get setLegalSection;

  /// No description provided for @setCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Güncel'**
  String get setCurrent;

  /// No description provided for @setAccentColor.
  ///
  /// In tr, this message translates to:
  /// **'Aksan Rengi'**
  String get setAccentColor;

  /// No description provided for @setFontSizeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Metin boyutunu ayarla'**
  String get setFontSizeDesc;

  /// No description provided for @setCustomizeHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Ekranı Özelleştir'**
  String get setCustomizeHome;

  /// No description provided for @setCustomizeHomeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı kart, ipuçları ve kutucuk sırası'**
  String get setCustomizeHomeDesc;

  /// No description provided for @cdSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Büyüme takibi · Dersler · Ödevler'**
  String get cdSubtitle;

  /// No description provided for @cdAddProfile.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk profili ekleyin'**
  String get cdAddProfile;

  /// No description provided for @cdChildName.
  ///
  /// In tr, this message translates to:
  /// **'Çocuğun adı'**
  String get cdChildName;

  /// No description provided for @cdSchoolName.
  ///
  /// In tr, this message translates to:
  /// **'Okul adı (isteğe bağlı)'**
  String get cdSchoolName;

  /// No description provided for @cdCreateProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil Oluştur'**
  String get cdCreateProfile;

  /// No description provided for @cdPickOrWriteLesson.
  ///
  /// In tr, this message translates to:
  /// **'Ders seç veya kendin yaz:'**
  String get cdPickOrWriteLesson;

  /// No description provided for @cdLessonName.
  ///
  /// In tr, this message translates to:
  /// **'Ders adı'**
  String get cdLessonName;

  /// No description provided for @cdAddLesson.
  ///
  /// In tr, this message translates to:
  /// **'Ders Ekle'**
  String get cdAddLesson;

  /// No description provided for @cdHomeworkDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ödev açıklaması'**
  String get cdHomeworkDesc;

  /// No description provided for @cdSaveHomework.
  ///
  /// In tr, this message translates to:
  /// **'Ödevi Kaydet'**
  String get cdSaveHomework;

  /// No description provided for @cdHeightCm.
  ///
  /// In tr, this message translates to:
  /// **'Boy (cm)'**
  String get cdHeightCm;

  /// No description provided for @cdWeightKg.
  ///
  /// In tr, this message translates to:
  /// **'Kilo (kg)'**
  String get cdWeightKg;

  /// No description provided for @cdDevGroup.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim grubu: {group}'**
  String cdDevGroup(Object group);

  /// No description provided for @cdCompleted.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get cdCompleted;

  /// No description provided for @cdStepGrowsTree.
  ///
  /// In tr, this message translates to:
  /// **'Her tamamlanan basamak ağacı büyütür'**
  String get cdStepGrowsTree;

  /// No description provided for @cdWeeklyPlanFor.
  ///
  /// In tr, this message translates to:
  /// **'AI ile {name}\'e Özel Haftalık Plan'**
  String cdWeeklyPlanFor(Object name);

  /// No description provided for @cdNoLessons.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ders eklenmedi\n+ ile ekleyin'**
  String get cdNoLessons;

  /// No description provided for @cdNoGrade.
  ///
  /// In tr, this message translates to:
  /// **'Not girilmedi'**
  String get cdNoGrade;

  /// No description provided for @cdAvg.
  ///
  /// In tr, this message translates to:
  /// **'ort.'**
  String get cdAvg;

  /// No description provided for @cdGradeRange.
  ///
  /// In tr, this message translates to:
  /// **'Not (0-100)'**
  String get cdGradeRange;

  /// No description provided for @cdNoHomework.
  ///
  /// In tr, this message translates to:
  /// **'Ödev yok — harika! 🎉'**
  String get cdNoHomework;

  /// No description provided for @cdNoMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ölçüm girilmedi\n+ ile ekleyin'**
  String get cdNoMeasurements;

  /// No description provided for @cdHeight.
  ///
  /// In tr, this message translates to:
  /// **'Boy'**
  String get cdHeight;

  /// No description provided for @cdWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get cdWeight;

  /// No description provided for @cdRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden üret'**
  String get cdRegenerate;

  /// No description provided for @cdGeneratingPlan.
  ///
  /// In tr, this message translates to:
  /// **'Gemini kişisel plan hazırlıyor...'**
  String get cdGeneratingPlan;

  /// No description provided for @cdPlanFailed.
  ///
  /// In tr, this message translates to:
  /// **'Plan üretilemedi (bağlantı/kota).'**
  String get cdPlanFailed;

  /// No description provided for @cdRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get cdRetry;

  /// No description provided for @cdParentChecklist.
  ///
  /// In tr, this message translates to:
  /// **'Ebeveyn Kontrol Listesi'**
  String get cdParentChecklist;

  /// No description provided for @fhFamilyDoctor.
  ///
  /// In tr, this message translates to:
  /// **'Aile Hekimi'**
  String get fhFamilyDoctor;

  /// No description provided for @fhSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık takibi & ilaç yönetimi'**
  String get fhSubtitle;

  /// No description provided for @fhAddMember.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyesi ekleyin'**
  String get fhAddMember;

  /// No description provided for @fhNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Ad (örn. Anne, Ahmet)'**
  String get fhNameHint;

  /// No description provided for @fhAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get fhAdd;

  /// No description provided for @fhMedName.
  ///
  /// In tr, this message translates to:
  /// **'İlaç adı'**
  String get fhMedName;

  /// No description provided for @fhDoseHint.
  ///
  /// In tr, this message translates to:
  /// **'Doz (örn. 500mg, 1 tablet)'**
  String get fhDoseHint;

  /// No description provided for @fhUsageHint.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım (örn. Günde 2 kez, sabah)'**
  String get fhUsageHint;

  /// No description provided for @fhNotesOptional.
  ///
  /// In tr, this message translates to:
  /// **'Notlar (isteğe bağlı)'**
  String get fhNotesOptional;

  /// No description provided for @fhSaveMed.
  ///
  /// In tr, this message translates to:
  /// **'İlacı Kaydet'**
  String get fhSaveMed;

  /// No description provided for @fhVitaminName.
  ///
  /// In tr, this message translates to:
  /// **'Vitamin adı (örn. D3, Omega-3)'**
  String get fhVitaminName;

  /// No description provided for @fhAmountHint.
  ///
  /// In tr, this message translates to:
  /// **'Miktar (örn. 1000 IU, 2 kapsül)'**
  String get fhAmountHint;

  /// No description provided for @fhUsageTime.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım zamanı'**
  String get fhUsageTime;

  /// No description provided for @fhSaveVitamin.
  ///
  /// In tr, this message translates to:
  /// **'Vitamin Kaydet'**
  String get fhSaveVitamin;

  /// No description provided for @fhReportTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Başlık (örn. Yıllık check-up)'**
  String get fhReportTitleHint;

  /// No description provided for @fhDoctorClinic.
  ///
  /// In tr, this message translates to:
  /// **'Doktor / Klinik adı'**
  String get fhDoctorClinic;

  /// No description provided for @fhReportType.
  ///
  /// In tr, this message translates to:
  /// **'Rapor türü'**
  String get fhReportType;

  /// No description provided for @fhNotesFindings.
  ///
  /// In tr, this message translates to:
  /// **'Notlar / Bulgular'**
  String get fhNotesFindings;

  /// No description provided for @fhSaveReport.
  ///
  /// In tr, this message translates to:
  /// **'Raporu Kaydet'**
  String get fhSaveReport;

  /// No description provided for @fhDoctorName.
  ///
  /// In tr, this message translates to:
  /// **'Doktor adı'**
  String get fhDoctorName;

  /// No description provided for @fhSpecialtyHint.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanlık (Kardiyoloji, Göz vb.)'**
  String get fhSpecialtyHint;

  /// No description provided for @fhHospitalClinic.
  ///
  /// In tr, this message translates to:
  /// **'Hastane / Klinik'**
  String get fhHospitalClinic;

  /// No description provided for @fhSaveAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Kaydet'**
  String get fhSaveAppointment;

  /// No description provided for @fhStartDate.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç: {date}'**
  String fhStartDate(Object date);

  /// No description provided for @fhComplete.
  ///
  /// In tr, this message translates to:
  /// **'Tamamla'**
  String get fhComplete;

  /// No description provided for @eduTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Eğitimi'**
  String get eduTitle;

  /// No description provided for @eduSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite ara...'**
  String get eduSearchHint;

  /// No description provided for @eduNoActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite bulunamadı'**
  String get eduNoActivity;

  /// No description provided for @eduFilterByAge.
  ///
  /// In tr, this message translates to:
  /// **'Yaşa Göre Filtrele'**
  String get eduFilterByAge;

  /// No description provided for @eduPracticalTips.
  ///
  /// In tr, this message translates to:
  /// **'Pratik İpuçları'**
  String get eduPracticalTips;

  /// No description provided for @eduYoutubeSearch.
  ///
  /// In tr, this message translates to:
  /// **'YouTube video araması'**
  String get eduYoutubeSearch;

  /// No description provided for @eduWatchYoutube.
  ///
  /// In tr, this message translates to:
  /// **'YouTube\'da video rehberleri izle'**
  String get eduWatchYoutube;

  /// No description provided for @eduRelatedActivities.
  ///
  /// In tr, this message translates to:
  /// **'İlgili Aktiviteler'**
  String get eduRelatedActivities;

  /// No description provided for @eduLearningTree.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenme Ağacın'**
  String get eduLearningTree;

  /// No description provided for @eduTreeGrows.
  ///
  /// In tr, this message translates to:
  /// **'Her tamamlanan aktivite ağacını büyütür'**
  String get eduTreeGrows;

  /// No description provided for @eduOverallProgress.
  ///
  /// In tr, this message translates to:
  /// **'Genel İlerleme'**
  String get eduOverallProgress;

  /// No description provided for @eduStopwatch.
  ///
  /// In tr, this message translates to:
  /// **'Kronometre'**
  String get eduStopwatch;

  /// No description provided for @eduEnterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir başlık girin'**
  String get eduEnterTitle;

  /// No description provided for @eduAddActivity.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Aktivite Ekle'**
  String get eduAddActivity;

  /// No description provided for @eduCreateOwn.
  ///
  /// In tr, this message translates to:
  /// **'Kendi eğitim içeriğinizi oluşturun'**
  String get eduCreateOwn;

  /// No description provided for @eduCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get eduCategory;

  /// No description provided for @eduAgeRange.
  ///
  /// In tr, this message translates to:
  /// **'Yaş aralığı'**
  String get eduAgeRange;

  /// No description provided for @eduDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get eduDuration;

  /// No description provided for @eduMaterials.
  ///
  /// In tr, this message translates to:
  /// **'Gerekenler (her satıra bir malzeme)'**
  String get eduMaterials;

  /// No description provided for @eduHowTo.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl Yapılır? (her satıra bir adım)'**
  String get eduHowTo;

  /// No description provided for @eduEnterTopic.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir konu yazın'**
  String get eduEnterTopic;

  /// No description provided for @eduGenerateAI.
  ///
  /// In tr, this message translates to:
  /// **'AI Ders / Görev Üret'**
  String get eduGenerateAI;

  /// No description provided for @eduTopicHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: saat okuma, geri dönüşüm, çarpım tablosu'**
  String get eduTopicHint;

  /// No description provided for @eduAge.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get eduAge;

  /// No description provided for @eduGenFailed.
  ///
  /// In tr, this message translates to:
  /// **'İçerik üretilemedi (bağlantı/kota). Tekrar deneyin.'**
  String get eduGenFailed;

  /// No description provided for @eduSteps.
  ///
  /// In tr, this message translates to:
  /// **'Adımlar'**
  String get eduSteps;

  /// No description provided for @eduParentTip.
  ///
  /// In tr, this message translates to:
  /// **'Ebeveyn ipucu: {tip}'**
  String eduParentTip(Object tip);

  /// No description provided for @kitRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Tarif'**
  String get kitRecipe;

  /// No description provided for @kitNoRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Tarif bulunamadı'**
  String get kitNoRecipe;

  /// No description provided for @kitCreateWeeklyPlan.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık Plan Oluştur'**
  String get kitCreateWeeklyPlan;

  /// No description provided for @kitAIFillWeek.
  ///
  /// In tr, this message translates to:
  /// **'AI tüm haftayı otomatik doldursun'**
  String get kitAIFillWeek;

  /// No description provided for @kitFill.
  ///
  /// In tr, this message translates to:
  /// **'Doldur'**
  String get kitFill;

  /// No description provided for @kitTapToChange.
  ///
  /// In tr, this message translates to:
  /// **'Değiştirmek için dokun'**
  String get kitTapToChange;

  /// No description provided for @kitPickMeal.
  ///
  /// In tr, this message translates to:
  /// **'Yemek seç...'**
  String get kitPickMeal;

  /// No description provided for @kitNewFoodIdea.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Yemek Fikri'**
  String get kitNewFoodIdea;

  /// No description provided for @kitAddOwnRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Kendi Tarifini Ekle'**
  String get kitAddOwnRecipe;

  /// No description provided for @kitAddWebRecipe.
  ///
  /// In tr, this message translates to:
  /// **'Web Tarifi Ekle'**
  String get kitAddWebRecipe;

  /// No description provided for @kitWebRecipeSub.
  ///
  /// In tr, this message translates to:
  /// **'Web\'de bulduğun güzel bir tarifin linkini yapıştır.'**
  String get kitWebRecipeSub;

  /// No description provided for @kitEnterNameForAI.
  ///
  /// In tr, this message translates to:
  /// **'Önce tarif adını yazın, AI gerisini doldursun'**
  String get kitEnterNameForAI;

  /// No description provided for @kitAINoResponse.
  ///
  /// In tr, this message translates to:
  /// **'AI şu an yanıt veremedi, elle doldurabilirsin'**
  String get kitAINoResponse;

  /// No description provided for @kitEnterRecipeName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir tarif adı girin'**
  String get kitEnterRecipeName;

  /// No description provided for @kitPasteLink.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tarif linkini yapıştırın'**
  String get kitPasteLink;

  /// No description provided for @kitCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get kitCategory;

  /// No description provided for @kitWeeklyAISuggestions.
  ///
  /// In tr, this message translates to:
  /// **'Bu Haftanın AI Önerileri'**
  String get kitWeeklyAISuggestions;

  /// No description provided for @kitIngredients.
  ///
  /// In tr, this message translates to:
  /// **'Malzemeler'**
  String get kitIngredients;

  /// No description provided for @kitPreparation.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanışı'**
  String get kitPreparation;

  /// No description provided for @chatGettingLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor…'**
  String get chatGettingLocation;

  /// No description provided for @chatCreatePoll.
  ///
  /// In tr, this message translates to:
  /// **'Anket Oluştur'**
  String get chatCreatePoll;

  /// No description provided for @chatAddOption.
  ///
  /// In tr, this message translates to:
  /// **'Seçenek ekle'**
  String get chatAddOption;

  /// No description provided for @chatSendPoll.
  ///
  /// In tr, this message translates to:
  /// **'Anketi Gönder'**
  String get chatSendPoll;

  /// No description provided for @chatFileFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dosya seçilemedi'**
  String get chatFileFailed;

  /// No description provided for @chatSearchMessages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlarda Ara'**
  String get chatSearchMessages;

  /// No description provided for @chatClearChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti Temizle'**
  String get chatClearChat;

  /// No description provided for @chatCamera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get chatCamera;

  /// No description provided for @chatGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get chatGallery;

  /// No description provided for @chatLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get chatLocation;

  /// No description provided for @chatEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik'**
  String get chatEvent;

  /// No description provided for @chatPoll.
  ///
  /// In tr, this message translates to:
  /// **'Anket'**
  String get chatPoll;

  /// No description provided for @chatGif.
  ///
  /// In tr, this message translates to:
  /// **'GIF'**
  String get chatGif;

  /// No description provided for @chatVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get chatVideo;

  /// No description provided for @chatFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya'**
  String get chatFile;

  /// No description provided for @subHomeExpenses.
  ///
  /// In tr, this message translates to:
  /// **'Ev Giderleri'**
  String get subHomeExpenses;

  /// No description provided for @subHomeExpensesSub.
  ///
  /// In tr, this message translates to:
  /// **'Kira, faturalar ve abonelikler'**
  String get subHomeExpensesSub;

  /// No description provided for @subMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get subMonthly;

  /// No description provided for @subYearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get subYearly;

  /// No description provided for @subActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get subActive;

  /// No description provided for @subCountryTemplate.
  ///
  /// In tr, this message translates to:
  /// **'Ülke şablonu'**
  String get subCountryTemplate;

  /// No description provided for @subNoSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik bulunamadı\n+ butonuna dokun'**
  String get subNoSubscription;

  /// No description provided for @subAddExpense.
  ///
  /// In tr, this message translates to:
  /// **'Gider Ekle'**
  String get subAddExpense;

  /// No description provided for @subAddCountryTemplate.
  ///
  /// In tr, this message translates to:
  /// **'Ülke gider şablonu ekle'**
  String get subAddCountryTemplate;

  /// No description provided for @subCommonExpenses.
  ///
  /// In tr, this message translates to:
  /// **'Sık Kullanılan Giderler'**
  String get subCommonExpenses;

  /// No description provided for @subServiceName.
  ///
  /// In tr, this message translates to:
  /// **'Servis adı'**
  String get subServiceName;

  /// No description provided for @subAmount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar ({cur})'**
  String subAmount(Object cur);

  /// No description provided for @subAddSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik Ekle'**
  String get subAddSubscription;

  /// No description provided for @srError.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {msg}'**
  String srError(Object msg);

  /// No description provided for @srBasicInfo.
  ///
  /// In tr, this message translates to:
  /// **'Temel Bilgiler'**
  String get srBasicInfo;

  /// No description provided for @srLatitude.
  ///
  /// In tr, this message translates to:
  /// **'Enlem'**
  String get srLatitude;

  /// No description provided for @srLongitude.
  ///
  /// In tr, this message translates to:
  /// **'Boylam'**
  String get srLongitude;

  /// No description provided for @srGeofenceRadius.
  ///
  /// In tr, this message translates to:
  /// **'Geofence Yarıçapı: {m}m'**
  String srGeofenceRadius(Object m);

  /// No description provided for @srProximity.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşma Mesafesi: {m}m'**
  String srProximity(Object m);

  /// No description provided for @srTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get srTime;

  /// No description provided for @srAnd.
  ///
  /// In tr, this message translates to:
  /// **'AND'**
  String get srAnd;

  /// No description provided for @srOr.
  ///
  /// In tr, this message translates to:
  /// **'OR'**
  String get srOr;

  /// No description provided for @srInterruptibility.
  ///
  /// In tr, this message translates to:
  /// **'Rahatsız Edilebilirlik: {pct}%'**
  String srInterruptibility(Object pct);

  /// No description provided for @srTone.
  ///
  /// In tr, this message translates to:
  /// **'Ton'**
  String get srTone;

  /// No description provided for @srSmartChoice.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı seçim (AI önerir)'**
  String get srSmartChoice;

  /// No description provided for @budIncome.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get budIncome;

  /// No description provided for @budExpense.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get budExpense;

  /// No description provided for @budBalance.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye'**
  String get budBalance;

  /// No description provided for @budAnalyzing.
  ///
  /// In tr, this message translates to:
  /// **'Gemini analiz ediyor…'**
  String get budAnalyzing;

  /// No description provided for @budMonthlyLimit.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Limit (€)'**
  String get budMonthlyLimit;

  /// No description provided for @budDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get budDelete;

  /// No description provided for @budAmount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get budAmount;

  /// No description provided for @budCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get budCategory;

  /// No description provided for @budDescOptional.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama (opsiyonel)'**
  String get budDescOptional;

  /// No description provided for @budAiSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'AI önerisi: {cat}'**
  String budAiSuggestion(Object cat);

  /// No description provided for @budSuggestCategory.
  ///
  /// In tr, this message translates to:
  /// **'AI ile kategori öner'**
  String get budSuggestCategory;

  /// No description provided for @budEnterValidAmount.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir tutar girin'**
  String get budEnterValidAmount;

  /// No description provided for @crashTest.
  ///
  /// In tr, this message translates to:
  /// **'Test Et'**
  String get crashTest;

  /// No description provided for @crashDetectionActive.
  ///
  /// In tr, this message translates to:
  /// **'Kaza tespiti aktif'**
  String get crashDetectionActive;

  /// No description provided for @crashSound.
  ///
  /// In tr, this message translates to:
  /// **'Ses'**
  String get crashSound;

  /// No description provided for @crashEmergencyAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Acil alarm'**
  String get crashEmergencyAlarm;

  /// No description provided for @crashSiren.
  ///
  /// In tr, this message translates to:
  /// **'Siren'**
  String get crashSiren;

  /// No description provided for @crashSos.
  ///
  /// In tr, this message translates to:
  /// **'SOS'**
  String get crashSos;

  /// No description provided for @crashAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Alarm'**
  String get crashAlarm;

  /// No description provided for @crashSaveUpper.
  ///
  /// In tr, this message translates to:
  /// **'KAYDET'**
  String get crashSaveUpper;

  /// No description provided for @crashAddContact.
  ///
  /// In tr, this message translates to:
  /// **'Acil Kişi Ekle'**
  String get crashAddContact;

  /// No description provided for @crashPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get crashPhone;

  /// No description provided for @crashAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get crashAdd;

  /// No description provided for @crashContacts.
  ///
  /// In tr, this message translates to:
  /// **'Acil Kişiler'**
  String get crashContacts;

  /// No description provided for @crashNoContacts.
  ///
  /// In tr, this message translates to:
  /// **'Henüz acil kişi yok. + ile ekleyin.'**
  String get crashNoContacts;

  /// No description provided for @crashSettingsSaved.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar kaydedildi'**
  String get crashSettingsSaved;

  /// No description provided for @crashTestMode.
  ///
  /// In tr, this message translates to:
  /// **'Test Modu'**
  String get crashTestMode;

  /// No description provided for @medEnterName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen ilaç adını girin.'**
  String get medEnterName;

  /// No description provided for @medTime.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Zamanı 💊'**
  String get medTime;

  /// No description provided for @medNewRecordSub.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ilaç kaydı oluştur'**
  String get medNewRecordSub;

  /// No description provided for @medWhose.
  ///
  /// In tr, this message translates to:
  /// **'Kime ait?'**
  String get medWhose;

  /// No description provided for @medName.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Adı'**
  String get medName;

  /// No description provided for @medType.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Türü'**
  String get medType;

  /// No description provided for @medDose.
  ///
  /// In tr, this message translates to:
  /// **'Doz'**
  String get medDose;

  /// No description provided for @medFrequency.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Sıklığı'**
  String get medFrequency;

  /// No description provided for @medStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get medStart;

  /// No description provided for @medEndOptional.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş (opsiyonel)'**
  String get medEndOptional;

  /// No description provided for @medReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma'**
  String get medReminder;

  /// No description provided for @medReminderTime.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma Saati'**
  String get medReminderTime;

  /// No description provided for @medNote.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get medNote;

  /// No description provided for @fdTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Detayları'**
  String get fdTitle;

  /// No description provided for @fdPhotoUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Aile fotoğrafı güncellendi'**
  String get fdPhotoUpdated;

  /// No description provided for @fdPhotoFailed.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklenemedi: {msg}'**
  String fdPhotoFailed(Object msg);

  /// No description provided for @fdInfoSaved.
  ///
  /// In tr, this message translates to:
  /// **'Aile bilgileri kaydedildi'**
  String get fdInfoSaved;

  /// No description provided for @fdSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi: {msg}'**
  String fdSaveFailed(Object msg);

  /// No description provided for @fdDeleteMemoryConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu anı silmek istediğinize emin misiniz?'**
  String get fdDeleteMemoryConfirm;

  /// No description provided for @fdMemoryDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Anı silindi'**
  String get fdMemoryDeleted;

  /// No description provided for @fdDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Silinemedi: {msg}'**
  String fdDeleteFailed(Object msg);

  /// No description provided for @fdAddMemory.
  ///
  /// In tr, this message translates to:
  /// **'Anı Ekle'**
  String get fdAddMemory;

  /// No description provided for @fdAddFailed.
  ///
  /// In tr, this message translates to:
  /// **'Eklenemedi: {msg}'**
  String fdAddFailed(Object msg);

  /// No description provided for @fdDetailOptional.
  ///
  /// In tr, this message translates to:
  /// **'Detay (isteğe bağlı)'**
  String get fdDetailOptional;

  /// No description provided for @hcUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık kartı güncellendi'**
  String get hcUpdated;

  /// No description provided for @hcHealthInfo.
  ///
  /// In tr, this message translates to:
  /// **'SAĞLIK BİLGİLERİ'**
  String get hcHealthInfo;

  /// No description provided for @hcAllergies.
  ///
  /// In tr, this message translates to:
  /// **'Alerjiler'**
  String get hcAllergies;

  /// No description provided for @hcOrganDonor.
  ///
  /// In tr, this message translates to:
  /// **'Organ Bağışçısı'**
  String get hcOrganDonor;

  /// No description provided for @hcEmergencyContact.
  ///
  /// In tr, this message translates to:
  /// **'ACİL DURUM KİŞİSİ'**
  String get hcEmergencyContact;

  /// No description provided for @hcFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get hcFullName;

  /// No description provided for @hcDoctorInfo.
  ///
  /// In tr, this message translates to:
  /// **'DOKTOR BİLGİLERİ'**
  String get hcDoctorInfo;

  /// No description provided for @hcExtraNotes.
  ///
  /// In tr, this message translates to:
  /// **'EK NOTLAR'**
  String get hcExtraNotes;

  /// No description provided for @hcNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get hcNotes;

  /// No description provided for @peTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil Düzenle: {label}'**
  String peTitle(Object label);

  /// No description provided for @peColor.
  ///
  /// In tr, this message translates to:
  /// **'Renk: {color}'**
  String peColor(Object color);

  /// No description provided for @peHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek (10m)'**
  String get peHigh;

  /// No description provided for @peMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta (50m)'**
  String get peMedium;

  /// No description provided for @peLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük (100m+)'**
  String get peLow;

  /// No description provided for @peWifiCellular.
  ///
  /// In tr, this message translates to:
  /// **'WiFi + Cellular dene'**
  String get peWifiCellular;

  /// No description provided for @peLastKnown.
  ///
  /// In tr, this message translates to:
  /// **'Son bilinen konumu kullan'**
  String get peLastKnown;

  /// No description provided for @peFastFix.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı fix (önceki konumdan)'**
  String get peFastFix;

  /// No description provided for @peActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite'**
  String get peActivity;

  /// No description provided for @peManual.
  ///
  /// In tr, this message translates to:
  /// **'Manuel'**
  String get peManual;

  /// No description provided for @peSaved.
  ///
  /// In tr, this message translates to:
  /// **'Profil kaydedildi'**
  String get peSaved;

  /// No description provided for @evTitleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık zorunlu'**
  String get evTitleRequired;

  /// No description provided for @evDeleteEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliği Sil'**
  String get evDeleteEvent;

  /// No description provided for @evTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik başlığı...'**
  String get evTitleHint;

  /// No description provided for @evEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get evEnd;

  /// No description provided for @evLocationHint.
  ///
  /// In tr, this message translates to:
  /// **'Konum ekle...'**
  String get evLocationHint;

  /// No description provided for @evDescHint.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama ekle...'**
  String get evDescHint;

  /// No description provided for @cddObservation.
  ///
  /// In tr, this message translates to:
  /// **'Gözlem'**
  String get cddObservation;

  /// No description provided for @cddSources.
  ///
  /// In tr, this message translates to:
  /// **'İçeriklerimizin kaynakları'**
  String get cddSources;

  /// No description provided for @cddOverallScore.
  ///
  /// In tr, this message translates to:
  /// **'Genel Gelişim Skoru'**
  String get cddOverallScore;

  /// No description provided for @cddTodayTasks.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün Görevleri'**
  String get cddTodayTasks;

  /// No description provided for @cddTapToStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlamak için dokun'**
  String get cddTapToStart;

  /// No description provided for @cddAiComment.
  ///
  /// In tr, this message translates to:
  /// **'AI Yorumu'**
  String get cddAiComment;

  /// No description provided for @cddNoObservation.
  ///
  /// In tr, this message translates to:
  /// **'Henüz gözlem yok — \"Gözlem\" ile ilk kaydı ekleyin.'**
  String get cddNoObservation;

  /// No description provided for @cddNoChildProfile.
  ///
  /// In tr, this message translates to:
  /// **'Henüz çocuk profili yok'**
  String get cddNoChildProfile;

  /// No description provided for @hchTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk Sağlığı'**
  String get hchTitle;

  /// No description provided for @hchSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk için sağlık takibi'**
  String get hchSubtitle;

  /// No description provided for @hchHealthSummary.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Özeti'**
  String get hchHealthSummary;

  /// No description provided for @hchNoUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan randevu yok'**
  String get hchNoUpcoming;

  /// No description provided for @hchHeightWeight.
  ///
  /// In tr, this message translates to:
  /// **'Boy & Kilo'**
  String get hchHeightWeight;

  /// No description provided for @hchVaccineSchedule.
  ///
  /// In tr, this message translates to:
  /// **'Aşı Takvimi'**
  String get hchVaccineSchedule;

  /// No description provided for @hchVaccineSub.
  ///
  /// In tr, this message translates to:
  /// **'Aşı takvimini görüntüleyin ve takip edin.'**
  String get hchVaccineSub;

  /// No description provided for @hchView.
  ///
  /// In tr, this message translates to:
  /// **'Gör'**
  String get hchView;

  /// No description provided for @hchTodayTip.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü İpucu'**
  String get hchTodayTip;

  /// No description provided for @docInfo.
  ///
  /// In tr, this message translates to:
  /// **'Belge Bilgileri'**
  String get docInfo;

  /// No description provided for @docName.
  ///
  /// In tr, this message translates to:
  /// **'Belge Adı'**
  String get docName;

  /// No description provided for @docUploadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme hatası: {msg}'**
  String docUploadFailed(Object msg);

  /// No description provided for @docDeleteDoc.
  ///
  /// In tr, this message translates to:
  /// **'Belgeyi Sil'**
  String get docDeleteDoc;

  /// No description provided for @docVault.
  ///
  /// In tr, this message translates to:
  /// **'Evrak Kasası'**
  String get docVault;

  /// No description provided for @galSyncFailed.
  ///
  /// In tr, this message translates to:
  /// **'Senkron hatası: {msg}'**
  String galSyncFailed(Object msg);

  /// No description provided for @galDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu medya silinecek. Emin misiniz?'**
  String get galDeleteConfirm;

  /// No description provided for @galPickMulti.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden Seç (Çoklu)'**
  String get galPickMulti;

  /// No description provided for @galSyncDevice.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz Galerisini Senkronla'**
  String get galSyncDevice;

  /// No description provided for @galSyncDeviceSub.
  ///
  /// In tr, this message translates to:
  /// **'Son fotoğrafları aile galerisine aktar'**
  String get galSyncDeviceSub;

  /// No description provided for @galAutoSync.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Senkron'**
  String get galAutoSync;

  /// No description provided for @galTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Galerisi'**
  String get galTitle;

  /// No description provided for @sfLocationDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kalıcı reddedildi. Ayarlardan etkinleştirin.'**
  String get sfLocationDenied;

  /// No description provided for @sfSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get sfSettings;

  /// No description provided for @sfEmergencyActive.
  ///
  /// In tr, this message translates to:
  /// **'ACİL DURUM AKTİF'**
  String get sfEmergencyActive;

  /// No description provided for @sfUpdateLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumu Güncelle'**
  String get sfUpdateLocation;

  /// No description provided for @sfAmbientListen.
  ///
  /// In tr, this message translates to:
  /// **'Ortam Dinleme'**
  String get sfAmbientListen;

  /// No description provided for @sfFlashlight.
  ///
  /// In tr, this message translates to:
  /// **'Fener'**
  String get sfFlashlight;

  /// No description provided for @conImportFailed.
  ///
  /// In tr, this message translates to:
  /// **'İçe aktarma hatası: {msg}'**
  String conImportFailed(Object msg);

  /// No description provided for @conEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get conEmail;

  /// No description provided for @conTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Rehberi'**
  String get conTitle;

  /// No description provided for @conSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Ara...'**
  String get conSearchHint;

  /// No description provided for @fmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Haritası'**
  String get fmTitle;

  /// No description provided for @fmKmh.
  ///
  /// In tr, this message translates to:
  /// **'km/h'**
  String get fmKmh;

  /// No description provided for @fmCall.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get fmCall;

  /// No description provided for @fmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get fmMessage;

  /// No description provided for @fmRoute.
  ///
  /// In tr, this message translates to:
  /// **'Yol'**
  String get fmRoute;

  /// No description provided for @fmTodayActivities.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü Aktiviteler'**
  String get fmTodayActivities;

  /// No description provided for @fmNoActivity.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için konum aktivitesi yok.'**
  String get fmNoActivity;

  /// No description provided for @szCenterCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki konumun merkez alınır.'**
  String get szCenterCurrent;

  /// No description provided for @szZoneName.
  ///
  /// In tr, this message translates to:
  /// **'Bölge adı'**
  String get szZoneName;

  /// No description provided for @szZoneNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Ev, Okul, İş'**
  String get szZoneNameHint;

  /// No description provided for @szRadius.
  ///
  /// In tr, this message translates to:
  /// **'Yarıçap: {m} m'**
  String szRadius(Object m);

  /// No description provided for @szEnterName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bölge adı girin'**
  String get szEnterName;

  /// No description provided for @szNoLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. GPS açık olmalı.'**
  String get szNoLocation;

  /// No description provided for @szDiameter.
  ///
  /// In tr, this message translates to:
  /// **'Çap: {m}m'**
  String szDiameter(Object m);

  /// No description provided for @szDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe: {d}'**
  String szDistance(Object d);

  /// No description provided for @fssEta.
  ///
  /// In tr, this message translates to:
  /// **'ETA: {eta}'**
  String fssEta(Object eta);

  /// No description provided for @fssMap.
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get fssMap;

  /// No description provided for @fssSendReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı Gönder'**
  String get fssSendReminder;

  /// No description provided for @fssSpeed.
  ///
  /// In tr, this message translates to:
  /// **'Hız'**
  String get fssSpeed;

  /// No description provided for @fssBattery.
  ///
  /// In tr, this message translates to:
  /// **'Batarya'**
  String get fssBattery;

  /// No description provided for @fssSignal.
  ///
  /// In tr, this message translates to:
  /// **'Sinyal'**
  String get fssSignal;

  /// No description provided for @obsSaved.
  ///
  /// In tr, this message translates to:
  /// **'Gözlem kaydedildi'**
  String get obsSaved;

  /// No description provided for @obsAdd.
  ///
  /// In tr, this message translates to:
  /// **'Gözlem Ekle'**
  String get obsAdd;

  /// No description provided for @obsDevArea.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim Alanı'**
  String get obsDevArea;

  /// No description provided for @obsYourObs.
  ///
  /// In tr, this message translates to:
  /// **'Gözleminiz'**
  String get obsYourObs;

  /// No description provided for @obsMood.
  ///
  /// In tr, this message translates to:
  /// **'Durum / Ruh Hali'**
  String get obsMood;

  /// No description provided for @obsSkillStatus.
  ///
  /// In tr, this message translates to:
  /// **'Beceri Durumu'**
  String get obsSkillStatus;

  /// No description provided for @obsHint.
  ///
  /// In tr, this message translates to:
  /// **'Bugün ne fark ettiniz?'**
  String get obsHint;

  /// No description provided for @obsMaxFiles.
  ///
  /// In tr, this message translates to:
  /// **'Maks. 5 dosya • JPG, PNG, MP4'**
  String get obsMaxFiles;

  /// No description provided for @cmDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Silme başarısız: {msg}'**
  String cmDeleteFailed(Object msg);

  /// No description provided for @cmTapToAddMember.
  ///
  /// In tr, this message translates to:
  /// **'Aile üyesi eklemek için aşağıya dokun'**
  String get cmTapToAddMember;

  /// No description provided for @cmBaby.
  ///
  /// In tr, this message translates to:
  /// **'Bebek'**
  String get cmBaby;

  /// No description provided for @cmPermissions.
  ///
  /// In tr, this message translates to:
  /// **'İzinler'**
  String get cmPermissions;

  /// No description provided for @cmCanMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderebilir'**
  String get cmCanMessage;

  /// No description provided for @cmCanApproveTask.
  ///
  /// In tr, this message translates to:
  /// **'Görev onaylayabilir'**
  String get cmCanApproveTask;

  /// No description provided for @cmCanSeeBudget.
  ///
  /// In tr, this message translates to:
  /// **'Bütçeyi görebilir'**
  String get cmCanSeeBudget;

  /// No description provided for @cmDailyScreenTime.
  ///
  /// In tr, this message translates to:
  /// **'Günlük ekran süresi'**
  String get cmDailyScreenTime;

  /// No description provided for @cmPinRepeat.
  ///
  /// In tr, this message translates to:
  /// **'PIN Tekrar'**
  String get cmPinRepeat;

  /// No description provided for @rtNewRoutine.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Rutin'**
  String get rtNewRoutine;

  /// No description provided for @rtNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an: {step}'**
  String rtNow(Object step);

  /// No description provided for @rtContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get rtContinue;

  /// No description provided for @rtApply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get rtApply;

  /// No description provided for @rtDeleteRoutine.
  ///
  /// In tr, this message translates to:
  /// **'Rutini Sil'**
  String get rtDeleteRoutine;

  /// No description provided for @cbSignInFailed.
  ///
  /// In tr, this message translates to:
  /// **'Giriş hatası: {msg}'**
  String cbSignInFailed(Object msg);

  /// No description provided for @cbDisconnectFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı kesme hatası: {msg}'**
  String cbDisconnectFailed(Object msg);

  /// No description provided for @cbBackupFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme hatası: {msg}'**
  String cbBackupFailed(Object msg);

  /// No description provided for @cbRestoreFailed.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme hatası: {msg}'**
  String cbRestoreFailed(Object msg);

  /// No description provided for @cbBackupDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Yedek silindi'**
  String get cbBackupDeleted;

  /// No description provided for @cbDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Silme hatası: {msg}'**
  String cbDeleteFailed(Object msg);

  /// No description provided for @cbTitle.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive Yedekleme'**
  String get cbTitle;

  /// No description provided for @hMoodQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Bugün kendini nasıl hissediyorsun?'**
  String get hMoodQuestion;

  /// No description provided for @hTodaySuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün Önerisi'**
  String get hTodaySuggestion;

  /// No description provided for @hdWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin {name}'**
  String hdWelcome(Object name);

  /// No description provided for @hdJourneyStart.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık yolculuğun burada başlıyor.'**
  String get hdJourneyStart;

  /// No description provided for @hdDailySummary.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Sağlık Özeti'**
  String get hdDailySummary;

  /// No description provided for @hdArticles.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Makaleleri'**
  String get hdArticles;

  /// No description provided for @hdArticlesSub.
  ///
  /// In tr, this message translates to:
  /// **'Güncel, güvenilir sağlık içerikleri.'**
  String get hdArticlesSub;

  /// No description provided for @hfTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Sağlığı'**
  String get hfTitle;

  /// No description provided for @hfSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Anne ve baba için sağlık merkezi'**
  String get hfSubtitle;

  /// No description provided for @hfFamilyContent.
  ///
  /// In tr, this message translates to:
  /// **'Aile İçeriği'**
  String get hfFamilyContent;

  /// No description provided for @hfNoParent.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ebeveyn eklenmedi. Aile üyelerini ekleyin.'**
  String get hfNoParent;

  /// No description provided for @hfSetValue.
  ///
  /// In tr, this message translates to:
  /// **'Değeri ayarla'**
  String get hfSetValue;

  /// No description provided for @hfDailySuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Öneri'**
  String get hfDailySuggestion;

  /// No description provided for @hwTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kadın Sağlığı'**
  String get hwTitle;

  /// No description provided for @hwSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Anne için kişisel sağlık alanı'**
  String get hwSubtitle;

  /// No description provided for @hwCycleTracking.
  ///
  /// In tr, this message translates to:
  /// **'Döngü Takibi'**
  String get hwCycleTracking;

  /// No description provided for @hwCycleDay.
  ///
  /// In tr, this message translates to:
  /// **'Adet döneminin {day}. günündesin.'**
  String hwCycleDay(Object day);

  /// No description provided for @hwTapToChangeStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç tarihini değiştirmek için dokun'**
  String get hwTapToChangeStart;

  /// No description provided for @hwSymptomTracking.
  ///
  /// In tr, this message translates to:
  /// **'Semptom Takibi'**
  String get hwSymptomTracking;

  /// No description provided for @sosTriggerWord.
  ///
  /// In tr, this message translates to:
  /// **'Trigger word analizi'**
  String get sosTriggerWord;

  /// No description provided for @ltAiOptimize.
  ///
  /// In tr, this message translates to:
  /// **'AI Optimize Et'**
  String get ltAiOptimize;

  /// No description provided for @ltTrackingActive.
  ///
  /// In tr, this message translates to:
  /// **'Konum takibi aktif'**
  String get ltTrackingActive;

  /// No description provided for @ltBalanced.
  ///
  /// In tr, this message translates to:
  /// **'Dengeli'**
  String get ltBalanced;

  /// No description provided for @ltAccuracy.
  ///
  /// In tr, this message translates to:
  /// **'Hassas'**
  String get ltAccuracy;

  /// No description provided for @stLockFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kilitleme başarısız: {msg}'**
  String stLockFailed(Object msg);

  /// No description provided for @stDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre: {h}s {m}d'**
  String stDuration(Object h, Object m);

  /// No description provided for @stReasonOptional.
  ///
  /// In tr, this message translates to:
  /// **'Neden (isteğe bağlı)'**
  String get stReasonOptional;

  /// No description provided for @stLock.
  ///
  /// In tr, this message translates to:
  /// **'Kilitle'**
  String get stLock;

  /// No description provided for @apAa.
  ///
  /// In tr, this message translates to:
  /// **'Aa'**
  String get apAa;

  /// No description provided for @apFontSizeNote.
  ///
  /// In tr, this message translates to:
  /// **'Yazı boyutu tüm uygulamaya anında uygulanır.'**
  String get apFontSizeNote;

  /// No description provided for @bsSettingsSection.
  ///
  /// In tr, this message translates to:
  /// **'AYARLAR'**
  String get bsSettingsSection;

  /// No description provided for @bsAutoBackup.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik Yedekleme'**
  String get bsAutoBackup;

  /// No description provided for @bsAutoBackupSub.
  ///
  /// In tr, this message translates to:
  /// **'Her hafta otomatik yedekle'**
  String get bsAutoBackupSub;

  /// No description provided for @pfSaved.
  ///
  /// In tr, this message translates to:
  /// **'Profil bilgileri kaydedildi'**
  String get pfSaved;

  /// No description provided for @pfNewEmail.
  ///
  /// In tr, this message translates to:
  /// **'Yeni E-posta'**
  String get pfNewEmail;

  /// No description provided for @sgWellDone.
  ///
  /// In tr, this message translates to:
  /// **'Duyularını harika kullandın! Yarın yeni bir keşif seni bekliyor.'**
  String get sgWellDone;

  /// No description provided for @sgPlayAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Oyna'**
  String get sgPlayAgain;

  /// No description provided for @sgFinish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get sgFinish;

  /// No description provided for @sgTitle.
  ///
  /// In tr, this message translates to:
  /// **'Duyusal Keşif'**
  String get sgTitle;

  /// No description provided for @sgTodayGame.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün oyunu: {game}'**
  String sgTodayGame(Object game);

  /// No description provided for @sgRound.
  ///
  /// In tr, this message translates to:
  /// **'Tur {r}/{total}'**
  String sgRound(Object r, Object total);

  /// No description provided for @sgFindThis.
  ///
  /// In tr, this message translates to:
  /// **'Bunu bul:'**
  String get sgFindThis;

  /// No description provided for @wtTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hava Durumu'**
  String get wtTitle;

  /// No description provided for @wtCelsius.
  ///
  /// In tr, this message translates to:
  /// **'Celsius (°C)'**
  String get wtCelsius;

  /// No description provided for @wtFahrenheit.
  ///
  /// In tr, this message translates to:
  /// **'Fahrenheit (°F)'**
  String get wtFahrenheit;

  /// No description provided for @wtFeelsLike.
  ///
  /// In tr, this message translates to:
  /// **'Hissedilen'**
  String get wtFeelsLike;

  /// No description provided for @wtHumidity.
  ///
  /// In tr, this message translates to:
  /// **'Nem'**
  String get wtHumidity;

  /// No description provided for @dsAuthSources.
  ///
  /// In tr, this message translates to:
  /// **'Resmi ve otoriter kaynaklar'**
  String get dsAuthSources;

  /// No description provided for @aisShared.
  ///
  /// In tr, this message translates to:
  /// **'Aile grubuna paylaşıldı'**
  String get aisShared;

  /// No description provided for @aisMissing.
  ///
  /// In tr, this message translates to:
  /// **'Eksik'**
  String get aisMissing;

  /// No description provided for @aisTurn.
  ///
  /// In tr, this message translates to:
  /// **'Sıra: {who}'**
  String aisTurn(Object who);

  /// No description provided for @aisCommentHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu öneri hakkında düşünceleriniz...'**
  String get aisCommentHint;

  /// No description provided for @aisCommentSaved.
  ///
  /// In tr, this message translates to:
  /// **'Yorum kaydedildi'**
  String get aisCommentSaved;

  /// No description provided for @aisAccept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul Et'**
  String get aisAccept;

  /// No description provided for @aisPostpone.
  ///
  /// In tr, this message translates to:
  /// **'Ertele'**
  String get aisPostpone;

  /// No description provided for @aisShowLess.
  ///
  /// In tr, this message translates to:
  /// **'Daha Az Göster'**
  String get aisShowLess;

  /// No description provided for @huShowSmartCard.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Kartı Göster'**
  String get huShowSmartCard;

  /// No description provided for @huShowTips.
  ///
  /// In tr, this message translates to:
  /// **'İpuçlarını Göster'**
  String get huShowTips;

  /// No description provided for @huEditTiles.
  ///
  /// In tr, this message translates to:
  /// **'Ana Ekran Kutucuklarını Düzenle'**
  String get huEditTiles;

  /// No description provided for @huDragSort.
  ///
  /// In tr, this message translates to:
  /// **'Kutucukları Sürükle-Sırala'**
  String get huDragSort;

  /// No description provided for @mrMedTime.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Zamanı'**
  String get mrMedTime;

  /// No description provided for @mrTaken.
  ///
  /// In tr, this message translates to:
  /// **'İlaç alındı olarak işaretlendi ✓'**
  String get mrTaken;

  /// No description provided for @mrTook.
  ///
  /// In tr, this message translates to:
  /// **'Aldım'**
  String get mrTook;

  /// No description provided for @mrSnooze15.
  ///
  /// In tr, this message translates to:
  /// **'15 dk. sonra hatırlat'**
  String get mrSnooze15;

  /// No description provided for @mrSnoozeMsg.
  ///
  /// In tr, this message translates to:
  /// **'15 dakika sonra tekrar hatırlatılacak.'**
  String get mrSnoozeMsg;

  /// No description provided for @cdtLessonAdded.
  ///
  /// In tr, this message translates to:
  /// **'Ders eklendi'**
  String get cdtLessonAdded;

  /// No description provided for @cdtDeleteLesson.
  ///
  /// In tr, this message translates to:
  /// **'Ders Sil'**
  String get cdtDeleteLesson;

  /// No description provided for @cdtSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi'**
  String get cdtSaved;

  /// No description provided for @chtFamilyChat.
  ///
  /// In tr, this message translates to:
  /// **'Aile Sohbeti'**
  String get chtFamilyChat;

  /// No description provided for @chtMyLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumum'**
  String get chtMyLocation;

  /// No description provided for @chtMyFamily.
  ///
  /// In tr, this message translates to:
  /// **'Ailem'**
  String get chtMyFamily;

  /// No description provided for @chtBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme'**
  String get chtBackup;

  /// No description provided for @chtRotation.
  ///
  /// In tr, this message translates to:
  /// **'Rotasyon'**
  String get chtRotation;

  /// No description provided for @frpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile Karnesi'**
  String get frpTitle;

  /// No description provided for @frpCategories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get frpCategories;

  /// No description provided for @frpOverallScore.
  ///
  /// In tr, this message translates to:
  /// **'Genel Aile Skoru'**
  String get frpOverallScore;

  /// No description provided for @frpAiPreparing.
  ///
  /// In tr, this message translates to:
  /// **'AI yorumu hazırlanıyor…'**
  String get frpAiPreparing;

  /// No description provided for @frpAiComment.
  ///
  /// In tr, this message translates to:
  /// **'AI Aile Yorumu'**
  String get frpAiComment;

  /// No description provided for @roleAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get roleAdmin;

  /// No description provided for @roleParent.
  ///
  /// In tr, this message translates to:
  /// **'Ebeveyn'**
  String get roleParent;

  /// No description provided for @roleTeen.
  ///
  /// In tr, this message translates to:
  /// **'Genç'**
  String get roleTeen;

  /// No description provided for @roleChild.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk'**
  String get roleChild;

  /// No description provided for @roleElder.
  ///
  /// In tr, this message translates to:
  /// **'Büyük'**
  String get roleElder;

  /// No description provided for @roleGuest.
  ///
  /// In tr, this message translates to:
  /// **'Misafir'**
  String get roleGuest;

  /// No description provided for @evCatAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevu'**
  String get evCatAppointment;

  /// No description provided for @evCatBirthday.
  ///
  /// In tr, this message translates to:
  /// **'Doğum Günü'**
  String get evCatBirthday;

  /// No description provided for @evCatSchool.
  ///
  /// In tr, this message translates to:
  /// **'Okul'**
  String get evCatSchool;

  /// No description provided for @evCatWork.
  ///
  /// In tr, this message translates to:
  /// **'İş'**
  String get evCatWork;

  /// No description provided for @evCatFamily.
  ///
  /// In tr, this message translates to:
  /// **'Aile'**
  String get evCatFamily;

  /// No description provided for @evCatTravel.
  ///
  /// In tr, this message translates to:
  /// **'Seyahat'**
  String get evCatTravel;

  /// No description provided for @evCatOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get evCatOther;

  /// No description provided for @hbNoNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik yeni bildirim yok'**
  String get hbNoNotifications;

  /// No description provided for @hbCoverUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Kapak fotoğrafı güncellendi'**
  String get hbCoverUpdated;

  /// No description provided for @hbCoverFailed.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf kaydedilemedi'**
  String get hbCoverFailed;

  /// No description provided for @hbTodayTask.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN GÖREV'**
  String get hbTodayTask;

  /// No description provided for @hbDayStreak.
  ///
  /// In tr, this message translates to:
  /// **'GÜN SERİSİ'**
  String get hbDayStreak;

  /// No description provided for @hbOnline.
  ///
  /// In tr, this message translates to:
  /// **'ÇEVRİMİÇİ'**
  String get hbOnline;

  /// No description provided for @fmnRole.
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get fmnRole;

  /// No description provided for @fmnEnterName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen ad girin'**
  String get fmnEnterName;

  /// No description provided for @fmnRoleUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Rol güncellenemedi: {msg}'**
  String fmnRoleUpdateFailed(Object msg);

  /// No description provided for @fmnOpFailed.
  ///
  /// In tr, this message translates to:
  /// **'İşlem başarısız: {msg}'**
  String fmnOpFailed(Object msg);

  /// No description provided for @hsAllergyHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: yer fıstığı, polen, antibiyotik (virgülle ayırın)'**
  String get hsAllergyHint;

  /// No description provided for @hsConditionHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: astım, diyabet (virgülle ayırın)'**
  String get hsConditionHint;

  /// No description provided for @catEarned.
  ///
  /// In tr, this message translates to:
  /// **'Kazanılan Rozetler ({n})'**
  String catEarned(Object n);

  /// No description provided for @catPending.
  ///
  /// In tr, this message translates to:
  /// **'Kazanılmayı Bekleyen ({n})'**
  String catPending(Object n);

  /// No description provided for @catLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {n} • Kahraman'**
  String catLevel(Object n);

  /// No description provided for @catNextLevel.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki seviyeye:'**
  String get catNextLevel;

  /// No description provided for @catOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get catOk;

  /// No description provided for @hbAllUpToDate.
  ///
  /// In tr, this message translates to:
  /// **'Her şey güncel'**
  String get hbAllUpToDate;

  /// No description provided for @stgTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get stgTitle;

  /// No description provided for @stgSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub\'ınızı yönetin'**
  String get stgSubtitle;

  /// No description provided for @stgNotifDesc.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik, görev, acil durum, sohbet ve konum bildirimleri'**
  String get stgNotifDesc;

  /// No description provided for @stgMemberCount.
  ///
  /// In tr, this message translates to:
  /// **'{n} Üye'**
  String stgMemberCount(Object n);

  /// No description provided for @stgClear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get stgClear;

  /// No description provided for @stgLeftFamily.
  ///
  /// In tr, this message translates to:
  /// **'Aileden ayrıldınız.'**
  String get stgLeftFamily;

  /// No description provided for @stgLeaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ayrılma hatası: {msg}'**
  String stgLeaveFailed(Object msg);

  /// No description provided for @stgAllDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriler silindi.'**
  String get stgAllDeleted;

  /// No description provided for @stgDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Silme hatası: {msg}'**
  String stgDeleteFailed(Object msg);

  /// No description provided for @stgCacheCleared.
  ///
  /// In tr, this message translates to:
  /// **'Önbellek temizlendi.'**
  String get stgCacheCleared;

  /// No description provided for @stgClearFailed.
  ///
  /// In tr, this message translates to:
  /// **'Temizleme hatası: {msg}'**
  String stgClearFailed(Object msg);

  /// No description provided for @regEmailHint.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresiniz'**
  String get regEmailHint;

  /// No description provided for @regFamilyCodeHint.
  ///
  /// In tr, this message translates to:
  /// **'Aile Kodu (Örn: FH-123456)'**
  String get regFamilyCodeHint;

  /// No description provided for @regFamilyNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Aile Adı (Örn: Yılmaz Ailesi)'**
  String get regFamilyNameHint;

  /// No description provided for @regOr.
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get regOr;

  /// No description provided for @regPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (en az 8 karakter)'**
  String get regPasswordHint;

  /// No description provided for @privExportShareText.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub Veri Dışa Aktarımı'**
  String get privExportShareText;

  /// No description provided for @privActivityStatus.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite Durumu'**
  String get privActivityStatus;

  /// No description provided for @baOptimize.
  ///
  /// In tr, this message translates to:
  /// **'Optimize Et'**
  String get baOptimize;

  /// No description provided for @baRecalculate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Hesapla'**
  String get baRecalculate;

  /// No description provided for @baAvgAccuracy.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama hassasiyet'**
  String get baAvgAccuracy;

  /// No description provided for @baOptimalRatio.
  ///
  /// In tr, this message translates to:
  /// **'Optimal profil oranı'**
  String get baOptimalRatio;

  /// No description provided for @baWrongSwitch.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış profil geçişi'**
  String get baWrongSwitch;

  /// No description provided for @stTime.
  ///
  /// In tr, this message translates to:
  /// **'Hikaye Zamanı'**
  String get stTime;

  /// No description provided for @stDailySub.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün 4 görselli hikayesi'**
  String get stDailySub;

  /// No description provided for @stPageRead.
  ///
  /// In tr, this message translates to:
  /// **'{n} sayfa · Oku'**
  String stPageRead(Object n);

  /// No description provided for @stIllustrated.
  ///
  /// In tr, this message translates to:
  /// **'Görselli hikaye'**
  String get stIllustrated;

  /// No description provided for @stLesson.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeden Ders'**
  String get stLesson;

  /// No description provided for @chatPickGif.
  ///
  /// In tr, this message translates to:
  /// **'GIF Seç'**
  String get chatPickGif;

  /// No description provided for @chatToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get chatYesterday;

  /// No description provided for @ambMicRequired.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni gerekli'**
  String get ambMicRequired;

  /// No description provided for @ambRecordSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt kaydedildi: {name}'**
  String ambRecordSaved(Object name);

  /// No description provided for @ambManualButton.
  ///
  /// In tr, this message translates to:
  /// **'Manuel Buton'**
  String get ambManualButton;

  /// No description provided for @masViewProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Görüntüle'**
  String get masViewProfile;

  /// No description provided for @masHealthCard.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Kartı'**
  String get masHealthCard;

  /// No description provided for @masLiveLocation.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Konum'**
  String get masLiveLocation;

  /// No description provided for @masLeaveFamily.
  ///
  /// In tr, this message translates to:
  /// **'Aileden Ayrıl'**
  String get masLeaveFamily;

  /// No description provided for @masRemoveMember.
  ///
  /// In tr, this message translates to:
  /// **'Üyeyi Çıkar'**
  String get masRemoveMember;

  /// No description provided for @fpRoleUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Rol güncellendi: {role}'**
  String fpRoleUpdated(Object role);

  /// No description provided for @fpPermUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yetki güncellenemedi: {msg}'**
  String fpPermUpdateFailed(Object msg);

  /// No description provided for @chlAnotherSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Başka Öneri'**
  String get chlAnotherSuggestion;

  /// No description provided for @chlTodayMeal.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün Yemeği'**
  String get chlTodayMeal;

  /// No description provided for @chlHousework.
  ///
  /// In tr, this message translates to:
  /// **'Ev İşleri'**
  String get chlHousework;

  /// No description provided for @chlSaveTip.
  ///
  /// In tr, this message translates to:
  /// **'Tasarruf İpucu'**
  String get chlSaveTip;

  /// No description provided for @chlEmergency.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum'**
  String get chlEmergency;

  /// No description provided for @strTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Başlık (örn: Egzersiz, Kitap Okuma)'**
  String get strTitleHint;

  /// No description provided for @strNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Not (isteğe bağlı)'**
  String get strNoteHint;

  /// No description provided for @strTitle.
  ///
  /// In tr, this message translates to:
  /// **'Streak'**
  String get strTitle;

  /// No description provided for @strAddNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Streak Ekle'**
  String get strAddNew;

  /// No description provided for @hapFullChat.
  ///
  /// In tr, this message translates to:
  /// **'Tam sohbet'**
  String get hapFullChat;

  /// No description provided for @hapThinking.
  ///
  /// In tr, this message translates to:
  /// **'Düşünüyor…'**
  String get hapThinking;

  /// No description provided for @hapAskHint.
  ///
  /// In tr, this message translates to:
  /// **'FamilyHub AI\'ya sor…'**
  String get hapAskHint;

  /// No description provided for @flStandard.
  ///
  /// In tr, this message translates to:
  /// **'Standart'**
  String get flStandard;

  /// No description provided for @flStrobe.
  ///
  /// In tr, this message translates to:
  /// **'Strobe'**
  String get flStrobe;

  /// No description provided for @vcAcceptFailed.
  ///
  /// In tr, this message translates to:
  /// **'Arama kabul edilemedi: {msg}'**
  String vcAcceptFailed(Object msg);

  /// No description provided for @vcReject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get vcReject;

  /// No description provided for @vcHangup.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get vcHangup;

  /// No description provided for @tskDeleteTask.
  ///
  /// In tr, this message translates to:
  /// **'Görevi Sil'**
  String get tskDeleteTask;

  /// No description provided for @csSyncFailed.
  ///
  /// In tr, this message translates to:
  /// **'Senkronizasyon hatası: {msg}'**
  String csSyncFailed(Object msg);

  /// No description provided for @csScanCalendars.
  ///
  /// In tr, this message translates to:
  /// **'Takvimleri Tara'**
  String get csScanCalendars;

  /// No description provided for @csConfigure.
  ///
  /// In tr, this message translates to:
  /// **'Ayarla'**
  String get csConfigure;

  /// No description provided for @csMainCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Ana takvim'**
  String get csMainCalendar;

  /// No description provided for @secBiometricError.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik hata: {msg}'**
  String secBiometricError(Object msg);

  /// No description provided for @secNewPasswordRepeat.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre (Tekrar)'**
  String get secNewPasswordRepeat;

  /// No description provided for @secAccountDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silme hatası: {msg}'**
  String secAccountDeleteFailed(Object msg);

  /// No description provided for @secBioEnabled.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş etkinleştirildi'**
  String get secBioEnabled;

  /// No description provided for @secBioDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş devre dışı bırakıldı'**
  String get secBioDisabled;

  /// No description provided for @cstLocationDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kalıcı reddedildi.'**
  String get cstLocationDenied;

  /// No description provided for @cstShareFailed.
  ///
  /// In tr, this message translates to:
  /// **'Konum paylaşılamadı: {msg}'**
  String cstShareFailed(Object msg);

  /// No description provided for @abProcessing.
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor...'**
  String get abProcessing;

  /// No description provided for @pgUpgrade.
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a Yükselt'**
  String get pgUpgrade;

  /// No description provided for @pgNotNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Değil'**
  String get pgNotNow;

  /// No description provided for @pgNoProduct.
  ///
  /// In tr, this message translates to:
  /// **'Şu anda ürün bulunamadı. Lütfen daha sonra tekrar deneyin.'**
  String get pgNoProduct;

  /// No description provided for @pgActive.
  ///
  /// In tr, this message translates to:
  /// **'Premium aktif! 🎉'**
  String get pgActive;

  /// No description provided for @pgRequired.
  ///
  /// In tr, this message translates to:
  /// **'Premium Gerekli'**
  String get pgRequired;

  /// No description provided for @pgFeatureLabel.
  ///
  /// In tr, this message translates to:
  /// **'{feature} Özelliği'**
  String pgFeatureLabel(Object feature);

  /// No description provided for @pgUpgradeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu özelliği kullanmak için Premium\'a yükseltin.'**
  String get pgUpgradeDesc;

  /// No description provided for @invCopied.
  ///
  /// In tr, this message translates to:
  /// **'Kod kopyalandı'**
  String get invCopied;

  /// No description provided for @invCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get invCopy;

  /// No description provided for @invShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get invShare;

  /// No description provided for @accFamilyCode.
  ///
  /// In tr, this message translates to:
  /// **'Aile Kodu'**
  String get accFamilyCode;
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
      <String>['en', 'fr', 'nl', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
