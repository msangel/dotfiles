#!/bin/bash

sudo apt-get install gnupg2 -q -y

# install RVM

gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
# тут коментар чому я установлюю через скрипт а не через https://github.com/rvm/ubuntu_rvm :
# справа в тому шо ubuntu_rvm ставить rvm на рівні системи по замовчуванням, в той час як я вибираю установку на рівні користувача (шо по дефолту і відбувається через установку через скрипт)
# якшо ж вам всеодно АБО це установка в контейнері то ubuntu_rvm досить таки хороше рішення
# всі нижче інструкції все ж про установку на рівні користувача. якшо ж ставити на рівні системи то автоліби не варто вимикати та і команди установки openssl і перекомпіляції з ними будуть відрізнятись(див мій коммент): https://github.com/rvm/rvm/issues/5209#issuecomment-2430429807
\curl -sSL https://get.rvm.io | bash -s -- --ignore-dotfiles
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> ~/.bashrc
sudo usermod -a -G rvm $USER
exec $SHELL -l # або рестарт/релогін шоб зміни вступили в силу
type rvm   # має показати "rvm is a function"

# виключити autolibs для того шоб рубі не міг собі встановлювати залежності на рівні системи.
# так, залежності явно треба буде поставити вручну АЛЕ 
# 1. система буде чистою від незрозумілих дублюючих версій бібліотек (openssl як живий приклад)
# 2. самі бібліотеки теж можна установити в папку користувача
rvm autolibs disable 

# власне вручну установлюю потрібну/сумісну версію openssl
curl -LO  https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz
tar xzf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w
./config --prefix=$HOME/opt/openssl-1.1 --openssldir=$HOME/opt/openssl-1.1 shared
make -j"$(nproc)"
make install_sw

#  установити флаги для вказання шляхів необхідних під час компіляції рубі при установці (нагадаю при установці рубі сам себе перекомпільовує)
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$HOME/opt/openssl-1.1"
export PKG_CONFIG_PATH="$HOME/opt/openssl-1.1/lib/pkgconfig"
export CFLAGS="-I$HOME/opt/openssl-1.1/include"
export LDFLAGS="-L$HOME/opt/openssl-1.1/lib -Wl,-rpath,$HOME/opt/openssl-1.1/lib"

# власне установка / компіляція
rvm get stable
rvm install 3.0.7
rvm --default use 3.0.7


# rubygems-bundler не підтримується, не сумісний але прописаний в глобальних gems, це бажано виправити для уникнення конфліктів
sed -i.bak '/^rubygems-bundler/d;/^rubygems-bundler-wrappers/d' ~/.rvm/gemsets/global.gems

# так як ми ставим НЕ ОСТАННЮ версію то оновлення всього через `rvm @global do gem update --system` не можлива бо буде конфлікт версій: 
# Error installing rubygems-update: rubygems-update-3.7.2 requires Ruby version >= 3.2.0. The current ruby version is 3.0.7.220.
# щоб цього уникнути установлюється конкретний rubygems-update і вже використовується він 
rvm @global do gem install rubygems-update -v 3.4.22 --no-document
# власне використання
rvm @global do update_rubygems
# з bundler все простіше
rvm @global do gem install bundler

