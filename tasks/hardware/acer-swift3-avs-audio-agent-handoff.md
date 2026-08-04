# Передача контексту новому агенту: Acer Swift SF315-52, AVS-аудіо, Ubuntu 26.04 та Ansible

**Призначення документа:** повністю відновити контекст після видалення початкового чату та дати новому агенту достатньо інформації, щоб безпечно супроводжувати аудіофікс після оновлень ядра, Ubuntu, ALSA, firmware, PipeWire або WirePlumber.

**Дата фіксації контексту:** 2026-08-05, Europe/Kyiv  
**Основний репозиторій:** https://github.com/msangel/dotfiles/tree/master  
**Стан `master`, на якому складено документ:** `9ff4438a64b6621a566106442addd1397443cf82`  
**Коміт, що додав поточний AVS-фікс:** `8bbe09c9774b0d4b57379ed7689380ef49b2a974`

- Поточний snapshot: https://github.com/msangel/dotfiles/tree/9ff4438a64b6621a566106442addd1397443cf82
- Коміт аудіофіксу: https://github.com/msangel/dotfiles/commit/8bbe09c9774b0d4b57379ed7689380ef49b2a974

> **Правило для нового агента:** спочатку прочитати актуальний стан репозиторію та зібрати новий precheck з реальної машини. Цей документ пояснює логіку та історію, але поточний GitHub і фактична система є джерелами істини.

---

## 1. Відповідь на питання про прив’язку до версії ядра

У поточній ролі **є пряма і жорстка прив’язка до версії ядра**, причому у двох місцях.

У `vars/hardware/acer-swift3-audio.yml` зафіксовано:

```yaml
swift3_audio_tested_platform:
  running_kernel: 7.0.0-28-generic

swift3_audio_tested_packages:
  linux-image-generic: 7.0.0-28.28
```

А в `tasks/hardware/acer-swift3/audio.yml` є окрема перевірка:

```yaml
- name: Verify tested running kernel
  ansible.builtin.assert:
    that:
      - ansible_kernel == swift3_audio_tested_platform.running_kernel
```

Тобто роль перевіряє:

1. версію встановленого метапакета `linux-image-generic`;
2. фактично запущене ядро через `ansible_kernel`.

Окрім цього, роль виконує **capability checks**, які важливіші для фактичної працездатності:

- активний драйвер PCI-пристрою має бути `snd_soc_avs`;
- потрібні AVS topology firmware-файли мають існувати;
- потрібні ALSA UCM-файли мають існувати;
- DMIC-карта має реально з’явитися;
- `alsaucm` має відкрити `HiFi`;
- `DMIC Volume` має бути ненульовим;
- PipeWire має створити карту і source.

Отже, правильне формулювання:

> Версія ядра в поточному коді зафіксована як safety lock, але сама по собі вона не визначає, чи працює звук. Реальний результат залежить щонайменше від ядра, firmware, UCM, mixer state і PipeWire/WirePlumber.

### Важливий сценарій після оновлення ядра

Можливий стан:

```text
linux-image-generic installed = 7.0.0-29.29
uname -r                    = 7.0.0-28-generic
```

Це означає: нове ядро встановлене, але система ще працює на старому, бо не було reboot.

Не можна просто записати обидві нові версії в lock-файл. Правильний порядок:

1. зафіксувати старий стан;
2. перезавантажитися в нове ядро;
3. переконатися через `uname -r`, що запущене саме воно;
4. виконати повний precheck;
5. протестувати всі аудіоканали;
6. лише після цього оновити обидва version pins.

---

## 2. Точна модель і апаратна конфігурація

Сценарій створено **не для всіх Acer Swift 3**, а для конкретної моделі та аудіопідсистеми.

### DMI

```text
sys_vendor=Acer
product_name=Swift SF315-52
product_version=V1.08
board_vendor=KBL
board_name=Erdinger_KL
bios_vendor=American Megatrends Inc.
bios_version=V1.08
```

### PCI-аудіопристрій

```text
Intel Sunrise Point-LP HD Audio
PCI vendor/device:       8086:9d71
PCI subsystem:           1025:1272
class:                   040100
expected active driver:  snd_soc_avs
codec:                   Realtek ALC256
```

### Очікувані ALSA-карти

Номери карт **не можна хардкодити**. У перевіреній системі вони були такими:

```text
card 0: HDAudio — AVS HD-Audio
card 1: HDMI    — AVS HDMI
card 2: PROBE   — AVS PROBE
card 3: DMIC    — AVS DMIC
```

У старішій конфігурації DMIC був `card 2`, а після змін стека став `card 3`. Саме тому роль шукає карту динамічно через:

```bash
/sys/class/sound/card*/id
```

та вибирає карту, для якої:

```text
id == DMIC
```

---

## 3. Який результат має бути збережений

Після фіксу одночасно мають працювати:

- вбудовані динаміки;
- навушники;
- аналоговий мікрофон гарнітури через 3.5 мм;
- вбудований цифровий масив мікрофонів AVS DMIC;
- PipeWire/WirePlumber;
- вибір AVS DMIC як default source;
- відновлення працездатності після чистого reboot.

Робочий PipeWire source у перевіреній системі:

```text
alsa_input.platform-avs_dmic.pro-input-0
```

Робоча PipeWire card prefix:

```text
alsa_card.platform-avs_dmic
```

Фактичне ім’я карти може мати suffix, тому поточний runtime-скрипт шукає:

```text
точне ім’я або ім’я, що починається з alsa_card.platform-avs_dmic.
```

---

## 4. Історична проблема та хибні шляхи

### 4.1. Не форсувати `snd_hda_intel`

Історичний workaround:

```text
options snd-intel-dspcfg dsp_driver=1
```

або аналогічний modprobe override змушує систему використовувати legacy `snd_hda_intel`.

