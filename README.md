# lapesd-slides

Template beamer para o LAPESD.

## Compilando

A compilação **deve** ser feita com  `make`. Isso é necessário pois o `userguide.tex` usa a *feature* de animações com `svg2pdf`. Isso depende do `Makefile` para que o arquivo `imgs/animation.svg` dê origem à 5 arquivos PDF (um para cada frame da animação).

Com exceção da geração desses PDFs, os procedimentos de compilação são normais. Apenas lembre de fornecer a opção `-shell-escape`.

### Dependências

Os pacotes LaTeX usados deveriam estar presentes na maioria das instalações texlive. Verifique as variantes de pacotes `texlive-*` da sua distribuições se tiver mensagens de pacotes não encontrados.

Adicionalmente, o pacote minted necessita do pygments. Verifique as instruções de instalação de acordo com o seu sistema. No MacOS a instalação é feita com um `sudo easy_install Pygments`. No arch linux, por exemplo, o nome do pacote a ser instalado via `pacman` é `pygmentize`.

## Overleaf

A classe funciona no Overleaf, e **eventualmente** alguém atualiza esse [projeto no Overleaf](https://www.overleaf.com/read/zbmmnfkmhdwz) que pode ser usado como template. Se quiser iniciar diretamente no Overleaf, crie uma cópia do projeto e atualize o arquivo `lapesd-slides.cls` com a última versão obtida desse repositório.

O Overleaf não processa `Makefile`s, e por isso viola as instruções da seção anterior. Se usar a feature de animações com svg2pdf, você deverá gerar os PDFs localmente (usando `make`), e enviá-los ao Overleaf. A interface git pode ser usada para esse fim.

## Documentação

A documentação está na forma de slides. Veja um snapshot no [Overleaf](https://www.overleaf.com/read/zbmmnfkmhdwz).
