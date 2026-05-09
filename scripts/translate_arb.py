#!/usr/bin/env python3
"""
Basit Turkce -> Ingilizce ARB cevirici.
Temel kelime ve cumle mapping'i kullanir.
Kaliteli olmayabilir ama baslangic noktasi saglar.
"""

import json
import re

# Basit Turkce -> Ingilizce sozluk (en yaygin kelimeler)
TR_TO_EN = {
    "aile": "Family",
    "ailem": "My Family",
    "ailemiz": "Our Family",
    "aileye": "to Family",
    "ailesi": "Family's",
    "ailenin": "of Family",
    "ailenize": "to your Family",
    "ailenizin": "of your Family",
    "ailenizi": "your Family",
    "ailenizle": "with your Family",
    "ailenizden": "from your Family",
    "ayarlar": "Settings",
    "ayarlarim": "My Settings",
    "profil": "Profile",
    "profilim": "My Profile",
    "cikis": "Logout",
    "cikis yap": "Log Out",
    "giris": "Login",
    "giris yap": "Sign In",
    "kaydol": "Sign Up",
    "kayit ol": "Register",
    "email": "Email",
    "e-posta": "Email",
    "eposta": "Email",
    "sifre": "Password",
    "sifremi": "my Password",
    "sifreni": "your Password",
    "sifrenizi": "your Password",
    "ad": "Name",
    "isim": "Name",
    "adiniz": "Your Name",
    "adinizi": "Your Name",
    "telefon": "Phone",
    "telefonu": "Phone",
    "telefonunuz": "Your Phone",
    "numarasi": "Number",
    "tamam": "OK",
    "iptal": "Cancel",
    "kaydet": "Save",
    "sil": "Delete",
    "duzenle": "Edit",
    "ekle": "Add",
    "gönder": "Send",
    "gonder": "Send",
    "yukleniyor": "Loading",
    "hata": "Error",
    "basarili": "Success",
    "tekrar dene": "Retry",
    "sohbet": "Chat",
    "takvim": "Calendar",
    "gorevler": "Tasks",
    "gorev": "Task",
    "guvenlik": "Safety",
    "saglik": "Health",
    "saglik karti": "Health Card",
    "alisveris": "Shopping",
    "butce": "Budget",
    "ana sayfa": "Home",
    "bildirimler": "Notifications",
    "bildirim": "Notification",
    "ara": "Search",
    "daha fazla": "More",
    "geri": "Back",
    "ileri": "Next",
    "bitti": "Done",
    "kapat": "Close",
    "evet": "Yes",
    "hayir": "No",
    "hos geldiniz": "Welcome",
    "hosgeldiniz": "Welcome",
    "uye": "Member",
    "uyeler": "Members",
    "online": "Online",
    "yonetici": "Admin",
    "admin": "Admin",
    "cocuk": "Child",
    "cocuklar": "Children",
    "ebeveyn": "Parent",
    "ebeveynler": "Parents",
    "rol": "Role",
    "resim": "Photo",
    "fotograf": "Photo",
    "konum": "Location",
    "etkinlik": "Event",
    "anket": "Poll",
    "sesli mesaj": "Voice Message",
    "bugun": "Today",
    "dun": "Yesterday",
    "yarim": "Tomorrow",
    "baslangic": "Start",
    "bitis": "End",
    "tum gun": "All Day",
    "hatirlatici": "Reminder",
    "kategori": "Category",
    "aciklama": "Description",
    "oncelik": "Priority",
    "yuksek": "High",
    "orta": "Medium",
    "dusuk": "Low",
    "tamamlandi": "Completed",
    "bekliyor": "Pending",
    "acil durum": "Emergency",
    "kan grubu": "Blood Type",
    "alerjiler": "Allergies",
    "ilaclar": "Medications",
    "doktor": "Doctor",
    "dil": "Language",
    "turkce": "Turkish",
    "english": "English",
    "ingilizce": "English",
    "tema": "Theme",
    "aydinlik": "Light",
    "karanlik": "Dark",
    "sistem": "System",
    "yazi boyutu": "Font Size",
    "kucuk": "Small",
    "normal": "Normal",
    "buyuk": "Large",
    "premium": "Premium",
    "abonelik": "Subscription",
    "internet": "Internet",
    "oturum": "Session",
    "sunucu": "Server",
    "veri": "Data",
    "sec": "Select",
    "kamera": "Camera",
    "galeri": "Gallery",
    "dosya": "File",
    "izin": "Permission",
    "davet": "Invite",
    "kopyala": "Copy",
    "paylas": "Share",
    "kopyalandi": "Copied",
    "yeni": "New",
    "olustur": "Create",
    "guncelle": "Update",
    "aktif": "Active",
    "pasif": "Inactive",
    "bilinmiyor": "Unknown",
    "secilmedi": "Not Selected",
    "devam et": "Continue",
    "dogrula": "Verify",
    "onayla": "Confirm",
    "reddet": "Decline",
    "kabul et": "Accept",
    "oku": "Read",
    "yaz": "Write",
    "gör": "View",
    "ara (isim)": "Call",
    "mesaj": "Message",
    "arama": "Call",
    "geldi": "Arrived",
    "gitti": "Left",
    "durum": "Status",
    "mod": "Mode",
    "acik": "Open",
    "kapali": "Closed",
    "ac": "Turn On",
    "kapat (fiil)": "Turn Off",
    "baslat": "Start",
    "durdur": "Stop",
    "baslik": "Title",
    "detay": "Detail",
    "detaylar": "Details",
    "rapor": "Report",
    "istatistik": "Statistics",
    "analiz": "Analysis",
    "aylik": "Monthly",
    "haftalik": "Weekly",
    "gunluk": "Daily",
    "yillik": "Yearly",
    "tum": "All",
    "hepsi": "All",
    "hicbiri": "None",
    "bazilari": "Some",
    "bir": "One",
    "iki": "Two",
    "uc": "Three",
    "dort": "Four",
    "bes": "Five",
    "alti": "Six",
    "yedi": "Seven",
    "sekiz": "Eight",
    "dokuz": "Nine",
    "on": "Ten",
    "simdi": "Now",
    "hemen": "Now",
    "sonra": "Later",
    "once": "Before",
    "sonra (zaman)": "After",
    "dakika": "minute",
    "saat": "hour",
    "gun": "day",
    "hafta": "week",
    "ay": "month",
    "yil": "year",
    "saniye": "second",
    "tarih": "Date",
    "zaman": "Time",
    "gecerli": "Valid",
    "gecersiz": "Invalid",
    "zorunlu": "Required",
    "secim": "Option",
    "varsayilan": "Default",
    "ozel": "Custom",
    "genel": "General",
    "ozellikler": "Features",
    "destek": "Support",
    "yardim": "Help",
    "hakkinda": "About",
    "surum": "Version",
    "gizlilik": "Privacy",
    "kosullar": "Terms",
    "politika": "Policy",
    "hesap": "Account",
    "hesabim": "My Account",
    "hesabiniz": "Your Account",
    "silme": "Deletion",
    "kayit": "Record",
    "kaydet (fiil)": "Save",
    "geri yukle": "Restore",
    "yedek": "Backup",
    "yedekle": "Backup",
    "senkronize": "Sync",
    "baglantı": "Connection",
    "bagli": "Connected",
    "baglanti yok": "No Connection",
    "yukle": "Upload",
    "indir": "Download",
    "yukleniyor (fiil)": "Uploading",
    "indiriliyor": "Downloading",
    "basarili": "Successful",
    "basarisiz": "Failed",
    "hazir": "Ready",
    "bekle": "Wait",
    "bekleyin": "Please wait",
    "lutfen": "Please",
    "tesekkurler": "Thank you",
    "tesekkur ederim": "Thank you",
    "ozur dilerim": "Sorry",
    "merhaba": "Hello",
    "gule gule": "Goodbye",
    "iyi gunler": "Good day",
    "iyi aksamlar": "Good evening",
    "gunaydin": "Good morning",
    "iyi geceler": "Good night",
    "hosca kal": "Goodbye",
}

