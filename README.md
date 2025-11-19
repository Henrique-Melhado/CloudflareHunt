- Fetches DNS and IP history for a domain using the SecurityTrails API.
- Busca histórico de DNS e IP de um domínio usando a API SecurityTrails.
----
``` Usage: ruby cloudflarhunt.rb <domain> ```

---- 
- To use this script, you need a SecurityTrails API key.
- Para usar este script, você precisa de uma chave de API do SecurityTrails.
----
- 1. Go to https://securitytrails.com/corp/api and sign up for a free account.
- 1. Acesse https://securitytrails.com/corp/api e crie uma conta gratuita.
- 2. Get your API key from your account dashboard.

- 2. Obtenha sua chave de API no painel da sua conta.
- 3. Set the API key as an environment variable:

- 3. Defina a chave de API como variável de ambiente:
-   ``` export SECURITYTRAILS_API_KEY='your_api_key' ```

-   ``` export SECURITYTRAILS_API_KEY='sua_chave_api'```

``` echo "export SECURITYTRAILS_API_KEY='your_api_key'" >> ~/.zshrc ```

``` echo "export SECURITYTRAILS_API_KEY='sua_chave_api'" >> ~/.zshrc ```
