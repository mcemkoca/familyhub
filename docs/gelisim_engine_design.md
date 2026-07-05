# FamilyHub — Çocuk Gelişimi İçerik & Güncelleme Motoru (Tasarım)

> Amaç: Aileye **TAKİP ET → ANLA → PLANLA → UYGULA → RAPORLA → GEREKİRSE UZMANA YÖNLENDİR**
> döngüsünü sunmak. Teşhis koymaz. Her içerik kaynak + yaş aralığı + dil + versiyon +
> review status ile üretilir. Belçika (Kind en Gezin / ONE) öncelikli.

## 0. Güvenlik & Tıbbi Sorumluluk (bağlayıcı)
- **Kaynağı olmayan gelişim iddiası yayınlanamaz.** Kaynak linki olmayan milestone yayınlanamaz.
- Sağlık, gelişim gecikmesi, tarama, kırmızı bayrak, konuşma gecikmesi, otizm, beslenme,
  uyku, güvenlik → **sadece resmi/klinik kaynak** (Kind en Gezin, ONE, WHO, CDC, AAP, NHS, UNICEF).
- Blog/forum/influencer/ticari siteler yalnızca **düşük riskli aktivite ilhamı** olarak.
- Yasaklı dil: "geri kalmış, problemli, anormal, kesin gecikme, otizm belirtisi, tanı, tedavi".
- Güvenli dil: "takip edilebilir / desteklenebilir / ek gözlem faydalı olabilir / uzmana danışın /
  bu içerik bilgilendirme amaçlıdır".
- Kaynak çelişkisi → kesin hüküm yok, editör kuyruğuna gönder.

## 1. Veri Modeli (özet şema)
```
ChildProfile { id, name, birthDate, ageMonths, languages[], country, region,
  schoolStatus, caregiverContext, allergies[], healthNotes, developmentConcerns[], createdAt, updatedAt }

DevelopmentArea { id, key, localizedName{tr,en,nl,fr}, description, icon, color, weight }
  key ∈ {language, gross_motor, fine_motor, social_emotional, cognitive, self_care, sensory, behavior, health_related_optional}

Milestone { id, area, ageMinMonths, ageMaxMonths, title, parentFriendlyDescription, examples[],
  observationQuestions[], activitySuggestions[], redFlagNotes, sourceIds[], sourceConfidence,
  medicalSensitivity ∈ {low,medium,high}, localeVersions{tr,en,nl,fr}, version, createdAt, updatedAt,
  reviewedAt, reviewStatus ∈ {draft, needs_human_review, approved, review_required} }

SkillAssessment { id, childId, milestoneId, status ∈ {achieved,emerging,not_yet,unknown},
  parentNote, mediaIds[], sourceSnapshotVersion, createdAt, updatedAt }

DevelopmentObservation { id, childId, area, note, detectedTags[], mood, skillStatus, mediaIds[],
  aiSummary, sourceSuggestedMilestones[], createdAt, updatedAt }

WeeklyDevelopmentPlan { id, childId, weekStart, focusAreas[], dailyDuration, difficulty, planType,
  activities[], sourceIds[], generatedReason, completedCount, createdAt, updatedAt }

DevelopmentActivity { id, title, area, ageMinMonths, ageMaxMonths, durationMinutes, difficulty,
  materials[], steps[], parentGoal, observationQuestion, safetyNotes, sourceIds[], localeVersions }

Source { id, title, organization, sourceType, country, language, url, canonicalUrl, lastFetchedAt,
  lastModifiedAt, contentHash, trustTier ∈ {official_local, official_intl, academic, activity},
  licenseNotes, usageAllowed, status, updateFrequency, extractedEntities[], version }

ContentVersion { id, contentType, contentId, version, sourceSnapshot, diffSummary, reviewer,
  publishStatus, createdAt }
```

## 2. Kaynak Güncelleme Motoru (Source Update Agent)
Supabase Edge Function + `pg_cron` ile:
1. `source_registry`'den aktif kaynakları çek.
2. Her kaynak: HTTP status + `Last-Modified` + `ETag` + içerik `hash` kontrolü.
3. Değişiklik yoksa dur. Varsa `raw_content` kaydet → temizle → chunk'la.
4. Milestone/aktivite/uyarı/yaş aralığı/alan/kaynak linkleri çıkar.
5. `staging_content`'e yaz (sourceIds ile).
6. AI kalite kontrol (bölüm 12) çalıştır.
7. `medicalSensitivity=high` → `human_review_required`. Düşük risk aktivite → otomatik yayın + version.
8. Yayınlanan içeriği embedding index'e ekle; app API cache yenile.
9. `affectedChildrenQuery` → aktif planı etkilenen kullanıcıya **sessizce** "plan güncellemesi mevcut".
**Sıklık:** resmi sağlık/yerel = haftalık, aktivite = aylık, kritik = manuel acil, app cache metadata = 24 saat.