Це може повернути:

- динаміки;
- HDA analog input;
- мікрофон гарнітури.

Але на цій моделі воно відключає окрему AVS DMIC-карту, тобто вбудований цифровий мікрофон зникає.

Тому очікуваний драйвер:

```text
snd_soc_avs
```

Поточна роль шукає forced override в `/etc/modprobe.d/*.conf`, перейменовує файл у `.disabled`, запускає:

```bash
update-initramfs -u
```

та вимагає reboot.

### 4.2. `snd_hda_intel` у `lsmod` сам по собі не означає помилку

У перевіреній системі модуль `snd_hda_intel` був завантажений, але фактичний PCI driver був:

```text
/sys/bus/pci/devices/0000:00:1f.3/driver -> snd_soc_avs
```

Дивитися треба не лише `lsmod`, а:

```bash
lspci -nnk
```

або sysfs symlink `.../driver`.

### 4.3. `hdajackretask` не виправляє вбудований DMIC

Відомі спостереження:

- HDA pin `0x19` відповідає мікрофону гарнітури;
- спроба зробити `0x12` Internal Mic давала білий шум;
- вбудований мікрофон не є звичайним HDA pin input;
- це окрема AVS DMIC-карта.

Тому `hdajackretask` не є рішенням для цього кейсу.

---

## 5. Чому одного нового ядра недостатньо

Проблема розділена щонайменше на п’ять незалежних шарів.

### 5.1. Kernel driver

Ядро повинно:

- розпізнати `8086:9d71 / 1025:1272`;
- вибрати `snd_soc_avs`;
- створити AVS HDA, HDMI, PROBE і DMIC-карти;
- не падати під час завантаження topology.

### 5.2. AVS topology firmware

Потрібні:

```text
/usr/lib/firmware/intel/avs/dmic-tplg.bin.zst
/usr/lib/firmware/intel/avs/hda-generic-1ep-tplg.bin.zst
/usr/lib/firmware/intel/avs/hda-generic-tplg.bin.zst
/usr/lib/firmware/intel/avs/hda-808628xx-3ep-tplg.bin.zst
/usr/lib/firmware/intel/avs/hda-8086-generic-tplg.bin.zst
```

У Ubuntu 26.04 вони штатно входять до:

```text
linux-firmware-intel-misc
```

Офіційний file list:

https://packages.ubuntu.com/resolute/all/linux-firmware-intel-misc/filelist

### 5.3. ALSA UCM

Потрібні:

```text
/usr/share/alsa/ucm2/conf.d/avs_dmic/Acer-Lars-1.0.conf
/usr/share/alsa/ucm2/Intel/avs/avs_dmic/DMIC-2ch.conf
/usr/share/alsa/ucm2/Intel/avs/avs_dmic/DMIC-2ch-HiFi.conf
```

Офіційний file list Ubuntu:

https://packages.ubuntu.com/resolute/all/alsa-ucm-conf/filelist

ALSA UCM documentation:

- https://www.alsa-project.org/alsa-doc/alsa-lib/group__ucm.html
- https://www.alsa-project.org/alsa-doc/alsa-lib/group__ucm__conf.html

UCM використовує дані карти, зокрема driver/name/longname, для пошуку конфігурації. На цій машині:

```text
driver:    avs_dmic
card id:   DMIC
long name: AVS DMIC
```

### 5.4. ALSA mixer state

Навіть після появи карти і UCM контрол:

```text
DMIC Volume
```

у перевіреній системі мав значення:

```text
0
```

Потрібне робоче значення:

```bash
amixer -c "$DMIC_CARD" cset name='DMIC Volume' 2147483647
```

Після зміни роль виконує:

```bash
alsactl store "$DMIC_CARD"
```

### 5.5. PipeWire/WirePlumber

Навіть працюючий ALSA device може не бути доступний програмам, якщо:

- PipeWire-карта має `Active Profile: off`;
- UCM не завантажився;
- source не створено;
- default source вказує на інший пристрій;
- user PipeWire session ще не запущена.

Потрібні операції:

```bash
pactl set-card-profile <actual-card-name> pro-audio
pactl set-default-source <actual-source-name>
```

WirePlumber ALSA documentation:

https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/alsa.html

WirePlumber використовує UCM за замовчуванням, коли UCM доступний; `pro-audio` лишається практичним fallback/activation profile для цього кейсу.

---

## 6. Яка саме проблема залишалася в Ubuntu 26.04

У перевіреному Ubuntu 26.04 були вже присутні:

- kernel із `snd_soc_avs`;
- усі AVS topology files;
- новий ALSA userspace;
- `Acer-Lars-1.0.conf`;
- `DMIC-2ch.conf`;
- `DMIC-2ch-HiFi.conf`;
- PipeWire;
- WirePlumber.

Але не було:

```text
/usr/share/alsa/ucm2/conf.d/avs_dmic/AVS DMIC.conf
/usr/share/alsa/ucm2/conf.d/avs_dmic/avs_dmic.conf
```

Через це:

```bash
alsaucm -c hw:3 list _verbs
```

повертало помилку відкриття UCM.

Робочий mapping:

```bash
ln -sfn Acer-Lars-1.0.conf \
  "/usr/share/alsa/ucm2/conf.d/avs_dmic/AVS DMIC.conf"
```

Поточна роль не хардкодить `AVS DMIC`. Вона:

1. знаходить DMIC card number;
2. отримує long name;
3. формує `${CardLongName}.conf`;
4. спочатку тестує `alsaucm`;
5. створює symlink лише якщо UCM не працює.

Для поточної системи динамічний результат:

```text
CardLongName = AVS DMIC
mapping path = /usr/share/alsa/ucm2/conf.d/avs_dmic/AVS DMIC.conf
```

### Upstream issue

https://github.com/alsa-project/alsa-ucm-conf/issues/497

