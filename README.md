# controle-de-exibicao

Painel interativo para ajustar a área de exibição vertical e a escala da interface do seu monitor em tempo real.

## Requisitos
*   Sistema rodando **X11**.
*   Pacotes `x11-xserver-utils` e `bc` instalados.

## Instalação
1. Instale as dependências:
`sudo apt update && sudo apt install x11-xserver-utils bc`

2. Clone ou baixe o arquivo
`git clone [https://github.com/desancto/controle-de-exibicao.git]
cd controle-de-exibicao`

3. Dê permissão de execução
`chmod +x ajustar-exibicao.sh`

## Como usar

1. Execute o script no terminal:
`./ajustar-exibicao.sh`

## Controles no painel

**Nota**: O script possui um sistema de segurança: se a nova configuração deixar a tela ilegível, basta não confirmar com 1 dentro de 5 segundos para que tudo reverta automaticamente.

