#!/bin/bash
if ! dpkg -l | grep -q snapd; then
    apt install snapd -q -y
fi

if ! grep -q "/snap/bin" /etc/environment; then
    sed -ri "s|PATH=\"(.*)(\")|PATH=\"\1:/snap/bin\"|" /etc/environment
fi

snap install intellij-idea-ultimate --classic
# idea plugins, but must be auto-downloaded via jet brains sync:
# https://plugins.jetbrains.com/plugin/6884-handlebars-mustache/
# https://plugins.jetbrains.com/plugin/9746-ideolog/
# https://plugins.jetbrains.com/plugin/7358-antlr-v4-grammar-plugin/
# https://plugins.jetbrains.com/plugin/7642-save-actions
# https://plugins.jetbrains.com/plugin/4230-bashsupport
# https://plugins.jetbrains.com/plugin/7160-camelcase
# https://plugins.jetbrains.com/plugin/7150-gradle-view
# https://plugins.jetbrains.com/plugin/7808-hashicorp-terraform--hcl-language-support/
# https://plugins.jetbrains.com/plugin/10229-spring-assistant
# https://plugins.jetbrains.com/plugin/9696-java-stream-debugger
# https://plugins.jetbrains.com/plugin/9707-ansi-highlighter/
# https://plugins.jetbrains.com/plugin/7007-liveedit/
# https://plugins.jetbrains.com/plugin/6317-lombok/
# https://plugins.jetbrains.com/plugin/9275-react-css-modules/
# https://plugins.jetbrains.com/plugin/1293-ruby/
# https://plugins.jetbrains.com/plugin/9997-styled-components/
# https://plugins.jetbrains.com/plugin/9696-java-stream-debugger
