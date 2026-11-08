# Współtworzenie JCUIScalera

*English version: [CONTRIBUTING.md](CONTRIBUTING.md)*

Dziękuję za zainteresowanie. Mile widziane są zgłoszenia błędów, raporty z testów na Twojej platformie, poprawki i nowe funkcje. JCUIScaler jest używany w aplikacjach produkcyjnych, dlatego zmiany muszą respektować kilka zasad architektury. Przeczytaj je przed pisaniem kodu — oszczędzi to nam obu pull requesta, którego nie da się przyjąć.

## Gdzie pomoc jest najbardziej potrzebna

Zgłoszenia z etykietą **help wanted**:

- **Zmiana monitora o innym DPI (LCL)** — przeniesienie okna z `Form.Scaled` między monitorami o różnym skalowaniu.
- **Zmiana DPI w Delphi/VCL** — ten sam problem w VCL (`OnBeforeMonitorDpiChanged` / `OnAfterMonitorDpiChanged`).
- **Skalowanie czcionek** — z dodatkową etykietą **experimental** (zob. zasady dla funkcji eksperymentalnych poniżej).

Każde z tych zgłoszeń opisuje, co już wiemy i co rozwiązanie musi zachować.

## Zasady architektury (nienegocjowalne)

1. **Deterministyczny model referencyjny.** Każde przeliczenie geometrii wychodzi od modelu zapisanego przy pierwszym `ScalerOnShow` — nigdy od bieżącego, już przeskalowanego stanu. Wielokrotna zmiana rozmiaru musi wracać do dokładnie tych samych pikseli.
2. **Wyłącznie jawne wywołania.** Skaler działa tylko w jawnych wywołaniach wykonywanych przez aplikację lub warstwę integracyjną (`ScalerInit`, `ScalerOnShow`, `ScalerOnResize`, `RestoreInitialScale`). **Nie rejestruje sam handlerów zdarzeń** formularza ani kontrolek. Dodanie nowego jawnego wywołania (np. dla zmiany monitora) jest dopuszczalne.
3. **`object`, nie `class`.** `TJCUIScaler` pozostaje typem `object`. Jego czas życia nie może zależeć od kontrolek formularza.
4. **Brak zależności od DPI w rdzeniu.** Rdzeń skaluje wyłącznie na podstawie geometrii okna; nie odczytuje DPI systemu.
5. **Warstwa integracyjna a rdzeń.** Komponent `TJCScaler` może podpinać zdarzenia formularza, ale wyłącznie po to, by wywołać metody publiczne rdzenia. Nowa funkcjonalność powinna w miarę możliwości trafiać do warstwy integracyjnej (zdarzenia, metody wirtualne), nie do rdzenia.
6. **Najpierw konfiguracja, potem kod.** Problemy wynikające z zachowania LCL lub widgetsetów rozwiązuje się w pierwszej kolejności zaleceniem konfiguracyjnym lub opisem w dokumentacji (zob. Specyfikacja, sekcja 13.1), nie zmianą rdzenia.
7. **Stabilne API.** Nazwa i publiczne API `TJCUIScaler` muszą pozostać zgodne — integracja ręczna jest używana w aplikacjach produkcyjnych.

Zmiany w rdzeniu są po wersji 1.0 możliwe, ale wyłącznie w granicach tych zasad.

### Zmiany dotykające sekwencji OnShow/OnResize

Kolejność zdarzeń to najbardziej wrażliwy obszar. Każda zmiana, która jej dotyka (także prace nad zmianą monitora), musi zachować **zachowanie identyczne z 1.0, gdy nowa sytuacja nie występuje** — np. bez zmiany monitora wszystko działa dokładnie jak dotąd.

### Funkcje eksperymentalne (np. skalowanie czcionek)

- **Domyślnie wyłączone**, włączane jawnie (np. właściwością).
- **Po wyłączeniu zachowanie identyczne z bieżącą wersją** — bit w bit.
- **Determinizm obowiązuje także w trybie eksperymentalnym.**
- Opisz zachowanie na każdej platformie, na której testowałeś.

## Konwencje kodu

- Komentarze po angielsku. Końce linii CRLF (pilnuje tego `.gitattributes`).
- **Zgodność źródłowa z Delphi:** bloki `{$IFDEF FPC}` ograniczone do minimum; bez konstrukcji wyłącznie LCL-owych w rdzeniu bez osłony. Komponent i pakiety są wyłącznie dla Lazarusa.
- Każdy nowy plik źródłowy ma nagłówek licencyjny taki jak istniejące pliki. **Nie usuwaj informacji o prawach autorskich ani nazwiska pierwotnego autora** z plików źródłowych.

## Testy

- Demo i oba pakiety muszą się budować — **CI sprawdza to automatycznie** przy każdym pushu i pull requeście (Linux/GTK2).
- W pull requeście opisz, co i na jakiej platformie testowałeś (system, wersja Lazarusa/FPC, widgetset), i dołącz zrzuty ekranu **przed i po**, jeśli zmiana jest widoczna.
- Przed scaleniem zmiany w rdzeniu opiekun wykonuje porównanie A/B dema co do piksela (przed i po). Nie musisz odtwarzać tego środowiska.

## Dokumentacja

Dokumentem utrzymywanym jest **Specyfikacja Techniczna** (`docs/pl`, `docs/en`). Jeśli zmiana wpływa na działanie, konfigurację lub API, opisz ją w pull requeście; specyfikację aktualizuje opiekun (dokumentem źródłowym jest wersja polska). Dokumenty w `docs/*/Additional` są zapisem procesu do wersji 1.0 i nie są na bieżąco aktualizowane.

## Zgłoszenia i pull requesty

- Korzystaj z szablonów zgłoszeń (błąd, raport z testu na platformie, propozycja funkcji). Można pisać po angielsku lub po polsku.
- Jeden temat na jeden pull request.
- Szablon pull requesta zawiera krótką listę kontrolną powyższych zasad.

## Licencja

Przesyłając wkład, zgadzasz się na jego rozpowszechnianie na licencji projektu (GNU Library General Public License wersja 2 z wyjątkiem dla linkowania statycznego — zob. `LICENSE`).
