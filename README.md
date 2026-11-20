# Баранка VPN (Flutter · VLESS/Xray)

## Что внутри
- `lib/` — приложение (главный экран с бараночной кнопкой, серверы + пинг, ввод ключа, трей Windows)
- `server/` — установка сервера (`install_vless.sh`) и управление пользователями
- `docs/SMETA.md` — смета, хостинги, цена подписки

## Сборка в облаке (без установки Flutter)
1. Создайте репозиторий на github.com и загрузите в него содержимое проекта (ветка `main`).
2. Вкладка **Actions → build → Run workflow**.
3. Через ~10 минут внизу страницы запуска скачайте `baranka-windows` (папка с `.exe`) и `baranka-android-apk`.
iOS так не собрать: нужен Mac и аккаунт Apple (см. раздел iOS).

## Сборка
```bash
flutter create --platforms=windows,android,ios .   # создаст папки платформ (lib/ и pubspec не перезапишутся)
flutter pub get
```

### Windows
1. Скачайте `Xray-windows-64.zip` с https://github.com/XTLS/Xray-core/releases, положите `xray.exe` в `assets/xray/`.
2. `flutter run -d windows`, релиз: `flutter build windows`.
3. Режим: системный прокси (HTTP 127.0.0.1:10809). Чтобы перехватывать весь трафик (игры, не-браузерные программы), замените
   `WindowsEngine` на запуск sing-box/Xray в TUN-режиме с wintun.dll (нужны права администратора, манифест `requireAdministrator`).
4. Установщик: Inno Setup или MSIX (`dart run msix:create`).

### Android
- `android/app/build.gradle`: `minSdk 23` (или 24).
- Ничего больше вручную не нужно: пакет flutter_v2ray сам добавляет VpnService. Release: `flutter build appbundle`.

### iOS (нужен Mac + Apple Developer Program)
1. Откройте `ios/Runner.xcworkspace`, добавьте Capabilities: Network Extensions (Packet Tunnel) и App Groups.
2. Добавьте таргет Packet Tunnel Extension по инструкции пакета flutter_v2ray (раздел iOS), укажите
   `providerBundleIdentifier` и `groupIdentifier` в `initializeV2Ray(...)` (`lib/services/mobile_engine.dart`).
3. Apple принимает VPN-приложения только от организации (аккаунт Organization, нужен D-U-N-S, бесплатно).

## Сервер
```bash
sudo bash server/install_vless.sh          # на чистой Ubuntu 22.04/24.04
baranka-add user@mail.com                  # новый ключ пользователя
baranka-del user@mail.com                  # удалить
```
Ключ вида `vless://...` вставляется в приложение на экране «Сервера».

## Проверка
Версии пакетов зафиксируйте после первого `flutter pub get`: API flutter_v2ray, tray_manager, window_manager
меняется между релизами — если компилятор ругается на имя метода, сверьтесь с README пакета.