Стан на момент складання документа: **open**.

Issue прямо описує відсутній mapping для Acer Swift SF315-52 та workaround через `avs_dmic.conf`.

### Пов’язаний PR

https://github.com/alsa-project/alsa-ucm-conf/pull/499

Стан на момент складання документа:

- closed;
- draft;
- `merged: false`;
- стосується HDA configuration для AVS;
- не можна вважати його доказом, що DMIC mapping повністю виправлено.

### Upstream `Acer-Lars-1.0.conf`

https://github.com/alsa-project/alsa-ucm-conf/blob/master/ucm2/conf.d/avs_dmic/Acer-Lars-1.0.conf

На момент перевірки upstream master містив UCM-файл із `HiFi`, який включає:

```text
/Intel/avs/avs_dmic/DMIC-2ch-HiFi.conf
```

В Ubuntu package цей шлях міг бути представлений symlink-ом на `DMIC-2ch.conf`. Поточний локальний mapping посилається на `Acer-Lars-1.0.conf`, тому залишається сумісним з обома packaging representations.

---

## 7. Kernel-side виправлення та чому issue все одно релевантний

У коментарях до issue #497 користувачі повідомляли:

- kernel-side patch працює в kernel `6.15.2-1`;
- kernel `6.16` також працював у Fedora client kernels.

Пов’язані посилання:

- https://bugzilla.kernel.org/show_bug.cgi?id=219654
- https://bugzilla.opensuse.org/show_bug.cgi?id=1243826
- https://github.com/alsa-project/alsa-ucm-conf/issues/497

Але перевірена Ubuntu-система вже працює на:

```text
7.0.0-28-generic
```

і все одно мала:

- відсутній UCM mapping;
- `DMIC Volume=0`;
- відсутній `pactl`, доки не встановлено `pulseaudio-utils`.

Це практичний доказ для цього ноутбука:

> Kernel-side fix був необхідний для коректного AVS support, але не закрив userspace integration повністю.

---

## 8. Перевірений системний стек 2026-08-04

### ОС

```text
Ubuntu 26.04 LTS
codename: resolute
architecture: amd64 / x86_64
running kernel: 7.0.0-28-generic
```

### Встановлені пакети

```text
linux-image-generic          7.0.0-28.28
linux-firmware               20260319.git217ca6e4.1ubuntu
linux-firmware-intel-misc    20260319.git217ca6e4-0ubuntu1
alsa-ucm-conf                1.2.15.3-1ubuntu1.4
libasound2t64                1.2.15.3-1ubuntu1.1
libasound2-data              1.2.15.3-1ubuntu1.1
alsa-utils                   1.2.15.2-1ubuntu1
pipewire                     1.6.2-1ubuntu1.1
pipewire-pulse               1.6.2-1ubuntu1.1
wireplumber                  0.5.13-1ubuntu1
```

На момент precheck candidate для kernel metapackage вже був:

```text
linux-image-generic candidate = 7.0.0-29.29
```

Це важливо: candidate не означає, що роль уже перевірена на ньому.

---

## 9. Історичний Ubuntu 24.04 workaround — лише для контексту

На Ubuntu 24.04 Noble раніше доводилося:

1. точково витягувати AVS topology з Plucky firmware package;
2. оновлювати ALSA userspace до 1.2.13;
3. накладати новіший `alsa-ucm-conf`;
4. створювати mapping;
5. встановлювати mixer;
6. активувати PipeWire profile.

Історичні URL:

```text
https://launchpadlibrarian.net/799759938/linux-firmware_20250317.git1d4c88ee-0ubuntu1.3_amd64.deb

http://archive.ubuntu.com/ubuntu/pool/main/a/alsa-lib/libasound2t64_1.2.13-1ubuntu0.1_amd64.deb
http://archive.ubuntu.com/ubuntu/pool/main/a/alsa-lib/libasound2-data_1.2.13-1ubuntu0.1_all.deb
http://archive.ubuntu.com/ubuntu/pool/main/a/alsa-utils/alsa-utils_1.2.13-1ubuntu1_amd64.deb

https://github.com/alsa-project/alsa-ucm-conf/archive/refs/heads/master.tar.gz
```

### Заборона для поточного Ubuntu 26.04

Не треба:

- завантажувати firmware з Plucky;
- встановлювати вручну старі Plucky ALSA packages;
- накладати `alsa-ucm-conf master` поверх `/usr/share/alsa/ucm2`;
- використовувати старі checksums;
- змішувати Noble fix і Resolute fix в одному branch без чіткого OS dispatch.

У 26.04 потрібні firmware і UCM-файли вже є в штатних пакетах.

---

## 10. Поточна структура репозиторію

### Bootstrap

`install.sh`:

https://github.com/msangel/dotfiles/blob/master/install.sh

Поточні важливі значення:

```bash
DOWNLOAD_PLAYBOOK=false
USE_LOCAL_ROLE=true
LOG_LEVEL=0
```

`LOG_LEVEL`:

```text
0 = normal/minimal
1 = -v
2 = -vv
3 = -vvv
4 = -vvvv
```

Скрипт передає:

```text
target_user
target_home
use_local_role
local_role_path
ansible_python_interpreter
```

### Playbook

https://github.com/msangel/dotfiles/blob/master/playbook.yml

Може:

- включити local role;
- або отримати актуальний `master` SHA;
- завантажити archive за exact SHA;
- встановити temporary role;
- виконати його;
- очистити temporary directory.

### Підготовка користувача

https://github.com/msangel/dotfiles/blob/master/tasks/00.prepare.yml

Готує:

```text
target_home
target_group
target_uid_result
```

`target_uid_result.stdout` потрібен аудіофіксу для:

```text
/run/user/${UID}
DBUS session bus
user systemd
PipeWire/WirePlumber
```