## 3. Dashboard Algoritması
```
areaScore = achieved*1.0 + emerging*0.6 + not_yet*0.2 + unknown*0.0
areaScorePercent = areaScore / değerlendirilebilir_beceri_sayısı * 100
confidence = 1 - (unknown / toplam)          // unknown skoru düşürmez, confidence düşürür
overallDevelopmentScore = Σ(areaPercent * area.weight) / Σ(weight)
```
Son 30 gün gözlemleri **sinyal** olarak eklenir (teşhis değil). Metinler: "Yaşına uygun ilerliyor /
Bu alan desteklenebilir / Ek gözlem faydalı olabilir / Güçlü alan / Takip alanı". Teşhis dili yok.

## 4. Beceri Değerlendirme Algoritması
Girdi: childAgeMonths, language, country, existingAssessments, latestObservations.
Çıktı: yaşa uygun milestone listesi (yaş aralığı çocuğun ay yaşını kapsayan). Status eşleme:
`Yapıyor=achieved, Bazen=emerging, Henüz değil=not_yet, Emin değilim=unknown`.
MVP sınırı: yaş başına **≤24 soru**, alan başına **≥3**. Her milestone: title, açıklama, örnekler,
gözlem sorusu, **kaynak linkleri**, medicalSensitivity.

## 5. Gözlem Sınıflandırma Algoritması
Not → AI: alan doğrula/öner, etiket çıkar, milestone eşle, plan etkisi, skor sinyali, riskli ifade →
güvenli uyarı. Medya AI analizi **varsayılan kapalı**; açık rıza + mahremiyet şart.
(Bkz. örnek JSON — bölüm 6 prompt.)

## 6. Haftalık Plan Üretme Algoritması
1. En düşük skorlu alanları bul → aile odak alanlarıyla kesiştir. 2. Yaşa uygun aktivite filtrele.
3. Günlük süreye göre sınırla (gün başına ≤2). 4. Ev içi + minimum malzeme. 5. Oyunlaştırıcı dil.
6. Sonuçları dashboard/rapora bağla. Plan tipleri: Oyun odaklı, Okul öncesi, Ev rutini,
Sosyal-duygusal, Dil destekli, İnce motor. 7 gün, aktivite 5–15 dk, durum: tamamlandı/devam/ertelendi.

## 7. AI Yorumu Kuralları
Girdi: son 7 gün gözlem + son değerlendirme + tamamlanan aktivite + milestone durumu + önceki haftaya
göre değişim. **≤3 cümle**: (1) güçlü alan (2) desteklenebilir alan (3) bu hafta önerilen aksiyon.
Teşhis yok, korkutmaz, kaynaklı, gerekirse "uzmana danışın".

## 8. Çok Dilli İçerik Standardı (tr/en/nl/fr)
Tıbbi anlam korunur; Belçika'ya uygun; TR sade & aile dostu; NL/FR yerel ebeveyn dili; EN sade.
Kaynak linkleri tüm dillerde aynı. **Çeviride iddia genişletilmez, kaynakta olmayan bilgi eklenmez.**
Format: `localeVersions{tr,en,nl,fr}{title,description,parentText}` + sourceIds + version + reviewStatus.

## 9. Kaynak Kayıt Önerisi (Source Registry — başlangıç)
| id | org | tier | ülke | url |
|----|-----|------|------|-----|
| kindengezin | Kind en Gezin | official_local | BE-VL | https://www.kindengezin.be |
| one_be | ONE | official_local | BE-WB | https://www.one.be |
| who_ecd | WHO | official_intl | INTL | https://www.who.int/health-topics/early-child-development |
| cdc_milestones | CDC | official_intl | US | https://www.cdc.gov/ncbddd/actearly/milestones |
| nhs_child | NHS | official_intl | UK | https://www.nhs.uk/conditions/baby/babys-development |
| aap_healthychildren | AAP | official_intl | US | https://www.healthychildren.org |
| unicef_parenting | UNICEF | official_intl | INTL | https://www.unicef.org/parenting/child-development |

