# Dockerfile Corrigido para Instalação do Plugin do NetBox

# 1. Inicia com a imagem oficial e estável
FROM oxidized/oxidized:latest

# 2. Instala a gem correta para a fonte de dados do NetBox
# O nome correto é "oxidized-netbox-sourcer", como visto no artigo.
RUN gem install oxidized-netbox-sourcer