### Main tasks

https://github.com/msangel/dotfiles/blob/master/tasks/main.yml

Викликає:

```yaml
- name: Configure Acer Swift 3
  ansible.builtin.import_tasks: hardware/acer-swift3.yml
  when: is_swift3
```

### DMI selector та defaults

https://github.com/msangel/dotfiles/blob/master/defaults/main.yml

```yaml
is_swift3: >-
  {{
    (ansible_facts.system_vendor | default('') | trim | lower) == 'acer'
    and
    (ansible_facts.product_name | default('') | trim | lower) == 'swift sf315-52'
  }}

swift3_audio_enabled: true
swift3_audio_enforce_tested_stack: true
swift3_audio_reboot: false
```

### Hardware entry point

https://github.com/msangel/dotfiles/blob/master/tasks/hardware/acer-swift3.yml

Містить лише імпорт аудіофіксу:

```yaml
- name: Configure Swift 3 AVS audio
  ansible.builtin.import_tasks: acer-swift3/audio.yml
  when: swift3_audio_enabled | bool
```

Не повертати сюди старий `remote-host.yml`: користувач прямо відмовився від нього.

### Version lock та paths

https://github.com/msangel/dotfiles/blob/master/vars/hardware/acer-swift3-audio.yml

### Реалізація

https://github.com/msangel/dotfiles/blob/master/tasks/hardware/acer-swift3/audio.yml

---

## 11. Що робить поточний `audio.yml`

Нижче не копія всіх 700+ рядків, а точна карта логіки. Перед змінами агент повинен читати актуальний файл із GitHub.

### Фаза A — завантаження lock variables

Завантажує:

```text
vars/hardware/acer-swift3-audio.yml
```

### Фаза B — hard identity checks

Перевіряє:

- Ubuntu;
- version `26.04`;
- codename `resolute`;
- architecture `x86_64`;
- Acer;
- Swift SF315-52;
- product version V1.08;
- board Erdinger_KL;
- BIOS V1.08.

### Фаза C — package installation і version lock

Встановлює штатні dependencies:

```text
pciutils
alsa-utils
alsa-ucm-conf
libasound2t64
libasound2-data
linux-firmware-intel-misc
pipewire
pipewire-pulse
wireplumber
pulseaudio-utils
```

Після цього перевіряє exact versions із `swift3_audio_tested_packages`, якщо:

```yaml
swift3_audio_enforce_tested_stack: true
```

`pulseaudio-utils` і `pciutils` зараз не включені до exact version lock. Вони розглядаються як diagnostic/runtime utilities, а не ядро протестованого audio stack.

### Фаза D — kernel lock

Окремо перевіряє:

```text
ansible_kernel == 7.0.0-28-generic
```

### Фаза E — legacy driver override cleanup

Шукає:

```text
options snd-intel-dspcfg ... dsp_driver=1
```

Якщо знаходить:

- перейменовує файл у `.disabled`;
- не перезаписує існуючий різний backup;
- виконує `update-initramfs -u`;
- ставить `swift3_audio_reboot_required=true`.

### Фаза F — firmware installation reboot logic

Якщо `linux-firmware-intel-misc` до запуску був відсутній:

- встановлює;
- ставить reboot required.

За замовчуванням:

```yaml
swift3_audio_reboot: false
```

Тому роль не перезавантажує машину сама, а завершується з поясненням і просить:

1. reboot;
2. повторно запустити `install.sh`.

### Фаза G — PCI та codec capability checks

Динамічно знаходить exact PCI device:

```text
8086:9d71
1025:1272
```

та перевіряє driver:

```text
snd_soc_avs
```

Потім перевіряє:

```text
Realtek ALC256
```

у `/proc/asound/card*/codec*`.

### Фаза H — firmware і UCM files

Перевіряє всі required paths із vars.

### Фаза I — DMIC dynamic discovery

Знаходить `cardN`, де:

```text
/sys/class/sound/cardN/id == DMIC
```

Отримує long name з `/proc/asound/cards`.

### Фаза J — UCM test та conditional mapping

Спочатку запускає:

```bash
alsaucm -c "hw:$N" list _verbs
```

Якщо `HiFi` вже є:

- symlink не створюється;
- upstream/package support вважається достатнім.

Якщо UCM не працює:

- обчислюється `${longname}.conf`;
- існуючий mapping за потреби backup-иться як `.pre-ansible-backup`;
- некоректний mapping видаляється;
- створюється symlink на `Acer-Lars-1.0.conf`;
- UCM перевіряється повторно.

### Фаза K — mixer

Активує:

```bash
alsaucm -c "hw:$N" set _verb HiFi
```

Читає:

```bash
amixer -c "$N" cget name='DMIC Volume'
```

Якщо `values=0`, ставить maximum integer і зберігає state.

### Фаза L — PipeWire runtime helper

Створює:

```text
~/.local/bin/swift3-audio-runtime
```

Helper:

- до 30 секунд чекає `pactl info`;
- шукає actual PipeWire card за prefix;
- якщо API/card/source не доступні, повертає `ANSIBLE_DEFERRED`, а не падає;
- перемикає profile на `pro-audio`;
- шукає preferred або fallback AVS DMIC source;
- робить source default;
- друкує `ANSIBLE_CHANGED`, якщо щось змінив.

### Фаза M — persistent user service

Створює:

```text
~/.config/systemd/user/swift3-audio-runtime.service
```

та symlink у:

```text
~/.config/systemd/user/default.target.wants/
```

Це дозволяє застосувати profile/default source при наступному login, навіть якщо Ansible запускався без активної user PipeWire session.

### Фаза N — live user-session handling

Якщо є:

```text
/run/user/${UID}/bus
```

роль:

- restart-ить WirePlumber/PipeWire після UCM або mixer changes;
- робить `systemctl --user daemon-reload`;
- запускає runtime helper.

