# Booking Platform

## 1. Přehled projektu

Tento projekt se zabývá vývojem jednoduché, ale funkční rezervační platformy pomocí Ruby on Rails. Aplikace spravuje soubor místností, z nichž každá má nastavitelný maximální počet souběžných rezervací.

Rozhraní **Rooms** zobrazuje všechny dostupné místnosti v tabulce a umožňuje uživatelům vytvářet nové místnosti zadáním názvu a maximální kapacity rezervací.

Rozhraní **Reservations** umožňuje uživatelům rezervovat existující místnost na zvolené období vymezené počátečním a koncovým datem a časem. Aplikace obsahuje vlastní algoritmus pro kontrolu kapacity, který zajišťuje, aby počet souběžných rezervací nikdy nepřekročil kapacitu vybrané místnosti. Pokud by navrhovaná rezervace toto omezení porušila, je zamítnuta a zobrazí se vlastní chybové hlášení.

Aplikace rovněž nabízí tabulku všech existujících rezervací s možnostmi jednotlivé rezervace zobrazit, upravit nebo smazat.

Celkově se projekt zaměřuje na splnění hlavních požadavků zadání, zejména na validaci rezervací, konzistenci dat a přehledné uživatelské rozhraní.

## 2. Architektura a návrhová rozhodnutí

Aplikace je postavena na dvou hlavních modelech: `Room` a `Reservation`.

Model `Room` představuje zdroje dostupné k rezervaci. Každá místnost má název a kapacitu definovanou jako maximální počet rezervací, které mohou být aktivní současně. Model `Reservation` představuje jednotlivou rezervaci, která je přiřazena ke konkrétní místnosti a vymezena počátečním a koncovým datem a časem.

Mezi těmito dvěma modely existuje vztah **jeden ku mnoha**: místnost může mít více rezervací, zatímco každá rezervace patří právě jedné místnosti. Tento vztah je implementován pomocí asociací `has_many` a `belongs_to` v Rails, přičemž `room_id` slouží jako cizí klíč.

Tyto dva modely postačují k zachycení hlavního problému bez zavádění zbytečné složitosti.

### 2.2. Obchodní logika a validace

Základním pravidlem aplikace je, že počet současně probíhajících rezervací nesmí nikdy překročit maximální kapacitu místnosti.

Toto pravidlo je implementováno přímo v modelu `Reservation` prostřednictvím vlastní validační metody. Tím je rezervační logika oddělena od kontrolerů a stejná validace se uplatní bez ohledu na to, jakým způsobem je rezervace vytvořena nebo upravena. Úplnou logickou kontrolu jsem nejprve přibližně během 30 minut vyjádřil v Pythonu a následně jsem její základní strukturu převedl do Ruby on Rails.

Kromě kontroly kapacity aplikace ověřuje, že jsou vyplněna všechna povinná pole, že kapacity místností jsou kladná celá čísla a že koncové datum a čas každé rezervace následují po jejím začátku.

Při úpravě existující rezervace algoritmus tuto rezervaci vyloučí z počátečního vyhledávání překrývajících se rezervací, aby ji nezapočítal dvakrát. Rezervace, které nesplňují validační pravidla, jsou zamítnuty a odpovídající chybová hlášení se zobrazí v uživatelském rozhraní.

### 2.3. Architektura aplikace

Aplikace využívá standardní architekturu **Model–View–Controller (MVC)** používanou ve frameworku Ruby on Rails.

- **Model** spravuje datové vztahy a validační pravidla.
- **View** zajišťuje uživatelské rozhraní (HTML, CSS, JS).
- **Controller** zpracovává požadavky aplikace a databázové operace.