def translate_value(value: str) -> str:
    """Basit kelime bazli cevirm yontemi."""
    if not value or not isinstance(value, str):
        return value
    
    result = value
    
    # Kelime bazli ceviriler (buyuk/kucuk harf duyarsiz)
    for tr_word, en_word in sorted(TR_TO_EN.items(), key=lambda x: -len(x[0])):
        # Tam kelime eslesmesi (kelime sinirlari ile)
        pattern = r'\b' + re.escape(tr_word) + r'\b'
        result = re.sub(pattern, en_word, result, flags=re.IGNORECASE)
    
    # Bazi common pattern'lar
    result = result.replace("'nin ", "'s ")
    result = result.replace("'nın ", "'s ")
    result = result.replace("'nun ", "'s ")
    result = result.replace("'nün ", "'s ")
    result = result.replace("'nin", "'s")
    result = result.replace("'nın", "'s")
    result = result.replace("İ", "I")
    
    # Turkce karakterleri normalize et (opsiyonel)
    result = result.replace("ç", "c").replace("Ç", "C")
    result = result.replace("ğ", "g").replace("Ğ", "G")
    result = result.replace("ı", "i").replace("I", "I")
    result = result.replace("ö", "o").replace("Ö", "O")
    result = result.replace("ş", "s").replace("Ş", "S")
    result = result.replace("ü", "u").replace("Ü", "U")
    
    return result

def main():
    with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translated = {"@@locale": "en"}
    
    for key, value in data.items():
        if key == "@@locale":
            continue
        
        if isinstance(value, str):
            translated[key] = translate_value(value)
        else:
            translated[key] = value
    
    with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
        json.dump(translated, f, ensure_ascii=False, indent=2)
    
    print(f"Cevirildi: {len(translated)} key -> lib/l10n/app_en.arb")

if __name__ == "__main__":
    main()