Усі user-команди виконуються з:

```text
become_user = target_user
HOME = target_home
XDG_RUNTIME_DIR = /run/user/${UID}
DBUS_SESSION_BUS_ADDRESS = unix:path=/run/user/${UID}/bus
```

---

## 12. Важливі властивості та недоліки поточного рішення

### 12.1. Рішення idempotent за основними effect checks

Повторний запуск не повинен:

- повторно створювати правильний mapping;
- змінювати ненульовий mixer;
- повторно змінювати правильний PipeWire profile;
- повторно змінювати правильний default source.

### 12.2. Exact version lock навмисно суворий

Будь-який drift зупиняє роль до аудіозмін. Це відповідає вимозі користувача: не застосовувати неперевірений hardware fix після оновлення залежностей.

### 12.3. BIOS version теж суворо зафіксована

BIOS update може зупинити роль, навіть якщо PCI audio hardware не змінилося.

Новий агент не повинен автоматично видаляти цю перевірку. Спочатку:

- повторно зняти DMI;
- перевірити PCI IDs;
- перевірити ACPI/kernel behavior;
- прогнати аудіотести;
- тоді оновити `bios_version`.

### 12.4. Локальний mapping може приховати upstream fix

Це дуже важливо.

Якщо файл:

```text
/usr/share/alsa/ucm2/conf.d/avs_dmic/AVS DMIC.conf
```

вже створений попереднім запуском ролі, то після оновлення `alsa-ucm-conf`:

```bash
alsaucm ... list _verbs
```

продовжить працювати через старий локальний workaround.

Тобто просто побачити `HiFi` недостатньо, щоб заявити, що upstream уже виправив проблему.

Для чистої перевірки треба тимчасово прибрати локальний mapping і протестувати пакетний стан.

### 12.5. Поточна роль сама не видаляє workaround після upstream fix

Якщо native/package mapping з’явиться, але локальний symlink уже існує, роль не доведе, що він більше не потрібен і не прибере його автоматично.

Майбутня версія ролі може додати explicit cleanup, але лише після clean-room verification.

### 12.6. `alsactl store` змінює `/var/lib/alsa/asound.state`

Поточний код не створює окремий backup цього файлу перед першим `alsactl store`.

Перед великим refactor можна додати:

```bash
cp -a /var/lib/alsa/asound.state \
  /var/lib/alsa/asound.state.pre-swift3-audio-fix
```

із `creates`, але не змінювати поточну працюючу систему без причини.

### 12.7. Є кілька фактичних змінних, які зараз не впливають на результат

У поточному коді можуть бути невикористані або лише diagnostic facts, наприклад:

```text
swift3_audio_runtime_available
swift3_audio_pci_path
swift3_audio_disabled_overrides
```

Не видаляти їх механічно під час термінового version bump. Окремий cleanup робити після тестів.

---

## 13. Обов’язковий workflow після оновлення пакетів або ядра

### Крок 1 — нічого не «виправляти» наосліп

Не починати з:

```yaml
swift3_audio_enforce_tested_stack: false
```

і не запускати всю роль на неперевіреному стеку.

Спочатку лише діагностика.

### Крок 2 — зафіксувати Git і систему

```bash
git -C /path/to/dotfiles status
git -C /path/to/dotfiles rev-parse HEAD
git -C /path/to/dotfiles log -1 --oneline

date --iso-8601=seconds
uname -a
cat /etc/os-release
```

### Крок 3 — зняти package versions

```bash
packages=(
  linux-image-generic
  linux-firmware
  linux-firmware-intel-misc
  alsa-ucm-conf
  libasound2t64
  libasound2-data
  alsa-utils
  pipewire
  pipewire-pulse
  wireplumber
  pulseaudio-utils
)

for p in "${packages[@]}"; do
  installed="$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null || echo MISSING)"
  candidate="$(apt-cache policy "$p" | awk '/Candidate:/ {print $2; exit}')"
  printf '%-32s installed=%-32s candidate=%s\n' \
    "$p" "$installed" "${candidate:-NONE}"
done
```

### Крок 4 — перевірити booted kernel окремо

```bash
uname -r
dpkg-query -W -f='${Version}\n' linux-image-generic
```

Не плутати installed metapackage і running kernel.

### Крок 5 — перевірити DMI та PCI

```bash
cat /sys/class/dmi/id/sys_vendor
cat /sys/class/dmi/id/product_name
cat /sys/class/dmi/id/product_version
cat /sys/class/dmi/id/board_name
cat /sys/class/dmi/id/bios_version

lspci -Dnnk
```

Очікувати:

```text
8086:9d71
1025:1272
Kernel driver in use: snd_soc_avs
```

### Крок 6 — перевірити local overrides

```bash
grep -RniE \
  'snd-intel-dspcfg|dsp_driver|snd_hda_intel' \
  /etc/modprobe.d || true
```

### Крок 7 — перевірити firmware ownership

```bash
for f in \
  dmic-tplg.bin.zst \
  hda-generic-1ep-tplg.bin.zst \
  hda-generic-tplg.bin.zst \
  hda-808628xx-3ep-tplg.bin.zst \
  hda-8086-generic-tplg.bin.zst
do
  path="/usr/lib/firmware/intel/avs/$f"
  ls -l "$path"
  readlink -f "$path"
  dpkg-query -S "$path" || true
done
```

### Крок 8 — динамічно знайти DMIC

```bash
for card in /sys/class/sound/card[0-9]*; do
  [ -r "$card/id" ] || continue
  printf '%s id=%s\n' "$(basename "$card")" "$(cat "$card/id")"
done

cat /proc/asound/cards
arecord -l
```

### Крок 9 — перевірити UCM

