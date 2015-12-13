# Dicionario-Aberto

Código fonte de http://dicionrio-aberto.net

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

