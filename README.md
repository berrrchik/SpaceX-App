# SpaceX iOS

> UIKit-приложение, которое показывает ракеты SpaceX, историю и детали запусков с возможностью фильтрации.

---

## Демо

---

**Ключевые экраны:**
- `Rockets`: карточки ракет с тех. характеристиками, стадиями и стоимостью запуска.
- `Launches`: список запусков конкретной ракеты с фильтрацией, сортировкой и пагинацией.
- `Launch Detail`: агрегированные детали миссии (ракета, полезные нагрузки, экипаж, капсулы, корабли, ссылки).
- `Settings`: переключение единиц измерения (м/ft, кг/lb) с сохранением в `UserDefaults`.

---

## Функционал

- Просмотр ракет SpaceX с деталями по ступеням, дате первого запуска, стране и стоимости запуска.
- Переход к запускам выбранной ракеты.
- Фильтры запусков: статус (`all/successful/failed/upcoming`), год, фильтрация по дате запуска.
- Сортировка запусков (новые/старые), бесконечная подгрузка страниц.
- Детальный экран запуска с объединением данных из нескольких эндпоинтов SpaceX API.
- Offline fallback: при сетевой ошибке используются кэшированные данные.
- Локализация интерфейса: `ru` и `en`.

---

## Технические решения

- **Разделение слоев:** `Features/*/Domain`, `Data`, `Presentation`, `UI`.
- **DI через `AppContainer`:** централизованная сборка зависимостей и фабрики ViewModel.
- **Паттерн Coordinator:** переходы вынесены из контроллеров в `AppCoordinator`.
- **Работа с сетью:** `URLSessionHTTPClient` с политикой повторных попыток.
- **Состояния экрана:** единая модель `LoadableState` (`idle/loading/loaded/empty/failed`).
- **Параллельные запросы:** `withTaskGroup` в `LaunchDetailRepository` для связанных сущностей.
- **Diffable Data Source:** стабильные снапшоты списка запусков и удобный UI.
- **Кэш:** `UserDefaults`-хранилища для ракет и запусков, стабильная работа без интернета.

## Технологии

- **Swift 5.0+**
- **UIKit** - весь UI построен на `UIView`/`UIViewController`.
- **Swift Concurrency (`async/await`, `Task`, `withTaskGroup`)** - загрузка и агрегация сетевых данных.
- **URLSession** - база сетевого слоя (`URLSessionHTTPClient` + retry policy).
- **SnapKit** - декларативная верстка Auto Layout.
- **Kingfisher** - загрузка, плейсхолдеры и кэширование изображений.
- **Combine** - мониторинг состояния сети в `NetworkMonitor`.
- **UserDefaults** - хранение настроек и кэша данных.
- **XCTest** - модульные и snapshot-тесты в `SpaceXTests`.
- **Зависимости SPM:** `SnapKit`, `Kingfisher`.

## API

Приложение использует официальное SpaceX API:
- **Ракеты**: `https://api.spacexdata.com/v4/rockets`
- **Запуски**: `https://api.spacexdata.com/v4/launches`

### Особенности работы с API
- **Единый HTTP-клиент:** все запросы проходят через `URLSessionHTTPClient` и `RequestBuilder`.
- **Декодирование JSON:** `keyDecodingStrategy = .convertFromSnakeCase`, поэтому DTO остаются чище.
- **Политика повторных попыток:** запросы повторяются при временных сетевых ошибках (`timedOut`, `networkConnectionLost`, `notConnectedToInternet` и др.).
- **Кэш + fallback:** при offline/ошибках репозитории возвращают кэшированные данные и помечают состояние как `isStale`.
- **Пагинация запусков:** список запусков запрашивается страницами (`page`, `limit`).
- **Клиентская фильтрация и сортировка:** по статусу/году/поиску/порядку, без дополнительных API-запросов.
- **`Launch Detail` как агрегатор:** отдельный экран собирает данные по связанным сущностям (launchpad, rocket, payloads, crew, capsules, ships) из нескольких endpoint'ов.

---

## Архитектура

Приложение построено по схеме **MVVM + Coordinator** с явным разделением на слои:
- `Domain` — модели и правила предметной области.
- `Data` — удаленные источники данных, мапперы, репозитории, кэш.
- `Presentation` — ViewModel и состояние экранов.
- `UI` — UIKit-экраны и компоненты.

## Структура проекта

```text
SpaceX/
├── App/                    # точка входа, coordinator и DI-контейнер
├── Core/                   # networking, formatting, logging, settings, UI-тема
├── Features/               # feature-модули (Domain/Data/Presentation/UI)
│   ├── Rockets/
│   ├── Launches/
│   ├── LaunchDetail/
│   ├── Launchpad/
│   └── Settings/
├── Shared/                 # локализация и общие extensions
└── Supporting/             # ассеты и вспомогательные ресурсы

SpaceXTests/                # unit/snapshot-тесты
```

### Ключевые модули

- `Features/Rockets`: экран ракет + форматирование display-модели.
- `Features/Launches`: пагинация, фильтрация, сортировка, snapshot builder.
- `Features/LaunchDetail`: объединение данных из launch/rocket/payload/crew/capsule/ship.
- `Features/Settings`: store + observer-механизм для обновления единиц измерения.

---

## Тестирование

Тестовый таргет `SpaceXTests`.

Покрытые зоны:
- cache stores (`RocketCacheStoreTests`, `LaunchCacheStoreTests`), включая поврежденные данные.
- offline/reliability-сценарии репозиториев (`RocketRepositoryOfflineTests`, `LaunchRepositoryOfflineTests`).
- агрегирование деталей запуска (`LaunchDetailRepositoryTests`).
- state transitions ViewModel (`LaunchViewModelTests`, `LaunchListViewModelTests`, `LaunchDetailViewModelTests`, `RocketViewModelTests`).
- форматирование и query-логика (`RocketFormattingTests`, `LaunchQueryTests`, `LaunchMapperTests`).
- snapshot-тесты diffable-снапшотов (`LaunchDiffableSnapshotTests`).

---

## Конфиденциальность

- Приложение не требует авторизации и не собирает персональные данные пользователя.
- Локально сохраняются только:
  - предпочтения единиц измерения,
  - кэш ракет и запусков для offline fallback.
- Источник данных: публичный SpaceX API (`/v4/rockets`, `/v4/launches`).

---

## Установка и запуск приложения

### Требования

- iOS 13.0+
- Xcode 14.0+
- Swift 5+

### Быстрый старт (Xcode)

1. Клонируйте репозиторий:
   `git clone https://github.com/berrrchik/SpaceX-App.git`
2. Перейдите в папку проекта:
   `cd SpaceX`
3. Откройте проект:
   `open SpaceX.xcodeproj`
4. В Xcode дождитесь, пока Swift Package Manager подтянет зависимости.
5. Выберите схему `SpaceX` и симулятор.
6. Нажмите `Cmd + R` для запуска.

### Запуск

1. `open SpaceX.xcodeproj`
2. Выберите схему `SpaceX`.
3. Запустите на симуляторе (`Cmd + R`).