```bash
DMIC_CARD="$(
  for card in /sys/class/sound/card[0-9]*; do
    [ -r "$card/id" ] || continue
    [ "$(cat "$card/id")" = DMIC ] || continue
    basename "$card" | sed 's/^card//'
    break
  done
)"

alsaucm -c "hw:$DMIC_CARD" list _verbs
```

### Крок 10 — перевірити mixer

```bash
amixer -c "$DMIC_CARD" cget name='DMIC Volume'
```

### Крок 11 — перевірити PipeWire

Від імені desktop user:

```bash
systemctl --user is-active pipewire
systemctl --user is-active pipewire-pulse
systemctl --user is-active wireplumber

pactl info
pactl list short cards
pactl list short sources
pactl list cards
```

Якщо `pactl` відсутній:

```bash
sudo apt install pulseaudio-utils
```

Це не означає, що PulseAudio server замінює PipeWire. `pactl` працює через PipeWire PulseAudio compatibility service.

---

## 14. Clean-room перевірка: чи upstream mapping уже виправлено

Виконувати обережно, з backup.

### 14.1. Визначити mapping

Для поточного long name:

```bash
mapping="/usr/share/alsa/ucm2/conf.d/avs_dmic/AVS DMIC.conf"
```

### 14.2. Перевірити ownership

```bash
dpkg-query -S "$mapping" || true
ls -l "$mapping"
```

Якщо `dpkg-query -S` нічого не знаходить, це локальний файл/symlink.

### 14.3. Тимчасово прибрати локальний workaround

```bash
sudo mv \
  "$mapping" \
  "${mapping}.test-disabled"
```

Не видаляти одразу.

### 14.4. Перевстановити package за потреби

```bash
sudo apt install --reinstall alsa-ucm-conf
```

### 14.5. Перевірити чистий пакетний стан

```bash
alsaucm -c "hw:$DMIC_CARD" list _verbs
```

#### Якщо `HiFi` працює без локального symlink

Це означає, що новий пакет/upstream lookup уже достатній.

Далі:

1. перевірити mixer;
2. перевірити PipeWire;
3. перезавантажитися;
4. перевірити ще раз;
5. змінити роль так, щоб локальний mapping більше не створювався;
6. додати cleanup старого symlink лише з перевіркою ownership/target;
7. видалити `${mapping}.test-disabled` після успішних тестів.

#### Якщо UCM знову падає

Workaround ще потрібний:

```bash
sudo mv \
  "${mapping}.test-disabled" \
  "$mapping"
```

або дозволити ролі відновити його.

---

## 15. Перевірка mixer після оновлення UCM

Навіть якщо UCM lookup виправлено upstream, не робити висновок, що mixer fix уже не потрібний.

Перевірити після чистого boot:

```bash
amixer -c "$DMIC_CARD" cget name='DMIC Volume'
```

Потім:

```bash
alsaucm -c "hw:$DMIC_CARD" set _verb HiFi
amixer -c "$DMIC_CARD" cget name='DMIC Volume'
```

Можливі результати:

1. `DMIC Volume` одразу ненульовий після boot — package/kernel/UCM уже ініціалізує його;
2. до `set _verb HiFi` нуль, після — ненульовий;
3. залишається нуль — manual mixer fix ще потрібний.

Прибирати mixer task можна лише після повторюваного успіху на чистому boot.

---

## 16. PipeWire/WirePlumber acceptance checks

### Карта

Має бути карта з ім’ям:

```text
alsa_card.platform-avs_dmic
```

або з suffix після цього prefix.

### Profile

Не повинен залишатися:

```text
Active Profile: off
```

Поточний fallback:

```text
pro-audio
```

### Source

Очікувано:

```text
alsa_input.platform-avs_dmic.pro-input-0
```

Але код має підтримувати інше ім’я з prefix:

```text
alsa_input.platform-avs_dmic.
```

### Default source

```bash
pactl info | grep '^Default Source:'
```

### Persistence

Повторити всі перевірки:

1. після logout/login;
2. після reboot;
3. після повторного запуску Ansible.

---

## 17. Запис і playback: правильні команди

### Direct ALSA test

```bash
arecord \
  -D "hw:${DMIC_CARD},0" \
  -f S16_LE \
  -c 2 \
  -r 48000 \
  -d 5 \
  /tmp/swift3-dmic.wav

aplay /tmp/swift3-dmic.wav
```

### PipeWire test

У встановленій версії `pw-record` параметр `--duration` був відсутній.

Не використовувати:

```bash
pw-record --duration 5 ...
```

Використовувати `timeout`:

```bash
timeout 5s pw-record \
  --target alsa_input.platform-avs_dmic.pro-input-0 \
  --channels 2 \
  --rate 48000 \
  /tmp/swift3-pw-dmic.wav || true

pw-play /tmp/swift3-pw-dmic.wav
```

Тихіший рівень вбудованого мікрофона допускається, якщо голос чітко присутній і немає лише білого шуму.

---

## 18. Повна acceptance matrix

Фікс вважається перевіреним лише якщо виконані всі пункти.

### Hardware

- [ ] DMI відповідає Acer Swift SF315-52.
- [ ] PCI device `8086:9d71`.
- [ ] subsystem `1025:1272`.
- [ ] codec Realtek ALC256.
- [ ] active driver `snd_soc_avs`.

### Kernel/firmware

- [ ] Немає active `dsp_driver=1` override.
- [ ] Усі topology files присутні.
- [ ] Kernel log не містить fatal AVS/topology errors.
- [ ] Після reboot DMIC card з’являється.

### ALSA

- [ ] HDAudio card існує.
- [ ] HDMI card існує.
- [ ] DMIC card існує.
- [ ] Номер DMIC визначається динамічно.
- [ ] `alsaucm ... list _verbs` повертає `HiFi`.
- [ ] `DMIC Volume` ненульовий.
- [ ] Direct `arecord` записує голос.

