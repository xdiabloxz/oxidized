# 1. Comece com a imagem oficial que já sabemos que funciona.
# Usar uma versão específica é uma boa prática para estabilidade.
FROM oxidized/oxidized:latest

# 2. Instale o plugin (gem) para a fonte de dados do NetBox.
# Esta é a única personalização que precisamos.
RUN gem install oxidized-sourcer-netbox
