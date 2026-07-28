# FH-01 — Migration 066 (health_records) uygulama
#
# NEDEN BU SCRIPT: Supabase'in doğrudan DB bağlantısı IPv6-only olduğu için
# `migration repair` / `db push` pooler'a düşemiyor ve DB şifresi istiyor.
# Şifre interaktif sorulur — bu yüzden senin çalıştırman gerekiyor.
#
# NE YAPAR:
#   1) 000-065 migration'larını "uygulanmış" işaretler (SADECE geçmiş tablosu;
#      hiçbir SQL çalıştırmaz, veriye dokunmaz) — böylece db push 66 migration'ı
#      canlı DB'ye yeniden oynatmaz.
#   2) Yalnızca 066'yı (health_records + RLS) uygular.
#   3) Sonucu doğrular.
#
# KULLANIM (PowerShell):
#   cd C:\Users\spqr_\Desktop\familyhub
#   .\docs\remediation\apply_066.ps1
#
# DB şifresi: Supabase Dashboard > Project Settings > Database > Database password
# (Bilmiyorsan aynı sayfadan "Reset database password" ile yenileyebilirsin.)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..\..

Write-Host "== 1/3: Migration gecmisi onariliyor (metadata-only) ==" -ForegroundColor Cyan
$versions = @('000','001','002','003','005','006','007','008','009','010','011','012',
  '013','014','015','016','017','018','019','020','021','022','023','024','025','026',
  '027','028','029','030','031','032','033','034','035','036','037','038','039','040',
  '042','043','044','045','046','047','048','049','050','051','052','053','054','055',
  '056','057','058','059','060','061','062','063','064','065')
npx --yes supabase@latest migration repair --status applied @versions
if ($LASTEXITCODE -ne 0) { throw "repair basarisiz" }

Write-Host "`n== 2/3: Yalnizca 066 uygulaniyor ==" -ForegroundColor Cyan
npx --yes supabase@latest db push
if ($LASTEXITCODE -ne 0) { throw "db push basarisiz" }

Write-Host "`n== 3/3: Dogrulama ==" -ForegroundColor Cyan
npx --yes supabase@latest migration list --linked

Write-Host "`nTAMAM. 066 satirinda 'remote' dolu gorunuyorsa health_records olusmustur." -ForegroundColor Green
Write-Host "Ciktiyi Claude'a yapistir; FH-01 VERIFIED yapilacak." -ForegroundColor Green