### PipeWire

- [ ] `pipewire` active.
- [ ] `pipewire-pulse` active.
- [ ] `wireplumber` active.
- [ ] AVS DMIC card існує.
- [ ] profile не `off`.
- [ ] AVS DMIC source існує.
- [ ] source можна зробити default.
- [ ] `pw-record` записує голос.

### User-visible functions

- [ ] Вбудовані динаміки працюють.
- [ ] Навушники працюють.
- [ ] Headset mic працює.
- [ ] Internal DMIC працює.
- [ ] Все зберігається після reboot.

### Ansible

- [ ] Перший запуск робить лише необхідні зміни.
- [ ] Другий запуск не робить повторних змін.
- [ ] Без `swift3_audio_reboot=true` автоматичного reboot немає.
- [ ] Version drift зупиняє роль до hardware modifications.
- [ ] Немає ручних Plucky packages на Resolute.

---

## 19. Як оновлювати version lock

Файл:

```text
vars/hardware/acer-swift3-audio.yml
```

### Оновлювати лише після повного тесту

Поля:

```yaml
swift3_audio_tested_platform:
  version:
  codename:
  architecture:
  product_version:
  board_name:
  bios_version:
  running_kernel:

swift3_audio_tested_packages:
  linux-image-generic:
  linux-firmware-intel-misc:
  alsa-ucm-conf:
  libasound2t64:
  libasound2-data:
  alsa-utils:
  pipewire:
  pipewire-pulse:
  wireplumber:
```

### Версії брати лише з фактично встановлених пакетів

```bash
dpkg-query -W -f='${Package}=${Version}\n' \
  linux-image-generic \
  linux-firmware-intel-misc \
  alsa-ucm-conf \
  libasound2t64 \
  libasound2-data \
  alsa-utils \
  pipewire \
  pipewire-pulse \
  wireplumber
```

Не копіювати `Candidate:` у lock, поки package не встановлений і не протестований.

### YAML quoting

Для майбутніх змін краще брати package versions у лапки:

```yaml
linux-image-generic: "7.0.0-29.29"
```

Це знімає неоднозначність YAML parsing.

---

## 20. Decision tree для типових збоїв

### Role fails: untested package version

Причина: package drift.

Дії:

1. не вимикати safety lock назавжди;
2. зняти precheck;
3. прочитати changelog;
4. перевірити upstream issue;
5. протестувати clean system state;
6. оновити lock після acceptance matrix.

### Role fails: untested running kernel

Перевірити:

```bash
uname -r
dpkg-query -W linux-image-generic
```

Можливо, потрібен лише reboot у вже встановлене ядро.

### Expected PCI device not found

Не застосовувати workaround.

Перевірити:

- DMI;
- `lspci -Dnn`;
- BIOS;
- чи не інша ревізія ноутбука;
- чи не змінився PCI enumeration.

### Driver is `snd_hda_intel`

Перевірити modprobe overrides та kernel parameters.

Не продовжувати до DMIC tasks: AVS DMIC може взагалі не існувати.

### Firmware missing

На Ubuntu 26.04+:

```bash
sudo apt install --reinstall linux-firmware-intel-misc
```

Не використовувати Plucky deb без окремої доказової причини.

Після firmware change — reboot.

### DMIC card missing

Перевірити:

```bash
journalctl -b -k | grep -Ei 'avs|dmic|topology|firmware|snd'
```

Це kernel/firmware/probe level, а не PipeWire.

### UCM fails but files exist

Перевірити:

- long name;
- mapping filename;
- package ownership;
- local stale symlink;
- upstream changes у lookup;
- `alsaucm -c hw:N list _verbs`.

### UCM works, але mixer zero

Залишити mixer fix.

### `pactl` command not found

Встановити:

```bash
sudo apt install pulseaudio-utils
```

### PipeWire Pulse API unavailable

Перевірити user session:

```bash
echo "$XDG_RUNTIME_DIR"
echo "$DBUS_SESSION_BUS_ADDRESS"
systemctl --user status pipewire pipewire-pulse wireplumber
```

Не запускати `pactl` як root без user-session environment.

### PipeWire card not found одразу після restart

Поточний runtime helper чекає до 30 секунд і може повернути deferred.

Перевірити після login або запустити user service вручну:

```bash
systemctl --user start swift3-audio-runtime.service
journalctl --user -u swift3-audio-runtime.service
```

### Source name змінився

Не хардкодити лише exact source. Зберегти prefix fallback.

---

## 21. Rollback

### Driver override

Якщо роль перейменувала:

```text
/etc/modprobe.d/example.conf
->
/etc/modprobe.d/example.conf.disabled
```

для rollback:

```bash
sudo mv \
  /etc/modprobe.d/example.conf.disabled \
  /etc/modprobe.d/example.conf

sudo update-initramfs -u
sudo reboot
```

Але це поверне legacy driver і, ймовірно, прибере internal DMIC.

### UCM mapping

Поточний mapping:

```text
/usr/share/alsa/ucm2/conf.d/avs_dmic/AVS DMIC.conf
```

Видалити локальний symlink:

```bash
sudo rm \
  "/usr/share/alsa/ucm2/conf.d/avs_dmic/AVS DMIC.conf"
```

Якщо існує backup:

```text
AVS DMIC.conf.pre-ansible-backup
```

відновити його.

### User runtime service

```bash
rm -f \
  ~/.config/systemd/user/default.target.wants/swift3-audio-runtime.service

rm -f \
  ~/.config/systemd/user/swift3-audio-runtime.service

rm -f \
  ~/.local/bin/swift3-audio-runtime

systemctl --user daemon-reload
```

### ALSA state

Перед rollback спочатку inspect:

```bash
grep -n -A8 -B4 'DMIC Volume' /var/lib/alsa/asound.state
```

