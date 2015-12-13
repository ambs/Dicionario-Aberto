# Dicionario-Aberto

Código fonte de http://dicionario-aberto.net

## Como contribuir

Para montar um sistema de teste:

  1. Criar uma base de dados mysql, usando a estrutura
     disponível em [SQL/structure.sql](SQL/structure.sql)
  2. Importar os dados, usando o ficheiro disponível em
     [SQL/data-20151213.sql.xz](SQL/data-20151213.sql.xz)
  3. Criar utilizador ``dicionarioaberto`` com permissões
     de acesso total a esta base de dados, e password 
     ``password``.
  4. Instalar a stack de modulos necessários. Seguem-se
     instruções para o uso do ``App::p5stack``.
  4. ``cpanm -S App::p5stack``
  4. ``p5stack setup``

## O que contribuir

Atualmente esta não é a versão em produção. Esta nova versão
irá funcionar em Dancer2, e pretende-se que seja desenvolvida
tendo como base MVC, colocando o código Perl a funcionar como
API JSON, e o site baseado em AngularJS ou similar. Também se
pretende fazer uma alteração drástica ao design.

Sugere-se que se consulte a [lista de probemas](https://github.com/ambs/Dicionario-Aberto/issues) para se dedicar às tarefas mais relevantes em primeiro lugar.