## 10. MVP Kapsamı
Yaşlar: 0-3,4-6,7-9,10-12,13-18,19-24 ay + 2,3,4,5,6 yaş. Alanlar: Dil, Motor, Sosyal-duygusal,
Bilişsel, Öz bakım, Duyusal. Her yaş: 6 alan, alan başına 3-5 milestone, ≤24 soru, 10 aktivite,
5 gözlem etiketi, 3 AI yorum şablonu, 3 aile önerisi, kaynak linkleri.
Ekranlar: Dashboard, Beceri Değerlendirme, Gözlem Ekle, Haftalık Plan, Gelişim Raporu, Kaynak Detayları.

## 11. Admin Review Akışı
`staging_content → AI QC → (medicalSensitivity high? human_review_required : auto_publish+version)`.
Review queue: `GET /admin/content/review-queue`; onay: `POST /admin/content/:id/approve`.
Kaynak linki bozulursa içerik `review_required`. Kaynak tarihi bilinmiyorsa `low confidence`.

## 12. İçerik Kalite Kontrolü (yayın öncesi)
- **Source Test:** ≥1 güvenilir kaynak, link çalışıyor, otoriter, iddiayı gerçekten destekliyor.
- **Age Test:** yaş aralığı doğru, ay yaşıyla uyumlu, erken/geç fark korkutucu değil.
- **Language Test:** aile dostu, teşhis/korkutucu dil yok, 4 dilde anlam korunmuş.
- **Safety Test:** sağlık/tarama → disclaimer, uzman yönlendirmesi, acil içerik doğru.
- **UX Test:** karta sığar, mobilde okunur, CTA net, kısa + detay ekranı uzun açıklama.

## 13. API Tasarımı
```
GET   /children/:id/development/dashboard
GET   /children/:id/development/areas
GET   /children/:id/development/milestones?ageMonths=
POST  /children/:id/development/assessment
POST  /children/:id/development/observation
GET   /children/:id/development/weekly-plan
POST  /children/:id/development/weekly-plan/generate
PATCH /children/:id/development/activities/:activityId/status
GET   /children/:id/development/report
GET   /development/sources/:sourceId
POST  /admin/content/sources/sync
GET   /admin/content/review-queue
POST  /admin/content/:contentId/approve
```

## 14. Aylık Rapor
Genel özet · Güçlü alanlar · Desteklenebilir alanlar · Tamamlanan aktiviteler · Sık gözlenen
davranışlar · Son 30 gün sinyalleri · Önerilen sonraki adımlar · Kaynaklar · Gerekirse uzman önerisi.
Dil: kısa, net, ebeveyn dostu, korkutmayan, kaynaklı, teşhis koymayan.

## 15. Test Senaryoları (örnek)
- 48 ay çocuk → değerlendirme ≤24 soru, alan başına ≥3, hepsi kaynaklı.
- Tüm "Emin değilim" → skor düşmez, confidence düşer, dashboard "ek gözlem faydalı" der.
- Kaynak linki 404 → milestone `review_required`, kullanıcıya gösterilmez.
- Gözlem "bağcıkta zorlandı" → area=self_care, secondary=fine_motor, safetyMessage=null.
- Yüksek riskli ifade içeren not → güvenli uyarı + uzman yönlendirmesi, teşhis yok.
- 4 dil: aynı milestone tr/en/nl/fr'de anlam korunmuş, sourceIds aynı.

## 16. Uygulama Yol Haritası (adım adım)
1. **(bu adım)** Kaynaklı içerik temeli: Source registry + her alan/milestone'a sourceIds +
   uygulama-içi disclaimer + Kaynak Detayları ekranı. *(backend gerektirmez)*
2. Çok dilli içerik paketi (JSON asset, tr/en/nl/fr) + locale seçimi.
3. Skor/confidence algoritmasının dashboard'a tam bağlanması (unknown→confidence).
4. Gözlem AI sınıflandırma (Gemini) + milestone eşleme.
5. AI Yorumu (son 7 gün) — Gemini, ≤3 cümle, kaynaklı.
6. Aylık Gelişim Raporu ekranı.
7. Backend: source_registry + Edge Function sync + staging + admin review (RAG motoru).
```