Не видаляти весь state без backup: там є стани інших аудіопристроїв.

---

## 22. Інтернет-перевірки, обов’язкові перед майбутньою зміною

Новий агент повинен виконати свіжий пошук, бо стан після 2026-08-05 може змінитися.

### Ubuntu package versions

Перевірити для фактичного release:

- `linux-image-generic`
- `linux-firmware-intel-misc`
- `alsa-ucm-conf`
- `libasound2t64`
- `libasound2-data`
- `alsa-utils`
- `pipewire`
- `pipewire-pulse`
- `wireplumber`
- `pulseaudio-utils`

Base:

https://packages.ubuntu.com/

### File lists

https://packages.ubuntu.com/resolute/all/linux-firmware-intel-misc/filelist

https://packages.ubuntu.com/resolute/all/alsa-ucm-conf/filelist

Для нового Ubuntu release замінити `resolute` на актуальний codename.

### Upstream ALSA UCM issue

https://github.com/alsa-project/alsa-ucm-conf/issues/497

Перевірити:

- open/closed;
- останні comments;
- linked PR/commit;
- чи є конкретний commit, що додає mapping;
- чи виправлення увійшло до release/tag;
- чи цей release уже запакований в Ubuntu.

### Upstream files

https://github.com/alsa-project/alsa-ucm-conf/tree/master/ucm2/conf.d/avs_dmic

Перевірити, чи з’явився один із:

```text
AVS DMIC.conf
avs_dmic.conf
```

Але наявність upstream file ще не означає, що він уже є в Ubuntu package.

### Kernel issue

https://bugzilla.kernel.org/show_bug.cgi?id=219654

### WirePlumber

https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/alsa.html

Перевірити зміни profile/UCM policy, якщо оновилася major/minor версія WirePlumber.

---

## 23. Пріоритет джерел

У разі суперечностей використовувати такий порядок:

1. фактичний стан конкретного ноутбука;
2. актуальний код `msangel/dotfiles`;
3. офіційний Ubuntu package metadata та file lists;
4. upstream ALSA/kernel/PipeWire repositories і documentation;
5. upstream issues та maintainer comments;
6. сторонні форуми та user reports.

Коментар «у kernel X уже працює» не переважає реальний тест на цьому ноутбуці.

---

## 24. Що агент не повинен робити

- Не повертати `remote-host.yml`.
- Не додавати SSH/GDM/TeamViewer/RustDesk до hardware audio fix.
- Не форсувати `snd_hda_intel`.
- Не використовувати `hdajackretask` для internal DMIC.
- Не припускати, що DMIC завжди `card 2` або `card 3`.
- Не вважати нове ядро повним вирішенням.
- Не вважати наявність `Acer-Lars-1.0.conf` достатньою.
- Не вважати `HiFi` доказом upstream fix, поки локальний mapping не прибрано для clean test.
- Не завантажувати старі Plucky packages у Ubuntu 26.04.
- Не накладати `alsa-ucm-conf master` поверх package-managed tree без крайньої причини.
- Не запускати автоматичний reboot без `swift3_audio_reboot=true`.
- Не запускати user PipeWire commands без environment цільового користувача.
- Не оновлювати version pins лише за `apt-cache candidate`.
- Не видаляти працюючий workaround до завершення reboot acceptance tests.
- Не заявляти idempotence без другого запуску Ansible.

---

## 25. Рекомендований формат роботи нового агента

Коли користувач повернеться після оновлення і скаже, що роль зупинилася на version drift:

1. отримати актуальний GitHub `master`;
2. попросити або створити read-only precheck;
3. порівняти старий і новий stack;
4. виконати web verification офіційних package/file lists;
5. перевірити issue #497 і kernel issue;
6. визначити, які workaround-и все ще реально потрібні;
7. не змінювати роль до завершення diagnosis;
8. зробити мінімальний patch;
9. дати користувачу exact diff або повний файл;
10. запустити Ansible;
11. виконати acceptance matrix;
12. reboot;
13. повторити tests;
14. запустити Ansible вдруге;
15. лише після цього оновити tested versions і commit.

---

## 26. Мінімальний контекст, який треба надати агенту разом із цим документом

Попросити нового агента прочитати:

```text
https://github.com/msangel/dotfiles/tree/master
```

і особливо:

```text
defaults/main.yml
tasks/main.yml
tasks/00.prepare.yml
tasks/hardware/acer-swift3.yml
tasks/hardware/acer-swift3/audio.yml
vars/hardware/acer-swift3-audio.yml
install.sh
playbook.yml
```

Додати новий precheck log з машини після оновлення.

---

## 27. Короткий технічний підсумок

Це Acer Swift SF315-52 із Intel Sunrise Point-LP HD Audio `8086:9d71`, subsystem `1025:1272`, Realtek ALC256.

Правильний driver path:

```text
snd_soc_avs
```

Internal microphone — окрема AVS DMIC-карта, не HDA pin.

Ubuntu 26.04 уже надає kernel, firmware та базові UCM-файли, але в перевіреному стеку автоматичний UCM lookup для card long name `AVS DMIC` не працював без локального mapping:

```text
AVS DMIC.conf -> Acer-Lars-1.0.conf
```

Після цього все одно потрібно було виправити:

```text
DMIC Volume = 0
```

та активувати PipeWire profile/source.

Поточна Ansible-роль:

- жорстко обмежена exact hardware/OS/version stack;
- використовує capability checks;
- динамічно знаходить DMIC;
- створює mapping тільки коли UCM не працює;
- змінює mixer тільки коли він zero;
- застосовує PipeWire runtime config у user session;
- не reboot-ить без окремої змінної;
- зупиняється на неперевіреному stack drift.

Це і є базова архітектура, яку треба зберегти під час майбутніх оновлень.
