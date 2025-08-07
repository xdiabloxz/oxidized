# Dockerfile Definitivo - Usando o método COPY (o mais confiável)

# 1. Inicia com a imagem oficial.
FROM oxidized/oxidized:latest

# 2. Copia o arquivo local netbox.rb para a pasta de plugins dentro da imagem.
#    O Docker irá procurar pelo arquivo 'netbox.rb' na mesma pasta do Dockerfile.
COPY netbox.rb /home/oxidized/.config/oxidized/source/

# 3. Garante que o usuário 'oxidized' seja o dono de toda a sua pasta de config.
RUN chown -R oxidized:oxidized /home/oxidized/.config/oxidized