Rozhodl jsem se pro jednoduchou implementaci frontendu pomocí standardních formulářů Rails, HTML a externího souboru CSS, jehož styl jsem převzal z návrhu svého osobního webu (viz repozitář [https://github.com/Dany-dan-san/portfolio-website](https://github.com/Dany-dan-san/portfolio-website)). Záznamy o místnostech a rezervacích lze zobrazovat a spravovat přímo prostřednictvím tabulkového rozhraní s rozbalovacími formuláři pro vytváření a úpravu záznamů. Tento přístup zachovává jednoduchou strukturu aplikace a klade důraz na správnost rezervační logiky namísto zbytečné složitosti frontendu.

### Organizace souborů projektu

Aplikace dodržuje obvyklou adresářovou strukturu Ruby on Rails. Následující strom zobrazuje hlavní soubory odpovědné za fungování rezervační platformy (ostatní soubory automaticky vytvořené Rails jsou pro přehlednost vynechány).

```text
reservation_system/
│
├── app/
│   ├── models/
│   │   ├── room.rb
│   │   └── reservation.rb          # Algoritmus kontroly kapacity
│   │
│   ├── controllers/
│   │   ├── rooms_controller.rb
│   │   └── reservations_controller.rb
│   │
│   ├── views/
│   │   ├── rooms/
│   │   │   ├── index.html.erb
│   │   │   ├── show.html.erb
│   │   │   ├── new.html.erb
│   │   │   └── _form.html.erb
│   │   │
│   │   └── reservations/
│   │       ├── index.html.erb
│   │       ├── show.html.erb
│   │       ├── new.html.erb
│   │       ├── edit.html.erb
│   │       └── _form.html.erb
│   │
│   └── assets/
│       └── stylesheets/
│           └── application.css
│
├── config/
│   ├── routes.rb                  # Směrování URL v aplikaci
│   └── database.yml              # Konfigurace MySQL
│
├── db/
│   ├── migrate/                   # Databázové migrace
│   ├── schema.rb                  # Struktura databáze
│   └── seeds.rb                   # Ukázkové místnosti a rezervace
│
├── Gemfile                        # Závislosti Ruby
└── README.md                      # Dokumentace projektu
```

Hlavní obchodní logika se nachází v souboru `app/models/reservation.rb`, zatímco kontrolery koordinují interakce mezi modely a příslušnými pohledy. Konfigurace databáze, její struktura a ukázková data jsou spravovány odděleně v adresářích `config/` a `db/`.

## 3. Algoritmus kontroly kapacity

Algoritmus načte existující rezervace, jejichž časové intervaly se překrývají s navrhovanou rezervací; při úpravě existujícího záznamu přitom samotnou upravovanou rezervaci vyloučí. Každý překryv je omezen na časový interval navrhované rezervace a převeden na chronologické události (`+1` na začátku a `-1` na konci), přičemž stejné události se přidají i pro navrhovanou rezervaci. Seřazením těchto událostí a průběžným sledováním počtu aktivních rezervací algoritmus zamítne rezervaci, jakmile tento počet překročí kapacitu místnosti.

Pokud dvě události nastanou ve stejném okamžiku, koncové události (`-1`) se zpracují před počátečními (`+1`). Rezervace končící v 11:00 a další začínající v 11:00 se proto nepovažují za překrývající se.

**Příklad:** Uvažujme místnost s kapacitou **2**:

| Rezervace | Začátek | Konec |
|---|---|---|
| Existující A | 09:00 | 11:00 |
| Existující B | 10:00 | 12:00 |
| Navrhovaná C | 10:30 | 11:30 |

Mezi 10:30 a 11:00 by současně probíhaly tři rezervace. Navrhovaná rezervace je proto zamítnuta. Naproti tomu další rezervace od 12:00 do 13:00 může být přijata, protože předchozí rezervace již skončily.

Tento chronologický přístup je důležitý, protože pouhé spočítání všech existujících rezervací, které se překrývají s navrhovanou rezervací, by mohlo nesprávně zamítnout platnou rezervaci: dvě existující rezervace se mohou překrývat s navrhovaným intervalem v různých časech, aniž by kdy probíhaly současně.

## 4. Instalace a spuštění

### 4.1. Požadavky

Projekt byl vyvinut v následujícím prostředí:

- Ruby 3.4
- Ruby on Rails 8.1.4
- MySQL 8.0
- Windows 11 a Visual Studio Code

Nainstalujte Ruby, Bundler a MySQL a ujistěte se, že je server MySQL spuštěný.

### 4.2. Instalace aplikace

Naklonujte repozitář a nainstalujte jeho závislosti Ruby:

```bash
git clone <repository-url>
cd reservation_system
bundle install
```

Zástupný text `<repository-url>` nahraďte adresou URL odevzdávaného repozitáře na GitHubu.

### 4.3. Konfigurace MySQL

Zkontrolujte soubor `config/database.yml` a ujistěte se, že nastavení uživatelského jména, hostitele a hesla odpovídá místnímu databázovému serveru MySQL. Pokud konfigurace načítá heslo z proměnné `MYSQL_PASSWORD`, nastavte tuto proměnnou prostředí před spuštěním Rails.

Pro Windows PowerShell:

```powershell
$env:MYSQL_PASSWORD = "your_mysql_password"
```

Databázové přihlašovací údaje ani místní tajné údaje neukládejte do repozitáře na GitHubu.

### 4.4. Inicializace databáze

V kořenovém adresáři projektu spusťte:

```bash
ruby bin/rails db:setup
```

Tento příkaz vytvoří vývojovou databázi, načte její schéma a spustí `db/seeds.rb`, čímž vloží ukázkové místnosti a rezervace. Příkaz je určen pro prvotní nastavení; neslouží k vymazání již naplněné vývojové databáze.

### 4.5. Spuštění aplikace

```bash
ruby bin/rails server
```

V prohlížeči otevřete **http://localhost:3000**. Stránky **Rooms** a **Reservations** by měly být dostupné s již načtenými ukázkovými daty.

## 5. Ukázková data a testovací scénáře

Skript `db/seeds.rb` vytváří tři místnosti s různými kapacitními limity a reprezentativními rezervacemi:

| Místnost | Kapacita | Ukázkové rezervace |
|---|---:|---|
| Room A | 1 | 10:00–11:00 |
| Room B | 2 | 09:00–11:00, 10:00–12:00 |
| Room C | 3 | 14:00–16:00, 15:00–17:00 |

Ukázkové rezervace jsou naplánovány na **dva dny po datu spuštění skriptu pro vložení dat**. Pro následující scénáře použijte toto vygenerované datum.

- **Překročení kapacity:** Vytvořte rezervaci místnosti Room B od 10:30 do 11:30. Rezervace by měla být zamítnuta, protože mezi 10:30 a 11:00 již v místnosti probíhají dvě rezervace.
- **Platná rezervace:** Vytvořte rezervaci místnosti Room B od 12:00 do 13:00. Rezervace by měla být přijata, protože obě předchozí rezervace již skončily.
- **Zbývající kapacita:** Vytvořte rezervaci místnosti Room C od 15:30 do 16:30. Rezervace by měla být přijata, protože současně nebudou aktivní více než tři rezervace.
- **Neplatný časový interval:** Nastavte konec rezervace před její začátek (nebo na stejný okamžik). Aplikace by měla zobrazit validační chybu.

Tyto příklady umožňují ověřit hlavní kapacitní pravidlo přímo prostřednictvím webového rozhraní.

## 6. Omezení a možná budoucí vylepšení

Projekt záměrně upřednostňuje hlavní pravidlo kontroly kapacity, nezbytné operace CRUD a přehledné rozhraní v rámci omezeného rozsahu zadání. Pokud bych měl na vývoj více času, zaměřil bych se na následující vylepšení:

**Ochrana proti souběžným požadavkům.** Současná validace v modelu kontroluje rezervace, které jsou viditelné v okamžiku odeslání požadavku. Dva současně zpracovávané požadavky by mohly oba projít validací dříve, než se kterýkoli z nich uloží, a tím potenciálně překročit kapacitu. Robustnější implementace by využívala databázovou transakci a vhodnou strategii zamykání při kontrole kapacity a ukládání rezervace.

**Automatizované testy.** Základní chování bylo otestováno ručně, ale opakovatelné testy modelů a HTTP požadavků by pomohly pokrýt hraniční případy, validaci dat, úpravy a překročení kapacity a snížit riziko regresí.

**Autentizace a autorizace.** Současná platforma nemá uživatelské účty a nerozlišuje mezi běžnými uživateli a administrátory. Rozšířená aplikace by mohla přiřazovat rezervace jednotlivým uživatelům a podle oprávnění omezovat správu místností nebo rušení rezervací.

**Vizualizace dostupnosti.** Kalendářové zobrazení nebo přehled dostupnosti jednotlivých místností by mohl usnadnit hledání volných časových intervalů, zejména při větším počtu rezervací.

## 7. Použité technologie

| Technologie | Úloha |
|---|---|
| Ruby 3.4 | Programovací jazyk aplikace |
| Ruby on Rails 8.1.4 | Framework MVC, asociace Active Record, kontrolery a validace |
| MySQL 8.0 | Relační úložiště místností a rezervací |
| ERB / HTML | Stránky a formuláře vykreslované na serveru |
| CSS | Samostatný soubor stylů pro rozvržení, vzhled a responzivní chování |
| Git / GitHub | Správa verzí, historie vývoje a odevzdání projektu |

Aplikace využívá standardní konvence Rails a nevyžaduje samostatný frontendový framework ani kontejner Docker.
